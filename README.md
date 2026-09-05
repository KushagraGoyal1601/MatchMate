# MatchMate

A matrimonial-style iOS app that fetches profiles from the Random User API, shows them as
cards, and lets you Accept or Decline from either the list or a full profile screen.
Decisions are stored locally, survive relaunch, work offline, and stay in sync between the
two screens.

## Running it

```
open MatchMate/MatchMate.xcodeproj
```

Select the **MatchMate** scheme and run on any iOS 18+ simulator. No dependencies, no
package resolution, no API key.

- Built with Xcode 26.6, Swift 5 language mode
- Deployment target: iOS 18.0

## Architecture

MVVM + Repository + Service. Dependencies point inward, every seam is a protocol, and
everything is constructor-injected.

```
Views ──────────► ViewModels ──────────► ProfileRepositoryProtocol
(SwiftUI)          @Observable                    │
                   @MainActor                     ├── ProfileNetworkRepository ──► NetworkService ──► URLSession
                                                  └── ProfilePersistenceRepository ──► CoreDataStack
```

```
App/          MatchMateApp, DependencyManager   — composition root
Models/       MatchProfile, MatchStatus, AppError
Views/        SwiftUI screens and shared components
ViewModels/   ProfileListViewModel, ProfileDetailViewModel
Network/      NetworkService, requests, wire models, mapper, monitor, image loader
              └── Repository/ ProfileNetworkRepository
Persistence/  CoreDataStack, entity, mapper, errors
              └── Repository/ ProfilePersistenceRepository
Repositories/ ProfileRepository — composes the two above
```

**Boundaries that are actually enforced, not just documented:**

- `NSManagedObject` cannot leave the persistence layer. `CoreDataStack.perform` requires its
  return type to be `Sendable`, and managed objects are not — so the compiler rejects any
  attempt to leak an entity. Every store method converts to `MatchProfile` inside the block.
- Wire models (`Profile`, `ProfileResponse`) never leave `Network/`. `ProfileMapper` converts
  them to domain models at the network repository boundary.
- `NetworkError` and `PersistenceError` never reach a ViewModel. `ProfileRepository` maps both
  onto `AppError`, so presentation depends on nothing below it.
- The data layer imports only `Foundation`, `Network` and `CoreData` — no SwiftUI anywhere.

**Concurrency.** The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`, so the data
layer needs no annotations and ViewModels are explicitly `@MainActor`. Repositories are
`actor`s, so network and database work stays off the main thread by construction.

**Dependency injection.** `DependencyManager` is the composition root and builds each
dependency lazily on first use — `NetworkMonitor` never starts its `NWPathMonitor` unless
something asks for it. It is `@MainActor` because `lazy var` is not thread-safe and two
concurrent first-accesses would otherwise build two instances. Nothing else touches the
container: every type takes its dependencies through `init`, which is why the tests never
reference it.

## Database choice: Core Data

Chosen over SwiftData for four concrete reasons this app actually needs:

1. **Explicit background contexts.** `performBackgroundTask` plus an explicit merge policy
   gives direct control over where writes happen. SwiftData's `ModelActor` is newer and
   leaves less room to tune this.
2. **Uniqueness constraints.** `id` has a real uniqueness constraint in the model, so a
   concurrent double-insert resolves via the merge policy instead of duplicating a profile.
3. **Predicate control.** Pagination reads a window of rows with an explicit `sortIndex`
   predicate and `fetchLimit`.
4. **A lower deployment floor.** SwiftData needs iOS 17+; Core Data does not constrain the
   target at all.

SwiftData would have been less code. For an app whose hardest requirement is *"one source of
truth, list and detail must never disagree"*, the explicit control was worth the extra lines.

## How pagination works

`https://randomuser.me/api/?page=N&results=10&seed=matchmate`

The list prefetches when a card **3 rows from the end** appears, so the next page usually
lands before the user reaches it.

Three details that matter more than they look:

- **The scroll trigger is `.onAppear`, not `.task`.** SwiftUI cancels a row's `.task` when the
  row scrolls away — which during a fast flick is exactly when the request is in flight. The
  page would silently never arrive.
- **The re-entrancy guard is synchronous.** `loadNextPageIfNeeded` checks `isLoading` *before*
  its first `await`. Since the ViewModel is `@MainActor`, three rows appearing in the same
  frame cannot start three requests. There is a test for this.
- **A failed page is not retried by scrolling.** Without that guard, every subsequent
  `onAppear` would hammer a failing endpoint. It takes an explicit tap on Retry.

Order is persisted. Core Data fetches are unordered without a sort descriptor, so cached
profiles would come back scrambled after relaunch. Each row gets a `sortIndex` assigned once
at insert and never rewritten. Sorting by `updatedAt` would have been wrong — it changes on
every decision, so accepting someone would make their card jump up the list.

## How status sync works

**The repository is write-through, and reads only ever come out of the database.**

```
profiles(page:)
   ├─ if online:  fetch page → upsert into Core Data
   └─ always:     read that page back OUT of Core Data and return it
```

The network result is never returned directly. That is what makes *"list and detail should
never disagree"* structural rather than a matter of discipline — the UI cannot display
anything that is not persisted. It also collapses online and offline into one code path.

**The trap.** `seed=matchmate` means page 1 returns the same ten people every time, always
with `status: pending`. A naive upsert wipes every decision on refresh. So the merge rule is:

- **row exists** → refresh the display fields only; `statusRaw` and `sortIndex` are left alone
- **row is new** → insert, with `sortIndex = (page - 1) * pageSize + offset`

**Keeping both screens in step.** `ProfileRepository` broadcasts on an `AsyncStream`, and both
ViewModels subscribe:

```
detail: accept → repository writes to Core Data → reads the row back → broadcasts
                                                                          │
                                          list VM patches the matching row ┘
```

The broadcast carries what the **database** holds, not what the caller asked for, so every
screen converges on stored truth. The list card is already correct before the pop animation
starts — hence no refresh on back. It works in both directions: acting on the list updates an
open detail screen too.

## Offline

`NetworkMonitor` (`NWPathMonitor`) is consulted *before* a request is attempted, so offline
skips the network entirely rather than waiting for a timeout.

- offline **with** cache → cached profiles, plus a banner. No error.
- offline **without** cache → `AppError.offline` and a full-screen state
- online but the request fails → still falls back to cache; the error only surfaces if the
  cache is empty too

Accept/Decline is a local write, so it behaves identically online and offline.

Profile photos are cached separately by `ImageLoader`, which owns a 50 MB disk `URLCache`.
When a request fails it retries with `.returnCacheDataDontLoad` — bypassing freshness so a
stale photo still draws instead of dying on a revalidation it cannot perform offline.

## Error handling

Three error types, one presentation type.

| Layer | Type | Examples |
|---|---|---|
| Network | `NetworkError` | `notConnected`, `timedOut`, `unacceptableStatusCode`, `decodingFailed` |
| Database | `PersistenceError` | `storeUnavailable`, `fetchFailed`, `saveFailed`, `notFound` |
| Presentation | `AppError` | `offline`, `requestFailed`, `storageFailed`, `unexpected` |

`URLError` never escapes the network layer, and `AppError` is the only error a ViewModel sees.
Task cancellation is converted to `CancellationError` at the repository boundary, so a
cancelled prefetch during a fast scroll never surfaces as an error toast.

A failed decision **rolls back**: the card flips optimistically for instant feedback, and if
the write fails the previous status is restored and the error is surfaced.

If Core Data fails to open, `CoreDataStack` records it and every operation throws
`storeUnavailable` — the app shows an error instead of crashing at launch.

## Tests

28 ViewModel tests, all passing. The assignment asks for ViewModel tests specifically, so the
suite stubs `ProfileRepositoryProtocol` — no network, no database anywhere in the target.

- `ProfileListViewModelTests` (19) — loading, pagination, prefetch threshold, concurrent-trigger
  collapse, page-failure isolation, no-auto-retry, retry recovery, decisions with rollback,
  connectivity, empty state, duplicate-ID prevention
- `ProfileDetailViewModelTests` (6) — accept/decline, rollback on failure, external updates
- `ProfileListDetailSyncTests` (3) — list ↔ detail status sync in both directions
