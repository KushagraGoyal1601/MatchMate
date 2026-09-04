//
//  TestSupport.swift
//  MatchMateTests
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation
import Testing
@testable import MatchMate

func makeProfile(
    _ id: String,
    firstName: String = "P",
    status: MatchStatus = .pending
) -> MatchProfile {
    MatchProfile(
        id: id,
        firstName: firstName,
        lastName: "Last",
        age: 30,
        gender: "female",
        city: "City",
        state: "State",
        country: "Country",
        nationality: "IN",
        email: "a@b.c",
        phone: "123",
        largePhotoURL: URL(string: "https://example.com/l.jpg"),
        mediumPhotoURL: URL(string: "https://example.com/m.jpg"),
        dateOfBirth: Date(timeIntervalSince1970: 0),
        registeredDate: Date(timeIntervalSince1970: 1_000_000_000),
        status: status
    )
}

@MainActor
func waitUntil(
    _ description: String,
    timeout: Duration = .seconds(5),
    _ condition: () async -> Bool
) async {
    let deadline = ContinuousClock.now + timeout

    while ContinuousClock.now < deadline {
        if await condition() { return }
        try? await Task.sleep(for: .milliseconds(5))
    }

    Issue.record("Timed out waiting for: \(description)")
}

final class StubProfileRepository: ProfileRepositoryProtocol, @unchecked Sendable {

    private let lock = NSLock()
    private var pages: [Int] = []
    private var stored: [MatchProfile.ID: MatchProfile] = [:]
    private var subscribers: [UUID: AsyncStream<MatchProfile>.Continuation] = [:]

    var pageSize = APIConfiguration.pageSize
    var failOnPage: Int?
    var emptyFromPage: Int?
    var updateFailure: Error?
    var loadDelay: Duration = .zero
    var isConnected = true

    var requestedPages: [Int] { lock.withLock { pages } }
    var subscriberCount: Int { lock.withLock { subscribers.count } }

    func status(forID id: MatchProfile.ID) -> MatchStatus? {
        lock.withLock { stored[id]?.status }
    }

    func profiles(page: Int) async throws -> [MatchProfile] {
        lock.withLock { pages.append(page) }

        if loadDelay != .zero {
            try? await Task.sleep(for: loadDelay)
        }
        if page == failOnPage {
            throw AppError.requestFailed("Stubbed failure")
        }
        if let emptyFromPage, page >= emptyFromPage {
            return []
        }

        return lock.withLock {
            (0..<pageSize).map { offset in
                let id = "p\(page)-\(offset)"
                if let existing = stored[id] { return existing }

                let profile = makeProfile(id)
                stored[id] = profile
                return profile
            }
        }
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        if let updateFailure { throw updateFailure }

        let updated: MatchProfile? = lock.withLock {
            guard var profile = stored[id] else { return nil }
            profile.status = status
            stored[id] = profile
            return profile
        }

        guard let updated else { return }
        lock.withLock { Array(subscribers.values) }.forEach { $0.yield(updated) }
    }

    func profileUpdates() async -> AsyncStream<MatchProfile> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { subscribers[id] = continuation }

            continuation.onTermination = { [weak self] _ in
                self?.lock.withLock { _ = self?.subscribers.removeValue(forKey: id) }
            }
        }
    }

    func connectionUpdates() -> AsyncStream<Bool> {
        let connected = isConnected
        return AsyncStream { continuation in
            continuation.yield(connected)
            continuation.finish()
        }
    }
}
