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
    @Environment(\.modelContext) private var modelContext

    // ✅ Store compartilhado — injetado no Environment para os filhos acessarem
    @State private var navStore = NewsNavigationStore()

    var body: some View {
        NavigationStack(path: $navStore.path) {
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

                // --- LISTA ---
                ZStack {
                    if viewModel.articles.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView("Sem notícias", systemImage: "newspaper")
                    } else {
                        articleList
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarHidden(true)
            // ✅ Destino para Article (lista)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            // ✅ Destino para URL (link clicado dentro de uma matéria)
            .navigationDestination(for: URL.self) { url in
                ArticleDetailView(article: Article(
                    id: url.absoluteString,
                    title: "",
                    link: url.absoluteString,
                    pubDate: Date(),
                    thumbnailURL: "",
                    excerpt: "",
                    author: "",
                    categories: []
                ))
            }
        }
        // ✅ Injeta o store no Environment para ArticleDetailView acessar
        .environment(\.newsNavigation, navStore)
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadArticles()
        }
        .refreshable { await viewModel.loadArticles(refresh: true) }
    }

    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: 10)

                ForEach(viewModel.articles) { article in
                    NavigationLink(value: article) {
                        ArticleCardView(article: article, style: .cover) {
                            viewModel.toggleFavorite(article)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 16)
                        .onAppear {
                            if article.id == viewModel.articles.last?.id {
                                Task { await viewModel.loadArticles() }
                            }
                        }
                }

                if viewModel.isLoading && !viewModel.articles.isEmpty {
                    ProgressView()
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
