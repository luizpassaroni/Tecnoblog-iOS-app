//
//  MiniPlayerView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(PodcastViewModel.self) private var viewModel
    @State private var showFullPlayer = false

    private var episode: PodcastEpisode? { viewModel.currentEpisode }

    var body: some View {
        guard let episode else { return AnyView(EmptyView()) }

        return AnyView(
            Button {
                showFullPlayer = true
            } label: {
                VStack(spacing: 0) {
                    // Barra de progresso
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 2)
                            Rectangle()
                                .fill(TBTheme.accent)
                                .frame(
                                    width: viewModel.duration > 0
                                        ? geo.size.width * (viewModel.currentTime / viewModel.duration)
                                        : 0,
                                    height: 2
                                )
                        }
                    }
                    .frame(height: 2)

                    HStack(spacing: 12) {
                        // Artwork
                        ZStack {
                            AsyncImage(url: URL(string: episode.thumbnailURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Rectangle()
                                        .fill(TBTheme.highlightGradient)
                                        .overlay {
                                            Image(systemName: "mic.fill")
                                                .foregroundStyle(.white)
                                                .font(.caption)
                                        }
                                }
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Título
                        VStack(alignment: .leading, spacing: 2) {
                            Text(episode.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundStyle(.primary)

                            Text("Tecnocast")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Controles
                        HStack(spacing: 16) {
                            // Voltar 15s
                            Button {
                                viewModel.skipBackward()
                            } label: {
                                Image(systemName: "gobackward.15")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }

                            // Play/Pause
                            Button {
                                viewModel.togglePlayPause()
                            } label: {
                                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                    .foregroundStyle(TBTheme.accent)
                            }

                            // Avançar 30s
                            Button {
                                viewModel.skipForward()
                            } label: {
                                Image(systemName: "goforward.30")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showFullPlayer) {
                PodcastPlayerView(episode: episode)
            }
        )
    }
}
