//
//  DefaultProfileRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

actor DefaultProfileRepository: ProfileRepository {

    private let remote: ProfileFetching

    private var decisions: [MatchProfile.ID: MatchStatus] = [:]

    init(remote: ProfileFetching) {
        self.remote = remote
    }

    func profiles(page: Int) async throws -> [MatchProfile] {
        do {
            let fetched = try await remote.fetchProfiles(page: page)
            return ProfileMapper.map(fetched).map(applyingStoredStatus)
        } catch {
            throw mapped(error)
        }
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        decisions[id] = status
    }

    private func applyingStoredStatus(_ profile: MatchProfile) -> MatchProfile {
        guard let status = decisions[profile.id] else { return profile }
        var profile = profile
        profile.status = status
        return profile
    }

    private func mapped(_ error: Error) -> Error {
        guard let networkError = error as? NetworkError else {
            return AppError.unexpected(error.localizedDescription)
        }

        switch networkError {
        case .cancelled:
            return CancellationError()
        case .notConnected:
            return AppError.offline
        default:
            return AppError.requestFailed(
                networkError.errorDescription ?? "Something went wrong. Please try again."
            )
        }
    }
}
