//
//  ProfilePersistenceRepository.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import CoreData

protocol ProfilePersistenceRepositoryProtocol: Sendable {
    func profiles(fromSortIndex startIndex: Int, limit: Int) async throws -> [MatchProfile]
    func profile(id: MatchProfile.ID) async throws -> MatchProfile?
    func save(_ profiles: [MatchProfile], startingAtSortIndex startIndex: Int) async throws
    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws
}

struct ProfilePersistenceRepository: ProfilePersistenceRepositoryProtocol {

    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func profiles(fromSortIndex startIndex: Int, limit: Int) async throws -> [MatchProfile] {
        try await stack.perform { context in
            let request = ProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "sortIndex >= %d", startIndex)
            request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
            request.fetchLimit = limit

            do {
                return try context.fetch(request).map(ProfileEntityMapper.toDomain)
            } catch {
                throw PersistenceError.fetchFailed(error.localizedDescription)
            }
        }
    }

    func profile(id: MatchProfile.ID) async throws -> MatchProfile? {
        try await stack.perform { context in
            try Self.entity(withID: id, in: context).map(ProfileEntityMapper.toDomain)
        }
    }

    func save(_ profiles: [MatchProfile], startingAtSortIndex startIndex: Int) async throws {
        guard !profiles.isEmpty else { return }

        try await stack.perform { context in
            let request = ProfileEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", profiles.map(\.id))

            let existing: [ProfileEntity]
            do {
                existing = try context.fetch(request)
            } catch {
                throw PersistenceError.fetchFailed(error.localizedDescription)
            }

            var byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

            for (offset, profile) in profiles.enumerated() {
                if let entity = byID[profile.id] {
                    ProfileEntityMapper.applyDetails(of: profile, to: entity)
                } else {
                    let entity = ProfileEntity(context: context)
                    ProfileEntityMapper.applyDetails(of: profile, to: entity)
                    entity.statusRaw = profile.status.rawValue
                    entity.sortIndex = Int64(startIndex + offset)
                    byID[profile.id] = entity
                }
            }

            try Self.save(context)
        }
    }

    func updateStatus(_ status: MatchStatus, forID id: MatchProfile.ID) async throws {
        try await stack.perform { context in
            guard let entity = try Self.entity(withID: id, in: context) else {
                throw PersistenceError.notFound(id)
            }

            entity.statusRaw = status.rawValue
            entity.updatedAt = .now

            try Self.save(context)
        }
    }

    private static func entity(
        withID id: MatchProfile.ID,
        in context: NSManagedObjectContext
    ) throws -> ProfileEntity? {
        let request = ProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }

    private static func save(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }
}
