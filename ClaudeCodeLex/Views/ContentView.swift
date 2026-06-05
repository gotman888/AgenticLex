// ContentView.swift
// Root tab container.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var router: AppRouter

    @AppStorage(AIConsent.storageKey) private var hasAcceptedAI: Bool = false
    @State private var showDisclosure: Bool = false

    var body: some View {
        #if DEBUG
        if let screen = ScreenshotHarness.activeScreen {
            ScreenshotRootView(screen: screen)
        } else {
            gatedFlow
        }
        #else
        gatedFlow
        #endif
    }

    // Apple Guideline 5.1.1(i): disclosure must appear before any third-party
    // AI feature is reachable. We gate at the root so it precedes onboarding.
    private var gatedFlow: some View {
        normalFlow
            .onAppear { if !hasAcceptedAI { showDisclosure = true } }
            .fullScreenCover(isPresented: $showDisclosure) {
                AIDisclosureView(
                    onAccept: { showDisclosure = false },
                    onDecline: { showDisclosure = false }
                )
            }
    }

    @ViewBuilder private var normalFlow: some View {
        if !settings.onboardingCompleted {
            OnboardingView()
        } else {
            mainTabs
        }
    }

    private var mainTabs: some View {
        TabView(selection: $router.selectedTab) {
            TodayView()
                .tabItem { Label("today.tab", systemImage: "house.fill") }
                .tag(AppTab.today)

            BrowseView()
                .tabItem { Label("browse.tab", systemImage: "books.vertical.fill") }
                .tag(AppTab.browse)

            QuizSetupView()
                .tabItem { Label("quiz.tab", systemImage: "target") }
                .tag(AppTab.quiz)

            SettingsView()
                .tabItem { Label("settings.tab", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(AppColor.brandPrimary)
    }
}


