//
//  ProfilesRequest.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

struct ProfilesRequest: DataRequest {

    typealias Response = ProfileResponse

    let page: Int
    var resultsPerPage: Int = APIConfiguration.pageSize
    var seed: String = APIConfiguration.seed

    var path: String { "api/" }

    var queryItems: [URLQueryItem]? {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "results", value: String(resultsPerPage)),
            URLQueryItem(name: "seed", value: seed)
        ]
    }
}
