//
//  PersistenceError.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

enum PersistenceError: Error, Equatable, Sendable {
    case storeUnavailable(String)
    case fetchFailed(String)
    case saveFailed(String)
    case notFound(String)
}

extension PersistenceError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .storeUnavailable(let detail):
            return "The local database could not be opened. \(detail)"
        case .fetchFailed(let detail):
            return "Could not read saved profiles. \(detail)"
        case .saveFailed(let detail):
            return "Could not save to the local database. \(detail)"
        case .notFound(let id):
            return "No saved profile with id \(id)."
        }
    }
}
