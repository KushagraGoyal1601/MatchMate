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
            details
            footer
        }
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .clipShape(.rect(cornerRadius: Theme.Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var details: some View {
        VStack(spacing: 12) {
            photo
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
    }

    private var photo: some View {
        AsyncImage(url: profile.largePhotoURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholderPhoto
            case .empty:
                ZStack {
                    Theme.pageBackground
                    ProgressView()
                }
            @unknown default:
                placeholderPhoto
            }
        }
        .frame(width: Theme.Layout.photoSize, height: Theme.Layout.photoSize)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var placeholderPhoto: some View {
        ZStack {
            Theme.pageBackground
            Image(systemName: "person.fill")
                .font(.system(size: Theme.Layout.photoSize / 3))
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch profile.status {
        case .pending:
            actionButtons
        case .accepted:
            statusBar(title: "Accepted")
        case .declined:
            statusBar(title: "Declined")
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 48) {
            circleButton(
                systemName: "xmark",
                tint: .secondary,
                label: "Decline \(profile.displayName)",
                action: onDecline
            )
            circleButton(
                systemName: "checkmark",
                tint: Theme.accent,
                label: "Accept \(profile.displayName)",
                action: onAccept
            )
        }
        .padding(.bottom, Theme.Layout.cardSpacing)
    }

    private func circleButton(
        systemName: String,
        tint: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tint)
                .frame(
                    width: Theme.Layout.actionButtonSize,
                    height: Theme.Layout.actionButtonSize
                )
                .overlay(Circle().stroke(Theme.accent, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
        .accessibilityLabel(label)
    }

    private func statusBar(title: String) -> some View {
        Text(title)
            .font(.body)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Layout.statusBarHeight)
            .background(Theme.accent)
    }
}
