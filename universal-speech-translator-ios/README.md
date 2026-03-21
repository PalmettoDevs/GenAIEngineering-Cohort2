# Universal Speech Translator — iOS

A native iOS app built with SwiftUI that translates spoken words from any language to English (or any other supported language) in real time.

## Features

- **SwiftUI + iOS 17** — Modern declarative UI with NavigationStack, sensory feedback, and the latest Apple design patterns
- **Real-time speech recognition** — Continuous listening via Apple's Speech framework (`SFSpeechRecognizer`)
- **50+ languages** — Full language support with auto-detection
- **On-device language detection** — Apple NaturalLanguage framework identifies the spoken language
- **Online translation** — MyMemory API (free, no key required)
- **Text-to-speech** — `AVSpeechSynthesizer` speaks translations in the target language
- **Translation history** — Scrollable list with tap-to-replay audio
- **Manual text input** — Type or paste text with auto-translate (debounced)
- **Swap languages** — Quick source/target swap with spring animation
- **Copy to clipboard** — One-tap copy with toast confirmation
- **Dark mode** — Fully supports system light/dark appearance
- **Haptic feedback** — Sensory feedback on mic toggle

## Requirements

- iOS 17.0 or higher
- iPhone with microphone
- Internet connection (for translation API)
- Xcode 15.0 or newer

## Build & Run

1. Open `universal-speech-translator-ios` in **Xcode** (15.0+)
2. Select your target device or simulator
3. Click **Run** (Cmd+R)

> **Note**: Speech recognition requires a physical device for best results. The simulator has limited speech recognition support.

## Architecture

```
UniversalTranslator/
├── App/
│   └── UniversalTranslatorApp.swift       # App entry point
├── Models/
│   ├── Language.swift                      # 50+ language definitions
│   └── HistoryItem.swift                   # Translation history model
├── Services/
│   ├── SpeechRecognitionService.swift      # Apple Speech framework wrapper
│   ├── TranslationService.swift            # MyMemory API translation
│   ├── TextToSpeechService.swift           # AVSpeechSynthesizer wrapper
│   └── TranslatorViewModel.swift           # Main MVVM view model
├── Views/
│   ├── ContentView.swift                   # Main screen layout
│   ├── LanguagePickerView.swift            # Searchable language picker sheet
│   └── HistoryItemView.swift               # History list item
└── Resources/
    └── Info.plist                           # Privacy permissions
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | SwiftUI (iOS 17) |
| Architecture | MVVM with Combine |
| Speech Input | Apple Speech Framework (`SFSpeechRecognizer`) |
| Language Detection | Apple NaturalLanguage (`NLLanguageRecognizer`) |
| Translation | MyMemory API (free) |
| Speech Output | AVFoundation (`AVSpeechSynthesizer`) |
| Concurrency | Swift async/await + Combine |

## Privacy Permissions

The app requests two permissions at launch:
- **Microphone** — Required for capturing speech
- **Speech Recognition** — Required for converting speech to text

Both permissions include clear descriptions in `Info.plist` explaining why they're needed.

## Supported Languages

Afrikaans, Arabic, Bengali, Bulgarian, Catalan, Chinese (Simplified), Chinese (Traditional), Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Persian, Polish, Portuguese, Punjabi, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese, Welsh
