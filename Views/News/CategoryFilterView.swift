//
//  CategoryFilterView.swift
//  Tecnoblog
//
//  Created by LUIZ PASSARONI on 25/03/26.
//  Copyright © 2026 Globo Comunicação e Participações S.A.  All rights reserved.
//

import SwiftUI

struct CategoryFilterView: View {
    let selected: TBCategory
    let onSelect: (TBCategory) -> Void

    var body: some View {
        // As categorias foram removidas conforme solicitado.
        // Mantemos a View como EmptyView para não quebrar a compilação onde ela é utilizada.
        EmptyView()
    }
}

// Mantemos a struct auxiliar caso decida voltar com a feature no futuro,
// mas ela não é renderizada.
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? TBTheme.accent : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
