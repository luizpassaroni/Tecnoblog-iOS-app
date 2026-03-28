//
//  NewsViewModel.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class NewsViewModel {
    var articles: [Article] = []
    var isLoading = false
    var errorMessage: String?
    var selectedCategory: TBCategory = .all

    private let feedService = FeedService()
    private var modelContext: ModelContext?
    
    // Controle de paginação
    private var currentPage = 1
    private var hasMorePages = true

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Load

    func loadArticles(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        // Se for refresh (pull-to-refresh ou troca de categoria), reinicia a contagem.
        // Se for paginação (scroll infinito), verifica se ainda tem páginas.
        if refresh {
            currentPage = 1
            hasMorePages = true
        } else if !hasMorePages {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Passa a página atual para o serviço
            let items = try await feedService.fetchArticles(category: selectedCategory, page: currentPage)
            
            // Se a API retornar vazio, significa que acabaram as notícias
            if items.isEmpty {
                hasMorePages = false
                isLoading = false
                return
            }
            
            // Prepara lista temporária dos itens recém-baixados
            var newArticles: [Article] = []

            if let context = modelContext {
                for item in items {
                    // Ignora se for podcast na lista de notícias
                    guard !item.isPodcast else { continue }
                    
                    let id = item.guid.isEmpty ? item.link : item.guid
                    
                    // Verifica se já existe no banco para preservar o status de Favorito
                    let descriptor = FetchDescriptor<Article>(
                        predicate: #Predicate { $0.id == id }
                    )
                    
                    if let existing = try? context.fetch(descriptor).first {
                        // Se existe, usamos o objeto do banco (preserva favoritos)
                        newArticles.append(existing)
                    } else {
                        // Se não existe, cria novo e insere
                        let newArticle = Article(
                            id: id,
                            title: item.title,
                            link: item.link,
                            pubDate: item.pubDate,
                            thumbnailURL: item.thumbnailURL,
                            excerpt: item.excerpt,
                            author: item.author,
                            categories: item.categories
                        )
                        context.insert(newArticle)
                        newArticles.append(newArticle)
                    }
                }
                
                // Salva alterações (novos inserts)
                try? context.save()
                
            } else {
                // Fallback (Preview ou sem contexto)
                newArticles = items.filter { !$0.isPodcast }.map { item -> Article in
                    Article(
                        id: item.guid.isEmpty ? item.link : item.guid,
                        title: item.title,
                        link: item.link,
                        pubDate: item.pubDate,
                        thumbnailURL: item.thumbnailURL,
                        excerpt: item.excerpt,
                        author: item.author,
                        categories: item.categories
                    )
                }
            }
            
            // Atualiza a lista principal na UI
            withAnimation {
                if refresh {
                    // Se é refresh, substitui tudo
                    self.articles = newArticles
                } else {
                    // Se é paginação, adiciona ao final (evitando duplicatas visuais)
                    let existingIDs = Set(self.articles.map { $0.id })
                    let uniqueNew = newArticles.filter { !existingIDs.contains($0.id) }
                    self.articles.append(contentsOf: uniqueNew)
                }
            }
            
            // Prepara a próxima página para a próxima vez que a função for chamada
            currentPage += 1

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFavorite(_ article: Article) {
        article.isFavorite.toggle()
        // Salva imediatamente
        try? modelContext?.save()
    }

    func selectCategory(_ category: TBCategory) {
        selectedCategory = category
        articles = [] 
        errorMessage = nil
        
        // Resetar paginação ao trocar de categoria
        currentPage = 1
        hasMorePages = true
        
        Task { await loadArticles(refresh: true) }
    }
}
