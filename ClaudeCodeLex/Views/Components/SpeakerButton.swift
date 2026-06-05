// SpeakerButton.swift  (v0.3)
// Tap = play once. Long press = open speed picker.

import SwiftUI

struct SpeakerButton: View {
    let text: String
    var size: CGFloat = 32

    @EnvironmentObject var settings: AppSettings
    @StateObject private var speech = SpeechService.shared
    @State private var showSpeedSheet = false

    private var voiceID: String {
        switch settings.voiceProvider {
        case .native:     return ""
        case .openai:     return settings.openAIVoice
        case .elevenlabs: return settings.elevenLabsVoice
        }
    }

    var body: some View {
        Button {
            if speech.isSpeaking {
                speech.stop()
            } else {
                speech.speak(text,
                             cloudProvider: settings.voiceProvider,
                             cloudVoice: voiceID)
            }
        } label: {
            ZStack {
                // Pulse ring while speaking
                if speech.isSpeaking {
                    Circle()
                        .stroke(AppColor.brandPrimary.opacity(0.4), lineWidth: 2)
                        .frame(width: size * 1.3, height: size * 1.3)
                        .scaleEffect(speech.isSpeaking ? 1.0 : 0.8)
                        .opacity(speech.isSpeaking ? 0.0 : 1.0)
                        .animation(
                            .easeOut(duration: 0.9).repeatForever(autoreverses: false),
                            value: speech.isSpeaking
                        )
                }
                Image(systemName: speech.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(AppColor.brandPrimary)
                    .clipShape(Circle())
                    .shadow(color: AppColor.brandPrimary.opacity(0.25), radius: 4, y: 2)
            }
            .frame(minWidth: 44, minHeight: 44)   // HIG: keep tap target ≥44pt even when size is 28
            .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("a11y.playPronunciation"))
        .accessibilityHint(Text("a11y.longPressForSpeed"))
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.4) {
            showSpeedSheet = true
        }
        .confirmationDialog(
            "audio.speed.label",
            isPresented: $showSpeedSheet,
            titleVisibility: .visible
        ) {
            ForEach(SpeedTier.allCases) { tier in
                Button {
                    speech.speedTier = tier
                    speech.speak(text,
                                 cloudProvider: settings.voiceProvider,
                                 cloudVoice: voiceID)
                } label: {
                    Text("\(tier.emoji)  \(NSLocalizedString("audio.speed.\(tier.rawValue)", comment: ""))")
                }
            }
            Button("common.cancel", role: .cancel) {}
        }
    }
}
