//
//  ProfilePhotoView.swift
//  MatchMate
//
//  Created by Kushagra Goyal on 05/09/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var imageLoader: ImageLoading = ImageLoader()
}

struct ProfilePhotoView: View {

    let url: URL?
    let size: CGFloat

    @Environment(\.imageLoader) private var imageLoader

    @State private var image: UIImage?
    @State private var isUnavailable = false

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: 8))
            .accessibilityHidden(true)
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if isUnavailable {
            placeholder
        } else {
            ZStack {
                Theme.pageBackground
                ProgressView()
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Theme.pageBackground
            Image(systemName: "person.fill")
                .font(.system(size: size / 3))
                .foregroundStyle(.tertiary)
        }
    }

    private func load() async {
        guard let url else {
            isUnavailable = true
            return
        }

        image = nil
        isUnavailable = false

        do {
            let data = try await imageLoader.data(for: url)
            guard let decoded = UIImage(data: data) else {
                isUnavailable = true
                return
            }
            image = decoded
        } catch is CancellationError {
            return
        } catch {
            isUnavailable = true
        }
    }
}
