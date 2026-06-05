// Block.swift
// Reusable section block with a label header.

import SwiftUI

struct Block<Content: View>: View {
    let label: String
    var tint: Color = Color(.secondarySystemBackground)
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SectionTitle: View {
    let titleKey: LocalizedStringKey
    init(_ key: LocalizedStringKey) { self.titleKey = key }

    var body: some View {
        Text(titleKey)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
