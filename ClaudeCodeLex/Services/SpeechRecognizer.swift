// SpeechRecognizer.swift
// Wraps the Speech framework for Shadow Read — records the microphone and
// transcribes spoken English. Recognition is forced ON-DEVICE: audio never
// leaves the phone. If a device cannot recognize speech on-device the
// feature reports itself `unavailable` rather than falling back to Apple's
// servers, so the App Store privacy label stays green.

import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {

    /// Live transcript — updates with partial results while recording.
    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false
    /// True when permission was denied, or on-device recognition is
    /// unsupported on this device — Shadow Read then shows a friendly note.
    @Published private(set) var unavailable = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // MARK: - Permission

    /// Requests speech + microphone permission. Marks the feature unavailable
    /// if either is denied, or if this device can't recognize on-device.
    func requestPermission() async {
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let micOK = await withCheckedContinuation { cont in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
            }
        }
        let onDevice = recognizer?.supportsOnDeviceRecognition ?? false
        unavailable = !(speechOK && micOK && onDevice)
    }

    // MARK: - Audio session

    /// Switches to a record-capable session for the Shadow Read screen.
    func beginSession() {
        try? AVAudioSession.sharedInstance().setCategory(
            .playAndRecord, mode: .default,
            options: [.duckOthers, .defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Restores the app's default playback session (mirrors SpeechService).
    func endSession() {
        stopRecording()
        try? AVAudioSession.sharedInstance().setCategory(
            .playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - Recording

    func startRecording() {
        guard !unavailable, !isRecording else { return }
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.request = request

        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024,
                         format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            self.request = nil
            return
        }

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.finishRecognition()
                }
            }
        }
        isRecording = true
    }

    /// Ends audio capture; the final transcript arrives via the task handler.
    func stopRecording() {
        guard isRecording else { return }
        if audioEngine.isRunning { audioEngine.stop() }
        request?.endAudio()
    }

    private func finishRecognition() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        task = nil
        request = nil
        isRecording = false
    }
}
