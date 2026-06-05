// TermDetailView.swift
// Big term hero + translation/example/memory-hook + related chips.

import SwiftUI

struct TermDetailView: View {
    let term: Term

    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var progress: ProgressStore
    @EnvironmentObject var settings: AppSettings
    @StateObject private var speech = SpeechService.shared
    @State private var showAskLexi = false
    @State private var shareImage: Image?
    @State private var showReportMail = false
    @Environment(\.openURL) private var openURL

    private var translation: LocalizedTranslation {
        termStore.translation(for: term.id, locale: settings.nativeLanguage)
    }

    /// Ask Lexi button only appears when user has configured a chat provider + key.
    private var canAskLexi: Bool {
        guard let p = settings.chatProvider else { return false }
        return KeychainHelper.read(account: p.keychainAccount)?.isEmpty == false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                translationBlock
                exampleBlock
                if let real = translation.realUse, !real.isEmpty {
                    realUseBlock(real)
                }
                if let hook = translation.memoryHook, !hook.isEmpty {
                    memoryHookBlock(hook)
                }
                if let conf = translation.commonConfusion, !conf.isEmpty {
                    commonConfusionBlock(conf)
                }
                if canAskLexi {
                    askLexiButton
                }
                relatedBlock
                if !term.relatedTerms.isEmpty {
                    conceptMapLink
                }
                actionBar
                reportButton
            }
            .padding(20)
        }
        .navigationTitle(term.english)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let img = shareImage {
                    ShareLink(item: img,
                              preview: SharePreview("AgenticLex · \(term.english)", image: img)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text("detail.share"))
                }
            }
        }
        .onAppear {
            renderShareCard()
            if settings.autoPlayOnOpen {
                let voice: String = {
                    switch settings.voiceProvider {
                    case .native:     return ""
                    case .openai:     return settings.openAIVoice
                    case .elevenlabs: return settings.elevenLabsVoice
                    }
                }()
                speech.speak(term.english,
                             cloudProvider: settings.voiceProvider,
                             cloudVoice: voice)
            }
        }
        .onDisappear { speech.stop() }
        .sheet(isPresented: $showAskLexi) {
            AskLexiView(term: term)
                .environmentObject(settings)
                .environmentObject(termStore)
        }
        .sheet(isPresented: $showReportMail) {
            MailComposer(subject: reportSubject, body: reportBody)
        }
    }

    /// Builds the shareable card image once, off the term + current locale.
    private func renderShareCard() {
        let catName = termStore.main?.categories
            .first(where: { $0.id == term.category })?
            .name(for: settings.uiLanguage) ?? term.category
        let card = ShareCardView(term: term, translation: translation, category: catName)
        if let ui = card.renderImage() {
            shareImage = Image(uiImage: ui)
        }
    }

    private var askLexiButton: some View {
        Button {
            showAskLexi = true
        } label: {
            HStack {
                LexiView(pose: .wave, size: 36, animated: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text("askLexi.button.title")
                        .font(.rounded(15, weight: .bold))
                    Text("askLexi.button.hint")
                        .font(.rounded(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.adaptive(light: "F0EBFF", dark: "2C2548"),
                             Color.adaptive(light: "E5DDFF", dark: "241E3C")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                CategoryChip(
                    label: termStore.main?.categories
                        .first(where: { $0.id == term.category })?
                        .name(for: settings.uiLanguage) ?? term.category,
                    selected: false,
                    action: {}
                )
                .allowsHitTesting(false)
                Spacer()
            }

            Text(term.english)
                .font(.rounded(56, weight: .bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)

            if term.isEnglishOnly {
                Label("term.englishOnly.note", systemImage: "globe")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }

            if let ipa = term.pronunciation {
                Text(ipa)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            SpeakerButton(text: term.english, size: 64)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.adaptive(light: "F6F4FF", dark: "2A2440"),
                         Color.adaptive(light: "ECE6FF", dark: "221C38")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var translationBlock: some View {
        Block(label: NSLocalizedString("detail.translation", comment: ""),
              tint: Color.adaptive(light: "F6F4FF", dark: "221C38")) {
            Text(translation.term)
                .font(.rounded(22, weight: .bold))
            if translation.status == .ai {
                aiBadge
            }
            Text(translation.definition)
                .font(.body)
                .padding(.top, 4)
        }
    }

    private var exampleBlock: some View {
        Block(label: NSLocalizedString("detail.example", comment: "")) {
            Text(translation.example)
                .font(.body)
                .padding(.top, 2)
        }
    }

    private func memoryHookBlock(_ hook: String) -> some View {
        Block(
            label: "💡 " + NSLocalizedString("detail.memoryHook", comment: ""),
            tint: Color.adaptive(light: "FFF7EA", dark: "2E2718")
        ) {
            Text(hook)
                .font(.body)
                .foregroundStyle(Color.adaptive(light: "92590F", dark: "E9C583"))
        }
    }

    private func realUseBlock(_ text: String) -> some View {
        Block(label: NSLocalizedString("detail.realUse", comment: "")) {
            Text(text)
                .font(.body)
                .padding(.top, 2)
        }
    }

    private func commonConfusionBlock(_ text: String) -> some View {
        Block(
            label: "⚠️ " + NSLocalizedString("detail.commonConfusion", comment: ""),
            tint: Color.adaptive(light: "FFF1EC", dark: "30231C")
        ) {
            Text(text)
                .font(.body)
                .foregroundStyle(Color.adaptive(light: "8A4B2E", dark: "E8AD8C"))
        }
    }

    private var relatedBlock: some View {
        Block(label: NSLocalizedString("detail.related", comment: "")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(term.relatedTerms, id: \.self) { id in
                        if let t = termStore.term(by: id) {
                            NavigationLink(value: t) {
                                CategoryChip(label: t.english, selected: false, action: {})
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
        }
    }

    /// Entry to the walkable relationship graph centered on this term.
    private var conceptMapLink: some View {
        NavigationLink {
            ConceptMapView(focus: term)
        } label: {
            HStack {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColor.brandPrimary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("conceptMap.title")
                        .font(.rounded(15, weight: .bold))
                    Text("conceptMap.hint")
                        .font(.rounded(12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.adaptive(light: "F0EBFF", dark: "2C2548"),
                             Color.adaptive(light: "E5DDFF", dark: "241E3C")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var aiBadge: some View {
        Label("detail.aiTranslation", systemImage: "sparkles")
            .font(.caption2)
            .foregroundStyle(AppColor.brandSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColor.brandSecondary.opacity(0.14))
            .clipShape(Capsule())
            .padding(.top, 2)
    }

    private var reportButton: some View {
        Button {
            if MailComposer.canSend {
                showReportMail = true
            } else if let u = FeedbackMail.mailtoURL(subject: reportSubject, body: reportBody) {
                openURL(u)
            }
        } label: {
            Label("detail.report", systemImage: "exclamationmark.bubble")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private var reportSubject: String {
        NSLocalizedString("feedback.subject", comment: "") + " · \(term.english) [\(term.id)]"
    }

    private var reportBody: String {
        let intro = NSLocalizedString("report.intro", comment: "")
        let snapshot = """


        — term —
        \(term.english) [\(term.id)] · locale \(settings.nativeLanguage)
        current: \(translation.term)
        status: \(translation.status.rawValue), by: \(translation.translator ?? "?")
        """
        return "\n\n" + intro + snapshot
            + FeedbackMail.context(settings: settings, dictVersion: termStore.main?.metadata.version)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                progress.toggleFavorite(term.id)
            } label: {
                Label(
                    progress.isFavorite(term.id) ? "detail.unfav" : "detail.fav",
                    systemImage: progress.isFavorite(term.id) ? "star.fill" : "star"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)

            Button {
                progress.mark(termId: term.id, correct: true)
            } label: {
                Label("detail.markMastered", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.brandPrimary)
        }
        .padding(.top, 8)
    }
}
