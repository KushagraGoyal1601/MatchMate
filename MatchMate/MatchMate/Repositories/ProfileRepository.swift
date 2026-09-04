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
    func profileUpdates() async -> AsyncStream<MatchProfile>
    func connectionUpdates() -> AsyncStream<Bool>
}

actor ProfileRepository: ProfileRepositoryProtocol {

    private let network: ProfileNetworkRepositoryProtocol
    private let persistence: ProfilePersistenceRepositoryProtocol
    private let monitor: NetworkMonitorProtocol
    private let pageSize: Int

    private var subscribers: [UUID: AsyncStream<MatchProfile>.Continuation] = [:]

    init(
        network: ProfileNetworkRepositoryProtocol,
        persistence: ProfilePersistenceRepositoryProtocol,
        monitor: NetworkMonitorProtocol,
        pageSize: Int = APIConfiguration.pageSize
    ) {
        self.network = network
        self.persistence = persistence
        self.monitor = monitor
        self.pageSize = pageSize
    }

    nonisolated func connectionUpdates() -> AsyncStream<Bool> {
        monitor.connectionUpdates()
    }

    func profileUpdates() -> AsyncStream<MatchProfile> {
        AsyncStream { continuation in
            let id = UUID()
            subscribers[id] = continuation

            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeSubscriber(id) }
            }
        }
    }

    func profiles(page: Int) async throws -> [MatchProfile] {
        let startIndex = (page - 1) * pageSize
        var networkFailure: Error?

        if monitor.isConnected {
            do {
                let fetched = try await network.profiles(page: page)
                try await persistence.save(fetched, startingAtSortIndex: startIndex)
            } catch let error as NetworkError where error == .cancelled {
                throw CancellationError()
            } catch {
                networkFailure = error
            }
        }

        let cached: [MatchProfile]
        do {
            cached = try await persistence.profiles(fromSortIndex: startIndex, limit: pageSize)
        } catch {
            throw mapped(networkFailure ?? error)
        }

        if cached.isEmpty {
            if let networkFailure { throw mapped(networkFailure) }
            if !monitor.isConnected { throw AppError.offline }
        }

        return cached
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        do {
            try await persistence.updateStatus(status, forID: id)

            // Broadcast what the database actually holds, not what the caller
            // asked for, so every screen converges on the same stored truth.
            if let stored = try await persistence.profile(id: id) {
                broadcast(stored)
            }
        } catch {
            throw mapped(error)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }

    private func broadcast(_ profile: MatchProfile) {
        for continuation in subscribers.values {
            continuation.yield(profile)
        }
    }

    private func mapped(_ error: Error) -> Error {
        if let networkError = error as? NetworkError {
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

        if let persistenceError = error as? PersistenceError {
            return AppError.storageFailed(
                persistenceError.errorDescription ?? "The local database is unavailable."
            )
        }

        return AppError.unexpected(error.localizedDescription)
    }
}
