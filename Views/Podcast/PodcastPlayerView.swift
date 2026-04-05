//
//  PodcastPlayerView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct PodcastPlayerView: View {
    let episode: PodcastEpisode
    @Environment(PodcastViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("isAdFree") private var isAdFree = false
    @State private var adFailed = false

    private var isCurrentEpisode: Bool {
        viewModel.currentEpisode?.id == episode.id
    }
    
    private var progress: Double {
        guard isCurrentEpisode, viewModel.duration > 0 else { return 0 }
        return viewModel.currentTime / viewModel.duration
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    artworkAndAdSection
                    episodeInfoSection
                    progressSection
                    mainPlaybackControls
                    secondaryActionControls
                    
                    if !episode.summary.isEmpty {
                        descriptionSection
                    }
                }
                .padding(24)
            }
            .navigationTitle("Tecnocast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Artwork Section
    private var artworkAndAdSection: some View {
        ZStack {
            AsyncImage(url: URL(string: episode.artworkURL)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    placeholderArtwork
                }
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .scaleEffect(!isAdFree ? 0.9 : 1.0)
            .blur(radius: !isAdFree ? 12 : 0)
            .opacity(!isAdFree ? 0.4 : 1.0)
            .shadow(color: TBTheme.accent.opacity(0.3), radius: 20, y: 10)

            if !isAdFree {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground).opacity(0.6))
                        .background(.ultraThinMaterial)
                    
                    if adFailed {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill").foregroundStyle(TBTheme.accent)
                            Text("Apoie o Tecnoblog").font(.caption).bold()
                        }
                    } else {
                        AdBannerView(adFailed: $adFailed)
                            .frame(width: 320, height: 50)
                            .scaleEffect(0.75)
                    }
                }
                .frame(width: 240, height: 240)
            }
        }
        .scaleEffect(isCurrentEpisode && viewModel.isPlaying ? 1.0 : 0.95)
        .animation(.spring(), value: viewModel.isPlaying)
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 24).fill(TBTheme.highlightGradient)
    }

    private var episodeInfoSection: some View {
        VStack(spacing: 8) {
            Text(episode.title).font(.title3).bold().multilineTextAlignment(.center)
            Text("Tecnocast").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(value: Binding(
                get: { progress },
                set: { viewModel.seek(to: $0 * viewModel.duration) }
            ))
            .tint(TBTheme.accent)
            
            HStack {
                Text(formatTime(isCurrentEpisode ? viewModel.currentTime : episode.playbackPosition))
                Spacer()
                Text(formatTime(isCurrentEpisode ? viewModel.duration : 0))
            }.font(.caption).monospacedDigit()
        }
    }

    private var mainPlaybackControls: some View {
        HStack(spacing: 48) {
            Button { viewModel.skipBackward() } label: { Image(systemName: "gobackward.15") }
            
            // ✅ CORREÇÃO: Chama viewModel.play()
            Button {
                viewModel.play(episode)
            } label: {
                ZStack {
                    Circle().fill(TBTheme.accent).frame(width: 72, height: 72)
                    Image(systemName: isCurrentEpisode && viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title).foregroundStyle(.white)
                }
            }
            
            Button { viewModel.skipForward() } label: { Image(systemName: "goforward.30") }
        }
        .font(.title2).buttonStyle(.plain)
    }

    private var secondaryActionControls: some View {
        HStack(spacing: 40) {
            Button { viewModel.toggleFavorite(episode) } label: {
                Image(systemName: episode.isFavorite ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(episode.isFavorite ? TBTheme.accent : .secondary)
            }
            // Adicione ShareLink se desejar
        }.font(.title3)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sobre este episódio").font(.headline)
            Text(episode.summary).font(.subheadline).foregroundStyle(.secondary)
        }
        .padding().background(Color(.secondarySystemBackground)).cornerRadius(16)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN, seconds > 0 else { return "0:00" }
        let m = Int(seconds) / 60, s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
