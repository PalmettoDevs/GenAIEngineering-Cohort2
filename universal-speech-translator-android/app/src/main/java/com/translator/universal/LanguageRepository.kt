package com.translator.universal

/**
 * Language data and mappings for speech recognition, translation, and TTS.
 */
object LanguageRepository {

    data class Language(
        val code: String,       // BCP-47 code for SpeechRecognizer / TTS
        val mlKitCode: String,  // ML Kit TranslateLanguage code
        val displayName: String
    )

    // Auto-detect sentinel
    val AUTO_DETECT = Language("auto", "auto", "Auto-detect")

    val languages: List<Language> = listOf(
        Language("af", "af", "Afrikaans"),
        Language("ar", "ar", "Arabic"),
        Language("bn", "bn", "Bengali"),
        Language("bg", "bg", "Bulgarian"),
        Language("ca", "ca", "Catalan"),
        Language("zh-CN", "zh", "Chinese (Simplified)"),
        Language("hr", "hr", "Croatian"),
        Language("cs", "cs", "Czech"),
        Language("da", "da", "Danish"),
        Language("nl", "nl", "Dutch"),
        Language("en", "en", "English"),
        Language("et", "et", "Estonian"),
        Language("fi", "fi", "Finnish"),
        Language("fr", "fr", "French"),
        Language("de", "de", "German"),
        Language("el", "el", "Greek"),
        Language("gu", "gu", "Gujarati"),
        Language("he", "he", "Hebrew"),
        Language("hi", "hi", "Hindi"),
        Language("hu", "hu", "Hungarian"),
        Language("id", "id", "Indonesian"),
        Language("it", "it", "Italian"),
        Language("ja", "ja", "Japanese"),
        Language("kn", "kn", "Kannada"),
        Language("ko", "ko", "Korean"),
        Language("lv", "lv", "Latvian"),
        Language("lt", "lt", "Lithuanian"),
        Language("ms", "ms", "Malay"),
        Language("ml", "ml", "Malayalam"),
        Language("mr", "mr", "Marathi"),
        Language("no", "no", "Norwegian"),
        Language("fa", "fa", "Persian"),
        Language("pl", "pl", "Polish"),
        Language("pt", "pt", "Portuguese"),
        Language("pa", "pa", "Punjabi"),
        Language("ro", "ro", "Romanian"),
        Language("ru", "ru", "Russian"),
        Language("sr", "sr", "Serbian"),
        Language("sk", "sk", "Slovak"),
        Language("sl", "sl", "Slovenian"),
        Language("es", "es", "Spanish"),
        Language("sw", "sw", "Swahili"),
        Language("sv", "sv", "Swedish"),
        Language("ta", "ta", "Tamil"),
        Language("te", "te", "Telugu"),
        Language("th", "th", "Thai"),
        Language("tr", "tr", "Turkish"),
        Language("uk", "uk", "Ukrainian"),
        Language("ur", "ur", "Urdu"),
        Language("vi", "vi", "Vietnamese"),
        Language("cy", "cy", "Welsh"),
    )

    /** All language names for dropdown, with Auto-detect prepended for source. */
    val sourceDisplayNames: List<String> =
        listOf(AUTO_DETECT.displayName) + languages.map { it.displayName }

    val targetDisplayNames: List<String> =
        languages.map { it.displayName }

    /** Find a Language by display name. */
    fun findByDisplayName(name: String): Language? =
        if (name == AUTO_DETECT.displayName) AUTO_DETECT
        else languages.find { it.displayName == name }

    /** Find a Language by its BCP-47 code or ML Kit code. */
    fun findByCode(code: String): Language? =
        languages.find { it.code == code || it.mlKitCode == code || it.code.startsWith(code) }

    /** Default target language index in targetDisplayNames. */
    val defaultTargetIndex: Int get() = languages.indexOfFirst { it.code == "en" }
}
