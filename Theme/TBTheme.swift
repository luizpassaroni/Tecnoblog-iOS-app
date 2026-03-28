//
//  TBTheme.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

enum TBTheme {
    // ✅ Azul oficial do Tecnoblog (#0073E6)
    static let blue = Color(hex: "#0073E6")

    // Alias principal — use sempre "accent" no código
    static var accent: Color { blue }

    // Azul escuro para hover / pressed states
    static let blueDark  = Color(hex: "#005BBF")

    // Azul claro para badges e backgrounds sutis
    static let blueLight = Color(hex: "#E8F3FF")

    // Backgrounds
    static let background          = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)

    // Text
    static let primaryText   = Color(.label)
    static let secondaryText = Color(.secondaryLabel)

    // Gradiente para cards de destaque
    static var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [blueDark, blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Hex initializer para Color

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
