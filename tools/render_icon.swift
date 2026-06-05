// render_icon.swift — generates the AgenticLex App Icon (1024x1024 PNG).
//
// Pure SwiftUI shapes (a simplified, static Lexi owl on a purple gradient),
// rendered offscreen with ImageRenderer. Run on macOS:
//
//   swift tools/render_icon.swift [output.png]
//
// Default output: ClaudeCodeLex/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
// The icon art here is intentionally a separate, simplified variant of
// Views/Components/LexiView.swift (a CLI script cannot import the app module).

import SwiftUI
import AppKit

extension Color {
    init(h: String) {
        var s = h; if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red:   Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue:  Double(v & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Classic SwiftUI heart shape (Lexi's belly emotion marker).
struct Heart: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w / 2, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h / 4),
                   control1: CGPoint(x: w / 2, y: h * 3 / 4),
                   control2: CGPoint(x: 0, y: h / 2))
        p.addArc(center: CGPoint(x: w / 4, y: h / 4), radius: w / 4,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: w * 3 / 4, y: h / 4), radius: w / 4,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: w / 2, y: h),
                   control1: CGPoint(x: w, y: h / 2),
                   control2: CGPoint(x: w / 2, y: h * 3 / 4))
        p.closeSubpath()
        return p
    }
}

/// Simplified, static Lexi owl-bot — sized to `s` (its bounding box).
struct OwlIcon: View {
    let s: CGFloat

    var body: some View {
        ZStack {
            // Wings (behind the body)
            HStack {
                wing(-14)
                Spacer()
                wing(14)
            }
            .frame(width: s * 0.88)
            .offset(y: s * 0.12)

            // Egg-shaped body
            Capsule()
                .fill(LinearGradient(colors: [Color(h: "A98FFF"), Color(h: "6E4BF5")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.78, height: s * 0.92)

            // Belly
            Ellipse()
                .fill(Color.white)
                .frame(width: s * 0.50, height: s * 0.56)
                .offset(y: s * 0.13)

            // Heart on belly
            Heart()
                .fill(Color(h: "FF9A3C"))
                .frame(width: s * 0.15, height: s * 0.14)
                .offset(y: s * 0.21)

            // Eyes
            HStack(spacing: s * 0.14) {
                eye()
                eye()
            }
            .offset(y: -s * 0.13)

            // Antenna
            VStack(spacing: 0) {
                Circle().fill(Color(h: "FFB84D"))
                    .frame(width: s * 0.11, height: s * 0.11)
                Rectangle().fill(Color(h: "4A28C8"))
                    .frame(width: s * 0.024, height: s * 0.11)
            }
            .offset(y: -s * 0.55)
        }
        .frame(width: s, height: s)
        .shadow(color: Color(h: "23105E").opacity(0.45), radius: s * 0.05, y: s * 0.03)
    }

    private func eye() -> some View {
        ZStack {
            Circle().fill(Color.white)
                .frame(width: s * 0.23, height: s * 0.23)
            Circle().fill(Color(h: "2D1B5C"))
                .frame(width: s * 0.125, height: s * 0.125)
            Circle().fill(Color.white)
                .frame(width: s * 0.05, height: s * 0.05)
                .offset(x: -s * 0.032, y: -s * 0.032)
        }
    }

    private func wing(_ angle: Double) -> some View {
        Capsule().fill(Color(h: "4A28C8"))
            .frame(width: s * 0.14, height: s * 0.34)
            .rotationEffect(.degrees(angle))
    }
}

/// The full 1024x1024 icon: deep-purple gradient + soft glow + Lexi.
struct IconView: View {
    let side: CGFloat = 1024

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(h: "8B6CF0"), Color(h: "3D1FA0")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(RadialGradient(colors: [Color.white.opacity(0.22), .clear],
                                     center: .center, startRadius: 0, endRadius: side * 0.45))

            OwlIcon(s: side * 0.62)
                .offset(y: side * 0.03)
        }
        .frame(width: side, height: side)
    }
}

// MARK: - Render

/// Drop the alpha channel — App Store icons must be fully opaque.
func flatten(_ cg: CGImage) -> CGImage {
    let ctx = CGContext(data: nil, width: cg.width, height: cg.height,
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    return ctx.makeImage() ?? cg
}

let defaultOut = "ClaudeCodeLex/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultOut

MainActor.assumeIsolated {
    let renderer = ImageRenderer(content: IconView())
    renderer.scale = 1.0
    guard let raw = renderer.cgImage else {
        FileHandle.standardError.write(Data("render failed\n".utf8)); exit(1)
    }
    let cg = flatten(raw)
    let rep = NSBitmapImageRep(cgImage: cg)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("png encode failed\n".utf8)); exit(1)
    }
    do {
        try data.write(to: URL(fileURLWithPath: outPath))
        print("wrote \(cg.width)x\(cg.height)px (opaque) -> \(outPath)")
    } catch {
        FileHandle.standardError.write(Data("write failed: \(error)\n".utf8)); exit(1)
    }
}
