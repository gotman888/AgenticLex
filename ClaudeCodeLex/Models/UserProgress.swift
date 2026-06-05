// UserProgress.swift
// Per-term learning progress, persisted locally.

import Foundation

enum LearnStatus: String, Codable, CaseIterable {
    case new       // never seen / answered wrong
    case learning  // seen once, +1 day
    case reviewing // partially mastered, +3 / 7 days
    case mastered  // confident, +30 / 90 days
}

struct UserProgress: Codable, Identifiable {
    let id: String          // == Term.id
    var status: LearnStatus
    var lastReviewed: Date?
    var nextReview: Date?
    var reviewCount: Int
    var isFavorite: Bool

    static func newRecord(termId: String) -> UserProgress {
        UserProgress(
            id: termId,
            status: .new,
            lastReviewed: nil,
            nextReview: nil,
            reviewCount: 0,
            isFavorite: false
        )
    }
}
