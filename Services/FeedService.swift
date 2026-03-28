//
//  FeedService.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import Foundation

enum FeedError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parseError(Error)
    case emptyFeed

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "URL inválida."
        case .networkError(let e): return "Erro de rede: \(e.localizedDescription)"
        case .parseError(let e):   return "Erro ao ler feed: \(e.localizedDescription)"
        case .emptyFeed:           return "Nenhum item encontrado no feed."
        }
    }
}

actor FeedService {

    func fetchArticles(category: TBCategory, page: Int = 1) async throws -> [RSSItem] {
        var urlString = category.feedURL.absoluteString
        if page > 1 {
            if urlString.contains("?") {
                urlString += "&paged=\(page)"
            } else {
                urlString += "?paged=\(page)"
            }
        }

        guard let url = URL(string: urlString) else { throw FeedError.invalidURL }

        let feed = try await fetchFeed(from: url)
        return feed.items.filter { !$0.isPodcast }
    }

    func fetchPodcasts() async throws -> (episodes: [RSSItem], channelArtwork: String) {
        let feed = try await fetchFeed(from: TBConfig.Feed.tecnocast)
        let episodes = feed.items.filter { $0.isPodcast }
        return (episodes, feed.channelArtworkURL)
    }

    // ✅ Busca via feed RSS com ?s= — mesmo parser do feed normal
    func search(term: String, page: Int = 1) async throws -> [RSSItem] {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        var urlString = "https://tecnoblog.net/feed/?s=\(encoded)"
        if page > 1 {
            urlString += "&paged=\(page)"
        }

        guard let url = URL(string: urlString) else { throw FeedError.invalidURL }

        let feed = try await fetchFeed(from: url)
        return feed.items.filter { !$0.isPodcast }
    }

    // MARK: - Private

    private func fetchFeed(from url: URL) async throws -> RSSFeed {
        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(from: url)
            data = d
        } catch {
            throw FeedError.networkError(error)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let xmlParser = XMLParser(data: data)
            let delegate = TBXMLParser(continuation: continuation)
            xmlParser.delegate = delegate
            xmlParser.parse()
        }
    }
}
