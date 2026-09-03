//
//  ProfileResponse.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

nonisolated struct ProfileResponse: Decodable, Sendable {
    let results: [Profile]
    let info: Info
}

extension ProfileResponse {
    
    struct Info: Decodable, Sendable {
        let seed: String?
        let results: Int?
        let page: Int?
        let version: String?
    }
}
