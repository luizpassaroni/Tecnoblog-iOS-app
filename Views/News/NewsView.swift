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
                // Fundo gradiente
                TBTheme.highlightGradient
                
                HStack {
                    Spacer()
                    Image("tb-logo") // Seu SVG centralizado
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28) // Altura para ficar elegante
                    Spacer()
                }
                .padding(.bottom, 12)
            }
            .frame(height: 100) // Altura que cobre o notch + espaço do logo
            
            // --- LISTA DE NOTÍCIAS ---
            ZStack {
                if viewModel.articles.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    articleList
                }
            }
        }
        // ESTA LINHA É A CHAVE: Faz a tela inteira começar no topo do vidro
        .ignoresSafeArea(edges: .top)
        
        // Remove barras fantasmas
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
                // Espaço invisível para a primeira notícia não ficar colada no azul
                Color.clear.frame(height: 10)
                
                ForEach(viewModel.articles) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        ArticleCardView(article: article, style: .cover) {
                            viewModel.toggleFavorite(article)
                        }
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 16)
                }
            }
        }
    }

    private var emptyView: some View {
        ContentUnavailableView("Sem notícias", systemImage: "newspaper")
    }
}
