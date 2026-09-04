//
//  ProfileNetworkRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

protocol ProfileNetworkRepositoryProtocol: Sendable {
    func profiles(page: Int) async throws -> [MatchProfile]
}

struct ProfileNetworkRepository: ProfileNetworkRepositoryProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func profiles(page: Int) async throws -> [MatchProfile] {
        let response = try await networkService.request(ProfilesRequest(page: page))
        return ProfileMapper.map(response.results)
    }
}
