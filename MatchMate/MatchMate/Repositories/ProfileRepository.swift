//
//  ProfileRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

protocol ProfileRepositoryProtocol: Sendable {
    func profiles(page: Int) async throws -> [MatchProfile]
    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws
}

actor ProfileRepository: ProfileRepositoryProtocol {

    private let network: ProfileNetworkRepositoryProtocol
    private let persistence: ProfilePersistenceRepositoryProtocol

    init(
        network: ProfileNetworkRepositoryProtocol,
        persistence: ProfilePersistenceRepositoryProtocol
    ) {
        self.network = network
        self.persistence = persistence
    }

    func profiles(page: Int) async throws -> [MatchProfile] {
        do {
            let profiles = try await network.profiles(page: page)
            let statuses = try await persistence.statuses()

            return profiles.map { profile in
                guard let status = statuses[profile.id] else { return profile }
                var profile = profile
                profile.status = status
                return profile
            }
        } catch {
            throw mapped(error)
        }
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        do {
            try await persistence.updateStatus(status, forID: id)
        } catch {
            throw mapped(error)
        }
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
