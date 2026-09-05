//
//  ProfileListView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

struct ProfileListView: View {

    @State private var viewModel: ProfileListViewModel

    private let makeDetailViewModel: (MatchProfile) -> ProfileDetailViewModel

    init(
        viewModel: ProfileListViewModel,
        makeDetailViewModel: @escaping (MatchProfile) -> ProfileDetailViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeDetailViewModel = makeDetailViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isOffline {
                    offlineBanner
                }
                content
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.pageBackground)
                .navigationTitle("Profile Matches")
                .navigationDestination(for: MatchProfile.self) { profile in
                    ProfileDetailView(viewModel: makeDetailViewModel(profile))
                }
        }
        .task { await viewModel.loadInitialIfNeeded() }
        .task { await viewModel.observeConnection() }
        .task { await viewModel.observeProfileUpdates() }
        .alert(
            "Couldn't save your decision",
            isPresented: Binding(
                get: { viewModel.decisionErrorMessage != nil },
                set: { if !$0 { viewModel.dismissDecisionError() } }
            )
        ) {
            Button("OK") { viewModel.dismissDecisionError() }
        } message: {
            Text(viewModel.decisionErrorMessage ?? "")
        }
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
                description: Text("There is nothing to show right now.")
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
                        onAccept: { Task { await viewModel.accept(profile) } },
                        onDecline: { Task { await viewModel.decline(profile) } }
                    )
                    .onAppear {
                        // Deliberately not `.task`: SwiftUI cancels that when the
                        // row scrolls away, which would kill the in-flight page.
                        Task { await viewModel.loadNextPageIfNeeded(after: profile) }
                    }
                }

                paginationFooter
            }
            .padding(.horizontal, Theme.Layout.cardHorizontalPadding)
            .padding(.vertical, Theme.Layout.cardSpacing)
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if let message = viewModel.errorMessage {
            VStack(spacing: 12) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Retry") {
                    Task { await viewModel.retry() }
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
            .padding(.vertical, 8)
        } else if viewModel.isLoading {
            ProgressView()
                .padding(.vertical, 12)
        } else if viewModel.showsEndOfList {
            Text("You're all caught up")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 12)
        }
    }

    private var offlineBanner: some View {
        Label("You're offline. Showing saved profiles.", systemImage: "wifi.slash")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.thinMaterial)
    }

    private func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't load matches", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await viewModel.retry() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
    }
}

#Preview {
    let dependencies = DependencyManager.shared

    return ProfileListView(
        viewModel: dependencies.makeProfileListViewModel(),
        makeDetailViewModel: dependencies.makeProfileDetailViewModel(for:)
    )
}
