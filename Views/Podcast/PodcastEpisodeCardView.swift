//
//  PodcastEpisodeCardView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct PodcastEpisodeCardView: View {
    let episode: PodcastEpisode
    @Environment(PodcastViewModel.self) private var viewModel
    
    // Callback para o botão de Play
    var onPlayTapped: () -> Void

    private var isCurrentEpisode: Bool {
        viewModel.currentEpisode?.id == episode.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            
            // Artwork / play indicator
            ZStack {
                AsyncImage(url: URL(string: episode.thumbnailURL)) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(TBTheme.highlightGradient)
                            .overlay { Image(systemName: "mic.fill").foregroundStyle(.white) }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if isCurrentEpisode {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black.opacity(0.45))
                        .frame(width: 64, height: 64)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(isCurrentEpisode ? TBTheme.accent : .primary)

                Text(episode.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(episode.pubDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption2)
                    
                    if !episode.duration.isEmpty {
                        Label(episode.duration, systemImage: "clock")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Botões de ação
            VStack(spacing: 12) {
                Button {
                    onPlayTapped()
                } label: {
                    Image(systemName: isCurrentEpisode && viewModel.isPlaying
                          ? "pause.circle.fill"
                          : "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(TBTheme.accent)
                }

                Button {
                    viewModel.toggleFavorite(episode)
                } label: {
                    Image(systemName: episode.isFavorite ? "bookmark.fill" : "bookmark")
                        .font(.callout)
                        .foregroundStyle(episode.isFavorite ? TBTheme.accent : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.001)) // Garante clique em toda área
    }
}
