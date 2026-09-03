//
//  ProfileRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

protocol ProfileRepository: Sendable {
    func profiles(page: Int) async throws -> [MatchProfile]
    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws
}
