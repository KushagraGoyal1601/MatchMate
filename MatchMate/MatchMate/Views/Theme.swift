//
//  Theme.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 03/09/26.
//

import SwiftUI

enum Theme {

    static let accent = Color(red: 0.314, green: 0.682, blue: 0.780)

    static let pageBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)

    enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let cardHorizontalPadding: CGFloat = 12
        static let cardSpacing: CGFloat = 16
        static let photoSize: CGFloat = 180
        static let actionButtonSize: CGFloat = 60
        static let statusBarHeight: CGFloat = 56
    }
}
