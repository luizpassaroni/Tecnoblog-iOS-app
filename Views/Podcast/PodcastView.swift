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

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER FIXO (ESTILO SITE) ---
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
            
            // --- CONTEÚDO ---
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    PodcastHeaderView()
                    
                    ForEach(viewModel.episodes) { episode in
                        PodcastEpisodeCardView(episode: episode)
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top) // Garante que o azul encoste no topo
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadEpisodes()
        }
        .refreshable { await viewModel.loadEpisodes() }
    }
}
