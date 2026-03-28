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

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER FIXO (LOGO CENTRALIZADO) ---
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
            
            // --- LISTA DE NOTÍCIAS ---
            ZStack {
                if viewModel.articles.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    articleList
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
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
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCardView(article: article, style: .cover) {
                            viewModel.toggleFavorite(article)
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 16)
                    // ✅ GATILHO DE SCROLL INFINITO:
                    .onAppear {
                        if article.id == viewModel.articles.last?.id {
                            Task {
                                await viewModel.loadArticles()
                            }
                        }
                    }
                }

                // ✅ INDICADOR DE CARREGAMENTO NO RODAPÉ
                if viewModel.isLoading && !viewModel.articles.isEmpty {
                    ProgressView()
                        .padding(.vertical, 32)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView("Sem notícias", systemImage: "newspaper")
    }
}
