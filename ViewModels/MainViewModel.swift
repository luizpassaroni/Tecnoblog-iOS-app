//
//  MainViewModel.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class MainViewModel {
    var selectedTab: AppTab = .news
    var deepLinkURL: URL?

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([Article.self, PodcastEpisode.self])
        let config = ModelConfiguration("TecnoblogDB", schema: schema)
        modelContainer = try! ModelContainer(for: schema, configurations: config)
    }
}

enum AppTab: String, CaseIterable {
    case news      = "Notícias"
    case podcast   = "Tecnocast"
    case favorites = "Favoritos"
    case settings  = "Ajustes"

    var sfSymbol: String {
        switch self {
        case .news:      return "newspaper"
        case .podcast:   return "mic"
        case .favorites: return "bookmark"
        case .settings:  return "gearshape"
        }
    }
}
