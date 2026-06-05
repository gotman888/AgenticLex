// QuizView.swift
// Quiz setup + card + result.

import SwiftUI

enum QuizDirection: String, CaseIterable, Identifiable {
    case enToL1   // show English, pick translation
    case l1ToEn   // show translation, pick English
    case mixed
    var id: String { rawValue }

    var localizationKey: LocalizedStringKey {
        switch self {
        case .enToL1: return "quiz.dir.enToL1"
        case .l1ToEn: return "quiz.dir.l1ToEn"
        case .mixed:  return "quiz.dir.mixed"
        }
    }
}

struct QuizSetupView: View {
    @EnvironmentObject var termStore: TermStore

    @State private var count: Int = 5
    // Default reversed: 母語 → 英文 才是真正在學英文 (per OPTIMIZATION B4)
    @State private var direction: QuizDirection = .l1ToEn
    @State private var startQuiz = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("quiz.setup.count")) {
                    Picker("", selection: $count) {
                        ForEach([5, 10, 20], id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("quiz.setup.direction")) {
                    Picker("", selection: $direction) {
                        ForEach(QuizDirection.allCases) { d in
                            Text(d.localizationKey).tag(d)
                        }
                    }
                }
                Section {
                    Button {
                        startQuiz = true
                    } label: {
                        Text("quiz.setup.start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColor.brandPrimary)
                }
            }
            .navigationTitle("quiz.tab")
            .navigationDestination(isPresented: $startQuiz) {
                QuizCardView(
                    terms: Array(termStore.allTerms.shuffled().prefix(count)),
                    direction: direction
                )
            }
        }
    }
}

struct QuizCardView: View {
    let terms: [Term]
    let direction: QuizDirection

    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings
    @StateObject private var speech = SpeechService.shared

    @State private var currentIndex: Int = 0
    @State private var selectedAnswer: String? = nil
    @State private var correctCount: Int = 0
    @State private var done: Bool = false

    // Per-answer feedback: confetti burst counter (correct) + hug flag (wrong).
    @State private var confettiTrigger: Int = 0
    @State private var showHug: Bool = false

    var body: some View {
        if done {
            QuizResultView(score: correctCount, total: terms.count)
        } else {
            ZStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(currentIndex), total: Double(terms.count))
                    .tint(AppColor.brandPrimary)
                Text("\(currentIndex + 1) / \(terms.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                let term = terms[currentIndex]
                let mode = effectiveDirection(for: currentIndex)
                let question = mode == .enToL1
                    ? term.english
                    : termStore.translation(for: term.id, locale: settings.nativeLanguage).term

                Text(question)
                    .font(.rounded(36, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if mode == .enToL1 {
                    SpeakerButton(text: term.english, size: 48)
                        .onAppear { speech.speak(term.english) }
                }

                Spacer()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(options(for: term, mode: mode), id: \.self) { opt in
                        Button {
                            handle(answer: opt, term: term, mode: mode)
                        } label: {
                            Text(opt)
                                .font(.body)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .padding(8)
                                .background(answerBg(opt, term: term, mode: mode))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(answerBorder(opt, term: term, mode: mode), lineWidth: 2)
                                )
                                .foregroundStyle(.primary)
                        }
                        .disabled(selectedAnswer != nil)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationTitle("quiz.tab")
            .navigationBarTitleDisplayMode(.inline)
            .padding()

            // Correct: short, non-modal confetti puff (~0.5s, self-fading).
            QuickConfetti(trigger: confettiTrigger)

            // Wrong: Lexi appears with a gentle hug pose for ~1s, no red.
            if showHug {
                LexiView(pose: .hug, size: 120)
                    .padding(20)
                    .background(AppColor.hug.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
            }
        }
    }

    // MARK: - Logic

    private func effectiveDirection(for idx: Int) -> QuizDirection {
        switch direction {
        case .enToL1: return .enToL1
        case .l1ToEn: return .l1ToEn
        case .mixed:  return idx.isMultiple(of: 2) ? .enToL1 : .l1ToEn
        }
    }

    private func options(for term: Term, mode: QuizDirection) -> [String] {
        let locale = settings.nativeLanguage
        let correct = mode == .enToL1
            ? termStore.translation(for: term.id, locale: locale).term
            : term.english

        // distractors from same category if possible
        let pool = termStore.terms(in: term.category).filter { $0.id != term.id }
        let distractors = pool.shuffled().prefix(3).map {
            mode == .enToL1
                ? termStore.translation(for: $0.id, locale: locale).term
                : $0.english
        }
        var all = [correct] + distractors
        // pad if pool too small
        while all.count < 4 {
            if let extra = termStore.allTerms.randomElement() {
                let candidate = mode == .enToL1
                    ? termStore.translation(for: extra.id, locale: locale).term
                    : extra.english
                if !all.contains(candidate) { all.append(candidate) }
            }
        }
        return all.shuffled()
    }

    private func handle(answer: String, term: Term, mode: QuizDirection) {
        withAnimation(.easeOut(duration: 0.2)) { selectedAnswer = answer }
        let correct = mode == .enToL1
            ? termStore.translation(for: term.id, locale: settings.nativeLanguage).term
            : term.english
        let isCorrect = (answer == correct)
        progress.mark(termId: term.id, correct: isCorrect)
        if isCorrect {
            correctCount += 1
            confettiTrigger += 1
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
            withAnimation(.easeOut(duration: 0.25)) { showHug = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeIn(duration: 0.25)) { showHug = false }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            advance()
        }
    }

    private func advance() {
        selectedAnswer = nil
        showHug = false
        if currentIndex < terms.count - 1 {
            currentIndex += 1
        } else {
            done = true
        }
    }

    private func answerBg(_ opt: String, term: Term, mode: QuizDirection) -> Color {
        guard let sel = selectedAnswer else { return Color(.systemBackground) }
        let correct = mode == .enToL1
            ? termStore.translation(for: term.id, locale: settings.nativeLanguage).term
            : term.english
        if opt == correct { return AppColor.leaf.opacity(0.15) }
        if opt == sel    { return AppColor.hug.opacity(0.12) }
        return Color(.systemBackground)
    }

    private func answerBorder(_ opt: String, term: Term, mode: QuizDirection) -> Color {
        guard let sel = selectedAnswer else { return Color(.systemGray4) }
        let correct = mode == .enToL1
            ? termStore.translation(for: term.id, locale: settings.nativeLanguage).term
            : term.english
        if opt == correct { return AppColor.leaf }
        if opt == sel    { return AppColor.hug }
        return Color(.systemGray4)
    }
}

struct QuizResultView: View {
    let score: Int
    let total: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings

    private var pose: LexiPose {
        if score == total { return .cheer }
        if score >= total / 2 { return .read }
        return .hug
    }

    private var titleKey: LocalizedStringKey {
        if score == total { return "quiz.result.perfect" }
        if score >= max(1, total / 2) { return "quiz.result.good" }
        return "quiz.result.tryAgain"
    }

    var body: some View {
        ZStack {
            AppColor.warmBg.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                LexiView(pose: pose, size: 140)
                Text("\(score) / \(total)")
                    .font(.rounded(56, weight: .bold))
                    .foregroundStyle(score == total ? AppColor.leaf : .primary)
                Text(titleKey)
                    .font(.rounded(18, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("quiz.result.backHome")
                        .font(.rounded(17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.brandPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            // High point: ask for an App Store review if the user is engaged
            // (gated + at most once per version inside ReviewPrompter).
            if ReviewPrompter.shouldAsk(streakDays: progress.streakDays,
                                        masteredCount: progress.masteredCount,
                                        settings: settings) {
                requestReview()
            }
        }
    }
}
