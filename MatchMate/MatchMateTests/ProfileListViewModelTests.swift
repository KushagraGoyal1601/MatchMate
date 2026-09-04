//
//  ProfileListViewModelTests.swift
//  MatchMateTests
//
//  Created by Kushagra Goyal on 05/09/26.
//

import Testing
import Foundation
@testable import MatchMate

@MainActor
struct ProfileListViewModelTests {

    private let pageSize = APIConfiguration.pageSize

    // MARK: - Loading

    @Test func initialLoadFetchesTheFirstPage() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.profiles.count == pageSize)
        #expect(repository.requestedPages == [1])
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func initialLoadIsSkippedWhenProfilesAreAlreadyLoaded() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadInitialIfNeeded()

        #expect(repository.requestedPages == [1], "re-entering the screen must not refetch")
    }

    // MARK: - Pagination

    @Test func scrollingNearTheEndLoadsTheNextPage() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)

        #expect(repository.requestedPages == [1, 2])
        #expect(viewModel.profiles.count == pageSize * 2)
    }

    @Test func earlyRowsDoNotTriggerPrefetch() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles[0])

        #expect(repository.requestedPages == [1], "the top of the list must not prefetch")
    }

    @Test func concurrentScrollTriggersFetchThePageOnce() async {
        let repository = StubProfileRepository()
        repository.loadDelay = .milliseconds(80)
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        let last = viewModel.profiles.last!
        async let first: Void = viewModel.loadNextPageIfNeeded(after: last)
        async let second: Void = viewModel.loadNextPageIfNeeded(after: last)
        async let third: Void = viewModel.loadNextPageIfNeeded(after: last)
        _ = await (first, second, third)

        #expect(repository.requestedPages == [1, 2])
        #expect(viewModel.profiles.count == pageSize * 2)
    }

    @Test func pagingContinuesWithoutACap() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        for _ in 0..<12 {
            await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)
        }

        #expect(viewModel.profiles.count == pageSize * 13)
        #expect(viewModel.hasMorePages)
    }

    @Test func pagingStopsWhenAPageComesBackEmpty() async {
        let repository = StubProfileRepository()
        repository.emptyFromPage = 4
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        for _ in 0..<8 {
            await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)
        }

        #expect(repository.requestedPages == [1, 2, 3, 4], "one empty page is enough to stop")
        #expect(viewModel.profiles.count == pageSize * 3)
        #expect(!viewModel.hasMorePages)
        #expect(viewModel.showsEndOfList)
    }

    @Test func pagingNeverProducesDuplicateIDs() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        for _ in 0..<3 {
            await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)
        }

        let ids = viewModel.profiles.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Errors

    @Test func firstPageFailureSurfacesAnErrorAndLeavesTheListEmpty() async {
        let repository = StubProfileRepository()
        repository.failOnPage = 1
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.profiles.isEmpty)
        #expect(viewModel.errorMessage == "Stubbed failure")
        #expect(!viewModel.showsEmptyState, "an error is not an empty state")
    }

    @Test func nextPageFailureKeepsTheLoadedPages() async {
        let repository = StubProfileRepository()
        repository.failOnPage = 2
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)

        #expect(viewModel.profiles.count == pageSize, "a failed page must not blank the list")
        #expect(viewModel.errorMessage != nil)
    }

    @Test func aFailedPageIsNotRetriedByScrolling() async {
        let repository = StubProfileRepository()
        repository.failOnPage = 2
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()
        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)

        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)
        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)

        #expect(repository.requestedPages == [1, 2], "a failing page must not be hammered")
    }

    @Test func retryRecoversFromAFailedPage() async {
        let repository = StubProfileRepository()
        repository.failOnPage = 2
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()
        await viewModel.loadNextPageIfNeeded(after: viewModel.profiles.last!)

        repository.failOnPage = nil
        await viewModel.retry()

        #expect(viewModel.profiles.count == pageSize * 2)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func retryReloadsTheFirstPageWhenNothingIsShowing() async {
        let repository = StubProfileRepository()
        repository.failOnPage = 1
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()

        repository.failOnPage = nil
        await viewModel.retry()

        #expect(viewModel.profiles.count == pageSize)
        #expect(repository.requestedPages == [1, 1])
    }

    // MARK: - Decisions

    @Test func acceptUpdatesTheCardAndReachesTheRepository() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()
        let target = viewModel.profiles[2]

        await viewModel.accept(target)

        #expect(viewModel.profiles[2].status == .accepted)
        #expect(repository.status(forID: target.id) == .accepted)
    }

    @Test func declineUpdatesTheCard() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()
        let target = viewModel.profiles[5]

        await viewModel.decline(target)

        #expect(viewModel.profiles[5].status == .declined)
        #expect(repository.status(forID: target.id) == .declined)
    }

    @Test func aFailedDecisionRevertsTheCardAndReportsTheError() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)
        await viewModel.loadInitialIfNeeded()
        repository.updateFailure = AppError.storageFailed("Disk is full")

        await viewModel.accept(viewModel.profiles[1])

        #expect(viewModel.profiles[1].status == .pending, "an optimistic update must roll back")
        #expect(viewModel.errorMessage == "Disk is full")
    }

    // MARK: - Connectivity

    @Test func offlineFlagFollowsConnectivity() async {
        let repository = StubProfileRepository()
        repository.isConnected = false
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.observeConnection()

        #expect(viewModel.isOffline)
    }

    @Test func onlineConnectivityLeavesTheBannerHidden() async {
        let repository = StubProfileRepository()
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.observeConnection()

        #expect(!viewModel.isOffline)
    }

    // MARK: - Empty state

    @Test func emptyStateIsShownOnlyWhenThereIsNothingToShow() async {
        let repository = StubProfileRepository()
        repository.emptyFromPage = 1
        let viewModel = ProfileListViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        #expect(viewModel.profiles.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showsEmptyState)
    }
}
