//
//  ProfileEntityMapper.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

enum ProfileEntityMapper {

    static func toDomain(_ entity: ProfileEntity) -> MatchProfile {
        MatchProfile(
            id: entity.id,
            firstName: entity.firstName,
            lastName: entity.lastName,
            age: entity.age?.intValue,
            gender: entity.gender,
            city: entity.city,
            state: entity.state,
            country: entity.country,
            nationality: entity.nationality,
            email: entity.email,
            phone: entity.phone,
            largePhotoURL: entity.largePhotoURL.flatMap(URL.init(string:)),
            mediumPhotoURL: entity.mediumPhotoURL.flatMap(URL.init(string:)),
            dateOfBirth: entity.dateOfBirth,
            registeredDate: entity.registeredDate,
            status: MatchStatus(rawValue: entity.statusRaw) ?? .pending
        )
    }

    static func applyDetails(of profile: MatchProfile, to entity: ProfileEntity) {
        entity.id = profile.id
        entity.firstName = profile.firstName
        entity.lastName = profile.lastName
        entity.age = profile.age.map(NSNumber.init(value:))
        entity.gender = profile.gender
        entity.city = profile.city
        entity.state = profile.state
        entity.country = profile.country
        entity.nationality = profile.nationality
        entity.email = profile.email
        entity.phone = profile.phone
        entity.largePhotoURL = profile.largePhotoURL?.absoluteString
        entity.mediumPhotoURL = profile.mediumPhotoURL?.absoluteString
        entity.dateOfBirth = profile.dateOfBirth
        entity.registeredDate = profile.registeredDate
        entity.updatedAt = .now
    }
}
