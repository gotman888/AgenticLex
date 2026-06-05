// AppShortcuts.swift
// Siri Shortcuts via the App Intents framework (iOS 16+). Both shortcuts
// auto-register on install — no user setup, no Apple Developer config and
// no Siri entitlement. They only open the app and route in-process;
// nothing leaves the device.

import AppIntents

// MARK: - Intents

/// Opens the app on the Today tab, where the Word of the Day lives.
struct WordOfTheDayIntent: AppIntent {
    static var title: LocalizedStringResource = "siri.wotd.title"
    static var description = IntentDescription("Open AgenticLex to today's word")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run { AppRouter.shared.selectedTab = .today }
        return .result()
    }
}

/// Opens the app and pushes Listen Mode, the audio-only review screen.
struct ListenModeIntent: AppIntent {
    static var title: LocalizedStringResource = "siri.listen.title"
    static var description = IntentDescription("Start Listen Mode in AgenticLex")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppRouter.shared.selectedTab = .today
            AppRouter.shared.pendingDeepLink = .listenMode
        }
        return .result()
    }
}

// MARK: - App Shortcuts (auto-registered with Siri)

struct AgenticLexShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WordOfTheDayIntent(),
            phrases: [
                "\(.applicationName) word of the day",
                "Word of the day in \(.applicationName)",
                "\(.applicationName) 今日單字",
                "\(.applicationName) 今日单词",
                "\(.applicationName) 今日の単語",
                "\(.applicationName) 오늘의 단어",
                "Palabra del día en \(.applicationName)",
                "Palavra do dia na \(.applicationName)"
            ],
            shortTitle: "siri.wotd.title",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: ListenModeIntent(),
            phrases: [
                "Start Listen Mode in \(.applicationName)",
                "Listen with \(.applicationName)",
                "\(.applicationName) 聽力模式",
                "\(.applicationName) 听力模式",
                "\(.applicationName) 聴くモード",
                "\(.applicationName) 리스닝 모드",
                "Modo escucha en \(.applicationName)",
                "Modo audição na \(.applicationName)"
            ],
            shortTitle: "siri.listen.title",
            systemImageName: "headphones"
        )
    }
}
