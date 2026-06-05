// ProgressStore.swift
// Per-term progress persisted to a JSON file in Documents directory.
// Simple SRS scheduling logic lives here too.

import Foundation
import Combine

@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var records: [String: UserProgress] = [:]
    @Published private(set) var streakDays: Int = 0
    @Published private(set) var lastLearnDate: Date?

    private let fileName = "progress.json"
    /// Serial queue for off-main disk writes — ordered, and never blocks the UI.
    private let ioQueue = DispatchQueue(label: "agenticlex.progress.io", qos: .userInitiated)

    init() {
        load()
    }

    // MARK: - Persistence

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        self.records       = snapshot.records
        self.streakDays    = snapshot.streakDays
        self.lastLearnDate = snapshot.lastLearnDate
    }

    private func save() {
        // Snapshot on the main actor, then encode + write off-main on a serial
        // queue so the interactive path (every quiz answer) never blocks on disk.
        // Serial → writes stay ordered; .atomic → never a torn file.
        let snapshot = Snapshot(
            records: records,
            streakDays: streakDays,
            lastLearnDate: lastLearnDate
        )
        let url = fileURL
        ioQueue.async {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    /// Synchronous flush for the app-background transition, so the last mutation
    /// (e.g. the final quiz answer + streak bump) is durable even if the OS
    /// suspends/jetsams us before the async write drains. Blocks briefly on the
    /// serial queue — acceptable on the way to background.
    func flush() {
        let snapshot = Snapshot(
            records: records,
            streakDays: streakDays,
            lastLearnDate: lastLearnDate
        )
        let url = fileURL
        ioQueue.sync {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    // MARK: - Queries

    func record(for termId: String) -> UserProgress {
        records[termId] ?? UserProgress.newRecord(termId: termId)
    }

    /// Terms the user has mastered — gates the App Store rating prompt.
    var masteredCount: Int { records.values.filter { $0.status == .mastered }.count }

    func isFavorite(_ termId: String) -> Bool {
        records[termId]?.isFavorite ?? false
    }

    func dueForReview(now: Date = Date()) -> [String] {
        records.values
            .filter { ($0.nextReview ?? .distantPast) <= now }
            .map { $0.id }
    }

    // MARK: - Mutations

    func toggleFavorite(_ termId: String) {
        var r = record(for: termId)
        r.isFavorite.toggle()
        records[termId] = r
        save()
    }

    /// Apply a quiz answer / detail interaction.
    func mark(termId: String, correct: Bool) {
        var r = record(for: termId)
        r.lastReviewed = Date()
        r.reviewCount += 1
        if correct {
            r.status = nextStatus(after: r.status)
            r.nextReview = scheduleNextDate(for: r.status)
        } else {
            r.status = .new
            r.nextReview = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
        records[termId] = r
        bumpStreak()
        save()
    }

    func resetProgress(termId: String) {
        records[termId] = UserProgress.newRecord(termId: termId)
        save()
    }

    func resetAll() {
        records = [:]
        streakDays = 0
        lastLearnDate = nil
        save()
    }

    // MARK: - SRS scheduling

    private func nextStatus(after current: LearnStatus) -> LearnStatus {
        switch current {
        case .new:       return .learning
        case .learning:  return .reviewing
        case .reviewing: return .mastered
        case .mastered:  return .mastered
        }
    }

    private func scheduleNextDate(for status: LearnStatus) -> Date {
        let cal = Calendar.current
        let days: Int = {
            switch status {
            case .new:       return 1
            case .learning:  return 3
            case .reviewing: return 7
            case .mastered:  return 30
            }
        }()
        return cal.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    // MARK: - Streak

    private func bumpStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let last = lastLearnDate.map(cal.startOfDay(for:)) {
            if cal.isDate(last, inSameDayAs: today) {
                // already counted today
            } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                      cal.isDate(last, inSameDayAs: yesterday) {
                streakDays += 1
                lastLearnDate = Date()
            } else {
                streakDays = 1
                lastLearnDate = Date()
            }
        } else {
            streakDays = 1
            lastLearnDate = Date()
        }
    }

    // MARK: - Snapshot

    private struct Snapshot: Codable {
        var records: [String: UserProgress]
        var streakDays: Int
        var lastLearnDate: Date?
    }
}
