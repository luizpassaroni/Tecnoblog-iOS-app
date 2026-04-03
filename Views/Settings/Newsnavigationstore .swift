//
//  Newsnavigationstore .swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 28/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

// ✅ Classe Observable que carrega o NavigationPath do NewsView
// para qualquer view filha, inclusive dentro da WebView
@Observable
final class NewsNavigationStore {
    var path = NavigationPath()
}

private struct NewsNavigationStoreKey: EnvironmentKey {
    static let defaultValue = NewsNavigationStore()
}

extension EnvironmentValues {
    var newsNavigation: NewsNavigationStore {
        get { self[NewsNavigationStoreKey.self] }
        set { self[NewsNavigationStoreKey.self] = newValue }
    }
}
