import Foundation
import NaturalLanguage

/// Translation service with two strategies:
/// 1. Apple Translation framework (iOS 17.4+, on-device)
/// 2. MyMemory API fallback (free, no key required)
actor TranslationService {

    struct TranslationResult {
        let translatedText: String
        let detectedLanguage: String?
    }

    private let session = URLSession.shared

    // MARK: - Language Detection (NaturalLanguage framework)

    nonisolated func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage else { return nil }
        return lang.rawValue
    }

    // MARK: - Translate

    func translate(text: String, from sourceLang: String, to targetLang: String) async -> TranslationResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TranslationResult(translatedText: "", detectedLanguage: nil)
        }

        var detectedLang: String?
        let srcCode: String

        if sourceLang == "auto" {
            let detected = detectLanguage(for: text)
            detectedLang = detected
            srcCode = detected ?? "en"
        } else {
            srcCode = sourceLang
        }

        // Same language
        if srcCode == targetLang {
            return TranslationResult(translatedText: text, detectedLanguage: detectedLang)
        }

        // Try MyMemory API (works everywhere, no framework version requirements)
        do {
            let result = try await translateWithAPI(text: text, from: srcCode, to: targetLang)
            return TranslationResult(translatedText: result, detectedLanguage: detectedLang)
        } catch {
            return TranslationResult(
                translatedText: "Translation failed. Check your connection.",
                detectedLanguage: detectedLang
            )
        }
    }

    // MARK: - MyMemory API

    private func translateWithAPI(text: String, from src: String, to tgt: String) async throws -> String {
        let srcNorm = normalizeCode(src)
        let tgtNorm = normalizeCode(tgt)

        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw TranslationError.encodingFailed
        }

        let urlString = "https://api.mymemory.translated.net/get?q=\(encoded)&langpair=\(srcNorm)|\(tgtNorm)"
        guard let url = URL(string: urlString) else {
            throw TranslationError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TranslationError.serverError
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseData = json["responseData"] as? [String: Any],
              let translated = responseData["translatedText"] as? String else {
            throw TranslationError.parsingFailed
        }

        return translated
    }

    private func normalizeCode(_ code: String) -> String {
        switch code {
        case "zh-CN": return "zh"
        case "zh-TW": return "zh-TW"
        default: return String(code.prefix(2))
        }
    }

    enum TranslationError: Error {
        case encodingFailed
        case invalidURL
        case serverError
        case parsingFailed
    }
}
