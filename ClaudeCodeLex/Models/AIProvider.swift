// AIProvider.swift
// All AI-provider enums and metadata for BYOK (Bring Your Own Key) features.
// Adding a new provider = adding a case here + a service method.

import Foundation

// MARK: - Voice (TTS) providers

enum AIVoiceProvider: String, CaseIterable, Identifiable, Codable {
    case native      // AVSpeechSynthesizer (free, offline)
    case openai      // tts-1-hd
    case elevenlabs  // eleven_turbo_v2_5

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .native:     return "iOS Built-in"
        case .openai:     return "OpenAI TTS"
        case .elevenlabs: return "ElevenLabs"
        }
    }

    var keychainAccount: String {
        switch self {
        case .native:     return ""
        case .openai:     return "openai"
        case .elevenlabs: return "elevenlabs"
        }
    }

    /// i18n key for "~$X per word" cost hint shown under each provider card.
    var costHintKey: String {
        switch self {
        case .native:     return "ai.cost.free"
        case .openai:     return "ai.cost.openaiTTS"
        case .elevenlabs: return "ai.cost.elevenlabs"
        }
    }

    var getKeyURL: URL? {
        switch self {
        case .native:     return nil
        case .openai:     return URL(string: "https://platform.openai.com/api-keys")
        case .elevenlabs: return URL(string: "https://elevenlabs.io/app/settings/api-keys")
        }
    }

    /// Available voice names per provider (user-friendly labels).
    var voices: [VoiceOption] {
        switch self {
        case .native:
            return [VoiceOption(id: "en-US", label: "System en-US")]
        case .openai:
            return [
                VoiceOption(id: "alloy",   label: "Alloy"),
                VoiceOption(id: "echo",    label: "Echo"),
                VoiceOption(id: "fable",   label: "Fable"),
                VoiceOption(id: "onyx",    label: "Onyx"),
                VoiceOption(id: "nova",    label: "Nova (recommended)"),
                VoiceOption(id: "shimmer", label: "Shimmer")
            ]
        case .elevenlabs:
            return [
                // These are public default voices; user can find more on elevenlabs.io
                VoiceOption(id: "21m00Tcm4TlvDq8ikWAM", label: "Rachel"),
                VoiceOption(id: "AZnzlk1XvdvUeBnXmlld", label: "Domi"),
                VoiceOption(id: "EXAVITQu4vr4xnSDxMaL", label: "Bella"),
                VoiceOption(id: "ErXwobaYiN019PkySvjV", label: "Antoni"),
                VoiceOption(id: "MF3mGyEYCl7XYWbV9V6O", label: "Elli"),
                VoiceOption(id: "TxGEqnHWrfWFTfGW9XjX", label: "Josh")
            ]
        }
    }

    var defaultVoice: String { voices.first?.id ?? "" }
}

struct VoiceOption: Identifiable, Hashable {
    let id: String     // provider's voice id (used in API call)
    let label: String  // user-facing label
}

// MARK: - Chat providers (for Ask Lexi)

enum AIChatProvider: String, CaseIterable, Identifiable, Codable {
    case claude
    case openai
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Anthropic Claude"
        case .openai: return "OpenAI GPT"
        case .gemini: return "Google Gemini"
        }
    }

    var keychainAccount: String {
        switch self {
        case .claude: return "claude"
        case .openai: return "openai_chat"   // separate from TTS key
        case .gemini: return "gemini"
        }
    }

    var getKeyURL: URL? {
        switch self {
        case .claude: return URL(string: "https://console.anthropic.com/settings/keys")
        case .openai: return URL(string: "https://platform.openai.com/api-keys")
        case .gemini: return URL(string: "https://aistudio.google.com/apikey")
        }
    }

    /// Default model id per provider.
    var defaultModel: String {
        switch self {
        case .claude: return "claude-sonnet-4-6"
        case .openai: return "gpt-4o-mini"
        case .gemini: return "gemini-1.5-pro"
        }
    }

    var availableModels: [String] {
        switch self {
        case .claude: return ["claude-sonnet-4-6", "claude-opus-4-6", "claude-haiku-4-5-20251001"]
        case .openai: return ["gpt-4o-mini", "gpt-4o", "gpt-4.1"]
        case .gemini: return ["gemini-1.5-pro", "gemini-1.5-flash"]
        }
    }
}
