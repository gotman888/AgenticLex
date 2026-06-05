// TodayView.swift  (v0.3 — friendly + WOTD + Listen Mode)
// Home tab. Now feels like an invitation, not a checklist.

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: AppRouter

    @State private var randomTerm: Term?
    @State private var celebration: Celebration?

    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            .background(AppColor.warmBg.ignoresSafeArea())
            .navigationTitle("app.name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Term.self) { term in
                TermDetailView(term: term)
            }
            .navigationDestination(isPresented: Binding(
                get: { router.pendingDeepLink == .listenMode },
                set: { if !$0 { router.pendingDeepLink = nil } }
            )) {
                ListenModeView()
            }
        }
        .celebrate($celebration)
    }

    /// Main scroll content — computes `pickedTerms` ONCE per body pass and threads
    /// it into the picks row + action buttons (previously recomputed ~5× per pass).
    private var content: some View {
        let picks = pickedTerms
        return VStack(alignment: .leading, spacing: 24) {
            header

            if let wotd = wordOfTheDay {
                wotdCard(wotd)
            }

            SectionTitle("today.picks")
            todaysPicks(picks)

            actionButtons(picks)

            SectionTitle("today.recentMastered")
            recentMastered
        }
        .padding(20)
    }

    // MARK: - Header (Lexi + greeting + streak)

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            LexiView(pose: lexiPoseForTimeOfDay, size: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreetingKey)
                    .font(.rounded(22, weight: .bold))
                Text("today.subtitle")
                    .font(.rounded(14))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if progress.streakDays > 0 {
                streakChip
            }
        }
    }

    private var timeGreetingKey: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:  return "today.greet.morning"
        case 11..<14: return "today.greet.noon"
        case 14..<18: return "today.greet.afternoon"
        case 18..<23: return "today.greet.evening"
        default:      return "today.greet.night"
        }
    }

    private var lexiPoseForTimeOfDay: LexiPose {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 5 || hour >= 23 { return .sleepy }
        if hour < 9 { return .wave }
        return .read
    }

    private var streakChip: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(progress.streakDays)")
                .font(.rounded(14, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(AppColor.brandSecondary.opacity(0.15))
        .foregroundStyle(AppColor.brandSecondary)
        .clipShape(Capsule())
    }

    // MARK: - Word of the Day

    private var wordOfTheDay: Term? {
        let pool = termStore.allTerms
        guard !pool.isEmpty else { return nil }
        // Deterministic by date: same word for everyone today
        let day = Calendar.current.startOfDay(for: Date())
        let seed = Int(day.timeIntervalSince1970 / 86400)
        return pool[abs(seed) % pool.count]
    }

    private func wotdCard(_ term: Term) -> some View {
        NavigationLink(value: term) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("today.wotd", systemImage: "sparkles")
                        .font(.rounded(11, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColor.cheer.opacity(0.25))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                    Spacer()
                }
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(term.english)
                            .font(.rounded(28, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                        Text(termStore.translation(for: term.id, locale: settings.nativeLanguage).term)
                            .font(.rounded(15))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SpeakerButton(text: term.english, size: 44)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.adaptive(light: "FFF6E8", dark: "3A2F1E"),
                             Color.adaptive(light: "FFE6C7", dark: "2E2616")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AppColor.brandSecondary.opacity(0.15), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    // MARK: - Today's Picks (h-scroll cards)

    private var pickedTerms: [Term] {
        let pool = termStore.allTerms
        let due  = pool.filter {
            let r = progress.record(for: $0.id)
            return r.status != .mastered
        }
        return Array(due.prefix(settings.dailyGoal))
    }

    private func todaysPicks(_ picks: [Term]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(picks) { term in
                    NavigationLink(value: term) {
                        TermCardMini(term: term)
                    }
                    .buttonStyle(.plain)
                }
                if picks.isEmpty {
                    emptyAllDoneCard
                }
            }
        }
    }

    private var emptyAllDoneCard: some View {
        VStack(spacing: 10) {
            LexiView(pose: .sleepy, size: 70)
            Text("today.allDone")
                .font(.rounded(14, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(width: 180, height: 160)
        .background(AppColor.warmCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Action buttons (Start / Listen / Random)

    private func actionButtons(_ picks: [Term]) -> some View {
        VStack(spacing: 12) {
            NavigationLink {
                ReviewSessionView(terms: picks)
            } label: {
                actionLabel(systemImage: "play.fill", key: "today.start",
                            fg: .white, bg: AppColor.brandPrimary)
            }
            .disabled(picks.isEmpty)
            .opacity(picks.isEmpty ? 0.5 : 1)

            NavigationLink {
                ShadowReadView()
            } label: {
                actionLabel(systemImage: "mic.fill", key: "today.shadow",
                            fg: AppColor.brandPrimary, bg: AppColor.brandPrimary.opacity(0.12))
            }

            HStack(spacing: 12) {
                NavigationLink {
                    ListenModeView()
                } label: {
                    actionLabel(systemImage: "headphones", key: "today.listen",
                                fg: AppColor.brandPrimary, bg: AppColor.brandPrimary.opacity(0.12))
                }
                Button {
                    pickRandomAndShow()
                } label: {
                    actionLabel(systemImage: "die.face.5.fill", key: "today.random",
                                fg: AppColor.brandSecondary, bg: AppColor.brandSecondary.opacity(0.12))
                }
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { randomTerm != nil },
                set: { if !$0 { randomTerm = nil } }
            )
        ) {
            if let t = randomTerm { TermDetailView(term: t) }
        }
    }

    private func actionLabel(systemImage: String, key: LocalizedStringKey,
                             fg: Color, bg: Color) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(key).font(.rounded(15, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg)
        .foregroundStyle(fg)
        .clipShape(Capsule())
    }

    private func pickRandomAndShow() {
        randomTerm = termStore.allTerms.randomElement()
    }

    // MARK: - Recent mastered

    private var recentMastered: some View {
        let mastered = progress.records.values
            .filter { $0.status == .mastered }
            .sorted { ($0.lastReviewed ?? .distantPast) > ($1.lastReviewed ?? .distantPast) }
            .prefix(3)
            .compactMap { termStore.term(by: $0.id) }

        return VStack(spacing: 0) {
            if mastered.isEmpty {
                HStack(spacing: 8) {
                    LexiView(pose: .read, size: 44, animated: false)
                    Text("today.noMastered")
                        .font(.rounded(14))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
            } else {
                ForEach(mastered) { t in
                    NavigationLink(value: t) {
                        TermRow(term: t)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
