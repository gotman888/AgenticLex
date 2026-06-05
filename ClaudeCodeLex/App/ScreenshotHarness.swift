// ScreenshotHarness.swift
// DEBUG-only App Store screenshot automation. The whole file is wrapped in
// `#if DEBUG`, so it is fully compiled out of Release / App Store builds.
//
// Driven by tools/shoot_screenshots.sh through launch arguments:
//   simctl launch <id> -screenshotScreen <screen> -screenshotSet <en|zh-TW>

#if DEBUG
import SwiftUI

enum ScreenshotHarness {
    /// Screen to render as the app root: today / detail / quiz / browse /
    /// settings / dark / sharecard / conceptmap / learningpath / shadowread.
    /// Returns nil for the normal app flow.
    static var activeScreen: String? {
        let s = UserDefaults.standard.string(forKey: "screenshotScreen")
        return (s?.isEmpty == false) ? s : nil
    }

    /// Content-rich term shown on the `detail` screen.
    static let demoTermID = "hook"

    /// Seed the locale / theme defaults the active screenshot needs.
    /// Called from ClaudeCodeLexApp.init(), before AppSettings is built, so
    /// its @AppStorage properties pick these up on first read.
    static func applyIfNeeded() {
        guard activeScreen != nil else { return }
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "screenshotSet") {
        case "zh-TW":
            defaults.set("zh-TW", forKey: "ui.language")
            defaults.set("zh-TW", forKey: "learning.nativeLanguage")
        default: // en set: English UI, Spanish term content
            defaults.set("en", forKey: "ui.language")
            defaults.set("es", forKey: "learning.nativeLanguage")
        }
        defaults.set(activeScreen == "dark" ? "dark" : "auto", forKey: "appearance.theme")
        defaults.set(true, forKey: "onboarding.completed")
    }
}

/// Renders a single screen as the app root for screenshot capture.
struct ScreenshotRootView: View {
    let screen: String
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        switch screen {
        case "browse":     BrowseView()
        case "quiz":       quiz
        case "settings":   SettingsView()
        case "detail":     detail
        case "dark":       SettingsView()   // dark-mode showcase (Form adapts cleanly)
        case "sharecard":  shareCard        // v1.1 verification: Share Card layout
        case "conceptmap": conceptMap       // v1.1 verification: Concept Map graph
        case "learningpath": NavigationStack { LearningPathView() }
        case "shadowread": NavigationStack { ShadowReadView() }
        default:           TodayView()      // "today"
        }
    }

    @ViewBuilder private var detail: some View {
        if let term = termStore.term(by: ScreenshotHarness.demoTermID)
            ?? termStore.allTerms.first {
            NavigationStack { TermDetailView(term: term) }
        } else {
            TodayView()
        }
    }

    @ViewBuilder private var quiz: some View {
        let terms = Array(termStore.allTerms.prefix(5))
        if terms.isEmpty {
            QuizSetupView()
        } else {
            NavigationStack {
                QuizCardView(terms: terms, direction: .l1ToEn)
            }
        }
    }

    /// Renders the shareable card through its real ImageRenderer path, fitted
    /// to the screen, so its layout can be eyeballed without tapping Share.
    @ViewBuilder private var shareCard: some View {
        if let term = termStore.term(by: ScreenshotHarness.demoTermID)
            ?? termStore.allTerms.first {
            let translation = termStore.translation(for: term.id,
                                                    locale: settings.nativeLanguage)
            let category = termStore.main?.categories
                .first(where: { $0.id == term.category })?
                .name(for: settings.uiLanguage) ?? term.category
            if let image = ShareCardView(term: term, translation: translation,
                                         category: category).renderImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(white: 0.45))
            } else {
                TodayView()
            }
        } else {
            TodayView()
        }
    }

    /// Concept map seeded on the most-connected term — the worst case for
    /// node crowding / edge overlap.
    @ViewBuilder private var conceptMap: some View {
        if let term = termStore.allTerms.max(by: {
            $0.relatedTerms.count < $1.relatedTerms.count
        }) {
            NavigationStack { ConceptMapView(focus: term) }
        } else {
            TodayView()
        }
    }
}
#endif
