// AIDisclosureView.swift
// First-launch disclosure required by Apple Guideline 5.1.1(i) / 5.1.2(i).
// Shown before any third-party AI feature is reachable; user must agree
// before AIChatService / AIVoiceService callsites run.

import SwiftUI

enum AIConsent {
    static let storageKey = "ai_disclosure_accepted_v1"
    static let acceptedAtKey = "ai_disclosure_accepted_at_v1"

    static var isAccepted: Bool {
        UserDefaults.standard.bool(forKey: storageKey)
    }

    static func revoke() {
        UserDefaults.standard.set(false, forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: acceptedAtKey)
    }

    static var acceptedDate: Date? {
        UserDefaults.standard.object(forKey: acceptedAtKey) as? Date
    }
}

struct AIDisclosureView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void

    @Environment(\.openURL) private var openURL

    private let privacyPolicyURL = URL(string: "https://agenticlex.pages.dev")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    section(title: "aidisclosure.sec.send.title",
                            body:  "aidisclosure.sec.send.body")
                    section(title: "aidisclosure.sec.recipients.title",
                            body:  "aidisclosure.sec.recipients.body")
                    section(title: "aidisclosure.sec.purpose.title",
                            body:  "aidisclosure.sec.purpose.body")
                    section(title: "aidisclosure.sec.notSent.title",
                            body:  "aidisclosure.sec.notSent.body")
                    section(title: "aidisclosure.sec.choice.title",
                            body:  "aidisclosure.sec.choice.body")
                    privacyLink
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("aidisclosure.nav.title")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColor.brandPrimary)
            Text("aidisclosure.header.title")
                .font(.title3.weight(.semibold))
            Text("aidisclosure.header.body")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func section(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var privacyLink: some View {
        Button {
            openURL(privacyPolicyURL)
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                Text("aidisclosure.button.privacy")
                Spacer()
                Image(systemName: "arrow.up.right.square")
            }
            .font(.subheadline)
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { accept() } label: {
                Text("aidisclosure.button.agree")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button { onDecline() } label: {
                Text("aidisclosure.button.decline")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.secondary)
        }
        .padding(.top, 8)
    }

    private func accept() {
        UserDefaults.standard.set(true, forKey: AIConsent.storageKey)
        UserDefaults.standard.set(Date(), forKey: AIConsent.acceptedAtKey)
        onAccept()
    }
}

struct PrivacySettingsRow: View {
    @AppStorage(AIConsent.storageKey) private var hasAcceptedAI: Bool = false
    @State private var showConfirm: Bool = false

    var body: some View {
        HStack {
            Image(systemName: "lock.shield")
            VStack(alignment: .leading) {
                Text("aidisclosure.settings.row.title")
                Text(hasAcceptedAI
                     ? "aidisclosure.settings.status.accepted"
                     : "aidisclosure.settings.status.notAccepted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if hasAcceptedAI {
                Button("aidisclosure.settings.revoke") {
                    showConfirm = true
                }
                .tint(.red)
            }
        }
        .alert("aidisclosure.settings.confirm.title", isPresented: $showConfirm) {
            Button("aidisclosure.settings.confirm.cancel", role: .cancel) {}
            Button("aidisclosure.settings.confirm.revoke", role: .destructive) {
                AIConsent.revoke()
            }
        } message: {
            Text("aidisclosure.settings.confirm.message")
        }
    }
}

#Preview("AI Disclosure") {
    AIDisclosureView(onAccept: {}, onDecline: {})
}
