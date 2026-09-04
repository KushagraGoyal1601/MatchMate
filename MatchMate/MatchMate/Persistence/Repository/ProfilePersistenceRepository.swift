//
//  ProfilePersistenceRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

protocol ProfilePersistenceRepositoryProtocol: Sendable {
    func statuses() async throws -> [MatchProfile.ID: MatchStatus]
    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws
}

actor ProfilePersistenceRepository: ProfilePersistenceRepositoryProtocol {

    private var statusByID: [MatchProfile.ID: MatchStatus] = [:]

    func statuses() async throws -> [MatchProfile.ID: MatchStatus] {
        statusByID
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        statusByID[id] = status
    }
}
