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
    
    // ✅ Verifica se o usuário é Pro para remover o anúncio
    @AppStorage("isAdFree") private var isAdFree = false
    
    // ✅ Estado para falha do anúncio (AdGuard/Sem Internet)
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
                    // 1. Capa (Tamanho total, sem blur)
                    artworkSection
                    
                    // 2. Informações do Episódio (Título e Data)
                    episodeInfoSection
                    
                    // ✅ 3. Anúncio ABAIXO da capa (Se não for Pro)
                    if !isAdFree {
                        adSection
                    }
                    
                    // 4. Barra de Progresso
                    progressSection
                    
                    // 5. Controles Principais (Play/Pause/Skip)
                    mainPlaybackControls
                    
                    // 6. Ações Secundárias (Favorito/Share)
                    secondaryActionControls
                    
                    // ✅ 7. Descrição/Resumo (Voltou)
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
            // ✅ Tenta dar o play assim que a view aparece
            .onAppear {
                if !isCurrentEpisode {
                    viewModel.play(episode)
                }
            }
        }
    }

    // MARK: - Seção da Capa (Artwork)
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
        // Efeito de pulsação suave quando o áudio está tocando
        .scaleEffect(isCurrentEpisode && viewModel.isPlaying ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.isPlaying)
    }

    private var placeholderArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(TBTheme.highlightGradient)
            Image(systemName: "mic.fill").font(.system(size: 64)).foregroundStyle(.white)
        }
    }

    // MARK: - Informações do Episódio
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
    
    // MARK: - ✅ Seção de Anúncio Dedicada (Abaixo da Info)
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
                    // O Banner do AdMob
                    AdBannerView(adFailed: $adFailed)
                        .frame(width: 320, height: 50)
                        .scaleEffect(0.9) // Ajuste leve para caber no layout
                }
            }
            .frame(height: adFailed ? 80 : 60)
            
            // Tag de Publicidade (Ética/Requisito Store)
            Text("PUBLICIDADE")
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - Seção de Progresso
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

    // MARK: - Controles de Reprodução
    private var mainPlaybackControls: some View {
        HStack(spacing: 48) {
            Button { viewModel.skipBackward(seconds: 15) } label: {
                Image(systemName: "gobackward.15").font(.system(size: 28))
            }
            .disabled(!isCurrentEpisode)

            // Botão Central de Play/Pause
            Button {
                // Chama a lógica centralizada de play do ViewModel
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

    // MARK: - Controles Secundários
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

    // MARK: - ✅ Seção de Descrição (Voltou)
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

    // Helper para formatar tempo (ex: 01:20:30)
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
