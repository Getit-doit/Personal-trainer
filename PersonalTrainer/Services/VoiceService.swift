import Foundation
import AVFoundation
import Speech

/// Hands-free voice for the in-workout coach: dictation (speech→text) so you can
/// ask without typing, and spoken replies (text→speech). Everything degrades
/// gracefully — if permission is denied or the recognizer is unavailable, the
/// chat still works by typing.
@MainActor
final class VoiceService: NSObject, ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isListening = false
    @Published private(set) var isSpeaking = false
    /// User toggle: read the coach's replies aloud.
    @Published var speakReplies = true
    /// Whether dictation is usable (authorized + recognizer available).
    @Published private(set) var dictationAvailable = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: Authorization

    /// Ask for speech + mic permission. Safe to call repeatedly.
    func requestAuthorization() async {
        let speech = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        dictationAvailable = speech && mic && (recognizer?.isAvailable ?? false)
    }

    // MARK: Dictation

    /// Start live transcription. Updates `transcript` as you speak.
    func startListening() {
        guard dictationAvailable, !isListening, let recognizer, recognizer.isAvailable else { return }
        stopSpeaking()   // don't transcribe our own voice
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        // Capture the request locally so the audio-thread closure doesn't touch
        // main-actor state.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do { try audioEngine.start() } catch { cleanupAudio(); return }
        isListening = true

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || (result?.isFinal ?? false) { self.stopListening() }
            }
        }
    }

    /// Stop transcription and return the final transcript.
    func stopListening() {
        guard isListening else { return }
        audioEngine.stop()
        request?.endAudio()
        task?.cancel()
        cleanupAudio()
        isListening = false
        if !isSpeaking { restoreOtherAudio() }   // bring the music back up
    }

    private func cleanupAudio() {
        audioEngine.inputNode.removeTap(onBus: 0)
        request = nil
        task = nil
    }

    /// Deactivate our session so any ducked audio (e.g. Apple Music) returns to
    /// full volume.
    private func restoreOtherAudio() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: Text to speech

    func speak(_ text: String) {
        guard speakReplies, !text.isEmpty else { return }
        // Make sure we can play even right after recording.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        isSpeaking = false
        if !isListening { restoreOtherAudio() }
    }

    func reset() {
        stopListening()
        stopSpeaking()
        transcript = ""
    }
}

extension VoiceService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = true }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            if !self.isListening { self.restoreOtherAudio() }
        }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            if !self.isListening { self.restoreOtherAudio() }
        }
    }
}
