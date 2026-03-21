package com.translator.universal

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.ArrayAdapter
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.color.DynamicColors
import com.google.android.material.snackbar.Snackbar
import com.translator.universal.databinding.ActivityMainBinding
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Locale

class MainActivity : AppCompatActivity(), TextToSpeech.OnInitListener {

    private lateinit var binding: ActivityMainBinding

    // Services
    private var speechRecognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private val translationService = TranslationService()

    // State
    private var isListening = false
    private var finalTranscript = ""
    private var translationJob: Job? = null
    private val historyItems = mutableListOf<HistoryItem>()
    private lateinit var historyAdapter: HistoryAdapter

    // Permission launcher
    private val micPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) toggleListening() else showSnackbar(getString(R.string.mic_permission_required))
    }

    // =========================================================
    // Lifecycle
    // =========================================================
    override fun onCreate(savedInstanceState: Bundle?) {
        // Apply Material You dynamic colors if available (Android 12+)
        DynamicColors.applyToActivityIfAvailable(this)
        super.onCreate(savedInstanceState)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupLanguageDropdowns()
        setupHistory()
        setupListeners()
        initTts()
    }

    override fun onDestroy() {
        super.onDestroy()
        speechRecognizer?.destroy()
        tts?.shutdown()
        translationService.close()
    }

    // =========================================================
    // Language Dropdowns (Material Exposed Dropdown Menus)
    // =========================================================
    private fun setupLanguageDropdowns() {
        val sourceAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_dropdown_item_1line,
            LanguageRepository.sourceDisplayNames
        )
        binding.sourceLanguageDropdown.setAdapter(sourceAdapter)
        binding.sourceLanguageDropdown.setText(LanguageRepository.AUTO_DETECT.displayName, false)

        val targetAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_dropdown_item_1line,
            LanguageRepository.targetDisplayNames
        )
        binding.targetLanguageDropdown.setAdapter(targetAdapter)
        binding.targetLanguageDropdown.setText(
            LanguageRepository.targetDisplayNames[LanguageRepository.defaultTargetIndex], false
        )
    }

    // =========================================================
    // History RecyclerView
    // =========================================================
    private fun setupHistory() {
        historyAdapter = HistoryAdapter { item ->
            speakText(item.translated, item.targetLang)
        }
        binding.historyRecyclerView.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = historyAdapter
        }
    }

    // =========================================================
    // Event Listeners
    // =========================================================
    private fun setupListeners() {
        // Microphone FAB
        binding.micFab.setOnClickListener {
            if (hasMicPermission()) {
                toggleListening()
            } else {
                micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
            }
        }

        // Swap languages
        binding.swapButton.setOnClickListener { swapLanguages() }

        // Speak translation
        binding.speakButton.setOnClickListener {
            val text = binding.targetTextView.text?.toString()
            if (!text.isNullOrBlank()) {
                val targetLang = getSelectedTargetLanguage()
                speakText(text, targetLang.code)
            }
        }

        // Copy translation
        binding.copyButton.setOnClickListener {
            val text = binding.targetTextView.text?.toString()
            if (!text.isNullOrBlank()) {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("translation", text))
                showSnackbar(getString(R.string.copied))
            }
        }

        // Clear
        binding.clearButton.setOnClickListener {
            binding.sourceTextInput.text?.clear()
            binding.targetTextView.text = ""
            binding.detectedLanguageChip.isVisible = false
            finalTranscript = ""
        }

        // Manual text input -> auto-translate with debounce
        binding.sourceTextInput.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                if (!isListening) {
                    debounceTranslation(s?.toString() ?: "")
                }
            }
        })
    }

    // =========================================================
    // Speech Recognition
    // =========================================================
    private fun toggleListening() {
        if (isListening) stopListening() else startListening()
    }

    private fun startListening() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            showSnackbar(getString(R.string.speech_not_available))
            return
        }

        finalTranscript = ""
        binding.sourceTextInput.text?.clear()
        binding.targetTextView.text = ""

        speechRecognizer?.destroy()
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(createRecognitionListener())

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)

            // Set source language if not auto-detect
            val srcLang = getSelectedSourceLanguage()
            if (srcLang.code != "auto") {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, srcLang.code)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, srcLang.code)
            }
        }

        speechRecognizer?.startListening(intent)
        isListening = true
        updateMicUi()
    }

    private fun stopListening() {
        speechRecognizer?.stopListening()
        isListening = false
        updateMicUi()
    }

    private fun createRecognitionListener() = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            binding.micFab.text = getString(R.string.listening)
        }

        override fun onBeginningOfSpeech() {}

        override fun onRmsChanged(rmsdB: Float) {}

        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {}

        override fun onError(error: Int) {
            // Restart listening on transient errors if still in listening mode
            if (isListening && (error == SpeechRecognizer.ERROR_NO_MATCH ||
                        error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT)) {
                restartListening()
            } else {
                isListening = false
                updateMicUi()
            }
        }

        override fun onResults(results: Bundle?) {
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_KEY)
            if (!matches.isNullOrEmpty()) {
                finalTranscript += matches[0] + " "
                binding.sourceTextInput.setText(finalTranscript.trim())
                binding.sourceTextInput.setSelection(binding.sourceTextInput.text?.length ?: 0)
                triggerTranslation(finalTranscript.trim())
            }
            // Auto-restart for continuous listening
            if (isListening) restartListening()
        }

        override fun onPartialResults(partialResults: Bundle?) {
            val partial = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_KEY)
            if (!partial.isNullOrEmpty()) {
                val display = finalTranscript + partial[0]
                binding.sourceTextInput.setText(display)
                binding.sourceTextInput.setSelection(binding.sourceTextInput.text?.length ?: 0)
            }
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
    }

    private fun restartListening() {
        lifecycleScope.launch {
            delay(100)
            if (isListening) startListening()
        }
    }

    private fun updateMicUi() {
        if (isListening) {
            binding.micFab.text = getString(R.string.listening)
            binding.micFab.setIconTintResource(R.color.mic_recording)
            binding.micFab.extend()
        } else {
            binding.micFab.text = getString(R.string.tap_to_speak)
            binding.micFab.setIconTintResource(com.google.android.material.R.color.m3_fab_efab_foreground_color_selector)
            binding.micFab.extend()
        }
    }

    // =========================================================
    // Translation
    // =========================================================
    private fun debounceTranslation(text: String) {
        translationJob?.cancel()
        translationJob = lifecycleScope.launch {
            delay(500)
            triggerTranslation(text)
        }
    }

    private fun triggerTranslation(text: String) {
        if (text.isBlank()) return

        translationJob?.cancel()
        translationJob = lifecycleScope.launch {
            binding.translationProgress.isVisible = true

            val srcLang = getSelectedSourceLanguage()
            val tgtLang = getSelectedTargetLanguage()

            val result = translationService.translate(
                text = text,
                sourceLang = srcLang.mlKitCode,
                targetLang = tgtLang.mlKitCode,
                onModelDownloading = {
                    runOnUiThread {
                        showSnackbar(getString(R.string.downloading_model))
                    }
                }
            )

            binding.translationProgress.isVisible = false
            binding.targetTextView.text = result.translatedText

            // Show detected language chip
            if (srcLang.code == "auto" && result.detectedLanguage != null) {
                val lang = LanguageRepository.findByCode(result.detectedLanguage)
                if (lang != null) {
                    binding.detectedLanguageChip.text = "Detected: ${lang.displayName}"
                    binding.detectedLanguageChip.isVisible = true
                }
            }

            // Speak translation when mic stops
            if (!isListening && result.translatedText.isNotBlank()) {
                speakText(result.translatedText, tgtLang.code)
            }

            // Add to history
            addToHistory(text, result.translatedText, srcLang.code, tgtLang.code)
        }
    }

    // =========================================================
    // Text-to-Speech
    // =========================================================
    private fun initTts() {
        tts = TextToSpeech(this, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.US
        }
    }

    private fun speakText(text: String, langCode: String) {
        tts?.let { engine ->
            val locale = Locale.forLanguageTag(langCode)
            val result = engine.setLanguage(locale)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                // Try just the language part
                engine.setLanguage(Locale(langCode.split("-")[0]))
            }
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "translation_${System.currentTimeMillis()}")
        }
    }

    // =========================================================
    // History
    // =========================================================
    private fun addToHistory(original: String, translated: String, srcLang: String, tgtLang: String) {
        val item = HistoryItem(original, translated, srcLang, tgtLang)
        historyItems.add(0, item)
        if (historyItems.size > 20) historyItems.removeAt(historyItems.lastIndex)

        historyAdapter.submitList(historyItems.toList())
        binding.emptyHistoryText.isVisible = historyItems.isEmpty()
    }

    // =========================================================
    // Helpers
    // =========================================================
    private fun getSelectedSourceLanguage(): LanguageRepository.Language {
        val name = binding.sourceLanguageDropdown.text.toString()
        return LanguageRepository.findByDisplayName(name) ?: LanguageRepository.AUTO_DETECT
    }

    private fun getSelectedTargetLanguage(): LanguageRepository.Language {
        val name = binding.targetLanguageDropdown.text.toString()
        return LanguageRepository.findByDisplayName(name)
            ?: LanguageRepository.languages.first { it.code == "en" }
    }

    private fun swapLanguages() {
        val srcName = binding.sourceLanguageDropdown.text.toString()
        val tgtName = binding.targetLanguageDropdown.text.toString()

        if (srcName == LanguageRepository.AUTO_DETECT.displayName) return

        binding.sourceLanguageDropdown.setText(tgtName, false)
        binding.targetLanguageDropdown.setText(srcName, false)

        // Swap the text too
        val srcText = binding.sourceTextInput.text?.toString() ?: ""
        val tgtText = binding.targetTextView.text?.toString() ?: ""
        binding.sourceTextInput.setText(tgtText)
        binding.targetTextView.text = srcText
        finalTranscript = tgtText
    }

    private fun hasMicPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) ==
                PackageManager.PERMISSION_GRANTED

    private fun showSnackbar(message: String) {
        Snackbar.make(binding.root, message, Snackbar.LENGTH_SHORT).show()
    }
}
