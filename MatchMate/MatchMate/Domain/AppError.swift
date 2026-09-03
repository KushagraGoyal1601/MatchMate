//
//  AppError.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

enum AppError: Error, Equatable, Sendable {
    case offline
    case requestFailed(String)
    case storageFailed(String)
    case unexpected(String)
}

extension AppError {

    var message: String {
        switch self {
        case .offline:
            return "You're offline. Showing what we have saved."
        case .requestFailed(let detail):
            return detail
        case .storageFailed(let detail):
            return detail
        case .unexpected(let detail):
            return detail
        }
    }
}
