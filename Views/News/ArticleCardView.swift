//
//  ArticleCardView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

enum ArticleCardStyle {
    case list
    case cover
}

struct ArticleCardView: View {
    let article: Article
    var style: ArticleCardStyle = .list
    let onFavorite: () -> Void

    var body: some View {
        switch style {
        case .list:
            listLayout
        case .cover:
            coverLayout
        }
    }

    // MARK: - Layouts

    private var listLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail / Capa
            AsyncImage(url: URL(string: article.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 70)
                        .clipped()
                case .failure, .empty:
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 100, height: 70)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Texto
            VStack(alignment: .leading, spacing: 4) {
                // Categoria badge
                if let category = article.categories.first {
                    Text(category.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(TBTheme.accent)
                }

                Text(article.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(article.pubDate.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !article.author.isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(article.author)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Botão favorito
            Button(action: onFavorite) {
                Image(systemName: article.isFavorite ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(article.isFavorite ? TBTheme.accent : .secondary)
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var coverLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Imagem Grande (Capa) — proporção 16:9 sem deformação
            AsyncImage(url: URL(string: article.thumbnailURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipped()
                case .failure, .empty:
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Conteúdo
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Categoria
                        if let category = article.categories.first {
                            Text(category.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(TBTheme.accent)
                        }

                        // Título
                        Text(article.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    // Botão favorito
                    Button(action: onFavorite) {
                        Image(systemName: article.isFavorite ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(article.isFavorite ? TBTheme.accent : .secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }

                // Metadata
                HStack(spacing: 4) {
                    Text(article.pubDate.formatted(.relative(presentation: .named)))
                    if !article.author.isEmpty {
                        Text("·")
                        Text(article.author).lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
    }
}
