// render_screenshots.swift — composites App Store marketing screenshots.
//
// Takes the 12 raw device screenshots from outputs/screenshots/raw/ (captured
// by tools/shoot_screenshots.sh) and places each on a branded purple gradient
// with its marketing tagline (per docs/APPSTORE_METADATA.md §截圖 Tagline),
// rendered offscreen with SwiftUI ImageRenderer. Run on macOS from repo root:
//
//   swift tools/render_screenshots.swift
//
// Output: outputs/screenshots/<set>/<screen>.png — 1320x2868, App Store 6.9".

import SwiftUI
import AppKit

// MARK: - Data

let screens = ["today", "detail", "quiz", "browse", "settings", "dark"]

let taglines: [String: [String: String]] = [
    "en": [
        "today":    "Learn AI coding, 5 min a day",
        "detail":   "Audio · Translation · Example",
        "quiz":     "Spaced repetition that sticks",
        "browse":   "60 terms, growing monthly",
        "settings": "6 languages, choose freely",
        "dark":     "Beautiful in Dark",
    ],
    "zh-TW": [
        "today":    "每天 5 分鐘，搞懂 AI 編程英文",
        "detail":   "發音 · 翻譯 · 實例",
        "quiz":     "間隔複習，學了不會忘",
        "browse":   "60 詞，每月持續新增",
        "settings": "6 語系隨你切換",
        "dark":     "深色模式同樣優雅",
    ],
]

// MARK: - Color hex

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

// MARK: - Layout

let canvasW: CGFloat = 1320
let canvasH: CGFloat = 2868

/// One marketing screenshot: branded gradient + headline + framed device shot.
struct MarketingShot: View {
    let screenshot: NSImage
    let tagline: String

    private let shotW: CGFloat = 1060
    private var shotH: CGFloat { shotW * canvasH / canvasW }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(h: "8B6CF0"), Color(h: "3D1FA0")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 70) {
                Text(tagline)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .frame(height: 300)
                    .padding(.horizontal, 90)

                Image(nsImage: screenshot)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: shotW, height: shotH)
                    .clipShape(RoundedRectangle(cornerRadius: 56))
                    .shadow(color: .black.opacity(0.35), radius: 40, y: 20)
            }
            .padding(.top, 90)
        }
        .frame(width: canvasW, height: canvasH)
    }
}

// MARK: - Render

/// Drop the alpha channel — keep the exported PNG fully opaque.
func flatten(_ cg: CGImage) -> CGImage {
    let ctx = CGContext(data: nil, width: cg.width, height: cg.height,
                        bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
    return ctx.makeImage() ?? cg
}

let fm = FileManager.default
let rawDir = "outputs/screenshots/raw"

MainActor.assumeIsolated {
    var count = 0
    for set in ["en", "zh-TW"] {
        let outDir = "outputs/screenshots/\(set)"
        try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)
        for screen in screens {
            let rawPath = "\(rawDir)/\(set)_\(screen).png"
            guard let img = NSImage(contentsOfFile: rawPath) else {
                FileHandle.standardError.write(Data("missing \(rawPath)\n".utf8))
                continue
            }
            let view = MarketingShot(screenshot: img,
                                     tagline: taglines[set]?[screen] ?? "")
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1.0
            guard let raw = renderer.cgImage else {
                FileHandle.standardError.write(Data("render failed \(set)/\(screen)\n".utf8))
                continue
            }
            let cg = flatten(raw)
            let rep = NSBitmapImageRep(cgImage: cg)
            guard let data = rep.representation(using: .png, properties: [:]) else {
                FileHandle.standardError.write(Data("png encode failed \(set)/\(screen)\n".utf8))
                continue
            }
            let outPath = "\(outDir)/\(screen).png"
            do {
                try data.write(to: URL(fileURLWithPath: outPath))
                count += 1
                print("  ✓ \(outPath)  \(cg.width)x\(cg.height)")
            } catch {
                FileHandle.standardError.write(Data("write failed \(outPath): \(error)\n".utf8))
            }
        }
    }
    print("rendered \(count) marketing screenshots")
}
