//
//  ProfileCardView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

struct ProfileCardView: View {

    let profile: MatchProfile
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink(value: profile) {
                details
            }
            .buttonStyle(.plain)

            MatchStatusActions(
                status: profile.status,
                profileName: profile.displayName,
                onAccept: onAccept,
                onDecline: onDecline
            )
        }
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var details: some View {
        VStack(spacing: 12) {
            ProfilePhotoView(url: profile.largePhotoURL, size: Theme.Layout.photoSize)

            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)

                if !profile.summary.isEmpty {
                    Text(profile.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(Theme.Layout.cardSpacing)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
    }
}
