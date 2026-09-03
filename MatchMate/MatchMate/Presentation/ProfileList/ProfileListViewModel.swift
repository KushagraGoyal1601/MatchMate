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

    private var decisions: [MatchProfile.ID: MatchStatus] = [:]

    private let service: ProfileFetching
    private let prefetchThreshold: Int

    init(service: ProfileFetching, prefetchThreshold: Int = 3) {
        self.service = service
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

    func accept(_ profile: MatchProfile) {
        setStatus(.accepted, for: profile.id)
    }

    func decline(_ profile: MatchProfile) {
        setStatus(.declined, for: profile.id)
    }

    private func load(page: Int) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchProfiles(page: page)
            apply(ProfileMapper.map(fetched), replacingAll: page == 1)
            currentPage = page
            hasMorePages = !fetched.isEmpty
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func setStatus(_ status: MatchStatus, for id: MatchProfile.ID) {
        decisions[id] = status

        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].status = status
    }

    private func apply(_ fetched: [MatchProfile], replacingAll: Bool) {
        let merged = fetched.map { profile in
            var profile = profile
            profile.status = decisions[profile.id] ?? profile.status
            return profile
        }

        if replacingAll {
            profiles = merged
        } else {
            let existingIDs = Set(profiles.map(\.id))
            profiles.append(contentsOf: merged.filter { !existingIDs.contains($0.id) })
        }
    }

    private func message(for error: Error) -> String? {
        guard let networkError = error as? NetworkError else {
            return error.localizedDescription
        }
        guard networkError != .cancelled else { return nil }
        return networkError.errorDescription
    }
}
