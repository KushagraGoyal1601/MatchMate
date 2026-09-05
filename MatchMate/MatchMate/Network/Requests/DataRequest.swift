//
//  DataRequest.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET"
}

protocol DataRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension DataRequest {
    var baseURL: URL { APIConfiguration.baseURL }
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
}
