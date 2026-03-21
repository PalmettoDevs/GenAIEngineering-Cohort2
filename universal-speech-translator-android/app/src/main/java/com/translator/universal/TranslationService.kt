package com.translator.universal

import com.google.mlkit.common.model.DownloadConditions
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.TranslatorOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.net.URLEncoder
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Translation service with two strategies:
 * 1. Google ML Kit (on-device, downloads models) — primary
 * 2. MyMemory API (online, free) — fallback
 */
class TranslationService {

    data class TranslationResult(
        val translatedText: String,
        val detectedLanguage: String? = null
    )

    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .build()

    private val languageIdentifier = LanguageIdentification.getClient()

    // Cache of downloaded ML Kit translators keyed by "src->tgt"
    private val translatorCache = mutableMapOf<String, com.google.mlkit.nl.translate.Translator>()

    /** Identify language of the given text. Returns ML Kit language code or null. */
    suspend fun identifyLanguage(text: String): String? =
        suspendCancellableCoroutine { cont ->
            languageIdentifier.identifyLanguage(text)
                .addOnSuccessListener { code ->
                    if (code != "und") cont.resume(code) else cont.resume(null)
                }
                .addOnFailureListener {
                    cont.resume(null)
                }
        }

    /**
     * Translate [text] from [sourceLang] to [targetLang].
     * Language codes should be ML Kit / BCP-47 style (e.g. "en", "es", "zh").
     * If [sourceLang] is "auto", language identification runs first.
     */
    suspend fun translate(
        text: String,
        sourceLang: String,
        targetLang: String,
        onModelDownloading: (() -> Unit)? = null
    ): TranslationResult {
        if (text.isBlank()) return TranslationResult("")

        var detectedLang: String? = null
        val srcCode = if (sourceLang == "auto") {
            val detected = identifyLanguage(text)
            detectedLang = detected
            detected ?: "en" // fallback
        } else {
            sourceLang
        }

        // Same language — no need to translate
        if (srcCode == targetLang) {
            return TranslationResult(text, detectedLang)
        }

        // Try ML Kit first
        return try {
            val result = translateWithMlKit(text, srcCode, targetLang, onModelDownloading)
            TranslationResult(result, detectedLang)
        } catch (e: Exception) {
            // Fallback to online API
            try {
                val result = translateWithApi(text, srcCode, targetLang)
                TranslationResult(result, detectedLang)
            } catch (e2: Exception) {
                TranslationResult("Translation failed", detectedLang)
            }
        }
    }

    /** Translate using Google ML Kit on-device models. */
    private suspend fun translateWithMlKit(
        text: String,
        srcCode: String,
        tgtCode: String,
        onModelDownloading: (() -> Unit)? = null
    ): String {
        val srcLang = TranslateLanguage.fromLanguageTag(srcCode) ?: throw Exception("Unsupported source")
        val tgtLang = TranslateLanguage.fromLanguageTag(tgtCode) ?: throw Exception("Unsupported target")

        val cacheKey = "$srcLang->$tgtLang"
        val translator = translatorCache.getOrPut(cacheKey) {
            val options = TranslatorOptions.Builder()
                .setSourceLanguage(srcLang)
                .setTargetLanguage(tgtLang)
                .build()
            Translation.getClient(options)
        }

        // Ensure model is downloaded
        onModelDownloading?.invoke()
        val conditions = DownloadConditions.Builder().build()
        suspendCancellableCoroutine { cont ->
            translator.downloadModelIfNeeded(conditions)
                .addOnSuccessListener { cont.resume(Unit) }
                .addOnFailureListener { cont.resumeWithException(it) }
        }

        // Translate
        return suspendCancellableCoroutine { cont ->
            translator.translate(text)
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resumeWithException(it) }
        }
    }

    /** Fallback: translate using MyMemory free API. */
    private suspend fun translateWithApi(
        text: String,
        srcCode: String,
        tgtCode: String
    ): String = withContext(Dispatchers.IO) {
        val encoded = URLEncoder.encode(text, "UTF-8")
        val url = "https://api.mymemory.translated.net/get?q=$encoded&langpair=$srcCode|$tgtCode"

        val request = Request.Builder().url(url).get().build()
        val response = httpClient.newCall(request).execute()
        val body = response.body?.string() ?: throw Exception("Empty response")
        val json = JSONObject(body)

        if (json.optInt("responseStatus") == 200) {
            json.getJSONObject("responseData").getString("translatedText")
        } else {
            throw Exception("API error: ${json.optString("responseStatus")}")
        }
    }

    fun close() {
        translatorCache.values.forEach { it.close() }
        translatorCache.clear()
        languageIdentifier.close()
    }
}
