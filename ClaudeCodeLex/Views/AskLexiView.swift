// AskLexiView.swift
// Conversation with Lexi about a specific term, powered by user's own AI key.
// Only accessible when settings.chatProvider != nil AND the key is in Keychain.

import SwiftUI

struct AskLexiView: View {
    let term: Term

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var termStore: TermStore
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var isSending: Bool = false
    @State private var errorText: String?
    /// The assistant reply currently streaming in, before it lands in `messages`.
    @State private var streaming: ChatMessage?

    /// Quick-prompt chips that auto-fill input for one-tap questions.
    private let quickPrompts: [(label: LocalizedStringKey, prompt: String)] = [
        ("askLexi.qp.eli5",       "Explain this term like I'm 5, but accurately."),
        ("askLexi.qp.examples",   "Give me 3 short real examples of using this term in Claude Code."),
        ("askLexi.qp.code",       "Show me a tiny code example that uses this concept."),
        ("askLexi.qp.compare",    "What's commonly confused with this term, and how do I tell them apart?")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Divider()
                conversation
                Divider()
                quickPromptsBar
                inputBar
            }
            .background(AppColor.warmBg.ignoresSafeArea())
            .navigationTitle("askLexi.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .alert("askLexi.errorTitle",
                   isPresented: Binding(
                        get: { errorText != nil },
                        set: { if !$0 { errorText = nil } }
                   )) {
                Button("common.ok") { errorText = nil }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            LexiView(pose: .read, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(term.english)
                    .font(.rounded(18, weight: .bold))
                if let provider = settings.chatProvider {
                    Text("askLexi.poweredBy.\(provider.rawValue)")
                        .font(.rounded(11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if messages.isEmpty {
                        emptyBubble
                    }
                    ForEach(messages) { msg in
                        bubble(for: msg).id(msg.id)
                    }
                    if let s = streaming {
                        bubble(for: s).id(s.id)
                    }
                    if isSending && streaming == nil {
                        thinkingBubble
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: streaming?.content) { _ in
                if let s = streaming {
                    proxy.scrollTo(s.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                LexiView(pose: .wave, size: 36, animated: false)
                Text("askLexi.intro")
                    .font(.rounded(15))
                    .padding(12)
                    .background(AppColor.warmCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func bubble(for msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .assistant {
                LexiView(pose: .read, size: 28, animated: false)
                Text(msg.content)
                    .font(.rounded(15))
                    .padding(12)
                    .background(AppColor.warmCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 280, alignment: .leading)
                Spacer(minLength: 8)
            } else {
                Spacer(minLength: 8)
                Text(msg.content)
                    .font(.rounded(15))
                    .padding(12)
                    .background(AppColor.brandPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(maxWidth: 280, alignment: .trailing)
            }
        }
    }

    private var thinkingBubble: some View {
        HStack {
            LexiView(pose: .read, size: 28)
            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(AppColor.brandPrimary.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(12)
            .background(AppColor.warmCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
    }

    // MARK: - Quick prompts

    private var quickPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.prompt) { qp in
                    Button {
                        send(qp.prompt)
                    } label: {
                        Text(qp.label)
                            .font(.rounded(12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColor.brandPrimary.opacity(0.12))
                            .foregroundStyle(AppColor.brandPrimary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("askLexi.inputPlaceholder", text: $input, axis: .vertical)
                .font(.rounded(15))
                .lineLimit(1...4)
                .padding(10)
                .background(Color.adaptive(light: "FFFFFF", dark: "2A2630"))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            Button {
                send(input)
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(AppColor.brandPrimary)
                    .clipShape(Circle())
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
            .opacity(input.trimmingCharacters(in: .whitespaces).isEmpty || isSending ? 0.4 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .padding(.top, 6)
    }

    // MARK: - Logic

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let provider = settings.chatProvider else { return }
        input = ""
        messages.append(ChatMessage(role: .user, content: trimmed))
        isSending = true
        streaming = nil

        // Snapshot history before streaming — the in-progress reply must not
        // be sent back to the API.
        let historyForAPI = messages
        let model: String
        switch provider {
        case .claude: model = settings.claudeModel
        case .openai: model = settings.openAIChatModel
        case .gemini: model = settings.geminiModel
        }
        let systemPrompt = AIChatService.systemPrompt(term: term,
                                                       locale: settings.nativeLanguage)

        Task {
            var buffer = streaming?.content ?? ""
            let streamID = streaming?.id ?? UUID()
            var lastUI = Date.distantPast
            do {
                for try await delta in AIChatService.stream(
                    provider: provider,
                    model: model,
                    system: systemPrompt,
                    history: historyForAPI
                ) {
                    buffer += delta   // local accumulate: O(n) total vs re-reading @State each token (O(n²))
                    if Date().timeIntervalSince(lastUI) > 0.06 {   // coalesce UI + scrollTo to ~16fps
                        lastUI = Date()
                        let snapshot = buffer
                        await MainActor.run {
                            streaming = ChatMessage(id: streamID, role: .assistant, content: snapshot)
                        }
                    }
                }
                let finalText = buffer
                await MainActor.run {
                    streaming = ChatMessage(id: streamID, role: .assistant, content: finalText)
                    finishStreaming(error: nil)
                }
            } catch {
                // Keep the partial reply already received before surfacing the error
                // (deltas accumulated since the last throttle tick are still in buffer).
                let finalText = buffer
                await MainActor.run {
                    if !finalText.isEmpty {
                        streaming = ChatMessage(id: streamID, role: .assistant, content: finalText)
                    }
                    finishStreaming(error: error)
                }
            }
        }
    }

    /// Commits any streamed text into the message list and clears transient state.
    private func finishStreaming(error: Error?) {
        isSending = false
        if let s = streaming, !s.content.isEmpty {
            messages.append(s)
        }
        streaming = nil
        if let error = error {
            errorText = error.localizedDescription
        }
    }
}
