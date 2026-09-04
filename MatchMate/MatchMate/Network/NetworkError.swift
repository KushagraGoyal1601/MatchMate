//
//  NetworkError.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

enum NetworkError: Error, Equatable, Sendable {
    case notConnected
    case timedOut
    case cancelled
    case invalidURL
    case invalidResponse
    case unacceptableStatusCode(Int)
    case decodingFailed(String)
    case transportFailed(URLError.Code)
    case unknown(String)
}

extension NetworkError {

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost,
             .dataNotAllowed, .internationalRoamingOff:
            self = .notConnected
        case .timedOut:
            self = .timedOut
        case .cancelled:
            self = .cancelled
        case .badURL, .unsupportedURL:
            self = .invalidURL
        default:
            self = .transportFailed(error.code)
        }
    }
}

extension NetworkError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "No internet connection."
        case .timedOut:
            return "The request timed out."
        case .cancelled:
            return "The request was cancelled."
        case .invalidURL:
            return "The request URL could not be built."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .unacceptableStatusCode(let code):
            return "The server responded with status code \(code)."
        case .decodingFailed(let details):
            return "The response could not be decoded. \(details)"
        case .transportFailed(let code):
            return "The network request failed (URLError code \(code.rawValue))."
        case .unknown(let details):
            return "An unexpected network error occurred. \(details)"
        }
    }
}
