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
                VStack(spacing: 24) {
                    artworkSection
                    episodeInfoSection

                    if !isAdFree {
                        adSection
                    }

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
                        .fontWeight(.medium)
                }
            }
            .onAppear {
                if !isCurrentEpisode {
                    viewModel.play(episode)
                }
            }
        }
    }

    // MARK: - Artwork
    private var artworkSection: some View {
        AsyncImage(url: URL(string: episode.artworkURL)) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                placeholderArtwork
            }
        }
        .id(episode.id)
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: TBTheme.accent.opacity(0.2), radius: 15, y: 8)
        .scaleEffect(isCurrentEpisode && viewModel.isPlaying ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isPlaying)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(TBTheme.highlightGradient)
            Image(systemName: "mic.fill").font(.system(size: 64)).foregroundStyle(.white)
        }
    }

    // MARK: - Episode Info
    private var episodeInfoSection: some View {
        VStack(spacing: 8) {
            Text(episode.title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            Text("Tecnocast · \(episode.pubDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Ad Section
    private var adSection: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))

                if adFailed {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(TBTheme.accent)
                        Text("Apoie o Tecnoblog")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding()
                } else {
                    AdBannerView(adFailed: $adFailed)
                        .frame(width: 320, height: 50)
                        .scaleEffect(0.9)
                }
            }
            .frame(height: adFailed ? 80 : 60)

            Text("PUBLICIDADE")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(value: Binding(
                get: { progress },
                set: { if isCurrentEpisode { viewModel.seek(to: $0 * viewModel.duration) } }
            ), in: 0...1)
            .tint(TBTheme.accent)

            HStack {
                Text(formatTime(isCurrentEpisode ? viewModel.currentTime : episode.playbackPosition))
                Spacer()
                Text(formatTime(isCurrentEpisode ? viewModel.duration : 0))
            }
            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    // MARK: - Main Controls
    private var mainPlaybackControls: some View {
        HStack(spacing: 48) {
            Button { viewModel.skipBackward(seconds: 15) } label: {
                Image(systemName: "gobackward.15").font(.system(size: 28))
            }
            .disabled(!isCurrentEpisode)

            Button {
                viewModel.play(episode)
            } label: {
                ZStack {
                    Circle()
                        .fill(TBTheme.accent)
                        .frame(width: 72, height: 72)
                        .shadow(color: TBTheme.accent.opacity(0.3), radius: 12, y: 6)

                    Image(systemName: isCurrentEpisode && viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: isCurrentEpisode && viewModel.isPlaying ? 0 : 2)
                }
            }

            Button { viewModel.skipForward(seconds: 30) } label: {
                Image(systemName: "goforward.30").font(.system(size: 28))
            }
            .disabled(!isCurrentEpisode)
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }

    // MARK: - Secondary Controls
    private var secondaryActionControls: some View {
        HStack(spacing: 40) {
            Button { viewModel.toggleFavorite(episode) } label: {
                Image(systemName: episode.isFavorite ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(episode.isFavorite ? TBTheme.accent : .secondary)
            }

            ShareLink(item: URL(string: episode.audioURL) ?? URL(string: "https://tecnoblog.net")!) {
                Image(systemName: "square.and.arrow.up").foregroundStyle(.secondary)
            }

            Button {
                if let url = URL(string: episode.audioURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "safari").foregroundStyle(.secondary)
            }
        }
        .font(.title3)
        .buttonStyle(.plain)
    }

    // MARK: - Description
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sobre este episódio").font(.headline)
            Text(episode.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN, !seconds.isInfinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}
