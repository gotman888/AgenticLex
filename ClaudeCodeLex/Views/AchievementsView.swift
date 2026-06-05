// AchievementsView.swift
// Grid of badges, locked vs unlocked, with Lexi at top.

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LexiView(pose: unlockedCount > 0 ? .cheer : .read, size: 100)
                    .padding(.top, 8)
                Text("achv.title")
                    .font(.rounded(26, weight: .bold))
                Text(String(format: NSLocalizedString("achv.subtitle.fmt", comment: ""),
                            unlockedCount, Achievements.all.count))
                    .font(.rounded(14))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 12) {
                    ForEach(Achievements.all) { achv in
                        badgeCard(achv)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle("achv.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var snapshot: AchievementSnapshot {
        AchievementSnapshot(
            masteredCount: progress.records.values.filter { $0.status == .mastered }.count,
            totalTerms: termStore.allTerms.count,
            streakDays: progress.streakDays,
            nowHour: Calendar.current.component(.hour, from: Date()),
            totalTipped: settings.tipJarLifetime
        )
    }

    private var unlockedCount: Int {
        Achievements.all.filter { $0.isUnlocked(snapshot) }.count
    }

    private func badgeCard(_ achv: Achievement) -> some View {
        let unlocked = achv.isUnlocked(snapshot)
        return VStack(spacing: 8) {
            Text(achv.emoji)
                .font(.system(size: 36))
                .saturation(unlocked ? 1 : 0)
                .opacity(unlocked ? 1 : 0.35)
            Text(LocalizedStringKey(achv.titleKey))
                .font(.rounded(14, weight: .bold))
                .multilineTextAlignment(.center)
            Text(LocalizedStringKey(achv.descriptionKey))
                .font(.rounded(11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(unlocked ? AppColor.warmCard : Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(unlocked ? AppColor.cheer.opacity(0.5) : .clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
