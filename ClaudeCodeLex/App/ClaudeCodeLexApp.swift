// ClaudeCodeLexApp.swift
// ClaudeCodeLex
//
// Entry point. SwiftUI App that wires up dependencies and root view.

import SwiftUI

@main
struct ClaudeCodeLexApp: App {
    // Singletons (light DI)
    @StateObject private var termStore     = TermStore()
    @StateObject private var progressStore = ProgressStore()
    @StateObject private var settings      = AppSettings()
    @StateObject private var router        = AppRouter.shared

    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        ScreenshotHarness.applyIfNeeded()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(termStore)
                .environmentObject(progressStore)
                .environmentObject(settings)
                .environmentObject(router)
                .preferredColorScheme(settings.colorScheme) // Auto / Light / Dark
        }
        .onChange(of: scenePhase) { phase in
            // Re-schedule on foreground so the reminder body reflects the
            // current streak count.
            if phase == .active && settings.dailyReminderEnabled {
                NotificationService.reschedule(
                    enabled: true,
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                    streakDays: progressStore.streakDays
                )
            }
            // Opt-in: pull a newer dictionary if the user enabled OTA updates.
            if phase == .active && settings.dictionaryAutoUpdate {
                Task {
                    await TermUpdateService.shared.check(
                        currentVersion: termStore.main?.metadata.version ?? "0")
                }
            }
            // Durability: flush progress synchronously on the way to background so
            // the last quiz answer / streak bump survives a suspend or jetsam
            // (save() is otherwise an async best-effort write).
            if phase == .background {
                progressStore.flush()
            }
        }
    }
}
