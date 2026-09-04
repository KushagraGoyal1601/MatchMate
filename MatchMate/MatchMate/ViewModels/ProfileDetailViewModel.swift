//
//  ProfileDetailViewModel.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import Foundation

@MainActor
@Observable
final class ProfileDetailViewModel {

    private(set) var profile: MatchProfile
    private(set) var errorMessage: String?

    private let repository: ProfileRepositoryProtocol

    init(profile: MatchProfile, repository: ProfileRepositoryProtocol) {
        self.profile = profile
        self.repository = repository
    }

    func observeProfileUpdates() async {
        for await updated in await repository.profileUpdates() where updated.id == profile.id {
            profile = updated
        }
    }

    func accept() async {
        await setStatus(.accepted)
    }

    func decline() async {
        await setStatus(.declined)
    }

    func dismissError() {
        errorMessage = nil
    }

    private func setStatus(_ status: MatchStatus) async {
        let previous = profile.status
        profile.status = status

        do {
            try await repository.updateStatus(status, forID: profile.id)
        } catch {
            profile.status = previous
            errorMessage = (error as? AppError)?.message ?? error.localizedDescription
        }
    }
}
