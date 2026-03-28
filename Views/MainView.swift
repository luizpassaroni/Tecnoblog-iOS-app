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
    @State private var newsViewModel = NewsViewModel()
    @State private var podcastViewModel = PodcastViewModel()
    @State private var selectedTab: AppTab = .news

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // --- ABA NOTÍCIAS ---
            Tab("Notícias", systemImage: "newspaper", value: AppTab.news) {
                NavigationStack {
                    NewsView()
                        .environment(newsViewModel)
                        .environment(podcastViewModel)
                }
                .safeAreaInset(edge: .bottom) {
                    if podcastViewModel.currentEpisode != nil {
                        Color.clear.frame(height: 72)
                    }
                }
            }

            // --- ABA TECNOCAST ---
            Tab("Tecnocast", systemImage: "mic", value: AppTab.podcast) {
                NavigationStack {
                    PodcastView()
                        .environment(podcastViewModel)
                }
            }

            // --- ABA FAVORITOS ---
            Tab("Favoritos", systemImage: "bookmark", value: AppTab.favorites) {
                NavigationStack {
                    FavoritesView()
                        .environment(newsViewModel)
                        .environment(podcastViewModel)
                }
            }

            // --- ABA AJUSTES ---
            Tab("Ajustes", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(TBTheme.accent)
        // Mini player global
        .overlay(alignment: .bottom) {
            if podcastViewModel.currentEpisode != nil {
                MiniPlayerView()
                    .environment(podcastViewModel)
                    .padding(.bottom, 49) // Altura aproximada da TabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: podcastViewModel.currentEpisode != nil)
    }
}
