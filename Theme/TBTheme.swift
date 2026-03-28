//
//  TBTheme.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

enum TBTheme {
    // Cores exatas extraídas do site oficial
    static let siteBlueLight = Color(hex: "#22A9E1")
    static let siteBlueDark  = Color(hex: "#004AB0")
    static let blue          = Color(hex: "#0073E6")

    static var accent: Color { blue }

    // MARK: - Gradientes
    
    // Nome mantido como highlightGradient para não quebrar o PodcastHeaderView
    static var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [siteBlueLight, siteBlueDark],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double(int         & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
