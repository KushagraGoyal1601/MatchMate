//
//  ProfilePhotoView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import SwiftUI

struct ProfilePhotoView: View {

    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            case .empty:
                ZStack {
                    Theme.pageBackground
                    ProgressView()
                }
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Theme.pageBackground
            Image(systemName: "person.fill")
                .font(.system(size: size / 3))
                .foregroundStyle(.tertiary)
        }
    }
}
