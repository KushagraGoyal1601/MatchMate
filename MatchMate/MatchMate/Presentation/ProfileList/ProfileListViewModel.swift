//
//  ProfileListViewModel.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

@MainActor
@Observable
final class ProfileListViewModel {

    private(set) var profiles: [MatchProfile] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var hasMorePages = true

    private var currentPage = 0

    private let repository: ProfileRepository
    private let prefetchThreshold: Int

    init(repository: ProfileRepository, prefetchThreshold: Int = 3) {
        self.repository = repository
        self.prefetchThreshold = prefetchThreshold
    }

    var showsEmptyState: Bool {
        profiles.isEmpty && !isLoading && errorMessage == nil
    }

    var showsEndOfList: Bool {
        !hasMorePages && !profiles.isEmpty
    }

    func loadInitialIfNeeded() async {
        guard profiles.isEmpty, errorMessage == nil else { return }
        await load(page: 1)
    }

    func refresh() async {
        await load(page: 1)
    }

    func loadNextPageIfNeeded(after profile: MatchProfile) async {
        guard hasMorePages, errorMessage == nil, !isLoading else { return }
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }),
              index >= profiles.count - prefetchThreshold else { return }

        await load(page: currentPage + 1)
    }

    func retry() async {
        await load(page: profiles.isEmpty ? 1 : currentPage + 1)
    }

    func accept(_ profile: MatchProfile) async {
        await setStatus(.accepted, for: profile.id)
    }

    func decline(_ profile: MatchProfile) async {
        await setStatus(.declined, for: profile.id)
    }

    private func load(page: Int) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await repository.profiles(page: page)
            apply(fetched, replacingAll: page == 1)
            currentPage = page
            hasMorePages = !fetched.isEmpty
        } catch is CancellationError {
            return
        } catch let error as AppError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setStatus(_ status: MatchStatus, for id: MatchProfile.ID) async {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }

        let previous = profiles[index].status
        profiles[index].status = status

        do {
            try await repository.updateStatus(status, forID: id)
        } catch {
            guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
            profiles[index].status = previous
            errorMessage = (error as? AppError)?.message ?? error.localizedDescription
        }
    }

    private func apply(_ fetched: [MatchProfile], replacingAll: Bool) {
        if replacingAll {
            profiles = fetched
        } else {
            let existingIDs = Set(profiles.map(\.id))
            profiles.append(contentsOf: fetched.filter { !existingIDs.contains($0.id) })
        }
    }
}
