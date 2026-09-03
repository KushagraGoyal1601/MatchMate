//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

@main
struct MatchMateApp: App {

    private let dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            ProfileListView(
                viewModel: ProfileListViewModel(repository: dependencies.profileRepository)
            )
        }
    }
}
