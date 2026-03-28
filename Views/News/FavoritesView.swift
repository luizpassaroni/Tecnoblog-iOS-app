//
//  FavoritesView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<Article> { $0.isFavorite == true }) private var favoriteArticles: [Article]
    @Query(filter: #Predicate<PodcastEpisode> { $0.isFavorite == true }) private var favoriteEpisodes: [PodcastEpisode]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(PodcastViewModel.self) private var podcastViewModel

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
            
            // --- LISTA DE FAVORITOS ---
            List {
                if !favoriteArticles.isEmpty {
                    Section("Notícias") {
                        ForEach(favoriteArticles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                favoriteArticleRow(article: article)
                            }
                        }
                        .onDelete(perform: deleteArticle)
                    }
                }

                if !favoriteEpisodes.isEmpty {
                    Section("Tecnocast") {
                        ForEach(favoriteEpisodes) { episode in
                            Button {
                                podcastViewModel.play(episode)
                            } label: {
                                favoriteEpisodeRow(episode: episode)
                            }
                        }
                        .onDelete(perform: deleteEpisode)
                    }
                }
            }
            .listStyle(.plain)
            .overlay {
                if favoriteArticles.isEmpty && favoriteEpisodes.isEmpty {
                    ContentUnavailableView(
                        "Nenhum favorito",
                        systemImage: "bookmark.slash",
                        description: Text("Os itens que marcar como favorito aparecerão aqui.")
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
    }

    // MARK: - Componentes Auxiliares

    @ViewBuilder
    private func favoriteArticleRow(article: Article) -> some View {
        HStack(spacing: 12) {
            // ✅ Corrigido de imageUrl para thumbnailURL
            AsyncImage(url: URL(string: article.thumbnailURL)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.secondarySystemBackground)
                    .overlay(Image(systemName: "newspaper").foregroundStyle(.secondary))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(article.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func favoriteEpisodeRow(episode: PodcastEpisode) -> some View {
        HStack(spacing: 12) {
            // ✅ Corrigido de imageUrl para artworkURL (que é a propriedade do seu modelo)
            AsyncImage(url: URL(string: episode.artworkURL)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.secondarySystemBackground)
                    .overlay(Image(systemName: "mic.fill").foregroundStyle(.secondary))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(episode.title)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .foregroundStyle(TBTheme.accent)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Funções de Exclusão

    private func deleteArticle(at offsets: IndexSet) {
        for index in offsets {
            favoriteArticles[index].isFavorite = false
        }
    }

    private func deleteEpisode(at offsets: IndexSet) {
        for index in offsets {
            favoriteEpisodes[index].isFavorite = false
        }
    }
}
