# Universal Speech Translator — Android

A native Android app that translates spoken words from any language to English (or any other supported language) in real time.

## Features

- **Material Design 3 (Material You)** — Dynamic color theming on Android 12+, full dark mode support
- **Real-time speech recognition** — Continuous listening via Android `SpeechRecognizer`
- **50+ languages** — Full language support with auto-detection
- **On-device translation** — Google ML Kit Translate (downloads models on demand, works offline after)
- **Online fallback** — MyMemory API when ML Kit models aren't available
- **Auto language detection** — ML Kit Language Identification identifies the spoken language
- **Text-to-speech** — Android TTS engine speaks translations in the target language
- **Translation history** — Scrollable list with tap-to-replay audio
- **Manual text input** — Type or paste text with auto-translate
- **Swap languages** — Quick source/target swap
- **Copy to clipboard** — One-tap copy of translated text

## Requirements

- Android 8.0 (API 26) or higher
- Google Play Services (for ML Kit)
- Microphone permission (requested at runtime)
- Internet connection (for initial model downloads and API fallback)

## Build & Run

1. Open the `universal-speech-translator-android` folder in **Android Studio** (Hedgehog 2023.1.1 or newer)
2. Sync Gradle dependencies
3. Connect an Android device or start an emulator
4. Click **Run** (or `./gradlew installDebug` from command line)

## Architecture

```
com.translator.universal/
├── MainActivity.kt          # Main UI, speech recognition, TTS, orchestration
├── TranslationService.kt    # ML Kit on-device translation + MyMemory API fallback
├── LanguageRepository.kt    # Language codes, names, and mappings
└── HistoryAdapter.kt        # RecyclerView adapter for translation history
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | Material Design 3 + ViewBinding |
| Speech Input | Android SpeechRecognizer |
| Translation | Google ML Kit Translate (on-device) |
| Language Detection | Google ML Kit Language ID |
| Fallback Translation | MyMemory API (free) |
| Speech Output | Android TextToSpeech |
| Networking | OkHttp 4 |
| Async | Kotlin Coroutines |

## Supported Languages

Afrikaans, Arabic, Bengali, Bulgarian, Catalan, Chinese, Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Persian, Polish, Portuguese, Punjabi, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese, Welsh
