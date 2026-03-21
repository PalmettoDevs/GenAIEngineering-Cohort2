import AVFoundation

/// Text-to-speech using AVSpeechSynthesizer.
class TextToSpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, languageCode: String) {
        guard !text.isEmpty else { return }

        synthesizer.stopSpeaking(at: .immediate)

        // Activate audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)

        // Find the best voice for this language
        let langId = Language.find(byId: languageCode)?.localeIdentifier ?? languageCode
        if let voice = AVSpeechSynthesisVoice(language: langId) {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: String(languageCode.prefix(2))) {
            utterance.voice = voice
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
