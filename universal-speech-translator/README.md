# Universal Speech Translator

A real-time universal speech translator that listens to spoken words in **any language** and translates them to English or any other supported language — instantly.

## Features

- **Real-time speech recognition** — Uses the Web Speech API to capture spoken words continuously
- **Auto-detect language** — Automatically identifies the language being spoken
- **50+ languages supported** — Translate between dozens of languages including English, Spanish, French, German, Chinese, Japanese, Hindi, Arabic, and many more
- **Text-to-speech output** — Hear the translated text spoken aloud in the target language
- **Manual text input** — Type or paste text to translate (no microphone needed)
- **Translation history** — Review past translations, click to replay audio
- **Swap languages** — Quickly swap source and target languages
- **Copy to clipboard** — One-click copy of translated text
- **Keyboard shortcut** — Press Space to toggle the microphone
- **No API key required** — Uses free MyMemory Translation API
- **No install needed** — Pure HTML/CSS/JS, runs in any modern browser

## How to Use

1. **Open `index.html`** in Chrome or Edge (these browsers support the Web Speech API)
2. **Select languages** — Choose the source language (or leave on Auto-detect) and the target language
3. **Click the microphone button** (or press Space) to start listening
4. **Speak** — Your words will appear in real-time and be translated automatically
5. **Click the speaker icon** to hear the translation spoken aloud

## Supported Languages

Afrikaans, Arabic, Bengali, Bulgarian, Catalan, Chinese (Simplified & Traditional), Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French, German, Greek, Gujarati, Hebrew, Hindi, Hungarian, Indonesian, Italian, Japanese, Kannada, Korean, Latvian, Lithuanian, Malay, Malayalam, Marathi, Norwegian, Persian, Polish, Portuguese, Punjabi, Romanian, Russian, Serbian, Slovak, Slovenian, Spanish, Swahili, Swedish, Tamil, Telugu, Thai, Turkish, Ukrainian, Urdu, Vietnamese, Welsh

## Technical Stack

- **Speech Recognition**: Web Speech API (`SpeechRecognition`)
- **Translation**: [MyMemory Translation API](https://mymemory.translated.net/) (free, no API key)
- **Text-to-Speech**: Web Speech Synthesis API (`SpeechSynthesisUtterance`)
- **Frontend**: Vanilla HTML5, CSS3, JavaScript (no frameworks or dependencies)

## Browser Support

| Browser | Speech Recognition | Translation | Text-to-Speech |
|---------|-------------------|-------------|----------------|
| Chrome  | Full              | Full        | Full           |
| Edge    | Full              | Full        | Full           |
| Firefox | Not supported     | Full        | Full           |
| Safari  | Partial           | Full        | Full           |

> **Note**: For the best experience, use **Google Chrome** or **Microsoft Edge** as they have the most complete Web Speech API support.
