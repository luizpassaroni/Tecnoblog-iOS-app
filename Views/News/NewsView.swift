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
    
    // ✅ Verifica se o usuário comprou a versão sem anúncios
    @AppStorage("isAdFree") private var isAdFree = false
    
    // ✅ Gerenciadores de Anúncios e Navegação
    @State private var adHandler = AdRewardedHandler()
    @State private var navStore = NewsNavigationStore()
    
    // ✅ Estados para o Alerta de Confirmação
    @State private var showAdAlert = false
    @State private var articleToOpen: Article?
    
    // ✅ Estado para aviso de falha (AdGuard/Sem Internet)
    @State private var showFailAlert = false

    var body: some View {
        NavigationStack(path: $navStore.path) {
            VStack(spacing: 0) {
                // --- HEADER FIXO (Padrão 100px) ---
                ZStack(alignment: .bottom) {
                    TBTheme.highlightGradient
                        .ignoresSafeArea(edges: .top)

                    HStack {
                        Spacer()
                        Image("tb-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 28) // Tamanho unificado
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
                .frame(height: 100)

                // --- LISTA DE NOTÍCIAS ---
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
            
            // ✅ Destinos de Navegação
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
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
        .environment(\.newsNavigation, navStore)
        
        // ✅ ALERTA 1: Pedir autorização para mostrar o AD
        .alert("Matéria Exclusiva", isPresented: $showAdAlert) {
            Button("Assistir e Ler") {
                if let article = articleToOpen {
                    adHandler.showAd(
                        onReward: {
                            // SUCESSO: Navega para a matéria
                            navStore.path.append(article)
                        },
                        onFailure: {
                            // FALHA: Bloqueado por AdGuard ou erro de carregamento
                            showFailAlert = true
                        }
                    )
                }
            }
            Button("Cancelar", role: .cancel) {
                articleToOpen = nil
            }
        } message: {
            Text("Assista a um vídeo rápido para apoiar o Tecnoblog e liberar o acesso a esta matéria.")
        }
        
        // ✅ ALERTA 2: Aviso caso o vídeo não carregue (Bloqueadores)
        .alert("Erro no Vídeo", isPresented: $showFailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Não conseguimos carregar o vídeo. Verifique sua conexão ou desative bloqueadores de anúncios (AdGuard) para prosseguir.")
        }
        
        // Inicialização
        .task {
            viewModel.setup(context: modelContext)
            await viewModel.loadArticles()
            
            // Só carrega o anúncio se o usuário não for Pro
            if !isAdFree {
                adHandler.loadAd()
            }
        }
        .refreshable { await viewModel.loadArticles(refresh: true) }
    }

    // MARK: - Componente da Lista
    private var articleList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Color.clear.frame(height: 10)

                ForEach(viewModel.articles) { article in
                    Button {
                        if isAdFree {
                            // ✅ Se for PRO: Abre direto
                            navStore.path.append(article)
                        } else {
                            // ✅ Se NÃO for PRO: Mostra o alerta do Ad
                            self.articleToOpen = article
                            self.showAdAlert = true
                        }
                    } label: {
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
