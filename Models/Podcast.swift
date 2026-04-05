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
    // ✅ O SwiftData usa o PersistentIdentifier internamente,
    // mas marcamos o 'id' do RSS como único para evitar duplicatas.
    @Attribute(.unique) var id: String
    
    var title: String
    var audioURL: String
    var pubDate: Date
    var duration: String
    var thumbnailURL: String      // artwork do episódio (se tiver)
    var channelArtworkURL: String // artwork do canal (fallback)
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
        summary: String,
        isFavorite: Bool = false,
        playbackPosition: Double = 0
    ) {
        self.id = id
        self.title = title
        self.audioURL = audioURL
        self.pubDate = pubDate
        self.duration = duration
        self.thumbnailURL = thumbnailURL
        self.channelArtworkURL = channelArtworkURL
        self.summary = summary
        self.isFavorite = isFavorite
        self.playbackPosition = playbackPosition
    }

    // ✅ Computada para facilitar o uso nas Views (Artwork do Ep ou do Canal)
    @Transient // Indica ao SwiftData para não tentar salvar esta propriedade no banco
    var artworkURL: String {
        thumbnailURL.isEmpty ? channelArtworkURL : thumbnailURL
    }
}

// MARK: - Extensão Identifiable
// O @Model já provê a conformidade básica, mas para usar o objeto em .sheet(item:)
// ou ForEach sem problemas, garantimos que o SwiftUI use o 'id' como referência.

