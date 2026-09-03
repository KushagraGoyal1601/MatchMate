//
//  HTTPClient.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

protocol HTTPClient: Sendable {
    func data(for endpoint: Endpoint) async throws -> Data
}

struct URLSessionHTTPClient: HTTPClient {

    static let randomUserBaseURL = URL(string: "https://randomuser.me")!

    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession? = nil, baseURL: URL = randomUserBaseURL) {
        self.session = session ?? Self.makeDefaultSession()
        self.baseURL = baseURL
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        let url = try endpoint.url(relativeTo: baseURL)

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.unacceptableStatusCode(httpResponse.statusCode)
            }
            return data
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError {
            throw NetworkError(error)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch {
            throw NetworkError.unknown(String(describing: error))
        }
    }

    private static func makeDefaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }
}
