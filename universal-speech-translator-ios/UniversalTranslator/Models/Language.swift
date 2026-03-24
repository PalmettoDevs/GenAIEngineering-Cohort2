import Foundation

struct Language: Identifiable, Hashable {
    let id: String           // BCP-47 code
    let displayName: String
    let localeIdentifier: String // For Speech/TTS

    static let autoDetect = Language(
        id: "auto",
        displayName: "Auto-detect",
        localeIdentifier: ""
    )

    static let all: [Language] = [
        Language(id: "af", displayName: "Afrikaans", localeIdentifier: "af-ZA"),
        Language(id: "ar", displayName: "Arabic", localeIdentifier: "ar-SA"),
        Language(id: "bn", displayName: "Bengali", localeIdentifier: "bn-IN"),
        Language(id: "bg", displayName: "Bulgarian", localeIdentifier: "bg-BG"),
        Language(id: "ca", displayName: "Catalan", localeIdentifier: "ca-ES"),
        Language(id: "zh-CN", displayName: "Chinese (Simplified)", localeIdentifier: "zh-CN"),
        Language(id: "zh-TW", displayName: "Chinese (Traditional)", localeIdentifier: "zh-TW"),
        Language(id: "hr", displayName: "Croatian", localeIdentifier: "hr-HR"),
        Language(id: "cs", displayName: "Czech", localeIdentifier: "cs-CZ"),
        Language(id: "da", displayName: "Danish", localeIdentifier: "da-DK"),
        Language(id: "nl", displayName: "Dutch", localeIdentifier: "nl-NL"),
        Language(id: "en", displayName: "English", localeIdentifier: "en-US"),
        Language(id: "et", displayName: "Estonian", localeIdentifier: "et-EE"),
        Language(id: "fi", displayName: "Finnish", localeIdentifier: "fi-FI"),
        Language(id: "fr", displayName: "French", localeIdentifier: "fr-FR"),
        Language(id: "de", displayName: "German", localeIdentifier: "de-DE"),
        Language(id: "el", displayName: "Greek", localeIdentifier: "el-GR"),
        Language(id: "gu", displayName: "Gujarati", localeIdentifier: "gu-IN"),
        Language(id: "he", displayName: "Hebrew", localeIdentifier: "he-IL"),
        Language(id: "hi", displayName: "Hindi", localeIdentifier: "hi-IN"),
        Language(id: "hu", displayName: "Hungarian", localeIdentifier: "hu-HU"),
        Language(id: "id", displayName: "Indonesian", localeIdentifier: "id-ID"),
        Language(id: "it", displayName: "Italian", localeIdentifier: "it-IT"),
        Language(id: "ja", displayName: "Japanese", localeIdentifier: "ja-JP"),
        Language(id: "kn", displayName: "Kannada", localeIdentifier: "kn-IN"),
        Language(id: "ko", displayName: "Korean", localeIdentifier: "ko-KR"),
        Language(id: "lv", displayName: "Latvian", localeIdentifier: "lv-LV"),
        Language(id: "lt", displayName: "Lithuanian", localeIdentifier: "lt-LT"),
        Language(id: "ms", displayName: "Malay", localeIdentifier: "ms-MY"),
        Language(id: "ml", displayName: "Malayalam", localeIdentifier: "ml-IN"),
        Language(id: "mr", displayName: "Marathi", localeIdentifier: "mr-IN"),
        Language(id: "no", displayName: "Norwegian", localeIdentifier: "nb-NO"),
        Language(id: "fa", displayName: "Persian", localeIdentifier: "fa-IR"),
        Language(id: "pl", displayName: "Polish", localeIdentifier: "pl-PL"),
        Language(id: "pt", displayName: "Portuguese", localeIdentifier: "pt-BR"),
        Language(id: "pa", displayName: "Punjabi", localeIdentifier: "pa-IN"),
        Language(id: "ro", displayName: "Romanian", localeIdentifier: "ro-RO"),
        Language(id: "ru", displayName: "Russian", localeIdentifier: "ru-RU"),
        Language(id: "sr", displayName: "Serbian", localeIdentifier: "sr-RS"),
        Language(id: "sk", displayName: "Slovak", localeIdentifier: "sk-SK"),
        Language(id: "sl", displayName: "Slovenian", localeIdentifier: "sl-SI"),
        Language(id: "es", displayName: "Spanish", localeIdentifier: "es-ES"),
        Language(id: "sw", displayName: "Swahili", localeIdentifier: "sw-KE"),
        Language(id: "sv", displayName: "Swedish", localeIdentifier: "sv-SE"),
        Language(id: "ta", displayName: "Tamil", localeIdentifier: "ta-IN"),
        Language(id: "te", displayName: "Telugu", localeIdentifier: "te-IN"),
        Language(id: "th", displayName: "Thai", localeIdentifier: "th-TH"),
        Language(id: "tr", displayName: "Turkish", localeIdentifier: "tr-TR"),
        Language(id: "uk", displayName: "Ukrainian", localeIdentifier: "uk-UA"),
        Language(id: "ur", displayName: "Urdu", localeIdentifier: "ur-PK"),
        Language(id: "vi", displayName: "Vietnamese", localeIdentifier: "vi-VN"),
        Language(id: "cy", displayName: "Welsh", localeIdentifier: "cy-GB"),
    ]

    static func find(byId id: String) -> Language? {
        all.first { $0.id == id }
    }

    static func find(byCode code: String) -> Language? {
        all.first { $0.id == code || $0.id.hasPrefix(code) || $0.localeIdentifier.hasPrefix(code) }
    }

    static var english: Language {
        all.first { $0.id == "en" }!
    }
}
