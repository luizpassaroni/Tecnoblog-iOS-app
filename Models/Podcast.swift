//
//  Podcast.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftData
import Foundation

@Model
final class PodcastEpisode {
    @Attribute(.unique) var id: String
    var title: String
    var audioURL: String
    var pubDate: Date
    var duration: String
    var thumbnailURL: String      // artwork do episódio (se tiver)
    var channelArtworkURL: String // ✅ artwork do canal (fallback)
    var summary: String
    var isFavorite: Bool
    var playbackPosition: Double

    init(
        id: String,
        title: String,
        audioURL: String,
        pubDate: Date,
        duration: String,
        thumbnailURL: String,
        channelArtworkURL: String = "",
        summary: String
    ) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.pubDate = pubDate
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.channelArtworkURL = channelArtworkURL
        self.summary = summary
        self.isFavorite = false
        self.playbackPosition = 0
    }

    // ✅ Retorna a melhor imagem disponível
    var artworkURL: String {
        thumbnailURL.isEmpty ? channelArtworkURL : thumbnailURL
    }
}
