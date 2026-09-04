//
//  ProfileDetailView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import SwiftUI

struct ProfileDetailView: View {

    @State private var viewModel: ProfileDetailViewModel

    init(viewModel: ProfileDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.cardSpacing) {
                header
                about
            }
            .padding(.horizontal, Theme.Layout.cardHorizontalPadding)
            .padding(.vertical, Theme.Layout.cardSpacing)
        }
        .background(Theme.pageBackground)
        .navigationTitle(viewModel.profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.observeProfileUpdates() }
        .alert(
            "Couldn't save your decision",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                ProfilePhotoView(url: viewModel.profile.largePhotoURL, size: 220)

                VStack(spacing: 4) {
                    Text(viewModel.profile.displayName)
                        .font(.title.bold())
                        .foregroundStyle(Theme.accent)
                        .multilineTextAlignment(.center)

                    if !viewModel.profile.summary.isEmpty {
                        Text(viewModel.profile.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(Theme.Layout.cardSpacing)

            MatchStatusActions(
                status: viewModel.profile.status,
                profileName: viewModel.profile.displayName,
                onAccept: { Task { await viewModel.accept() } },
                onDecline: { Task { await viewModel.decline() } }
            )
        }
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About")
                .font(.headline)
                .padding(.bottom, 12)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    Divider()
                }
                infoRow(label: row.label, value: row.value)
            }
        }
        .padding(Theme.Layout.cardSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var rows: [(label: String, value: String)] {
        let profile = viewModel.profile
        var rows: [(String, String)] = []

        if let email = profile.email, !email.isEmpty { rows.append(("Email", email)) }
        if let phone = profile.phone, !phone.isEmpty { rows.append(("Phone", phone)) }
        if let nationality = profile.nationality, !nationality.isEmpty {
            rows.append(("Nationality", nationality))
        }
        if let gender = profile.gender, !gender.isEmpty {
            rows.append(("Gender", gender.capitalized))
        }
        if let country = profile.country, !country.isEmpty { rows.append(("Country", country)) }
        if let dateOfBirth = profile.dateOfBirth {
            rows.append(("Date of birth", dateOfBirth.formatted(date: .abbreviated, time: .omitted)))
        }
        if let registered = profile.registeredDate {
            rows.append(("Member since", registered.formatted(date: .abbreviated, time: .omitted)))
        }
        return rows
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}
