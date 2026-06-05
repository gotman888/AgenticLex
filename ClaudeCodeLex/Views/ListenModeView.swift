// ListenModeView.swift
// Pure-audio "podcast mode" for the user's due-review terms.
//
// Plays en → 0.5s gap → native → 1s gap → next term.
// Works in background. Lock screen shows the term.
//
// Why this matters: 王宏盟 self-described as a strong auditory learner.
// This screen is the heart of the friendly experience for him.

import SwiftUI

struct ListenModeView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings
    @StateObject private var speech = SpeechService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var queueTerms: [Term] = []

    var body: some View {
        VStack(spacing: 32) {
            // Lexi listens with you
            LexiView(pose: speech.listenModeActive ? .read : .sleepy, size: 140)
                .padding(.top, 24)

            VStack(spacing: 6) {
                Text("listen.title")
                    .font(.rounded(28, weight: .bold))
                if speech.listenModeActive {
                    Text(speech.currentItemText)
                        .font(.rounded(36, weight: .bold))
                        .foregroundStyle(AppColor.brandPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                } else {
                    Text("listen.subtitle")
                        .font(.rounded(15))
                        .foregroundStyle(.secondary)
                }
            }

            if speech.listenModeActive {
                progressBar
            }

            speedSection

            Spacer()

            primaryButton

            Text("listen.hint")
                .font(.rounded(12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle("listen.tab")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prepareQueue() }
        .onDisappear { speech.stop() }
    }

    // MARK: - Sub views

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(
                value: Double(speech.listenIndex),
                total: Double(max(speech.listenTotal, 1))
            )
            .tint(AppColor.brandPrimary)
            Text("\(speech.listenIndex) / \(speech.listenTotal)")
                .font(.rounded(12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 40)
    }

    private var speedSection: some View {
        VStack(spacing: 8) {
            Text("audio.speed.label")
                .font(.rounded(12, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(SpeedTier.allCases) { tier in
                    Button {
                        speech.speedTier = tier
                    } label: {
                        VStack(spacing: 4) {
                            Text(tier.emoji).font(.rounded(24))
                            Text(LocalizedStringKey("audio.speed.\(tier.rawValue)"))
                                .font(.rounded(11, weight: .medium))
                        }
                        .frame(width: 72, height: 72)
                        .background(
                            speech.speedTier == tier
                                ? AppColor.brandPrimary.opacity(0.15)
                                : AppColor.warmCard
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    speech.speedTier == tier
                                        ? AppColor.brandPrimary
                                        : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private var primaryButton: some View {
        Button {
            if speech.listenModeActive {
                speech.stop()
            } else {
                startListening()
            }
        } label: {
            HStack {
                Image(systemName: speech.listenModeActive ? "stop.fill" : "play.fill")
                Text(speech.listenModeActive ? "listen.stop" : "listen.start")
                    .font(.rounded(17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColor.brandPrimary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(color: AppColor.brandPrimary.opacity(0.3), radius: 12, y: 6)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Logic

    private func prepareQueue() {
        // Default queue: today's due-review terms, then sprinkle some new ones.
        let due = termStore.allTerms.filter {
            let r = progress.record(for: $0.id)
            return r.status != .mastered
        }
        queueTerms = Array(due.prefix(10))
        if queueTerms.isEmpty {
            queueTerms = Array(termStore.allTerms.shuffled().prefix(10))
        }
    }

    private func startListening() {
        let locale = settings.nativeLanguage
        var items: [SpokenItem] = []
        for t in queueTerms {
            let tr = termStore.translation(for: t.id, locale: locale)
            // 1. English term (uses current speed tier)
            items.append(SpokenItem(text: t.english, language: "en-US",
                                    termId: t.id, postDelay: 0.5))
            // 2. Native translation if available — helps audio-only learning
            if tr.status != .missing {
                items.append(SpokenItem(text: tr.term, language: locale,
                                        termId: t.id, postDelay: 1.0))
            }
        }
        speech.startListenMode(items)
    }
}
