// AIChatService.swift
// Unified streaming chat completion across Claude / OpenAI / Gemini.
// Called from AskLexiView when user has configured a chat key.
//
// All requests go DIRECTLY from device to provider — no AgenticLex server in the path.
// Replies stream token-by-token over SSE (Server-Sent Events).

import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let role: Role
    let content: String

    init(id: UUID = UUID(), role: Role, content: String) {
        self.id = id; self.role = role; self.content = content
    }

    enum Role: String, Codable { case user, assistant, system }
}

enum AIChatError: LocalizedError {
    case missingKey
    case http(Int, String)
    case decode
    case consentRevoked

    var errorDescription: String? {
        switch self {
        case .missingKey:        return "API key not configured"
        case .http(let c, let m): return "HTTP \(c): \(m)"
        case .decode:            return "Could not decode response"
        case .consentRevoked:    return NSLocalizedString("aidisclosure.error.notConsented",
                                                          comment: "AI consent not granted")
        }
    }
}

enum AIChatService {

    /// Build a system prompt that turns the LLM into Lexi for a specific term.
    static func systemPrompt(term: Term, locale: String) -> String {
        """
        You are Lexi, a friendly purple owl-bot tutor inside AgenticLex,
        an iOS app teaching Claude Code / agentic-coding terminology to
        non-native English speakers.

        Right now the user is studying the term: "\(term.english)".
        Category: \(term.category). Difficulty: \(term.difficulty)/3.

        Rules:
        - Respond in the user's language: \(locale).
        - Keep responses under ~150 words unless they ask for code.
        - Use real Claude Code / Cursor / Cline examples where useful.
        - Be warm, encouraging, never condescending.
        - If asked something off-topic, gently bring it back to the term.
        - Sign off occasionally with 🦉 but don't overdo it.
        """
    }

    /// Streams the assistant reply as text deltas, dispatching to the right
    /// provider. The stream finishes when the reply is complete, or finishes
    /// with an error (`AIChatError`) on failure.
    static func stream(provider: AIChatProvider,
                       model: String,
                       system: String,
                       history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    // Apple Guideline 5.1.1(i): no third-party AI traffic without consent.
                    guard AIConsent.isAccepted else { throw AIChatError.consentRevoked }
                    let onDelta: (String) -> Void = { continuation.yield($0) }
                    switch provider {
                    case .claude:
                        try await streamClaude(model: model, system: system,
                                               history: history, onDelta: onDelta)
                    case .openai:
                        try await streamOpenAI(model: model, system: system,
                                               history: history, onDelta: onDelta)
                    case .gemini:
                        try await streamGemini(model: model, system: system,
                                               history: history, onDelta: onDelta)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - SSE helpers

    /// Extracts the payload of an SSE `data:` line, or nil for other lines.
    private static func sseData(_ line: String) -> String? {
        guard line.hasPrefix("data:") else { return nil }
        let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        return payload.isEmpty ? nil : payload
    }

    private static func jsonObject(_ s: String) -> [String: Any]? {
        guard let d = s.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
    }

    /// Throws `.http` on a non-2xx response, draining the body for its message.
    private static func checkStatus(_ resp: URLResponse,
                                    bytes: URLSession.AsyncBytes) async throws {
        guard let http = resp as? HTTPURLResponse else { throw AIChatError.decode }
        guard !(200..<300).contains(http.statusCode) else { return }
        var body = ""
        for try await line in bytes.lines { body += line }
        throw AIChatError.http(http.statusCode, body.isEmpty ? "error" : body)
    }

    // MARK: - Anthropic Claude

    private static func streamClaude(model: String, system: String,
                                     history: [ChatMessage],
                                     onDelta: (String) -> Void) async throws {
        guard let key = KeychainHelper.read(account: AIChatProvider.claude.keychainAccount),
              !key.isEmpty else { throw AIChatError.missingKey }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        let messages = history.filter { $0.role != .system }.map {
            ["role": $0.role.rawValue, "content": $0.content]
        }
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": messages,
            "stream": true
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        try await checkStatus(resp, bytes: bytes)

        // Events: content_block_delta carries { delta: { type: text_delta, text } }.
        for try await line in bytes.lines {
            guard let payload = sseData(line), let json = jsonObject(payload) else { continue }
            if json["type"] as? String == "content_block_delta",
               let delta = json["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                onDelta(text)
            }
        }
    }

    // MARK: - OpenAI Chat Completions

    private static func streamOpenAI(model: String, system: String,
                                     history: [ChatMessage],
                                     onDelta: (String) -> Void) async throws {
        guard let key = KeychainHelper.read(account: AIChatProvider.openai.keychainAccount),
              !key.isEmpty else { throw AIChatError.missingKey }
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        var msgs: [[String: String]] = [["role": "system", "content": system]]
        for m in history where m.role != .system {
            msgs.append(["role": m.role.rawValue, "content": m.content])
        }
        let body: [String: Any] = [
            "model": model,
            "messages": msgs,
            "max_tokens": 1024,
            "stream": true
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        try await checkStatus(resp, bytes: bytes)

        // Events: { choices: [{ delta: { content } }] }, terminated by [DONE].
        for try await line in bytes.lines {
            guard let payload = sseData(line) else { continue }
            if payload == "[DONE]" { break }
            guard let json = jsonObject(payload),
                  let choices = json["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let text = delta["content"] as? String
            else { continue }
            onDelta(text)
        }
    }

    // MARK: - Google Gemini

    private static func streamGemini(model: String, system: String,
                                     history: [ChatMessage],
                                     onDelta: (String) -> Void) async throws {
        guard let key = KeychainHelper.read(account: AIChatProvider.gemini.keychainAccount),
              !key.isEmpty else { throw AIChatError.missingKey }
        var comps = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent")
        comps?.queryItems = [
            URLQueryItem(name: "alt", value: "sse"),
            URLQueryItem(name: "key", value: key)   // percent-encoded; no force-unwrap on a pasted key
        ]
        guard let url = comps?.url else { throw AIChatError.missingKey }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 60

        var contents: [[String: Any]] = []
        for m in history where m.role != .system {
            contents.append([
                "role": m.role == .user ? "user" : "model",
                "parts": [["text": m.content]]
            ])
        }
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": system]]],
            "contents": contents,
            "generationConfig": ["maxOutputTokens": 1024]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        try await checkStatus(resp, bytes: bytes)

        // Events: { candidates: [{ content: { parts: [{ text }] } }] }.
        for try await line in bytes.lines {
            guard let payload = sseData(line), let json = jsonObject(payload) else { continue }
            guard let candidates = json["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]]
            else { continue }
            for p in parts {
                if let t = p["text"] as? String { onDelta(t) }
            }
        }
    }
}
