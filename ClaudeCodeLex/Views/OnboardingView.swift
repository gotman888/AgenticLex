// OnboardingView.swift
// First-launch 3-step flow:
//   1. Welcome + trademark disclaimer (prominent, not buried)
//   2. UI language + native language (deliberately separate)
//   3. Daily goal + finish
//
// Per OPTIMIZATION.md B12: UI 語 ≠ native 語. Many TW users want
// English UI for the technical feel, but zh-TW translations for memory.

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var termStore: TermStore
    @State private var step: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i <= step ? AppColor.brandPrimary : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Step content
            Group {
                switch step {
                case 0: welcomeStep
                case 1: languageStep
                default: goalStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // Bottom nav
            HStack {
                if step > 0 {
                    Button("onboarding.back") {
                        withAnimation { step -= 1 }
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                Button(step == 2 ? "onboarding.start" : "onboarding.next") {
                    if step == 2 {
                        settings.onboardingCompleted = true
                    } else {
                        withAnimation { step += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColor.brandPrimary)
            }
            .padding(24)
        }
    }

    // MARK: - Step 1: Welcome + Disclaimer

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            LexiView(pose: .wave, size: 140)
            Text("onboarding.lexi.intro")
                .font(.rounded(20, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Text("app.name")
                .font(.rounded(36, weight: .bold))
            Text(termStore.tagline(for: settings.uiLanguage))
                .font(.rounded(17))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()

            // Trademark disclaimer — prominent (moved from Settings footer per OPTIMIZATION A8)
            VStack(alignment: .leading, spacing: 6) {
                Label("onboarding.disclaimer.title", systemImage: "exclamationmark.shield")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Text("onboarding.disclaimer.body")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.orange.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Step 2: Language pickers (UI vs native)

    private var languageStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("onboarding.lang.title")
                    .font(.title.bold())
                Text("onboarding.lang.subtitle")
                    .font(.body)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Label("onboarding.uiLang.label", systemImage: "iphone")
                        .font(.headline)
                    Text("onboarding.uiLang.help")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    languageGrid(selection: $settings.uiLanguage)
                }

                Divider().padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Label("onboarding.nativeLang.label", systemImage: "person.fill")
                        .font(.headline)
                    Text("onboarding.nativeLang.help")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    languageGrid(selection: $settings.nativeLanguage,
                                 showCoverage: true)
                }
            }
            .padding(24)
        }
    }

    private func languageGrid(selection: Binding<String>, showCoverage: Bool = false) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(AppSettings.supportedLanguages, id: \.code) { lang in
                let isFull = termStore.isFullyTranslated(lang.code)
                Button {
                    selection.wrappedValue = lang.code
                } label: {
                    HStack {
                        Text(lang.label)
                            .font(.body)
                            .fontWeight(selection.wrappedValue == lang.code ? .bold : .regular)
                        Spacer()
                        if showCoverage && !isFull {
                            Text("onboarding.comingSoon")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                        if selection.wrappedValue == lang.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColor.brandPrimary)
                        }
                    }
                    .padding(12)
                    .background(selection.wrappedValue == lang.code
                                ? AppColor.brandPrimary.opacity(0.1)
                                : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Step 3: Daily goal

    private var goalStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎯").font(.system(size: 60))
            Text("onboarding.goal.title")
                .font(.title.bold())
            Text("onboarding.goal.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ForEach([3, 5, 10, 20], id: \.self) { n in
                    Button {
                        settings.dailyGoal = n
                    } label: {
                        HStack {
                            Text(verbatim: "\(n)")
                                .font(.title2.bold())
                                .frame(width: 40)
                            Text(goalDescription(for: n))
                                .font(.body)
                            Spacer()
                            if settings.dailyGoal == n {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColor.brandPrimary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(settings.dailyGoal == n
                                    ? AppColor.brandPrimary.opacity(0.1)
                                    : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func goalDescription(for n: Int) -> LocalizedStringKey {
        switch n {
        case 3:  return "onboarding.goal.relaxed"
        case 5:  return "onboarding.goal.regular"
        case 10: return "onboarding.goal.serious"
        default: return "onboarding.goal.intense"
        }
    }
}
