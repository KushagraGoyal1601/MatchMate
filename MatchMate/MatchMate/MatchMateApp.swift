//
//  MatchMateApp.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

@main
struct MatchMateApp: App {
    var body: some Scene {
        WindowGroup {
            ProfileListView(
                viewModel: ProfileListViewModel(
                    service: ProfileService(client: URLSessionHTTPClient())
                )
            )
        }
    }
}
