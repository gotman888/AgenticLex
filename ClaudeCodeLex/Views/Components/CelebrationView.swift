// CelebrationView.swift
// A short, joyful overlay that bursts confetti + a Lexi cheer when the user
// completes a meaningful action (mastered a word, streak +1, achievement).

import SwiftUI

struct CelebrationOverlay: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let pose: LexiPose
    var onDismiss: () -> Void = {}

    @State private var visible: Bool = false
    @State private var confettiSeed: Int = Int.random(in: 0..<999_999)

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(visible ? 0.35 : 0)
                .ignoresSafeArea()
                .onTapGesture { close() }

            // Confetti
            ConfettiBurst(seed: confettiSeed)
                .allowsHitTesting(false)
                .opacity(visible ? 1 : 0)

            // Card
            VStack(spacing: 16) {
                LexiView(pose: pose, size: 130)
                Text(title)
                    .font(.rounded(28, weight: .bold))
                    .multilineTextAlignment(.center)
                if let subtitle {
                    Text(subtitle)
                        .font(.rounded(15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button("celebration.cool") { close() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.brandPrimary)
                    .controlSize(.large)
                    .padding(.top, 6)
            }
            .padding(28)
            .background(AppColor.warmCard)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
            .scaleEffect(visible ? 1.0 : 0.7)
            .opacity(visible ? 1 : 0)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                visible = true
            }
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.2)) { visible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
    }
}

// MARK: - Confetti

struct ConfettiBurst: View {
    let seed: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate: Bool = false

    var body: some View {
        GeometryReader { geo in
            // Reduce Motion: skip the falling burst — pieces stay scattered in
            // place and the whole layer simply fades in (handled by the parent's
            // .opacity on this view).
            if reduceMotion {
                ForEach(0..<40, id: \.self) { i in
                    ConfettiPiece(
                        color: confettiColors[i % confettiColors.count],
                        delay: Double(i) * 0.015,
                        seed: seed &+ i,
                        reduceMotion: true
                    )
                    .frame(width: 8, height: 12)
                    .position(
                        x: geo.size.width / 2 + randomOffset(i, range: geo.size.width * 0.55),
                        y: geo.size.height * 0.35
                    )
                }
            } else {
                ForEach(0..<40, id: \.self) { i in
                    ConfettiPiece(
                        color: confettiColors[i % confettiColors.count],
                        delay: Double(i) * 0.015,
                        seed: seed &+ i,
                        reduceMotion: false
                    )
                    .frame(width: 8, height: 12)
                    .position(
                        x: geo.size.width / 2 + (animate ? randomOffset(i, range: geo.size.width * 0.55) : 0),
                        y: animate ? geo.size.height + 50 : geo.size.height * 0.35
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 1.6).delay(Double(i) * 0.012),
                        value: animate
                    )
                }
            }
        }
        .onAppear {
            if !reduceMotion { animate = true }
        }
    }

    private var confettiColors: [Color] {
        [AppColor.cheer, AppColor.brandPrimary, AppColor.leaf,
         AppColor.hug, AppColor.brandSecondary]
    }

    private func randomOffset(_ i: Int, range: CGFloat) -> CGFloat {
        // Deterministic-ish jitter per piece
        let s = (seed &+ i).hashValue
        let normalized = CGFloat((s % 1000)) / 1000.0
        return (normalized - 0.5) * range * 2
    }
}

struct ConfettiPiece: View {
    let color: Color
    let delay: Double
    let seed: Int
    var reduceMotion: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(color)
            .rotationEffect(.degrees(reduceMotion ? staticRotation : rotation))
            .onAppear {
                // Reduce Motion: no spin — render at a fixed resting angle.
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.6).delay(delay)) {
                    rotation = Double(seed % 720) - 360
                }
            }
    }

    // A fixed, varied tilt per piece so the scattered fade-in still looks lively.
    private var staticRotation: Double {
        Double(seed % 90) - 45
    }
}

// MARK: - Quick confetti (non-modal, single-answer feedback)

/// A lightweight, non-modal confetti puff for in-place feedback (e.g. a
/// correct quiz answer). Unlike `CelebrationOverlay` it has no backdrop, no
/// card and no dismiss button — it bursts for ~0.5s and fades itself out.
/// Place it inside a `ZStack` with `.allowsHitTesting(false)` so it never
/// blocks interaction.
struct QuickConfetti: View {
    /// Changing this value re-triggers the burst.
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired: Bool = false
    @State private var visible: Bool = false

    private let pieceCount = 18

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieceCount, id: \.self) { i in
                    ConfettiPiece(
                        color: confettiColors[i % confettiColors.count],
                        delay: Double(i) * 0.01,
                        seed: trigger &* 31 &+ i,
                        reduceMotion: reduceMotion
                    )
                    .frame(width: 8, height: 11)
                    .position(
                        x: geo.size.width / 2
                            + ((reduceMotion || fired)
                               ? offset(i, range: geo.size.width * 0.42)
                               : 0),
                        y: reduceMotion
                            ? geo.size.height * 0.42
                            : (fired ? geo.size.height * 0.72 : geo.size.height * 0.42)
                    )
                }
            }
            .opacity(visible ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _ in run() }
        .onAppear { if trigger != 0 { run() } }
    }

    private func run() {
        // Reset, then burst.
        fired = false
        withAnimation(.easeIn(duration: 0.08)) { visible = true }
        if reduceMotion {
            // Reduce Motion: no scatter travel — just fade in then out.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) { visible = false }
            }
        } else {
            withAnimation(.easeOut(duration: 0.5)) { fired = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.2)) { visible = false }
            }
        }
    }

    private var confettiColors: [Color] {
        [AppColor.cheer, AppColor.brandPrimary, AppColor.leaf,
         AppColor.hug, AppColor.brandSecondary]
    }

    private func offset(_ i: Int, range: CGFloat) -> CGFloat {
        let s = (trigger &* 31 &+ i).hashValue
        let normalized = CGFloat(s % 1000) / 1000.0
        return (normalized - 0.5) * range * 2
    }
}

// MARK: - Convenience modifier

extension View {
    func celebrate(_ celebration: Binding<Celebration?>) -> some View {
        ZStack {
            self
            if let c = celebration.wrappedValue {
                CelebrationOverlay(
                    title: c.title,
                    subtitle: c.subtitle,
                    pose: c.pose,
                    onDismiss: { celebration.wrappedValue = nil }
                )
                .transition(.opacity)
            }
        }
    }
}

struct Celebration: Equatable {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let pose: LexiPose

    static func == (lhs: Celebration, rhs: Celebration) -> Bool {
        // LocalizedStringKey isn't directly comparable; we just compare identity.
        false
    }
}
