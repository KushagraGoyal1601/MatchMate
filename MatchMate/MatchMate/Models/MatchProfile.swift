//
//  MatchProfile.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

struct MatchProfile: Identifiable, Equatable, Sendable {
    let id: String
    let firstName: String
    let lastName: String
    let age: Int?
    let gender: String?
    let city: String?
    let state: String?
    let country: String?
    let nationality: String?
    let email: String?
    let phone: String?
    let largePhotoURL: URL?
    let mediumPhotoURL: URL?
    let dateOfBirth: Date?
    let registeredDate: Date?
    var status: MatchStatus
}

extension MatchProfile {

    var displayName: String {
        let name = [firstName, lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return name.isEmpty ? "Unknown" : name
    }

    var summary: String {
        var parts: [String] = []
        if let age { parts.append("\(age)") }
        if let city, !city.isEmpty { parts.append(city) }
        if let state, !state.isEmpty { parts.append(state) }
        return parts.joined(separator: ", ")
    }
}
