// ShareCardView.swift
// A branded, shareable image card for a single term.
//
// Rendered offscreen via ImageRenderer (see `renderImage()`), never shown
// on screen directly. Styling is fixed light/brand — a shared image must
// look identical regardless of the sharer's appearance settings, so this
// view deliberately uses literal colors, not `Color.adaptive`.

import SwiftUI

struct ShareCardView: View {
    let term: Term
    let translation: LocalizedTranslation
    /// Pre-localized category display name.
    let category: String

    /// Fixed canvas — exported at `side` × `side` pixels.
    static let side: CGFloat = 1080

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "8B6CF0"), Color(hex: "3D1FA0")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Text(category.uppercased())
                    .font(.rounded(30, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.15), in: Capsule())
                    .padding(.top, 96)

                Spacer(minLength: 0)

                Text(term.english)
                    .font(.rounded(110, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .lineLimit(3)
                    .padding(.horizontal, 80)

                if let ipa = term.pronunciation, !ipa.isEmpty {
                    Text(ipa)
                        .font(.rounded(40))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 16)
                }

                Text(translation.term)
                    .font(.rounded(60, weight: .bold))
                    .foregroundColor(Color(hex: "FFD89E"))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(2)
                    .padding(.top, 36)
                    .padding(.horizontal, 80)

                Text(translation.definition)
                    .font(.rounded(36))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 28)
                    .padding(.horizontal, 96)

                Spacer(minLength: 0)

                HStack(spacing: 20) {
                    LexiView(pose: .cheer, size: 96, animated: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AgenticLex")
                            .font(.rounded(44, weight: .heavy))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("app.tagline", comment: ""))
                            .font(.rounded(28, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                .padding(.bottom, 90)
            }
        }
        .frame(width: Self.side, height: Self.side)
    }
}

#if canImport(UIKit)
import UIKit

extension ShareCardView {
    /// Renders the card to a UIImage at full `side` × `side` resolution.
    /// Must run on the main actor (ImageRenderer requirement).
    @MainActor
    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = 1.0          // view is already laid out at `side` pt
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
#endif
