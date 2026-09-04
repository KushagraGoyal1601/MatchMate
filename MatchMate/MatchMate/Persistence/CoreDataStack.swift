//
//  CoreDataStack.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import CoreData

final class CoreDataStack: @unchecked Sendable {

    static let modelName = "MatchMate"

    private let container: NSPersistentContainer
    private let loadError: PersistenceError?

    init() {
        container = NSPersistentContainer(name: Self.modelName)

        var failure: PersistenceError?
        container.loadPersistentStores { _, error in
            if let error {
                failure = .storeUnavailable(error.localizedDescription)
            }
        }
        loadError = failure

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func perform<T: Sendable>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        if let loadError { throw loadError }

        return try await container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return try block(context)
        }
    }
}
