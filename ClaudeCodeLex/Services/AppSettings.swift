// AppSettings.swift
// User preferences (UI language, native language, theme, daily goal).
// Persisted via @AppStorage / UserDefaults.

import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    // UI language: which Localizable.xcstrings locale to use
    @AppStorage("ui.language") var uiLanguage: String = autoDetectLocale()
    // Native language: which Translation key to pull from terms.json
    @AppStorage("learning.nativeLanguage") var nativeLanguage: String = autoDetectLocale()
    @AppStorage("learning.dailyGoal") var dailyGoal: Int = 5
    @AppStorage("audio.rate") var audioRate: Double = 0.45
    @AppStorage("audio.autoplay") var autoPlayOnOpen: Bool = true
    @AppStorage("appearance.theme") var theme: String = "auto" // auto/light/dark
    // Onboarding gate
    @AppStorage("onboarding.completed") var onboardingCompleted: Bool = false
    // Tip Jar
    @AppStorage("tipjar.lifetime") var tipJarLifetime: Double = 0.0
    // OTA dictionary updates — OFF by default; the app is fully offline-capable.
    @AppStorage("dict.autoUpdate") var dictionaryAutoUpdate: Bool = false
    // App Store rating: app version we last showed the review prompt for (≤1×/version).
    @AppStorage("rating.promptedVersion") var ratingPromptedVersion: String = ""

    // ---- Notifications ----
    // Daily local streak reminder. Scheduling lives in NotificationService.
    @AppStorage("notify.dailyEnabled") var dailyReminderEnabled: Bool = false
    @AppStorage("notify.hour") var reminderHour: Int = 20
    @AppStorage("notify.minute") var reminderMinute: Int = 0

    // ---- AI BYOK ----
    // Which voice provider is currently active. Keys live in Keychain, never here.
    @AppStorage("ai.voiceProvider") var voiceProviderRaw: String = AIVoiceProvider.native.rawValue
    @AppStorage("ai.openai.voice") var openAIVoice: String = "nova"
    @AppStorage("ai.elevenlabs.voice") var elevenLabsVoice: String = "21m00Tcm4TlvDq8ikWAM"
    // Active chat provider for Ask Lexi. nil = feature disabled.
    @AppStorage("ai.chatProvider") var chatProviderRaw: String = ""
    @AppStorage("ai.claude.model") var claudeModel: String = "claude-sonnet-4-6"
    @AppStorage("ai.openai.model") var openAIChatModel: String = "gpt-4o-mini"
    @AppStorage("ai.gemini.model") var geminiModel: String = "gemini-1.5-pro"
    // First-time BYOK disclosure shown?
    @AppStorage("ai.disclosureShown") var byokDisclosureShown: Bool = false

    var voiceProvider: AIVoiceProvider {
        get { AIVoiceProvider(rawValue: voiceProviderRaw) ?? .native }
        set { voiceProviderRaw = newValue.rawValue }
    }

    var chatProvider: AIChatProvider? {
        get { AIChatProvider(rawValue: chatProviderRaw) }
        set { chatProviderRaw = newValue?.rawValue ?? "" }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    static func autoDetectLocale() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        // Normalize to one of our supported keys
        let supported = ["en", "zh-TW", "zh-CN", "ja", "ko", "es", "pt"]
        if supported.contains(preferred) { return preferred }
        let lang = String(preferred.prefix(2))
        if supported.contains(lang) { return lang }
        // Chinese: distinguish Simplified (zh-Hans*) from Traditional.
        if preferred.hasPrefix("zh-Hans") { return "zh-CN" }
        if preferred.hasPrefix("zh") { return "zh-TW" }
        return "en"
    }

    static let supportedLanguages: [(code: String, label: String)] = [
        ("en",    "English"),
        ("zh-TW", "繁體中文"),
        ("zh-CN", "简体中文"),
        ("ja",    "日本語"),
        ("ko",    "한국어"),
        ("es",    "Español"),
        ("pt",    "Português")
    ]
}
