package dev.ae1.local_translation

import android.app.Activity
import android.content.Context
import android.content.IntentSender
import android.icu.util.ULocale
import android.os.Build
import android.os.SystemClock
import android.view.translation.TranslationCapability
import android.view.translation.TranslationContext
import android.view.translation.TranslationManager
import android.view.translation.TranslationRequest
import android.view.translation.TranslationRequestValue
import android.view.translation.TranslationResponse
import android.view.translation.TranslationResponseValue
import android.view.translation.TranslationSpec
import android.view.translation.Translator
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

internal class OnDeviceTranslator(
    private val context: Context,
    private val languageDetector: LanguageDetector,
) {
    private val workExecutor = Executors.newSingleThreadExecutor()
    private val callbackExecutor = Executors.newCachedThreadPool()
    private val translators = mutableMapOf<String, Translator>()

    @Volatile
    var activity: Activity? = null

    fun isSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return false
        }
        val manager = translationManager() ?: return false
        return getCapabilities(manager).any { capability ->
            TranslationCapabilityPicker.isUsable(capability.state)
        }
    }

    fun close() {
        workExecutor.execute {
            translators.values.forEach { translator -> translator.destroy() }
            translators.clear()
        }
    }

    fun translate(
        request: HostTranslateRequest,
        callback: (Result<HostTranslationResult>) -> Unit,
    ) {
        val text = request.text
        val targetLanguage = request.targetLanguage
        if (text == null || targetLanguage == null) {
            callback(Result.failure(missingArgument("Missing text or target language")))
            return
        }

        workExecutor.execute {
            try {
                val result = translateTexts(
                    texts = listOf(text),
                    sourceLanguage = request.sourceLanguage,
                    targetLanguage = targetLanguage,
                ).single()
                callback(Result.success(result))
            } catch (error: Throwable) {
                callback(Result.failure(mapError(error)))
            }
        }
    }

    fun translateBatch(
        request: HostTranslateBatchRequest,
        callback: (Result<List<HostTranslationResult>>) -> Unit,
    ) {
        val texts = request.texts
        val targetLanguage = request.targetLanguage
        if (texts == null || targetLanguage == null) {
            callback(Result.failure(missingArgument("Missing texts or target language")))
            return
        }

        workExecutor.execute {
            try {
                val results = translateBatchTexts(
                    texts = texts,
                    sourceLanguage = request.sourceLanguage,
                    targetLanguage = targetLanguage,
                )
                callback(Result.success(results))
            } catch (error: Throwable) {
                callback(Result.failure(mapError(error)))
            }
        }
    }

    private fun translateBatchTexts(
        texts: List<String>,
        sourceLanguage: String?,
        targetLanguage: String,
    ): List<HostTranslationResult> {
        if (texts.isEmpty()) {
            return emptyList()
        }
        if (sourceLanguage != null) {
            return translateTexts(texts, sourceLanguage, targetLanguage)
        }

        val groups = TranslationBatchPlanner.group(
            texts = texts,
            detections = languageDetector.detectSync(texts),
        )

        val results = arrayOfNulls<HostTranslationResult>(texts.size)
        for ((code, items) in groups.byLanguage) {
            val translated = translateTexts(
                texts = items.map { it.text },
                sourceLanguage = code,
                targetLanguage = targetLanguage,
            )
            items.forEachIndexed { offset, item ->
                results[item.index] = translated[offset]
            }
        }
        for (item in groups.unknown) {
            results[item.index] = translateTexts(
                texts = listOf(item.text),
                sourceLanguage = null,
                targetLanguage = targetLanguage,
            ).single()
        }

        return results.map { result ->
            result ?: throw FlutterError("unknown", "Missing translation result", null)
        }
    }

    private fun translateTexts(
        texts: List<String>,
        sourceLanguage: String?,
        targetLanguage: String,
    ): List<HostTranslationResult> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            throw unsupportedPlatform()
        }

        val resolvedSource = sourceLanguage ?: resolveSourceLanguage(texts.first())
        val manager = translationManager() ?: throw unsupportedPlatform()
        val capability = waitForCapability(manager, resolvedSource, targetLanguage)
            ?: throw unsupportedLanguagePair(
                "Unsupported language pair: $resolvedSource -> $targetLanguage",
            )

        val sourceLocale = capability.sourceSpec.locale
        val targetLocale = capability.targetSpec.locale
        val translationContext = TranslationContext.Builder(
            buildTextSpec(sourceLocale),
            buildTextSpec(targetLocale),
        ).build()

        val translator = translatorFor(
            manager,
            translationContext,
            resolvedSource,
            targetLanguage,
        )

        val requestValues = texts.map { TranslationRequestValue.forText(it) }
        val translationRequest = TranslationRequest.Builder()
            .setTranslationRequestValues(requestValues)
            .setFlags(TranslationRequest.FLAG_TRANSLATION_RESULT)
            .build()
        val response = translateRequest(translator, translationRequest)
        return mapResponse(
            response = response,
            texts = texts,
            sourceLanguage = resolvedSource,
            targetLanguage = targetLanguage,
        )
    }

    private fun resolveSourceLanguage(text: String): String {
        val detection = languageDetector.detectSync(text)
        return detection.languageCode
            ?: throw unsupportedLanguagePair("Could not detect source language")
    }

    private fun translatorFor(
        manager: TranslationManager,
        translationContext: TranslationContext,
        sourceLanguage: String,
        targetLanguage: String,
    ): Translator {
        val key = "$sourceLanguage->$targetLanguage"
        val existing = translators[key]
        if (existing != null && !existing.isDestroyed) {
            return existing
        }
        existing?.destroy()
        val translator = createTranslator(manager, translationContext)
            ?: throw unsupportedPlatform()
        translators[key] = translator
        return translator
    }

    private fun createTranslator(
        manager: TranslationManager,
        translationContext: TranslationContext,
    ): Translator? {
        var translator: Translator? = null
        val latch = CountDownLatch(1)
        manager.createOnDeviceTranslator(translationContext, callbackExecutor) { value ->
            translator = value
            latch.countDown()
        }
        if (!latch.await(TRANSLATOR_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
            translator?.destroy()
            throw FlutterError("unknown", "Timed out creating translator", null)
        }
        return translator
    }

    private fun translateRequest(
        translator: Translator,
        request: TranslationRequest,
    ): TranslationResponse {
        var response: TranslationResponse? = null
        val latch = CountDownLatch(1)
        translator.translate(
            request,
            null,
            callbackExecutor,
        ) { value ->
            response = value
            latch.countDown()
        }
        if (!latch.await(TRANSLATION_TIMEOUT_SECONDS, TimeUnit.SECONDS)) {
            throw FlutterError("unknown", "Translation timed out", null)
        }
        return response ?: throw FlutterError("unknown", "Translation timed out", null)
    }

    private fun mapResponse(
        response: TranslationResponse,
        texts: List<String>,
        sourceLanguage: String,
        targetLanguage: String,
    ): List<HostTranslationResult> {
        when (response.translationStatus) {
            TranslationResponse.TRANSLATION_STATUS_SUCCESS -> Unit
            TranslationResponse.TRANSLATION_STATUS_CONTEXT_UNSUPPORTED -> throw unsupportedLanguagePair(
                "Translation context is unsupported",
            )
            else -> throw FlutterError("unknown", "Translation failed", null)
        }

        val values = response.translationResponseValues
        return texts.indices.map { index ->
            val value = values.get(index)
                ?: throw FlutterError("unknown", "Missing translation response value", null)
            if (value.statusCode != TranslationResponseValue.STATUS_SUCCESS) {
                throw FlutterError("unknown", "Translation value failed", null)
            }
            val translatedText = value.text?.toString()
                ?: throw FlutterError("unknown", "Missing translated text", null)
            HostTranslationResult(
                sourceText = texts[index],
                translatedText = translatedText,
                sourceLanguage = sourceLanguage,
                targetLanguage = targetLanguage,
            )
        }
    }

    private fun waitForCapability(
        manager: TranslationManager,
        sourceLanguage: String,
        targetLanguage: String,
    ): TranslationCapability? {
        val deadline = SystemClock.elapsedRealtime() + DOWNLOAD_TIMEOUT_MS
        var openedSettings = false

        while (true) {
            val capability = findCapability(manager, sourceLanguage, targetLanguage)
            when (TranslationCapabilityPicker.downloadAction(capability?.state)) {
                TranslationCapabilityPicker.DownloadAction.Ready -> return capability
                TranslationCapabilityPicker.DownloadAction.Unsupported -> return null
                TranslationCapabilityPicker.DownloadAction.OpenSettings -> {
                    if (!openedSettings) {
                        openTranslationSettings(manager)
                        openedSettings = true
                    }
                }
                TranslationCapabilityPicker.DownloadAction.Wait -> Unit
            }
            if (SystemClock.elapsedRealtime() >= deadline) {
                throw FlutterError(
                    "unknown",
                    "Timed out waiting for Live Translate language download",
                    null,
                )
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
    }

    private fun openTranslationSettings(manager: TranslationManager) {
        val pendingIntent = manager.onDeviceTranslationSettingsActivityIntent ?: return
        val host = activity
        val launch = Runnable {
            try {
                if (host != null) {
                    host.startIntentSender(pendingIntent.intentSender, null, 0, 0, 0)
                } else {
                    pendingIntent.send()
                }
            } catch (_: IntentSender.SendIntentException) {
                try {
                    pendingIntent.send()
                } catch (_: Exception) {
                }
            } catch (_: Exception) {
            }
        }
        if (host != null) {
            host.runOnUiThread(launch)
        } else {
            launch.run()
        }
    }

    private fun findCapability(
        manager: TranslationManager,
        sourceLanguage: String,
        targetLanguage: String,
    ): TranslationCapability? {
        val capabilities = getCapabilities(manager).toList()
        val picked = TranslationCapabilityPicker.pick(
            capabilities = capabilities.map { capability ->
                LanguagePairCapability(
                    sourceTag = capability.sourceSpec.locale.toLanguageTag(),
                    targetTag = capability.targetSpec.locale.toLanguageTag(),
                    state = capability.state,
                )
            },
            sourceLanguage = sourceLanguage,
            targetLanguage = targetLanguage,
        ) ?: return null

        return capabilities.firstOrNull { capability ->
            capability.sourceSpec.locale.toLanguageTag() == picked.sourceTag &&
                capability.targetSpec.locale.toLanguageTag() == picked.targetTag &&
                capability.state == picked.state
        }
    }

    private fun getCapabilities(manager: TranslationManager): Set<TranslationCapability> {
        return manager.getOnDeviceTranslationCapabilities(
            TranslationSpec.DATA_FORMAT_TEXT,
            TranslationSpec.DATA_FORMAT_TEXT,
        )
    }

    private fun buildTextSpec(locale: ULocale): TranslationSpec {
        return TranslationSpec(locale, TranslationSpec.DATA_FORMAT_TEXT)
    }

    private fun translationManager(): TranslationManager? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return null
        }
        return context.getSystemService(TranslationManager::class.java)
    }

    private fun mapError(error: Throwable): FlutterError {
        if (error is FlutterError) {
            return error
        }
        val message = error.message ?: error.toString()
        val lower = message.lowercase()
        if (lower.contains("cancel")) {
            return FlutterError("cancelled", message, null)
        }
        if (lower.contains("unsupported") || lower.contains("language")) {
            return unsupportedLanguagePair(message)
        }
        return FlutterError("unknown", message, null)
    }

    companion object {
        private const val TRANSLATOR_TIMEOUT_SECONDS = 30L
        private const val TRANSLATION_TIMEOUT_SECONDS = 60L
        private const val DOWNLOAD_TIMEOUT_MS = 180_000L
        private const val POLL_INTERVAL_MS = 500L
    }
}

private fun unsupportedPlatform(): FlutterError {
    return FlutterError(
        "unsupportedPlatform",
        "Translation requires Android 12 or later with an on device translation service",
        null,
    )
}

private fun unsupportedLanguagePair(message: String): FlutterError {
    return FlutterError("unsupportedLanguagePair", message, null)
}

private fun missingArgument(message: String): FlutterError {
    return FlutterError("unknown", message, null)
}
