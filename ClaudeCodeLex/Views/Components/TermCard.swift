// TermCard.swift
// Reusable card and row components for displaying a Term.

import SwiftUI

/// Small horizontal card used in Today's Picks.
struct TermCardMini: View {
    let term: Term
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategoryChip(
                label: termStore.main?.categories
                    .first(where: { $0.id == term.category })?
                    .name(for: settings.uiLanguage) ?? term.category,
                selected: false,
                action: {}
            )
            .allowsHitTesting(false)

            Text(term.english)
                .font(.rounded(18, weight: .bold))
                .lineLimit(2)

            Text(termStore.translation(for: term.id, locale: settings.nativeLanguage).term)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            HStack {
                Spacer()
                SpeakerButton(text: term.english, size: 28)
            }
        }
        .padding(16)
        .frame(width: 180, height: 160, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color.adaptive(light: "F6F4FF", dark: "2A2440"),
                         Color.adaptive(light: "ECE6FF", dark: "221C38")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Row used in Browse list.
struct TermRow: View {
    let term: Term
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            statusDot
            VStack(alignment: .leading, spacing: 2) {
                Text(term.english)
                    .font(.rounded(16, weight: .semibold))
                Text(termStore.translation(for: term.id, locale: settings.nativeLanguage).term)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            SpeakerButton(text: term.english, size: 28)
        }
        .padding(.vertical, 4)
    }

    private var statusDot: some View {
        let s = progress.record(for: term.id).status
        let color: Color = {
            switch s {
            case .new:       return Color(.systemGray4)
            case .learning:  return AppColor.brandPrimary
            case .reviewing: return AppColor.brandSecondary
            case .mastered:  return AppColor.leaf
            }
        }()
        return Circle().fill(color).frame(width: 8, height: 8)
    }
}
