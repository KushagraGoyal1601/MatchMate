//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

@main
struct MatchMateApp: App {

    private let dependencies = DependencyManager.shared

    var body: some Scene {
        WindowGroup {
            ProfileListView(
                viewModel: dependencies.makeProfileListViewModel(),
                makeDetailViewModel: dependencies.makeProfileDetailViewModel(for:)
            )
            .environment(\.imageLoader, dependencies.imageLoader)
        }
    }
}
