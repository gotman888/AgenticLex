// LexiView.swift
// Lexi — purple owl-bot mascot.
// Pure SwiftUI shapes (no images), scales freely, works in Light/Dark.
//
// Usage:
//   LexiView(pose: .wave, size: 120)
//   LexiView(pose: .cheer)
//
// 6 poses cover most app moments: wave (onboarding), read (default),
// hug (wrong answer), cheer (celebrate), wizard (random word), sleepy (empty).

import SwiftUI

enum LexiPose {
    case wave    // 👋 onboarding greeting
    case read    // 📖 default / today
    case hug     // 🫂 wrong answer comfort
    case cheer   // 🎉 celebration
    case wizard  // 🎩 random word picker
    case sleepy  // 😴 empty state / all done
}

struct LexiView: View {
    var pose: LexiPose = .read
    var size: CGFloat = 100
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var blink: Bool = false
    @State private var bob: Bool = false

    // Motion is enabled only when requested AND the system isn't in Reduce Motion.
    private var motionEnabled: Bool { animated && !reduceMotion }

    var body: some View {
        ZStack {
            // Backdrop glow for celebration poses
            if pose == .cheer {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColor.cheer.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.7
                        )
                    )
                    .frame(width: size * 1.4, height: size * 1.4)
            }

            ZStack {
                body_main
                eyes
                arms
                accessory
            }
            .frame(width: size, height: size)
            .offset(y: bob ? -4 : 0)
            .animation(
                motionEnabled
                    ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                    : .default,
                value: bob
            )
        }
        .onAppear {
            // Reduce Motion: stay grounded (no bob) and don't blink.
            if motionEnabled {
                bob = true
                startBlinking()
            }
        }
        .accessibilityHidden(true)   // decorative mascot — keep its sub-shapes out of the VoiceOver tree
    }

    // MARK: - Body parts

    private var body_main: some View {
        ZStack {
            // Outer body (egg shape)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [AppColor.brandPrimary, AppColor.brandPrimaryD],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.78, height: size * 0.92)

            // Belly (lighter oval)
            Ellipse()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.5, height: size * 0.55)
                .offset(y: size * 0.12)

            // Little heart on belly (emotion indicator)
            heartIcon
                .offset(y: size * 0.22)
        }
    }

    private var heartIcon: some View {
        let color: Color = {
            switch pose {
            case .cheer:  return AppColor.cheer
            case .hug:    return AppColor.hug
            case .wizard: return AppColor.brandPrimary
            default:      return AppColor.brandSecondary
            }
        }()
        return Image(systemName: "heart.fill")
            .font(.system(size: size * 0.10))
            .foregroundStyle(color)
    }

    private var eyes: some View {
        HStack(spacing: size * 0.16) {
            eye(side: -1)
            eye(side: 1)
        }
        .offset(y: -size * 0.12)
    }

    private func eye(side: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.18, height: size * 0.18)
            // Pupil — closes on blink, looks sideways for wizard
            Capsule()
                .fill(Color(hex: "2D1B5C"))
                .frame(
                    width: blink ? size * 0.14 : size * 0.10,
                    height: blink ? size * 0.02 : size * 0.10
                )
                .offset(x: pose == .wizard ? side * size * 0.02 : 0,
                        y: pose == .sleepy ? size * 0.02 : 0)
            // Sparkle highlight
            if pose != .sleepy && !blink {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.03, height: size * 0.03)
                    .offset(x: -size * 0.02, y: -size * 0.02)
            }
        }
    }

    @ViewBuilder
    private var arms: some View {
        switch pose {
        case .wave:
            HStack {
                wing(angle: -40, leftSide: true)
                Spacer()
                wing(angle: -20, leftSide: false)
            }
            .frame(width: size * 0.95)
            .offset(y: size * 0.05)
        case .cheer:
            HStack {
                wing(angle: -55, leftSide: true)
                Spacer()
                wing(angle: 55, leftSide: false)
            }
            .frame(width: size * 1.0)
            .offset(y: -size * 0.05)
        case .hug:
            HStack {
                wing(angle: 30, leftSide: true)
                Spacer()
                wing(angle: -30, leftSide: false)
            }
            .frame(width: size * 0.6)
            .offset(y: size * 0.15)
        case .wizard:
            HStack {
                wing(angle: 20, leftSide: true)
                Spacer()
                wing(angle: -45, leftSide: false)
            }
            .frame(width: size * 0.85)
            .offset(y: size * 0.05)
        case .read, .sleepy:
            HStack {
                wing(angle: 5, leftSide: true)
                Spacer()
                wing(angle: -5, leftSide: false)
            }
            .frame(width: size * 0.85)
            .offset(y: size * 0.1)
        }
    }

    private func wing(angle: Double, leftSide: Bool) -> some View {
        Capsule()
            .fill(AppColor.brandPrimaryD.opacity(0.9))
            .frame(width: size * 0.12, height: size * 0.28)
            .rotationEffect(.degrees(leftSide ? angle : -angle))
    }

    @ViewBuilder
    private var accessory: some View {
        switch pose {
        case .wizard:
            // Wizard hat
            ZStack {
                Triangle()
                    .fill(AppColor.brandPrimaryD)
                    .frame(width: size * 0.32, height: size * 0.34)
                Circle()
                    .fill(AppColor.cheer)
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(y: -size * 0.13)
            }
            .offset(y: -size * 0.45)
        case .sleepy:
            // Sleep "z"
            Text("zZ")
                .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.brandPrimary.opacity(0.6))
                .offset(x: size * 0.30, y: -size * 0.35)
        case .read:
            // Tiny book at bottom
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColor.cheer)
                .frame(width: size * 0.30, height: size * 0.10)
                .overlay(
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: size * 0.08)
                )
                .offset(y: size * 0.42)
        case .cheer:
            // Confetti dots
            ForEach(0..<6) { i in
                Circle()
                    .fill([AppColor.cheer, AppColor.brandPrimary, AppColor.leaf, AppColor.hug].randomElement()!)
                    .frame(width: size * 0.04, height: size * 0.04)
                    .offset(
                        x: cos(Double(i) * .pi / 3) * size * 0.55,
                        y: sin(Double(i) * .pi / 3) * size * 0.55
                    )
            }
        default:
            EmptyView()
        }

        // Antenna (always present — mark as robot/owl)
        Circle()
            .fill(AppColor.cheer)
            .frame(width: size * 0.08, height: size * 0.08)
            .overlay(
                Rectangle()
                    .fill(AppColor.brandPrimaryD)
                    .frame(width: 2, height: size * 0.08)
                    .offset(y: size * 0.06)
            )
            .offset(y: -size * 0.50)
    }

    // MARK: - Blink

    private func startBlinking() {
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 2_500_000_000...5_500_000_000))
                withAnimation(.easeInOut(duration: 0.12)) { blink = true }
                try? await Task.sleep(nanoseconds: 150_000_000)
                withAnimation(.easeInOut(duration: 0.12)) { blink = false }
            }
        }
    }
}

// Helper triangle shape (for wizard hat)
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            LexiView(pose: .wave, size: 90)
            LexiView(pose: .read, size: 90)
            LexiView(pose: .hug, size: 90)
        }
        HStack(spacing: 16) {
            LexiView(pose: .cheer, size: 90)
            LexiView(pose: .wizard, size: 90)
            LexiView(pose: .sleepy, size: 90)
        }
    }
    .padding()
    .background(AppColor.warmBg)
}
