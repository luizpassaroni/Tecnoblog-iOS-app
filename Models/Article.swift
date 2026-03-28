//
//  Article.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftData
import Foundation

@Model
final class Article {
    @Attribute(.unique) var id: String
    var title: String
    var link: String
    var pubDate: Date
    var thumbnailURL: String
    var excerpt: String
    var author: String
    var categories: [String]
    var isFavorite: Bool

    init(
        id: String,
        title: String,
        link: String,
        pubDate: Date,
        thumbnailURL: String,
        excerpt: String,
        author: String,
        categories: [String]
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.pubDate = pubDate
        self.thumbnailURL = thumbnailURL
        self.excerpt = excerpt
        self.author = author
        self.categories = categories
        self.isFavorite = false
    }
}
