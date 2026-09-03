//
//  Endpoint.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

struct Endpoint: Sendable, Equatable {
    let path: String
    let queryItems: [URLQueryItem]

    init(path: String, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.queryItems = queryItems
    }

    func url(relativeTo baseURL: URL) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
}

extension Endpoint {

    static let defaultPageSize = 10

    static let defaultSeed = "matchmate"

    static func profiles(
        page: Int,
        resultsPerPage: Int = defaultPageSize,
        seed: String = defaultSeed
    ) -> Endpoint {
        Endpoint(
            path: "api/",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "results", value: String(resultsPerPage)),
                URLQueryItem(name: "seed", value: seed)
            ]
        )
    }
}
