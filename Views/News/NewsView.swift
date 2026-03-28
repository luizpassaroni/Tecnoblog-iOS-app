//
//  NewsView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

struct NewsView: View {
    @Environment(NewsViewModel.self) private var viewModel
    @Environment(PodcastViewModel.self) private var podcastViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if viewModel.articles.isEmpty && !viewModel.isLoading {
                emptyView
            } else if let error = viewModel.errorMessage, viewModel.articles.isEmpty {
                errorView(error)
            } else {
                articleList
            }
            
            if viewModel.isLoading && viewModel.articles.isEmpty {
                loadingView.background(Color(.systemBackground))
            }
        }
        .navigationTitle("Tecnoblog")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isLoading { ProgressView() }
            }
        }
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadArticles()
        }
        .refreshable {
            await viewModel.loadArticles(refresh: true)
        }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCardView(article: article, style: .cover) {
                            viewModel.toggleFavorite(article)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if article == viewModel.articles.last {
                            Task { await viewModel.loadArticles() }
                        }
                    }
                    Divider().padding(.leading, 16)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Carregando notícias...")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView("Sem notícias", systemImage: "newspaper", description: Text("Nenhuma notícia encontrada."))
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Erro ao carregar", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Tentar novamente") { Task { await viewModel.loadArticles(refresh: true) } }
                .buttonStyle(.borderedProminent)
                .tint(TBTheme.accent)
        }
    }
}
