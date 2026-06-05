// SpeechService.swift  (v0.3)
// Thin wrapper over AVSpeechSynthesizer.
// New in v0.3:
//   - SpeedTier enum (slow / normal / fast)
//   - repeat N times
//   - Listen Mode: queued continuous playback with locale alternation
//   - Background audio (requires UIBackgroundModes = audio in Info.plist)
//   - Now Playing lock-screen integration (MPNowPlayingInfoCenter)
//
// Free, offline, no API key.

import AVFoundation
import Combine
import MediaPlayer

enum SpeedTier: String, CaseIterable, Codable, Identifiable {
    case slow   // 🐢 練聽辨
    case normal // 🚶 預設
    case fast   // 🏃 練流暢

    var id: String { rawValue }

    var rate: Float {
        switch self {
        case .slow:   return AVSpeechUtteranceDefaultSpeechRate * 0.65
        case .normal: return AVSpeechUtteranceDefaultSpeechRate * 0.90
        case .fast:   return AVSpeechUtteranceDefaultSpeechRate * 1.10
        }
    }

    var emoji: String {
        switch self {
        case .slow:   return "🐢"
        case .normal: return "🚶"
        case .fast:   return "🏃"
        }
    }
}

/// One playback item — used by Listen Mode queue.
struct SpokenItem {
    let text: String
    let language: String          // "en-US", "zh-TW", etc.
    let termId: String?           // optional reference back to source term
    let postDelay: TimeInterval   // pause after this item
}

@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()

    // MARK: - Published

    @Published private(set) var isSpeaking: Bool = false
    @Published private(set) var currentItemText: String = ""
    // Intentionally NOT @Published: no view reads it (the karaoke IPA highlight
    // was never built). Publishing it fired objectWillChange on every word
    // boundary, re-rendering every visible SpeakerButton for nothing.
    private(set) var currentRange: NSRange = NSRange(location: 0, length: 0)
    @Published var speedTier: SpeedTier = .normal
    @Published private(set) var listenModeActive: Bool = false
    @Published private(set) var listenIndex: Int = 0
    @Published private(set) var listenTotal: Int = 0

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    private var queue: [SpokenItem] = []
    private var repeatCount: Int = 1
    private var repeatRemaining: Int = 0
    private var lastItem: SpokenItem?

    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        configureRemoteCommands()
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Public API: single-shot

    /// Speak a single term once at current speed.
    /// If a cloud provider is enabled in settings, will try cloud first and
    /// fall back to AVSpeechSynthesizer on failure.
    func speak(_ text: String, language: String = "en-US",
               cloudProvider: AIVoiceProvider = .native,
               cloudVoice: String = "") {
        stop()
        if cloudProvider == .native || !language.hasPrefix("en") {
            // Native path (or non-English text — cloud TTS not needed for translation playback)
            repeatCount = 1
            repeatRemaining = 1
            let item = SpokenItem(text: text, language: language, termId: nil, postDelay: 0)
            enqueueAndStart([item])
        } else {
            Task { await speakCloud(text, provider: cloudProvider, voice: cloudVoice, language: language) }
        }
    }

    /// Cloud-TTS path. Falls back to native on any error.
    private func speakCloud(_ text: String, provider: AIVoiceProvider,
                            voice: String, language: String) async {
        isSpeaking = true
        currentItemText = text
        do {
            let data: Data
            switch provider {
            case .openai:
                data = try await AIVoiceService.openAI(text: text, voice: voice)
            case .elevenlabs:
                data = try await AIVoiceService.elevenLabs(text: text, voiceID: voice)
            case .native:
                return // already handled above
            }
            AIVoicePlayer.shared.play(data, displayTitle: text)
            // We rely on AIVoicePlayer's delegate to clear isPlaying.
            // Mirror that here for UI consistency:
            Task { @MainActor in
                while AIVoicePlayer.shared.isPlaying {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                isSpeaking = false
                currentItemText = ""
            }
        } catch {
            // Fallback to native — user still hears the word
            isSpeaking = false
            let item = SpokenItem(text: text, language: language, termId: nil, postDelay: 0)
            enqueueAndStart([item])
        }
    }

    /// Speak a term N times (repeat for memorization).
    func speakRepeated(_ text: String, times: Int, language: String = "en-US") {
        stop()
        repeatCount = max(1, times)
        repeatRemaining = repeatCount
        let item = SpokenItem(text: text, language: language, termId: nil, postDelay: 0.6)
        enqueueAndStart([item])
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        queue.removeAll()
        repeatRemaining = 0
        listenModeActive = false
        clearNowPlaying()
    }

    // MARK: - Public API: Listen Mode

    /// Play a queue of items continuously. Each item is followed by `postDelay` silence.
    /// Use case: a list of N terms, each with en + native translation alternating.
    func startListenMode(_ items: [SpokenItem]) {
        stop()
        guard !items.isEmpty else { return }
        listenModeActive = true
        listenIndex = 0
        listenTotal = items.count
        queue = items
        repeatCount = 1
        repeatRemaining = 1
        speakNext()
    }

    // MARK: - Internals

    private func enqueueAndStart(_ items: [SpokenItem]) {
        queue.append(contentsOf: items)
        speakNext()
    }

    private func speakNext() {
        guard let item = queue.first else {
            // Empty queue: maybe still need to repeat last item
            if repeatRemaining > 1, let last = lastItem {
                repeatRemaining -= 1
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(last.postDelay * 1_000_000_000))
                    queue.append(last)
                    speakNext()
                }
            } else {
                isSpeaking = false
                listenModeActive = false
                clearNowPlaying()
            }
            return
        }
        queue.removeFirst()
        lastItem = item
        speak(item)
    }

    private func speak(_ item: SpokenItem) {
        currentItemText = item.text
        currentRange = NSRange(location: 0, length: 0)
        let utterance = AVSpeechUtterance(string: item.text)
        utterance.voice = AVSpeechSynthesisVoice(language: item.language)
            ?? AVSpeechSynthesisVoice(language: "en-US")
        // Rate by tier — but only for the English (en-*) utterances; keep native locale at normal
        utterance.rate = item.language.hasPrefix("en") ? speedTier.rate : SpeedTier.normal.rate
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = item.postDelay
        synthesizer.speak(utterance)
        updateNowPlaying(item)
    }

    // MARK: - Now Playing (lock-screen)

    private func updateNowPlaying(_ item: SpokenItem) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.text,
            MPMediaItemPropertyArtist: "AgenticLex",
            MPMediaItemPropertyAlbumTitle: listenModeActive
                ? "Listen Mode · \(listenIndex + 1)/\(listenTotal)"
                : "Pronunciation"
        ]
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { _ in
            // No-op resume yet (TTS does not pause cleanly). Future: split.
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.stop() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipCurrent() }
            return .success
        }
    }

    func skipCurrent() {
        synthesizer.stopSpeaking(at: .immediate)
        // delegate will fire didFinish → next item
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       willSpeakRangeOfSpeechString range: NSRange,
                                       utterance: AVSpeechUtterance) {
        // For karaoke-style IPA highlight
        Task { @MainActor in self.currentRange = range }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentRange = NSRange(location: 0, length: 0)
            // Listen mode bookkeeping
            if self.listenModeActive {
                self.listenIndex = min(self.listenIndex + 1, self.listenTotal)
            }
            self.speakNext()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                       didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.currentRange = NSRange(location: 0, length: 0)
            // Don't auto-continue on user-initiated cancel
        }
    }
}
