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
        ZStack {
            if viewModel.isLoading && viewModel.episodes.isEmpty {
                loadingView
            } else if viewModel.episodes.isEmpty {
                emptyView
            } else {
                episodeList
            }
        }
        .navigationTitle("Tecnocast")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadEpisodes()
        }
        .refreshable { await viewModel.loadEpisodes() }
    }

    private var episodeList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                PodcastHeaderView()
                ForEach(viewModel.episodes) { episode in
                    PodcastEpisodeCardView(episode: episode)
                    Divider().padding(.leading, 16)
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Carregando Tecnocast...").frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView("Sem episódios", systemImage: "mic.slash")
    }
}
