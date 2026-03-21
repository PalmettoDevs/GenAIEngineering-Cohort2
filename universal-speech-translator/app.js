// ============================================================
// Universal Speech Translator
// Real-time speech recognition, translation, and text-to-speech
// Uses: Web Speech API + MyMemory Translation API
// ============================================================

const LANGUAGES = [
    { code: 'af', name: 'Afrikaans' },
    { code: 'ar', name: 'Arabic' },
    { code: 'bn', name: 'Bengali' },
    { code: 'bg', name: 'Bulgarian' },
    { code: 'ca', name: 'Catalan' },
    { code: 'zh-CN', name: 'Chinese (Simplified)' },
    { code: 'zh-TW', name: 'Chinese (Traditional)' },
    { code: 'hr', name: 'Croatian' },
    { code: 'cs', name: 'Czech' },
    { code: 'da', name: 'Danish' },
    { code: 'nl', name: 'Dutch' },
    { code: 'en', name: 'English' },
    { code: 'et', name: 'Estonian' },
    { code: 'fi', name: 'Finnish' },
    { code: 'fr', name: 'French' },
    { code: 'de', name: 'German' },
    { code: 'el', name: 'Greek' },
    { code: 'gu', name: 'Gujarati' },
    { code: 'he', name: 'Hebrew' },
    { code: 'hi', name: 'Hindi' },
    { code: 'hu', name: 'Hungarian' },
    { code: 'id', name: 'Indonesian' },
    { code: 'it', name: 'Italian' },
    { code: 'ja', name: 'Japanese' },
    { code: 'kn', name: 'Kannada' },
    { code: 'ko', name: 'Korean' },
    { code: 'lv', name: 'Latvian' },
    { code: 'lt', name: 'Lithuanian' },
    { code: 'ms', name: 'Malay' },
    { code: 'ml', name: 'Malayalam' },
    { code: 'mr', name: 'Marathi' },
    { code: 'no', name: 'Norwegian' },
    { code: 'fa', name: 'Persian' },
    { code: 'pl', name: 'Polish' },
    { code: 'pt', name: 'Portuguese' },
    { code: 'pa', name: 'Punjabi' },
    { code: 'ro', name: 'Romanian' },
    { code: 'ru', name: 'Russian' },
    { code: 'sr', name: 'Serbian' },
    { code: 'sk', name: 'Slovak' },
    { code: 'sl', name: 'Slovenian' },
    { code: 'es', name: 'Spanish' },
    { code: 'sw', name: 'Swahili' },
    { code: 'sv', name: 'Swedish' },
    { code: 'ta', name: 'Tamil' },
    { code: 'te', name: 'Telugu' },
    { code: 'th', name: 'Thai' },
    { code: 'tr', name: 'Turkish' },
    { code: 'uk', name: 'Ukrainian' },
    { code: 'ur', name: 'Urdu' },
    { code: 'vi', name: 'Vietnamese' },
    { code: 'cy', name: 'Welsh' },
];

// DOM Elements
const sourceLangSelect = document.getElementById('source-lang');
const targetLangSelect = document.getElementById('target-lang');
const sourceText = document.getElementById('source-text');
const targetText = document.getElementById('target-text');
const micBtn = document.getElementById('mic-btn');
const micStatus = document.getElementById('mic-status');
const detectedLang = document.getElementById('detected-lang');
const swapBtn = document.getElementById('swap-btn');
const speakBtn = document.getElementById('speak-translation');
const copyBtn = document.getElementById('copy-translation');
const clearBtn = document.getElementById('clear-source');
const historyList = document.getElementById('history-list');

// State
let recognition = null;
let isListening = false;
let finalTranscript = '';
let translationTimeout = null;
let autoSpeakEnabled = true;

// ============================================================
// Initialize
// ============================================================
function init() {
    populateLanguageSelects();
    setupSpeechRecognition();
    setupEventListeners();
}

function populateLanguageSelects() {
    // Source language: keep "Auto-detect" as first option
    LANGUAGES.forEach(lang => {
        const opt = document.createElement('option');
        opt.value = lang.code;
        opt.textContent = lang.name;
        sourceLangSelect.appendChild(opt);
    });

    // Target language: replace default with full list, default to English
    targetLangSelect.innerHTML = '';
    LANGUAGES.forEach(lang => {
        const opt = document.createElement('option');
        opt.value = lang.code;
        opt.textContent = lang.name;
        if (lang.code === 'en') opt.selected = true;
        targetLangSelect.appendChild(opt);
    });
}

// ============================================================
// Speech Recognition (Web Speech API)
// ============================================================
function setupSpeechRecognition() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;

    if (!SpeechRecognition) {
        micBtn.disabled = true;
        micStatus.textContent = 'Speech recognition not supported in this browser. Try Chrome or Edge.';
        return;
    }

    recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;

    recognition.onstart = () => {
        isListening = true;
        micBtn.classList.add('listening');
        micStatus.textContent = 'Listening... Speak now';
        micStatus.classList.add('active');
    };

    recognition.onresult = (event) => {
        let interimTranscript = '';

        for (let i = event.resultIndex; i < event.results.length; i++) {
            const transcript = event.results[i][0].transcript;
            if (event.results[i].isFinal) {
                finalTranscript += transcript + ' ';
                // Translate after each final result
                triggerTranslation(finalTranscript.trim());
            } else {
                interimTranscript += transcript;
            }
        }

        // Display both final and interim text
        sourceText.innerHTML = escapeHtml(finalTranscript) +
            (interimTranscript ? `<span class="interim">${escapeHtml(interimTranscript)}</span>` : '');

        // Detect language from recognition if available
        if (event.results[0] && event.results[0][0]) {
            updateDetectedLanguage(event.results[0]);
        }
    };

    recognition.onerror = (event) => {
        if (event.error === 'no-speech') {
            micStatus.textContent = 'No speech detected. Try again.';
        } else if (event.error === 'not-allowed') {
            micStatus.textContent = 'Microphone access denied. Please allow microphone access.';
        } else {
            micStatus.textContent = `Error: ${event.error}`;
        }
        stopListening();
    };

    recognition.onend = () => {
        // Auto-restart if still in listening mode
        if (isListening) {
            try {
                recognition.start();
            } catch (e) {
                stopListening();
            }
        }
    };
}

function startListening() {
    if (!recognition) return;

    finalTranscript = '';
    sourceText.textContent = '';
    targetText.textContent = '';

    // Set the recognition language
    const srcLang = sourceLangSelect.value;
    if (srcLang !== 'auto') {
        recognition.lang = srcLang;
    } else {
        // Let the browser auto-detect
        recognition.lang = '';
    }

    try {
        recognition.start();
    } catch (e) {
        // Already started
    }
}

function stopListening() {
    isListening = false;
    micBtn.classList.remove('listening');
    micStatus.textContent = 'Click microphone to start';
    micStatus.classList.remove('active');

    if (recognition) {
        try {
            recognition.stop();
        } catch (e) {
            // Already stopped
        }
    }
}

function toggleListening() {
    if (isListening) {
        stopListening();
    } else {
        startListening();
    }
}

// ============================================================
// Translation (MyMemory API - free, no key required)
// ============================================================
function triggerTranslation(text) {
    clearTimeout(translationTimeout);
    // Debounce translation requests (300ms)
    translationTimeout = setTimeout(() => translateText(text), 300);
}

async function translateText(text) {
    if (!text.trim()) return;

    const srcLang = sourceLangSelect.value === 'auto' ? 'auto' : sourceLangSelect.value;
    const tgtLang = targetLangSelect.value;

    // Don't translate if source and target are the same
    if (srcLang === tgtLang && srcLang !== 'auto') {
        targetText.textContent = text;
        return;
    }

    // Map language codes for MyMemory API (uses ISO format like "en|es")
    const srcCode = srcLang === 'auto' ? 'auto' : normalizeCode(srcLang);
    const tgtCode = normalizeCode(tgtLang);
    const langPair = `${srcCode}|${tgtCode}`;

    try {
        const url = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${langPair}`;
        const response = await fetch(url);
        const data = await response.json();

        if (data.responseStatus === 200 && data.responseData) {
            const translated = data.responseData.translatedText;
            targetText.textContent = translated;

            // Update detected language if auto-detect
            if (srcLang === 'auto' && data.responseData.detectedLanguage) {
                const detected = data.responseData.detectedLanguage;
                const langName = LANGUAGES.find(l =>
                    normalizeCode(l.code) === detected ||
                    l.code.startsWith(detected)
                );
                if (langName) {
                    detectedLang.textContent = `Detected: ${langName.name}`;
                }
            }

            // Auto-speak the translation
            if (autoSpeakEnabled && !isListening) {
                speakText(translated, tgtLang);
            }

            // Add to history
            addToHistory(text, translated, srcLang, tgtLang);
        } else {
            // Fallback: try with simpler language codes
            targetText.textContent = data.responseData?.translatedText || 'Translation unavailable';
        }
    } catch (error) {
        console.error('Translation error:', error);
        targetText.textContent = 'Translation failed. Check your connection.';
    }
}

function normalizeCode(code) {
    // MyMemory uses simple 2-letter codes; map special ones
    const map = {
        'zh-CN': 'zh',
        'zh-TW': 'zh-TW',
        'auto': 'auto',
    };
    return map[code] || code.split('-')[0];
}

// ============================================================
// Text-to-Speech (Web Speech Synthesis API)
// ============================================================
function speakText(text, langCode) {
    if (!text || !window.speechSynthesis) return;

    // Cancel any ongoing speech
    window.speechSynthesis.cancel();

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = langCode;
    utterance.rate = 0.9;
    utterance.pitch = 1;

    // Try to find a voice matching the target language
    const voices = window.speechSynthesis.getVoices();
    const matchingVoice = voices.find(v => v.lang.startsWith(langCode)) ||
                          voices.find(v => v.lang.startsWith(langCode.split('-')[0]));
    if (matchingVoice) {
        utterance.voice = matchingVoice;
    }

    window.speechSynthesis.speak(utterance);
}

// Pre-load voices
if (window.speechSynthesis) {
    window.speechSynthesis.onvoiceschanged = () => {
        window.speechSynthesis.getVoices();
    };
}

// ============================================================
// Translation History
// ============================================================
function addToHistory(original, translated, srcLang, tgtLang) {
    const item = document.createElement('div');
    item.className = 'history-item';

    const srcName = srcLang === 'auto' ? 'Auto' :
        (LANGUAGES.find(l => l.code === srcLang)?.name || srcLang);
    const tgtName = LANGUAGES.find(l => l.code === tgtLang)?.name || tgtLang;

    item.innerHTML = `
        <span class="original" title="${srcName}">${escapeHtml(truncate(original, 60))}</span>
        <span class="arrow">&rarr;</span>
        <span class="translated" title="${tgtName}">${escapeHtml(truncate(translated, 60))}</span>
    `;

    // Add click to re-speak
    item.addEventListener('click', () => speakText(translated, tgtLang));
    item.style.cursor = 'pointer';
    item.title = 'Click to hear translation';

    historyList.prepend(item);

    // Keep only last 20 entries
    while (historyList.children.length > 20) {
        historyList.removeChild(historyList.lastChild);
    }
}

// ============================================================
// Event Listeners
// ============================================================
function setupEventListeners() {
    micBtn.addEventListener('click', toggleListening);

    swapBtn.addEventListener('click', () => {
        const srcVal = sourceLangSelect.value;
        const tgtVal = targetLangSelect.value;

        if (srcVal === 'auto') return; // Can't swap auto-detect

        sourceLangSelect.value = tgtVal;
        targetLangSelect.value = srcVal;

        // Swap text content too
        const srcText = sourceText.textContent;
        const tgtText = targetText.textContent;
        sourceText.textContent = tgtText;
        targetText.textContent = srcText;
        finalTranscript = tgtText;
    });

    speakBtn.addEventListener('click', () => {
        const text = targetText.textContent;
        if (text) speakText(text, targetLangSelect.value);
    });

    copyBtn.addEventListener('click', () => {
        const text = targetText.textContent;
        if (text) {
            navigator.clipboard.writeText(text).then(() => {
                copyBtn.textContent = '\u2713';
                setTimeout(() => { copyBtn.innerHTML = '&#128203;'; }, 1500);
            });
        }
    });

    clearBtn.addEventListener('click', () => {
        sourceText.textContent = '';
        targetText.textContent = '';
        detectedLang.textContent = '';
        finalTranscript = '';
    });

    // Allow manual text entry + translate
    let manualTimeout;
    sourceText.addEventListener('input', () => {
        if (!isListening) {
            clearTimeout(manualTimeout);
            manualTimeout = setTimeout(() => {
                finalTranscript = sourceText.textContent;
                triggerTranslation(finalTranscript);
            }, 500);
        }
    });

    // Keyboard shortcut: Space to toggle mic
    document.addEventListener('keydown', (e) => {
        if (e.code === 'Space' && document.activeElement === document.body) {
            e.preventDefault();
            toggleListening();
        }
    });
}

// ============================================================
// Utilities
// ============================================================
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function truncate(text, maxLen) {
    return text.length > maxLen ? text.substring(0, maxLen) + '...' : text;
}

function updateDetectedLanguage(result) {
    if (sourceLangSelect.value !== 'auto') return;
    // The Web Speech API doesn't directly expose detected language,
    // but the translation API response will update it
}

// ============================================================
// Start the app
// ============================================================
init();
