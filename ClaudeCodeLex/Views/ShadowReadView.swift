// ShadowReadView.swift
// Shadow Read — a multi-term pronunciation practice session. For each term:
// hear the model, say it back, get friendly feedback. Speech is recognized
// on-device (see SpeechRecognizer); nothing leaves the phone. Scoring is
// lenient and encouraging — a miss still gets a warm nudge, never red.

import SwiftUI

struct ShadowReadView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speech = SpeechService.shared
    @StateObject private var recognizer = SpeechRecognizer()

    private enum Stage { case intro, practice, summary }
    private enum Phase { case ready, recording, scored }

    private struct Score {
        enum Grade { case great, close, tryAgain }
        let grade: Grade
        let heard: String
    }

    @State private var stage: Stage = .intro
    @State private var phase: Phase = .ready
    @State private var queue: [Term] = []
    @State private var index = 0
    @State private var score: Score?
    @State private var scores: [Score] = []

    var body: some View {
        Group {
            switch stage {
            case .intro:    introView
            case .practice: practiceView
            case .summary:  summaryView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle("today.shadow")
        .navigationBarTitleDisplayMode(.inline)
        .task { await recognizer.requestPermission() }
        .onAppear { recognizer.beginSession() }
        .onDisappear {
            recognizer.endSession()
            speech.stop()
        }
        .onChange(of: recognizer.isRecording) { recording in
            if !recording && phase == .recording { scoreCurrent() }
        }
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 20) {
            Spacer()
            LexiView(pose: recognizer.unavailable ? .sleepy : .wave, size: 130)
            Text(recognizer.unavailable ? "shadow.unavailable" : "shadow.intro")
                .font(.rounded(16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
            if !recognizer.unavailable {
                Button { startSession() } label: {
                    primaryLabel("shadow.start", systemImage: "mic.fill")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Practice

    private var practiceView: some View {
        let term = queue[index]
        return VStack(spacing: 0) {
            Text("\(index + 1) / \(queue.count)")
                .font(.rounded(13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
            ProgressView(value: Double(index), total: Double(queue.count))
                .tint(AppColor.brandPrimary)
                .padding(.horizontal, 44)
                .padding(.top, 4)

            Spacer()

            LexiView(pose: lexiPose, size: 104)

            Text(term.english)
                .font(.rounded(40, weight: .heavy))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            if let ipa = term.pronunciation {
                Text(ipa)
                    .font(.rounded(17))
                    .foregroundStyle(.secondary)
            }

            Button { playModel() } label: {
                Label("shadow.replay", systemImage: "speaker.wave.2.fill")
                    .font(.rounded(14, weight: .medium))
                    .foregroundStyle(AppColor.brandPrimary)
            }
            .padding(.top, 12)

            Spacer()

            if phase == .scored, let score {
                resultBlock(score)
            }
            controlArea
                .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var controlArea: some View {
        switch phase {
        case .ready, .recording:
            VStack(spacing: 8) {
                Button { toggleRecording() } label: { micButton }
                    .disabled(recognizer.unavailable)
                Text(phase == .recording ? "shadow.listening" : "shadow.tapToSpeak")
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
            }
        case .scored:
            Button { advance() } label: {
                primaryLabel(isLastTerm ? "shadow.finish" : "review.next",
                             systemImage: isLastTerm ? "checkmark" : "arrow.right")
            }
            .padding(.horizontal, 32)
        }
    }

    private var micButton: some View {
        let tint = phase == .recording ? AppColor.hug : AppColor.brandPrimary
        return ZStack {
            Circle()
                .fill(tint)
                .frame(width: 84, height: 84)
                .shadow(color: tint.opacity(0.4), radius: 12, y: 6)
            Image(systemName: phase == .recording ? "stop.fill" : "mic.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func resultBlock(_ score: Score) -> some View {
        VStack(spacing: 6) {
            Text(resultMessageKey(score.grade))
                .font(.rounded(18, weight: .bold))
                .foregroundStyle(resultColor(score.grade))
            if !score.heard.isEmpty {
                Text(String(format: NSLocalizedString("shadow.heardFmt", comment: ""),
                            score.heard))
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 14)
        .padding(.horizontal, 24)
    }

    // MARK: - Summary

    private var summaryView: some View {
        VStack(spacing: 16) {
            Spacer()
            LexiView(pose: .cheer, size: 140)
            Text(String(format: NSLocalizedString("shadow.summaryFmt", comment: ""),
                        scores.count))
                .font(.rounded(22, weight: .bold))
                .multilineTextAlignment(.center)
            Text(String(format: NSLocalizedString("shadow.summaryGreatFmt", comment: ""),
                        scores.filter { $0.grade == .great }.count))
                .font(.rounded(15))
                .foregroundStyle(.secondary)
            Spacer()
            Button { startSession() } label: {
                primaryLabel("shadow.again", systemImage: "arrow.clockwise")
            }
            .padding(.horizontal, 32)
            Button { dismiss() } label: {
                Text("shadow.finish")
                    .font(.rounded(15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Shared bits

    private func primaryLabel(_ key: LocalizedStringKey,
                              systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(key).font(.rounded(16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(AppColor.brandPrimary)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private var lexiPose: LexiPose {
        if phase == .scored, let score {
            switch score.grade {
            case .great:    return .cheer
            case .close:    return .read
            case .tryAgain: return .hug
            }
        }
        return phase == .recording ? .read : .wave
    }

    private func resultMessageKey(_ g: Score.Grade) -> LocalizedStringKey {
        switch g {
        case .great:    return "shadow.great"
        case .close:    return "shadow.close"
        case .tryAgain: return "shadow.tryAgain"
        }
    }

    private func resultColor(_ g: Score.Grade) -> Color {
        switch g {
        case .great:    return AppColor.leaf
        case .close:    return AppColor.brandPrimary
        case .tryAgain: return AppColor.brandSecondary   // warm orange — never red
        }
    }

    private var isLastTerm: Bool { index >= queue.count - 1 }

    // MARK: - Session logic

    private func startSession() {
        let built = buildQueue()
        guard !built.isEmpty else { return }
        queue = built
        index = 0
        scores = []
        stage = .practice
        loadTerm()
    }

    /// Due-review terms first; fall back to a shuffled sample. Capped at 10.
    private func buildQueue() -> [Term] {
        let due = termStore.allTerms.filter {
            progress.record(for: $0.id).status != .mastered
        }
        let pool = due.isEmpty ? termStore.allTerms.shuffled() : due
        return Array(pool.prefix(10))
    }

    private func loadTerm() {
        score = nil
        phase = .ready
        playModel()
    }

    private func playModel() {
        guard index < queue.count else { return }
        speech.speak(queue[index].english)
    }

    private func toggleRecording() {
        switch phase {
        case .ready:
            speech.stop()                    // silence the model before recording
            recognizer.startRecording()
            if recognizer.isRecording { phase = .recording }
        case .recording:
            recognizer.stopRecording()       // scoreCurrent() runs via onChange
        case .scored:
            break
        }
    }

    private func scoreCurrent() {
        let target = normalized(queue[index].english)
        let said = normalized(recognizer.transcript)
        let grade: Score.Grade
        if !said.isEmpty && said == target {
            grade = .great
        } else if !said.isEmpty &&
                  (said.contains(target) || target.contains(said)
                   || levenshtein(said, target) <= 2) {
            grade = .close
        } else {
            grade = .tryAgain
        }
        #if canImport(UIKit)
        switch grade {
        case .great:    UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .close:    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .tryAgain: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
        let s = Score(grade: grade, heard: recognizer.transcript)
        score = s
        scores.append(s)
        phase = .scored
    }

    private func advance() {
        if isLastTerm {
            stage = .summary
        } else {
            index += 1
            loadTerm()
        }
    }

    /// Lowercased, alphanumerics only — so "M C P" / "sub-agent" still match.
    private func normalized(_ s: String) -> String {
        String(String.UnicodeScalarView(
            s.lowercased().unicodeScalars.filter(CharacterSet.alphanumerics.contains)
        ))
    }

    private func levenshtein(_ a: String, _ b: String) -> Int {
        let s = Array(a), t = Array(b)
        if s.isEmpty { return t.count }
        if t.isEmpty { return s.count }
        var prev = Array(0...t.count)
        var curr = [Int](repeating: 0, count: t.count + 1)
        for i in 1...s.count {
            curr[0] = i
            for j in 1...t.count {
                let cost = s[i - 1] == t[j - 1] ? 0 : 1
                curr[j] = min(prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost)
            }
            swap(&prev, &curr)
        }
        return prev[t.count]
    }
}
