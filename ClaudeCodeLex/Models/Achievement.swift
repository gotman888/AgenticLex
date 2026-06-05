// Achievement.swift
// Static catalog of unlockable badges. Unlock state is computed from ProgressStore.

import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let emoji: String
    let titleKey: String
    let descriptionKey: String
    let lexiPose: LexiPose
    /// Closure to evaluate whether this is unlocked given the user's snapshot.
    let isUnlocked: @MainActor (AchievementSnapshot) -> Bool
}

extension Achievement {
    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct AchievementSnapshot {
    let masteredCount: Int
    let totalTerms: Int
    let streakDays: Int
    let nowHour: Int        // 0..23
    let totalTipped: Double
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(
            id: "first-word",
            emoji: "🌱",
            titleKey: "achv.firstWord.title",
            descriptionKey: "achv.firstWord.desc",
            lexiPose: .read,
            isUnlocked: { $0.masteredCount >= 1 }
        ),
        Achievement(
            id: "bookworm",
            emoji: "📚",
            titleKey: "achv.bookworm.title",
            descriptionKey: "achv.bookworm.desc",
            lexiPose: .read,
            isUnlocked: { $0.masteredCount >= 10 }
        ),
        Achievement(
            id: "scholar",
            emoji: "🎓",
            titleKey: "achv.scholar.title",
            descriptionKey: "achv.scholar.desc",
            lexiPose: .cheer,
            isUnlocked: { $0.masteredCount >= 30 }
        ),
        Achievement(
            id: "master",
            emoji: "🌟",
            titleKey: "achv.master.title",
            descriptionKey: "achv.master.desc",
            lexiPose: .cheer,
            isUnlocked: { $0.totalTerms > 0 && $0.masteredCount >= $0.totalTerms }
        ),
        Achievement(
            id: "spark",
            emoji: "🔥",
            titleKey: "achv.spark.title",
            descriptionKey: "achv.spark.desc",
            lexiPose: .cheer,
            isUnlocked: { $0.streakDays >= 3 }
        ),
        Achievement(
            id: "flame",
            emoji: "🔥🔥",
            titleKey: "achv.flame.title",
            descriptionKey: "achv.flame.desc",
            lexiPose: .cheer,
            isUnlocked: { $0.streakDays >= 7 }
        ),
        Achievement(
            id: "blaze",
            emoji: "🔥🔥🔥",
            titleKey: "achv.blaze.title",
            descriptionKey: "achv.blaze.desc",
            lexiPose: .wizard,
            isUnlocked: { $0.streakDays >= 30 }
        ),
        Achievement(
            id: "night-owl",
            emoji: "🦉",
            titleKey: "achv.nightOwl.title",
            descriptionKey: "achv.nightOwl.desc",
            lexiPose: .sleepy,
            isUnlocked: { $0.nowHour >= 0 && $0.nowHour < 4 }
        ),
        Achievement(
            id: "early-bird",
            emoji: "🌅",
            titleKey: "achv.earlyBird.title",
            descriptionKey: "achv.earlyBird.desc",
            lexiPose: .wave,
            isUnlocked: { $0.nowHour >= 5 && $0.nowHour < 8 }
        ),
        Achievement(
            id: "coffee-helper",
            emoji: "☕",
            titleKey: "achv.coffeeHelper.title",
            descriptionKey: "achv.coffeeHelper.desc",
            lexiPose: .wave,
            isUnlocked: { $0.totalTipped > 0 }
        )
    ]
}
