//
//  MatchStatusActions.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import SwiftUI

struct MatchStatusActions: View {

    let status: MatchStatus
    let profileName: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        switch status {
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
                label: "Decline \(profileName)",
                action: onDecline
            )
            circleButton(
                systemName: "checkmark",
                tint: Theme.accent,
                label: "Accept \(profileName)",
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
