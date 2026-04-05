//
//  PodcastView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

struct PodcastView: View {
    @Environment(PodcastViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("isAdFree") private var isAdFree = false
    
    @State private var adHandler = AdRewardedHandler()
    @State private var showAdAlert = false
    @State private var episodeToPlay: PodcastEpisode?
    @State private var showFailAlert = false
    
    // ✅ Estado para abrir o Player apenas após o Ad
    @State private var selectedEpisodeForSheet: PodcastEpisode?

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER FIXO ---
            ZStack(alignment: .bottom) {
                TBTheme.highlightGradient
                
                HStack {
                    Spacer()
                    Image("tb-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                    Spacer()
                }
                .padding(.bottom, 12)
            }
            .frame(height: 100)
            
            // --- LISTA DE EPISÓDIOS ---
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    PodcastHeaderView()
                    
                    ForEach(viewModel.episodes) { episode in
                        ZStack {
                            // O Card (agora ele não abre o sheet sozinho)
                            PodcastEpisodeCardView(episode: episode) {
                                handlePlayClick(for: episode)
                            }
                            
                            // ✅ INTERCEPTADOR: Se não for Pro, cobre o card todo
                            if !isAdFree {
                                Color.white.opacity(0.001)
                                    .onTapGesture {
                                        handlePlayClick(for: episode)
                                    }
                            }
                        }
                        
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        
        // ✅ Abre o Player (Sheet) de forma controlada
        .sheet(item: $selectedEpisodeForSheet) { episode in
            PodcastPlayerView(episode: episode)
        }
        
        // ✅ ALERTA 1: Confirmação do Vídeo
        .alert("Ouvir Tecnocast", isPresented: $showAdAlert) {
            Button("Assistir e Ouvir") {
                if let episode = episodeToPlay {
                    adHandler.showAd(
                        onReward: {
                            // SUCESSO: Libera o áudio e abre o Player
                            viewModel.currentEpisode = episode
                            self.selectedEpisodeForSheet = episode
                        },
                        onFailure: {
                            showFailAlert = true
                        }
                    )
                }
            }
            Button("Cancelar", role: .cancel) {
                episodeToPlay = nil
            }
        } message: {
            Text("Assista a um vídeo rápido para liberar este episódio. Usuários Pro não veem anúncios.")
        }
        
        .alert("Anúncio Bloqueado", isPresented: $showFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Não conseguimos carregar o vídeo. Desative bloqueadores para ouvir ou assine a versão Pro.")
        }
        
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadEpisodes()
            if !isAdFree { adHandler.loadAd() }
        }
        .refreshable { await viewModel.loadEpisodes() }
    }
    
    private func handlePlayClick(for episode: PodcastEpisode) {
        if isAdFree {
            viewModel.currentEpisode = episode
            self.selectedEpisodeForSheet = episode
        } else {
            self.episodeToPlay = episode
            self.showAdAlert = true
        }
    }
}

