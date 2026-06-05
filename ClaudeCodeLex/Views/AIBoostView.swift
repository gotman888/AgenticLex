// AIBoostView.swift
// Settings → AI Boost subpage.
// Lets the user paste their own API keys to upgrade Voice and enable Ask Lexi.
//
// Apple compliance:
//   - We never link to a provider's pricing/checkout page (only their API-keys page).
//   - Keys stored in Keychain via KeychainHelper. Never sent to AgenticLex.
//   - First time toggling on, we show a one-time disclosure.

import SwiftUI

struct AIBoostView: View {
    @EnvironmentObject var settings: AppSettings

    @State private var showDisclosure = false

    var body: some View {
        Form {
            // Intro
            Section {
                HStack(spacing: 12) {
                    LexiView(pose: .wizard, size: 60, animated: false)
                    Text("aiboost.intro")
                        .font(.rounded(14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            // ---- Voice ----
            Section {
                ForEach(AIVoiceProvider.allCases) { provider in
                    VoiceProviderRow(provider: provider)
                }
            } header: {
                Text("aiboost.voice.section")
            } footer: {
                Text("aiboost.voice.footer")
            }

            // ---- Chat (Ask Lexi) ----
            Section {
                ForEach(AIChatProvider.allCases) { provider in
                    ChatProviderRow(provider: provider)
                }
            } header: {
                Text("aiboost.chat.section")
            } footer: {
                Text("aiboost.chat.footer")
            }

            // ---- Privacy ----
            Section {
                Label {
                    Text("aiboost.privacy")
                        .font(.rounded(12))
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("aiboost.title")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.warmBg.ignoresSafeArea())
        .onAppear {
            if !settings.byokDisclosureShown {
                showDisclosure = true
            }
        }
        .alert("aiboost.disclosure.title",
               isPresented: $showDisclosure) {
            Button("common.ok") {
                settings.byokDisclosureShown = true
            }
        } message: {
            Text("aiboost.disclosure.body")
        }
    }
}

// MARK: - Voice Provider Row

struct VoiceProviderRow: View {
    let provider: AIVoiceProvider
    @EnvironmentObject var settings: AppSettings

    @State private var inputKey: String = ""
    @State private var savedKey: String?
    @State private var testStatus: TestStatus = .idle

    enum TestStatus { case idle, testing, ok, failed }

    private var isActive: Bool { settings.voiceProvider == provider }
    private var hasKey: Bool { !(savedKey ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Text(provider.displayName)
                    .font(.rounded(15, weight: .semibold))
                Spacer()
                if provider == .native {
                    Text("aiboost.free").font(.caption).foregroundStyle(.green)
                }
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { on in
                        if on {
                            settings.voiceProvider = provider
                        } else if isActive {
                            settings.voiceProvider = .native
                        }
                    }
                ))
                .labelsHidden()
                .disabled(provider != .native && !hasKey)
            }

            if provider != .native {
                // API key field
                HStack {
                    Image(systemName: "key.fill").foregroundStyle(.secondary)
                    SecureField(
                        savedKey.map(KeychainHelper.redacted) ?? NSLocalizedString("aiboost.keyPlaceholder", comment: ""),
                        text: $inputKey
                    )
                    .font(.rounded(13))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    Button("aiboost.save") {
                        saveKey()
                    }
                    .disabled(inputKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(AppColor.brandPrimary)
                    if hasKey {
                        Button {
                            deleteKey()
                        } label: {
                            Image(systemName: "trash").foregroundStyle(.red)
                        }
                    }
                }

                // Voice picker
                Picker("aiboost.voicePicker", selection: voiceBinding) {
                    ForEach(provider.voices) { v in
                        Text(v.label).tag(v.id)
                    }
                }
                .font(.rounded(13))

                // Cost hint + Get key link
                HStack {
                    Text(LocalizedStringKey(provider.costHintKey))
                        .font(.rounded(11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let url = provider.getKeyURL {
                        Link(destination: url) {
                            Label("aiboost.getKey", systemImage: "arrow.up.right.square")
                                .font(.rounded(11))
                        }
                    }
                }

                // Test button (only useful if there's a key)
                if hasKey {
                    Button {
                        runTest()
                    } label: {
                        HStack {
                            Image(systemName: testIcon)
                                .foregroundStyle(testColor)
                            Text(testLabel)
                                .font(.rounded(12, weight: .medium))
                        }
                    }
                    .disabled(testStatus == .testing)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            savedKey = provider == .native
                ? nil
                : KeychainHelper.read(account: provider.keychainAccount)
        }
    }

    private var voiceBinding: Binding<String> {
        switch provider {
        case .openai:     return $settings.openAIVoice
        case .elevenlabs: return $settings.elevenLabsVoice
        default:          return .constant("")
        }
    }

    private func saveKey() {
        let trimmed = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if KeychainHelper.save(trimmed, account: provider.keychainAccount) {
            savedKey = trimmed
            inputKey = ""
        }
    }

    private func deleteKey() {
        KeychainHelper.delete(account: provider.keychainAccount)
        savedKey = nil
        if isActive { settings.voiceProvider = .native }
    }

    private func runTest() {
        testStatus = .testing
        let voice = voiceBinding.wrappedValue
        Task {
            do {
                _ = try await {
                    switch provider {
                    case .openai:
                        return try await AIVoiceService.openAI(text: "Slash Command", voice: voice)
                    case .elevenlabs:
                        return try await AIVoiceService.elevenLabs(text: "Slash Command", voiceID: voice)
                    case .native:
                        throw AIVoiceError.missingKey
                    }
                }()
                await MainActor.run { testStatus = .ok }
            } catch {
                await MainActor.run { testStatus = .failed }
            }
        }
    }

    private var testIcon: String {
        switch testStatus {
        case .idle:    return "play.circle"
        case .testing: return "hourglass"
        case .ok:      return "checkmark.circle.fill"
        case .failed:  return "exclamationmark.circle"
        }
    }
    private var testColor: Color {
        switch testStatus {
        case .ok:     return AppColor.leaf
        case .failed: return AppColor.hug
        default:      return AppColor.brandPrimary
        }
    }
    private var testLabel: LocalizedStringKey {
        switch testStatus {
        case .idle:    return "aiboost.test"
        case .testing: return "aiboost.testing"
        case .ok:      return "aiboost.testOK"
        case .failed:  return "aiboost.testFailed"
        }
    }
}

// MARK: - Chat Provider Row

struct ChatProviderRow: View {
    let provider: AIChatProvider
    @EnvironmentObject var settings: AppSettings

    @State private var inputKey: String = ""
    @State private var savedKey: String?

    private var isActive: Bool { settings.chatProvider == provider }
    private var hasKey: Bool { !(savedKey ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(provider.displayName)
                    .font(.rounded(15, weight: .semibold))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { on in
                        if on { settings.chatProvider = provider }
                        else if isActive { settings.chatProvider = nil }
                    }
                ))
                .labelsHidden()
                .disabled(!hasKey)
            }

            // Key input
            HStack {
                Image(systemName: "key.fill").foregroundStyle(.secondary)
                SecureField(
                    savedKey.map(KeychainHelper.redacted) ?? NSLocalizedString("aiboost.keyPlaceholder", comment: ""),
                    text: $inputKey
                )
                .font(.rounded(13))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button("aiboost.save") {
                    let trimmed = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty,
                       KeychainHelper.save(trimmed, account: provider.keychainAccount) {
                        savedKey = trimmed
                        inputKey = ""
                    }
                }
                .disabled(inputKey.isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(AppColor.brandPrimary)
                if hasKey {
                    Button {
                        KeychainHelper.delete(account: provider.keychainAccount)
                        savedKey = nil
                        if isActive { settings.chatProvider = nil }
                    } label: {
                        Image(systemName: "trash").foregroundStyle(.red)
                    }
                }
            }

            // Model picker
            Picker("aiboost.modelPicker", selection: modelBinding) {
                ForEach(provider.availableModels, id: \.self) { m in
                    Text(m).tag(m)
                }
            }
            .font(.rounded(13))

            // Get key link
            if let url = provider.getKeyURL {
                Link(destination: url) {
                    Label("aiboost.getKey", systemImage: "arrow.up.right.square")
                        .font(.rounded(11))
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            savedKey = KeychainHelper.read(account: provider.keychainAccount)
        }
    }

    private var modelBinding: Binding<String> {
        switch provider {
        case .claude: return $settings.claudeModel
        case .openai: return $settings.openAIChatModel
        case .gemini: return $settings.geminiModel
        }
    }
}
