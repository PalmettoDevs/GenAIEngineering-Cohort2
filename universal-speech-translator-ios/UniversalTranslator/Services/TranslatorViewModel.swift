import Foundation
import Combine
import SwiftUI

/// Main view model that orchestrates speech recognition, translation, and TTS.
@MainActor
class TranslatorViewModel: ObservableObject {

    // MARK: - Published State

    @Published var sourceLanguage: Language = .autoDetect
    @Published var targetLanguage: Language = .english
    @Published var sourceText: String = ""
    @Published var translatedText: String = ""
    @Published var detectedLanguageName: String?
    @Published var isListening: Bool = false
    @Published var isTranslating: Bool = false
    @Published var errorMessage: String?
    @Published var history: [HistoryItem] = []
    @Published var permissionsGranted: Bool = false

    // MARK: - Services

    let speechService = SpeechRecognitionService()
    private let translationService = TranslationService()
    private let ttsService = TextToSpeechService()

    private var translationTask: Task<Void, Never>?
    private var textDebounceTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        setupSpeechCallbacks()
        setupTextObserver()
    }

    // MARK: - Permissions

    func requestPermissions() async {
        permissionsGranted = await speechService.requestPermissions()
    }

    // MARK: - Speech Recognition

    private func setupSpeechCallbacks() {
        speechService.onFinalResult = { [weak self] text in
            guard let self else { return }
            Task { @MainActor in
                self.sourceText = text
                self.triggerTranslation(text: text)
            }
        }

        // Observe partial results for live display
        speechService.$partialTranscript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] partial in
                guard let self, self.isListening, !partial.isEmpty else { return }
                self.sourceText = partial
            }
            .store(in: &cancellables)

        speechService.$isListening
            .receive(on: DispatchQueue.main)
            .assign(to: &$isListening)

        speechService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] err in
                self?.errorMessage = err
            }
            .store(in: &cancellables)
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    func startListening() {
        sourceText = ""
        translatedText = ""
        detectedLanguageName = nil

        let locale: Locale?
        if sourceLanguage.id == "auto" {
            locale = nil
        } else {
            locale = Locale(identifier: sourceLanguage.localeIdentifier)
        }

        speechService.startListening(locale: locale)
    }

    func stopListening() {
        speechService.stopListening()
        // Translate whatever we have
        if !sourceText.isEmpty {
            triggerTranslation(text: sourceText)
        }
    }

    // MARK: - Manual Text Input Observer

    private func setupTextObserver() {
        $sourceText
            .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self, !self.isListening, !text.isEmpty else { return }
                self.triggerTranslation(text: text)
            }
            .store(in: &cancellables)
    }

    // MARK: - Translation

    func triggerTranslation(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        translationTask?.cancel()
        translationTask = Task {
            isTranslating = true
            defer { isTranslating = false }

            let result = await translationService.translate(
                text: text,
                from: sourceLanguage.id,
                to: targetLanguage.id
            )

            guard !Task.isCancelled else { return }

            translatedText = result.translatedText

            if let detected = result.detectedLanguage {
                detectedLanguageName = Language.find(byCode: detected)?.displayName
            }

            // Auto-speak when not listening
            if !isListening && !result.translatedText.isEmpty {
                speakTranslation()
            }

            // Add to history
            if !result.translatedText.isEmpty && result.translatedText != text {
                let item = HistoryItem(
                    original: text,
                    translated: result.translatedText,
                    sourceLang: sourceLanguage.id == "auto" ? (result.detectedLanguage ?? "auto") : sourceLanguage.id,
                    targetLang: targetLanguage.id
                )
                history.insert(item, at: 0)
                if history.count > 20 { history.removeLast() }
            }
        }
    }

    // MARK: - TTS

    func speakTranslation() {
        guard !translatedText.isEmpty else { return }
        ttsService.speak(text: translatedText, languageCode: targetLanguage.id)
    }

    func speakHistoryItem(_ item: HistoryItem) {
        ttsService.speak(text: item.translated, languageCode: item.targetLang)
    }

    // MARK: - Actions

    func swapLanguages() {
        guard sourceLanguage.id != "auto" else { return }
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }

    func clearAll() {
        sourceText = ""
        translatedText = ""
        detectedLanguageName = nil
        ttsService.stop()
    }

    func copyTranslation() {
        UIPasteboard.general.string = translatedText
    }
}
