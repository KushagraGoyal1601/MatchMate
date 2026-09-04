//
//  ProfileEntity.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import CoreData

@objc(ProfileEntity)
final class ProfileEntity: NSManagedObject {

    @nonobjc static func fetchRequest() -> NSFetchRequest<ProfileEntity> {
        NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
    }

    @NSManaged var id: String
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var age: NSNumber?
    @NSManaged var gender: String?
    @NSManaged var city: String?
    @NSManaged var state: String?
    @NSManaged var country: String?
    @NSManaged var nationality: String?
    @NSManaged var email: String?
    @NSManaged var phone: String?
    @NSManaged var largePhotoURL: String?
    @NSManaged var mediumPhotoURL: String?
    @NSManaged var dateOfBirth: Date?
    @NSManaged var registeredDate: Date?
    @NSManaged var statusRaw: String
    @NSManaged var sortIndex: Int64
    @NSManaged var updatedAt: Date
}
