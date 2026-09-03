//
//  ProfileService.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

protocol ProfileFetching: Sendable {
    func fetchProfiles(page: Int) async throws -> [Profile]
}

struct ProfileService: ProfileFetching {

    private let client: HTTPClient
    private let pageSize: Int
    private let seed: String

    init(
        client: HTTPClient,
        pageSize: Int = Endpoint.defaultPageSize,
        seed: String = Endpoint.defaultSeed
    ) {
        self.client = client
        self.pageSize = pageSize
        self.seed = seed
    }

    func fetchProfiles(page: Int) async throws -> [Profile] {
        let endpoint = Endpoint.profiles(page: page, resultsPerPage: pageSize, seed: seed)
        let data = try await client.data(for: endpoint)

        do {
            return try JSONDecoder().decode(ProfileResponse.self, from: data).results
        } catch {
            throw NetworkError.decodingFailed(String(describing: error))
        }
    }
}
