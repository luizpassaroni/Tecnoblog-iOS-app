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
    
    @Environment(PodcastViewModel.self) private var podcastViewModel

    var body: some View {
        List {
            if !favoriteArticles.isEmpty {
                Section("Notícias") {
                    ForEach(favoriteArticles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            Text(article.title).font(.subheadline).lineLimit(2)
                        }
                    }
                }
            }

            if !favoriteEpisodes.isEmpty {
                Section("Tecnocast") {
                    ForEach(favoriteEpisodes) { episode in
                        Button { podcastViewModel.play(episode) } label: {
                            HStack {
                                Text(episode.title).font(.subheadline).lineLimit(2)
                                Spacer()
                                Image(systemName: "play.circle.fill").foregroundStyle(TBTheme.accent)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favoritos")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if favoriteArticles.isEmpty && favoriteEpisodes.isEmpty {
                ContentUnavailableView("Nenhum favorito", systemImage: "bookmark.slash", description: Text("Itens favoritados aparecerão aqui."))
            }
        }
    }
}
