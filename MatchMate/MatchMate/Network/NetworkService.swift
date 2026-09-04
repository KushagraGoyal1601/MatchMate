//
//  NetworkService.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

protocol NetworkServiceProtocol: Sendable {
    func request<R: DataRequest>(_ request: R) async throws -> R.Response
}

struct NetworkService: NetworkServiceProtocol {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<R: DataRequest>(_ request: R) async throws -> R.Response {
        let urlRequest = try makeURLRequest(for: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.unacceptableStatusCode(httpResponse.statusCode)
            }

            do {
                return try JSONDecoder().decode(R.Response.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(String(describing: error))
            }
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

    private func makeURLRequest<R: DataRequest>(for request: R) throws -> URLRequest {
        guard var components = URLComponents(
            url: request.baseURL.appending(path: request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = request.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpBody = request.body
        return urlRequest
    }
}
