// AppRouter.swift
// Bridges Siri Shortcuts (App Intents) to in-app navigation. The intents
// run in-process and mutate AppRouter.shared; ContentView and TodayView
// observe it and navigate. Plain device-only state — no server, no tracking.

import Foundation

/// The four root tabs, used as `TabView` selection tags.
enum AppTab: Hashable {
    case today, browse, quiz, settings
}

/// A one-shot navigation request raised by a Siri Shortcut.
enum DeepLink: Hashable {
    case listenMode
}

final class AppRouter: ObservableObject {
    static let shared = AppRouter()
    private init() {}

    /// Which root tab `ContentView` shows.
    @Published var selectedTab: AppTab = .today

    /// Pending deep link from a shortcut; the destination view consumes it
    /// and resets it to nil.
    @Published var pendingDeepLink: DeepLink?
}
