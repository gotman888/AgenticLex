// LearningPathView.swift
// A 3-level learning journey, tiered by term difficulty. Levels are never
// locked — the path only shows where the learner is and what to focus on
// next, keeping things friendly (no anxiety). Progress is computed live
// from ProgressStore; nothing new is persisted.

import SwiftUI

/// One rung of the path — a difficulty tier (`id` == difficulty, 1...3).
private struct LearningLevel: Identifiable {
    let id: Int
    let nameKey: LocalizedStringKey
    let pose: LexiPose
}

private let learningLevels: [LearningLevel] = [
    LearningLevel(id: 1, nameKey: "path.level.foundations", pose: .wave),
    LearningLevel(id: 2, nameKey: "path.level.core",        pose: .read),
    LearningLevel(id: 3, nameKey: "path.level.advanced",    pose: .wizard),
]

struct LearningPathView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                ForEach(Array(learningLevels.enumerated()), id: \.element.id) { idx, level in
                    levelRow(level, isLast: idx == learningLevels.count - 1)
                }
            }
            .padding(20)
        }
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle("path.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            LexiView(pose: allComplete ? .cheer : .read, size: 64)
            Text("path.intro")
                .font(.rounded(14))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Level row (rail + tappable card)

    private func levelRow(_ level: LearningLevel, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            rail(for: level, isLast: isLast)
            NavigationLink {
                LevelTermsList(level: level, terms: terms(in: level))
            } label: {
                card(for: level)
            }
            .buttonStyle(.plain)
            .padding(.bottom, isLast ? 0 : 18)
        }
    }

    /// The node circle plus the connecting line down to the next level.
    private func rail(for level: LearningLevel, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            node(for: level)
            if !isLast {
                Capsule()
                    .fill(isComplete(level) ? AppColor.brandPrimary
                                            : Color.gray.opacity(0.2))
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 40)
    }

    private func node(for level: LearningLevel) -> some View {
        ZStack {
            Circle().fill(nodeColor(level))
            if isComplete(level) {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(level.id)")
                    .font(.rounded(17, weight: .bold))
                    .foregroundStyle(level.id == currentLevelID ? .white : .secondary)
            }
        }
        .frame(width: 40, height: 40)
    }

    private func card(for level: LearningLevel) -> some View {
        let all = terms(in: level)
        let done = masteredCount(in: level)
        let isCurrent = level.id == currentLevelID
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: NSLocalizedString("path.levelNumFmt", comment: ""),
                                level.id))
                        .font(.rounded(11, weight: .bold))
                        .foregroundStyle(AppColor.brandPrimary)
                    Text(level.nameKey)
                        .font(.rounded(19, weight: .bold))
                }
                Spacer()
                if isCurrent {
                    LexiView(pose: level.pose, size: 44, animated: false)
                }
            }
            progressBar(done: done, total: all.count,
                        tint: isComplete(level) ? AppColor.leaf : AppColor.brandPrimary)
            HStack {
                if isComplete(level) {
                    Label("path.complete", systemImage: "checkmark.seal.fill")
                        .font(.rounded(13, weight: .semibold))
                        .foregroundStyle(AppColor.leaf)
                } else {
                    Text(String(format: NSLocalizedString("path.progressFmt", comment: ""),
                                done, all.count))
                        .font(.rounded(13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isCurrent: isCurrent))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColor.brandPrimary.opacity(isCurrent ? 0.5 : 0), lineWidth: 1.5)
        )
        .foregroundStyle(.primary)
    }

    private func progressBar(done: Int, total: Int, tint: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.gray.opacity(0.15))
                Capsule().fill(tint)
                    .frame(width: total > 0
                           ? geo.size.width * CGFloat(done) / CGFloat(total)
                           : 0)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Styling

    private func nodeColor(_ level: LearningLevel) -> Color {
        if isComplete(level) { return AppColor.leaf }
        if level.id == currentLevelID { return AppColor.brandPrimary }
        return Color.gray.opacity(0.2)
    }

    private func cardBackground(isCurrent: Bool) -> Color {
        isCurrent
            ? Color.adaptive(light: "F0EBFF", dark: "2C2548")
            : AppColor.warmCard
    }

    // MARK: - Progress queries

    private func terms(in level: LearningLevel) -> [Term] {
        termStore.allTerms
            .filter { $0.difficulty == level.id }
            .sorted { $0.english.lowercased() < $1.english.lowercased() }
    }

    private func masteredCount(in level: LearningLevel) -> Int {
        terms(in: level).filter {
            progress.record(for: $0.id).status == .mastered
        }.count
    }

    private func isComplete(_ level: LearningLevel) -> Bool {
        let all = terms(in: level)
        return !all.isEmpty && masteredCount(in: level) == all.count
    }

    /// Lowest level not yet fully mastered — the learner's focus. nil = all done.
    private var currentLevelID: Int? {
        learningLevels.first { !isComplete($0) }?.id
    }

    private var allComplete: Bool { currentLevelID == nil }
}

// MARK: - Level terms list

/// The terms inside one level — reached by tapping a level card.
private struct LevelTermsList: View {
    let level: LearningLevel
    let terms: [Term]

    var body: some View {
        List(terms) { term in
            NavigationLink {
                TermDetailView(term: term)
            } label: {
                TermRow(term: term)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle(level.nameKey)
        .navigationBarTitleDisplayMode(.inline)
    }
}
