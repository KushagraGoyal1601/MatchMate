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

    private let service: ProfileFetching

    init(service: ProfileFetching) {
        self.service = service
    }

    var showsEmptyState: Bool {
        profiles.isEmpty && !isLoading && errorMessage == nil
    }

    func loadProfiles() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchProfiles(page: 1)
            profiles = ProfileMapper.map(fetched)
        } catch let error as NetworkError {
            guard error != .cancelled else { return }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ profile: MatchProfile) {
        setStatus(.accepted, for: profile.id)
    }

    func decline(_ profile: MatchProfile) {
        setStatus(.declined, for: profile.id)
    }

    private func setStatus(_ status: MatchStatus, for id: MatchProfile.ID) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].status = status
    }
}
