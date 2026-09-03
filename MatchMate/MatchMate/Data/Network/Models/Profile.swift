//
//  Profile.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

nonisolated struct Profile: Decodable, Sendable {
    let login: Login
    let name: Name
    let location: Location
    let dob: DateInfo
    let registered: DateInfo
    let picture: Picture
    let gender: String?
    let email: String?
    let phone: String?
    let nat: String?
}

extension Profile {

    struct Login: Decodable, Sendable {
        let uuid: String
    }

    struct Name: Decodable, Sendable {
        let title: String?
        let first: String?
        let last: String?
    }

    struct Location: Decodable, Sendable {
        let city: String?
        let state: String?
        let country: String?
    }

    struct DateInfo: Decodable, Sendable {
        let date: String?
        let age: Int?
    }

    struct Picture: Decodable, Sendable {
        let large: String?
        let medium: String?
        let thumbnail: String?
    }
}
