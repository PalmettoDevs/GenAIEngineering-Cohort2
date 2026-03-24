import Foundation
import Speech
import AVFoundation

/// Real-time speech recognition using Apple's Speech framework.
class SpeechRecognitionService: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var partialTranscript = ""
    @Published var detectedLocale: String?
    @Published var error: String?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    var onFinalResult: ((String) -> Void)?

    // MARK: - Permissions

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            await MainActor.run {
                error = "Speech recognition permission denied"
            }
            return false
        }

        let audioStatus: Bool
        if #available(iOS 17.0, *) {
            audioStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            audioStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard audioStatus else {
            await MainActor.run {
                error = "Microphone permission denied"
            }
            return false
        }

        return true
    }

    // MARK: - Start/Stop

    func startListening(locale: Locale?) {
        stopListening()

        let recognizerLocale = locale ?? Locale.current
        speechRecognizer = SFSpeechRecognizer(locale: recognizerLocale)

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognition not available for this language"
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true

        // On-device recognition when available (iOS 13+)
        if speechRecognizer.supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = false // Allow cloud for better accuracy
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    if result.isFinal {
                        self.transcript = text
                        self.partialTranscript = ""
                        self.onFinalResult?(text)

                        // Auto-restart for continuous listening
                        if self.isListening {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if self.isListening {
                                    let loc = locale
                                    self.startListening(locale: loc)
                                }
                            }
                        }
                    } else {
                        self.partialTranscript = text
                    }
                }
            }

            if let error {
                let nsError = error as NSError
                // Ignore "no speech detected" restarts
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    DispatchQueue.main.async {
                        if self.isListening {
                            self.startListening(locale: locale)
                        }
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.stopListening()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.error = nil
            }
        } catch {
            self.error = "Audio engine error: \(error.localizedDescription)"
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isListening = false
        }

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
