//
//  MainView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//
import SwiftUI

struct MainView: View {
    @Environment(MainViewModel.self) private var mainViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    // ✅ Observa se o usuário comprou a versão sem anúncios
    @AppStorage("isAdFree") private var isAdFree = false
    
    @State private var newsViewModel = NewsViewModel()
    @State private var podcastViewModel = PodcastViewModel()
    @State private var selectedTab: AppTab = .news
    
    // Estado para controlar se o anúncio foi bloqueado pelo AdGuard
    @State private var adFailed = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // Notícias
                Tab("Notícias", systemImage: "newspaper", value: AppTab.news) {
                    NewsView()
                        .environment(newsViewModel)
                        .environment(podcastViewModel)
                }

                // Tecnocast
                Tab("Tecnocast", systemImage: "mic", value: AppTab.podcast) {
                    NavigationStack {
                        PodcastView()
                            .environment(podcastViewModel)
                    }
                }

                // Favoritos
                Tab("Favoritos", systemImage: "bookmark", value: AppTab.favorites) {
                    NavigationStack {
                        FavoritesView()
                            .environment(newsViewModel)
                            .environment(podcastViewModel)
                    }
                }

                // Ajustes
                Tab("Ajustes", systemImage: "gearshape", value: AppTab.settings) {
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            
            // ✅ Só exibe o overlay de anúncios se o usuário NÃO for Pro (isAdFree == false)
            if !isAdFree {
                adFixedOverlay
            }
        }
        .tint(TBTheme.accent)
        .overlay(alignment: .bottom) {
            if podcastViewModel.currentEpisode != nil {
                MiniPlayerView()
                    .environment(podcastViewModel)
                    .padding(.bottom, 49)
            }
        }
    }

    // MARK: - Layout do Anúncio Fixo
    private var adFixedOverlay: some View {
        VStack(spacing: 0) {
            // 1. Espaço para saltar o logo
            Color.clear.frame(height: 85)
            
            HStack {
                Spacer()
                
                if adFailed {
                    // MENSAGEM DE APOIO (Caso o AdGuard bloqueie o banner)
                    Text("Apoie o Tecnoblog: desative seu bloqueador ❤️")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 320, height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .transition(.opacity)
                } else {
                    // BANNER REAL
                    AdBannerView(adFailed: $adFailed)
                        .frame(width: 320, height: 50)
                        .background(Color.clear)
                }
                
                Spacer()
            }
            // 2. Deslocamento para posicionar na transição azul/preto
            .offset(y: 10)
        }
        .allowsHitTesting(true)
        .ignoresSafeArea(edges: .top)
    }
}
