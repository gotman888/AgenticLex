// AppColor.swift
// Centralized design tokens.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppColor {
    /// Claude purple — Lexi 主色. Adaptive per DESIGN.md: a touch deeper in
    /// light, lighter in dark so it stays legible on the dark background.
    static let brandPrimary   = Color.adaptive(light: "7C5BFF", dark: "A48BFF")
    static let brandPrimaryD  = Color(hex: "5430E5")
    /// Streak / accent — 溫暖橙
    static let brandSecondary = Color(hex: "FF9A3C")
    /// Warm backgrounds (v0.3 friendly palette) — adaptive: warm cream in
    /// light, a near-black warm tint in dark.
    static let warmBg         = Color.adaptive(light: "FFFBF5", dark: "15131A")
    static let warmCard       = Color.adaptive(light: "FFF6E8", dark: "221E2A")
    /// Celebration color
    static let cheer          = Color(hex: "FFB84D")
    /// Wrong-answer color — 粉橘不是紅 (no anxiety)
    static let hug            = Color(hex: "FFA8A8")
    /// Mastered / success
    static let leaf           = Color(hex: "62C896")
}

/// Convenience: SF Pro Rounded font shortcuts so the whole app feels friendly.
extension Font {
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// Hex initialiser for SwiftUI Color
extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let r, g, b: UInt64
        switch s.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue:  Double(b) / 255.0,
            opacity: 1.0
        )
    }

    /// A color that resolves to `light` or `dark` (hex strings) depending on
    /// the interface style — keeps light/dark design tokens in one place.
    static func adaptive(light: String, dark: String) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
        #else
        return Color(hex: light)
        #endif
    }
}
