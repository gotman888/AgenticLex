// AIVoiceService.swift
// Cloud TTS via user-provided API keys (BYOK).
// Returns raw mp3 Data; the caller hands it to AIVoicePlayer.
//
// Free fallback (AVSpeechSynthesizer) lives in SpeechService.
// This service is ONLY called when the user has explicitly enabled a cloud provider
// and saved a valid key.

import Foundation

enum AIVoiceError: LocalizedError {
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

enum AIVoiceService {

    // MARK: - OpenAI TTS

    /// Calls https://api.openai.com/v1/audio/speech
    /// Returns mp3 bytes. Throws AIVoiceError on failure.
    static func openAI(text: String, voice: String) async throws -> Data {
        guard AIConsent.isAccepted else { throw AIVoiceError.consentRevoked }
        guard let apiKey = KeychainHelper.read(account: AIVoiceProvider.openai.keychainAccount),
              !apiKey.isEmpty else { throw AIVoiceError.missingKey }

        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "tts-1-hd",
            "input": text,
            "voice": voice,
            "response_format": "mp3"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 15

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AIVoiceError.decode }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "error"
            throw AIVoiceError.http(http.statusCode, msg)
        }
        return data
    }

    // MARK: - ElevenLabs

    /// Calls https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
    /// `eleven_turbo_v2_5` is the fast, multi-lingual model.
    static func elevenLabs(text: String, voiceID: String) async throws -> Data {
        guard AIConsent.isAccepted else { throw AIVoiceError.consentRevoked }
        guard let apiKey = KeychainHelper.read(account: AIVoiceProvider.elevenlabs.keychainAccount),
              !apiKey.isEmpty else { throw AIVoiceError.missingKey }

        var req = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)")!)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_turbo_v2_5",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "style": 0.0,
                "use_speaker_boost": true
            ]
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 15

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AIVoiceError.decode }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "error"
            throw AIVoiceError.http(http.statusCode, msg)
        }
        return data
    }
}
