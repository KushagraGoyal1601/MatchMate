//
//  ImageLoader.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import Foundation

protocol ImageLoading: Sendable {
    func data(for url: URL) async throws -> Data
}

final class ImageLoader: ImageLoading {

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false

        session = URLSession(configuration: configuration)
    }

    func data(for url: URL) async throws -> Data {
        do {
            let (data, _) = try await session.data(from: url)
            return data
        } catch {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataDontLoad

            let (data, _) = try await session.data(for: request)
            return data
        }
    }
}
