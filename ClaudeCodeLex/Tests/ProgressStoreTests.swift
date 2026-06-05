// ProgressStoreTests.swift
// Unit tests for the SRS (spaced-repetition) core logic in ProgressStore.
//
// NOTE: ProgressStore is @MainActor, so this test case is annotated @MainActor.
// ProgressStore persists to a JSON file in the app's Documents directory;
// each test calls resetAll() in setUp() to start from a clean, deterministic state.

import XCTest
@testable import ClaudeCodeLex

@MainActor
final class ProgressStoreTests: XCTestCase {

    private var store: ProgressStore!

    override func setUp() async throws {
        try await super.setUp()
        store = ProgressStore()
        // Wipe any persisted records / streak from previous runs so every
        // test starts from a known baseline.
        store.resetAll()
    }

    override func tearDown() async throws {
        store.resetAll()
        store = nil
        try await super.tearDown()
    }

    // MARK: - Status transitions

    /// A brand-new term answered correctly must move from `.new` to `.learning`.
    func testCorrectAnswerMovesNewToLearning() {
        let termId = "agentic-coding"

        // A term that has never been touched defaults to `.new`.
        XCTAssertEqual(store.record(for: termId).status, .new)

        store.mark(termId: termId, correct: true)

        let record = store.record(for: termId)
        XCTAssertEqual(record.status, .learning)
        XCTAssertEqual(record.reviewCount, 1)
        XCTAssertNotNil(record.lastReviewed)
        XCTAssertNotNil(record.nextReview)
    }

    /// A second correct answer must move `.learning` to `.reviewing`.
    func testCorrectAnswerMovesLearningToReviewing() {
        let termId = "context-window"

        store.mark(termId: termId, correct: true)   // new -> learning
        XCTAssertEqual(store.record(for: termId).status, .learning)

        store.mark(termId: termId, correct: true)   // learning -> reviewing

        let record = store.record(for: termId)
        XCTAssertEqual(record.status, .reviewing)
        XCTAssertEqual(record.reviewCount, 2)
    }

    /// A third correct answer must move `.reviewing` to `.mastered`,
    /// and further correct answers must stay `.mastered` (terminal state).
    func testCorrectAnswerMovesReviewingToMasteredAndStays() {
        let termId = "tool-use"

        store.mark(termId: termId, correct: true)   // new -> learning
        store.mark(termId: termId, correct: true)   // learning -> reviewing
        store.mark(termId: termId, correct: true)   // reviewing -> mastered
        XCTAssertEqual(store.record(for: termId).status, .mastered)

        store.mark(termId: termId, correct: true)   // mastered -> mastered
        XCTAssertEqual(store.record(for: termId).status, .mastered)
    }

    /// A wrong answer must drop the term all the way back to `.new`,
    /// regardless of how far it had progressed.
    func testWrongAnswerResetsStatusToNew() {
        let termId = "prompt-caching"

        store.mark(termId: termId, correct: true)   // new -> learning
        store.mark(termId: termId, correct: true)   // learning -> reviewing
        XCTAssertEqual(store.record(for: termId).status, .reviewing)

        store.mark(termId: termId, correct: false)  // reviewing -> new

        let record = store.record(for: termId)
        XCTAssertEqual(record.status, .new)
        // reviewCount keeps incrementing even on a wrong answer.
        XCTAssertEqual(record.reviewCount, 3)
        XCTAssertNotNil(record.nextReview)
    }

    // MARK: - Streak

    /// The first study action of a fresh store must start the streak at 1.
    func testFirstMarkStartsStreakAtOne() {
        XCTAssertEqual(store.streakDays, 0)
        XCTAssertNil(store.lastLearnDate)

        store.mark(termId: "mcp-server", correct: true)

        XCTAssertEqual(store.streakDays, 1)
        XCTAssertNotNil(store.lastLearnDate)
    }

    /// Multiple study actions on the SAME calendar day must not inflate the
    /// streak — it stays at 1 because the streak counts distinct days, not marks.
    func testSameDayMarksDoNotIncrementStreak() {
        store.mark(termId: "subagent", correct: true)
        XCTAssertEqual(store.streakDays, 1)

        // Several more marks within the same test run = same calendar day.
        store.mark(termId: "subagent", correct: false)
        store.mark(termId: "hooks", correct: true)
        store.mark(termId: "slash-command", correct: true)

        XCTAssertEqual(store.streakDays, 1,
                       "Streak must only advance once per calendar day.")
    }

    /// resetAll() must break/clear the streak: counter back to 0 and the
    /// last-learn date cleared, so the next mark restarts the streak fresh.
    func testResetAllBreaksStreak() {
        store.mark(termId: "byok", correct: true)
        XCTAssertEqual(store.streakDays, 1)

        store.resetAll()

        XCTAssertEqual(store.streakDays, 0)
        XCTAssertNil(store.lastLearnDate)
        XCTAssertTrue(store.records.isEmpty)

        // After a break, the next study action restarts the streak at 1.
        store.mark(termId: "byok", correct: true)
        XCTAssertEqual(store.streakDays, 1)
    }

    // MARK: - Per-term reset & favorites (supporting SRS behaviour)

    /// resetProgress(termId:) must return a single term to a clean `.new` record
    /// without touching the global streak.
    func testResetProgressClearsSingleTerm() {
        let termId = "celebration-view"
        store.mark(termId: termId, correct: true)
        store.mark(termId: termId, correct: true)
        XCTAssertEqual(store.record(for: termId).status, .reviewing)

        store.resetProgress(termId: termId)

        let record = store.record(for: termId)
        XCTAssertEqual(record.status, .new)
        XCTAssertEqual(record.reviewCount, 0)
        XCTAssertNil(record.lastReviewed)
        XCTAssertNil(record.nextReview)
        // Streak is global state and must survive a per-term reset.
        XCTAssertEqual(store.streakDays, 1)
    }

    /// A correctly answered term schedules a future review and therefore must
    /// not be reported as due "now".
    func testDueForReviewExcludesFreshlyScheduledTerm() {
        let termId = "spaced-repetition"
        store.mark(termId: termId, correct: true)   // nextReview = today + 1 day

        let dueNow = store.dueForReview(now: Date())
        XCTAssertFalse(dueNow.contains(termId),
                       "A term scheduled for the future must not be due now.")
    }
}
