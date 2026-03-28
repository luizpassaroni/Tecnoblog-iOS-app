//
//  TBCategory.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import Foundation

enum TBCategory: String, CaseIterable, Identifiable {
    case all        = "Todos"
    case celulares  = "Celulares"
    case software   = "Software"
    case hardware   = "Hardware"
    case games      = "Games"
    case negocios   = "Negócios"
    case telecom    = "Telecom"
    case ciencia    = "Ciência"
    case podcast    = "Tecnocast"

    var id: String { rawValue }

    // Slug usado na URL do feed: tecnoblog.net/tema/{slug}/feed
    var feedSlug: String? {
        switch self {
        case .all:       return nil
        case .celulares: return "celulares"
        case .software:  return "software"
        case .hardware:  return "hardware"
        case .games:     return "jogos"
        case .negocios:  return "negocios"
        case .telecom:   return "telecomun"
        case .ciencia:   return "ciencia"
        case .podcast:   return nil
        }
    }

    var feedURL: URL {
        if let slug = feedSlug {
            return URL(string: "https://tecnoblog.net/tema/\(slug)/feed")!
        }
        return URL(string: "https://tecnoblog.net/feed")!
    }

    var sfSymbol: String {
        switch self {
        case .all:       return "newspaper"
        case .celulares: return "iphone"
        case .software:  return "laptopcomputer"
        case .hardware:  return "cpu"
        case .games:     return "gamecontroller"
        case .negocios:  return "chart.bar"
        case .telecom:   return "antenna.radiowaves.left.and.right"
        case .ciencia:   return "atom"
        case .podcast:   return "mic"
        }
    }
}
