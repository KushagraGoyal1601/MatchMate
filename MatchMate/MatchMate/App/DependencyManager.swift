//
//  DependencyManager.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 04/09/26.
//

import Foundation

@MainActor
final class DependencyManager {

    static let shared = DependencyManager()

    private init() {}

    lazy var networkService: NetworkServiceProtocol = NetworkService()

    lazy var networkMonitor: NetworkMonitorProtocol = NetworkMonitor()

    lazy var coreDataStack: CoreDataStack = CoreDataStack()

    lazy var profileNetworkRepository: ProfileNetworkRepositoryProtocol =
        ProfileNetworkRepository(networkService: networkService)

    lazy var profilePersistenceRepository: ProfilePersistenceRepositoryProtocol =
        ProfilePersistenceRepository(stack: coreDataStack)

    lazy var profileRepository: ProfileRepositoryProtocol = ProfileRepository(
        network: profileNetworkRepository,
        persistence: profilePersistenceRepository,
        monitor: networkMonitor
    )

    func makeProfileListViewModel() -> ProfileListViewModel {
        ProfileListViewModel(repository: profileRepository)
    }
}
