//
//  PodcastHeaderView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct PodcastHeaderView: View {
    @Environment(PodcastViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 16) {
            // Artwork do canal vinda do feed RSS
            Group {
                if !viewModel.channelArtworkURL.isEmpty,
                   let url = URL(string: viewModel.channelArtworkURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            placeholderArtwork
                        }
                    }
                } else {
                    placeholderArtwork
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tecnocast")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("O podcast semanal do Tecnoblog sobre tecnologia, inovação e cultura digital.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    PodcastBadge(title: "Spotify", icon: "music.note")
                    PodcastBadge(title: "Apple", icon: "applelogo")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(TBTheme.highlightGradient)
            Image(systemName: "mic.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
        }
    }
}

struct PodcastBadge: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(TBTheme.accent.opacity(0.15))
            .foregroundStyle(TBTheme.accent)
            .clipShape(Capsule())
    }
}
