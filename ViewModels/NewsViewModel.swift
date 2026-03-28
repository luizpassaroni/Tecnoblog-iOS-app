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
    
    private var currentPage = 1
    private var hasMorePages = true

    func setup(context: ModelContext) {
        self.modelContext = context
    }

    func loadArticles(refresh: Bool = false) async {
        guard !isLoading else { return }
        
        if refresh {
            currentPage = 1
            hasMorePages = true
        } else if !hasMorePages {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Busca os itens brutos do serviço
            let items = try await feedService.fetchArticles(category: selectedCategory, page: currentPage)
            
            // ✅ Se o servidor retornar VAZIO, realmente não há mais páginas
            if items.isEmpty {
                hasMorePages = false
                isLoading = false
                return
            }
            
            // Filtra o que não é podcast
            let filteredItems = items.filter { !$0.isPodcast }

            // ✅ Se a página atual só tinha podcasts, pula para a próxima automaticamente
            if filteredItems.isEmpty && hasMorePages {
                currentPage += 1
                isLoading = false
                await loadArticles()
                return
            }

            var newArticles: [Article] = []

            if let context = modelContext {
                for item in filteredItems {
                    let id = item.guid.isEmpty ? item.link : item.guid
                    let descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.id == id })
                    
                    if let existing = try? context.fetch(descriptor).first {
                        newArticles.append(existing)
                    } else {
                        let newArticle = Article(
                            id: id, title: item.title, link: item.link,
                            pubDate: item.pubDate, thumbnailURL: item.thumbnailURL,
                            excerpt: item.excerpt, author: item.author, categories: item.categories
                        )
                        context.insert(newArticle)
                        newArticles.append(newArticle)
                    }
                }
                try? context.save()
            }
            
            withAnimation {
                if refresh {
                    self.articles = newArticles
                } else {
                    let existingIDs = Set(self.articles.map { $0.id })
                    let uniqueNew = newArticles.filter { !existingIDs.contains($0.id) }
                    self.articles.append(contentsOf: uniqueNew)
                }
            }
            
            currentPage += 1

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleFavorite(_ article: Article) {
        article.isFavorite.toggle()
        try? modelContext?.save()
    }

    func selectCategory(_ category: TBCategory) {
        selectedCategory = category
        articles = []
        errorMessage = nil
        currentPage = 1
        hasMorePages = true
        Task { await loadArticles(refresh: true) }
    }
}
