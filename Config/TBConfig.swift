//
//  TBConfig.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import Foundation

enum TBConfig {
    // MARK: - Feeds
    enum Feed {
        static let main      = URL(string: "https://tecnoblog.net/feed")!
        static let tecnocast = URL(string: "https://tecnoblog.net/tecnocast/feed")!

        static func category(_ slug: String) -> URL {
            URL(string: "https://tecnoblog.net/tema/\(slug)/feed")!
        }
    }

    // MARK: - WordPress REST API
    enum API {
        static let base     = "https://tecnoblog.net/wp-json/wp/v2"
        static let posts    = "\(base)/posts"
        static let search   = "\(base)/posts?search="
        static let perPage  = 20
    }

    // MARK: - App
    enum App {
        static let name     = "Tecnoblog"
        static let siteURL  = URL(string: "https://tecnoblog.net")!
        static let youtube  = URL(string: "https://www.youtube.com/@tecnoblog")!
    }
}
