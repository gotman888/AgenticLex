// AIVoicePlayer.swift
// Plays mp3 Data from cloud TTS.
// Shares AVAudioSession with SpeechService so background playback works.

import AVFoundation
import Combine
import MediaPlayer

@MainActor
final class AIVoicePlayer: NSObject, ObservableObject {
    static let shared = AIVoicePlayer()

    @Published private(set) var isPlaying: Bool = false
    private var player: AVAudioPlayer?

    private override init() { super.init() }

    func play(_ data: Data, displayTitle: String = "") {
        stop()
        do {
            // Reuse the playback category set by SpeechService
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(data: data)
            p.delegate = self
            p.prepareToPlay()
            p.play()
            player = p
            isPlaying = true

            // Lock-screen "Now Playing"
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle:      displayTitle,
                MPMediaItemPropertyArtist:     "AgenticLex (cloud voice)",
                MPNowPlayingInfoPropertyPlaybackRate: 1.0
            ]
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

extension AIVoicePlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                                 successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
}
