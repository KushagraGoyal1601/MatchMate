//
//  AppDependencies.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

struct AppDependencies {

    let profileRepository: ProfileRepository

    static func live() -> AppDependencies {
        let client = URLSessionHTTPClient(baseURL: APIConfiguration.baseURL)
        let remote = ProfileService(client: client)

        return AppDependencies(
            profileRepository: DefaultProfileRepository(remote: remote)
        )
    }
}
