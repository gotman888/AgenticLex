// ReviewPrompter.swift
// Gate logic for the App Store rating ask. The actual system prompt is fired by
// the view via @Environment(\.requestReview); this just decides whether now is a
// good, polite moment. Device-only, no backend, no tracking, no strings.

import Foundation

enum ReviewPrompter {
    /// Returns true (and records the attempt) when the user looks happily
    /// engaged and we haven't asked this app version yet. Apple additionally
    /// rate-limits to ~3 prompts/year. Gate: streak ≥3 days AND ≥10 mastered.
    @MainActor
    static func shouldAsk(streakDays: Int, masteredCount: Int, settings: AppSettings) -> Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        guard settings.ratingPromptedVersion != version,
              streakDays >= 3,
              masteredCount >= 10 else { return false }
        settings.ratingPromptedVersion = version   // record before asking
        return true
    }
}
