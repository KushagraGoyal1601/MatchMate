//
//  ProfileMapper.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import Foundation

enum ProfileMapper {

    private static let fractionalSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let wholeSeconds = Date.ISO8601FormatStyle(includingFractionalSeconds: false)

    static func map(_ profiles: [Profile]) -> [MatchProfile] {
        profiles.map(map)
    }

    static func map(_ profile: Profile) -> MatchProfile {
        MatchProfile(
            id: profile.login.uuid,
            firstName: profile.name.first ?? "",
            lastName: profile.name.last ?? "",
            age: profile.dob.age,
            gender: profile.gender,
            city: profile.location.city,
            state: profile.location.state,
            country: profile.location.country,
            nationality: profile.nat,
            email: profile.email,
            phone: profile.phone,
            largePhotoURL: url(from: profile.picture.large),
            mediumPhotoURL: url(from: profile.picture.medium),
            dateOfBirth: date(from: profile.dob.date),
            registeredDate: date(from: profile.registered.date),
            status: .pending
        )
    }

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        if let date = try? fractionalSeconds.parse(string) { return date }
        return try? wholeSeconds.parse(string)
    }

    private static func url(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}
