//
//  ProfileListView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

struct ProfileListView: View {

    @State private var viewModel: ProfileListViewModel

    init(viewModel: ProfileListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.pageBackground)
                .navigationTitle("Profile Matches")
        }
        .task { await viewModel.loadProfiles() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.profiles.isEmpty, viewModel.isLoading {
            ProgressView()
        } else if viewModel.profiles.isEmpty, let errorMessage = viewModel.errorMessage {
            errorState(message: errorMessage)
        } else if viewModel.showsEmptyState {
            ContentUnavailableView(
                "No matches yet",
                systemImage: "person.2.slash",
                description: Text("Pull to refresh once you are back online.")
            )
        } else {
            profileList
        }
    }

    private var profileList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.cardSpacing) {
                ForEach(viewModel.profiles) { profile in
                    ProfileCardView(
                        profile: profile,
                        onAccept: { viewModel.accept(profile) },
                        onDecline: { viewModel.decline(profile) }
                    )
                }
            }
            .padding(.horizontal, Theme.Layout.cardHorizontalPadding)
            .padding(.vertical, Theme.Layout.cardSpacing)
        }
        .refreshable { await viewModel.loadProfiles() }
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't load matches", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.loadProfiles() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
    }
}

#Preview {
    ProfileListView(
        viewModel: ProfileListViewModel(
            service: ProfileService(client: URLSessionHTTPClient())
        )
    )
}
