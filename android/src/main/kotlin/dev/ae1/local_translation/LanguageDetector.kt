package dev.ae1.local_translation

import android.content.Context
import android.os.Build
import android.view.textclassifier.TextClassificationManager
import android.view.textclassifier.TextLanguage
import java.util.concurrent.Executors

internal class LanguageDetector(
    private val classify: (String) -> HostLanguageDetection,
) {
    constructor(context: Context) : this({ text -> classifyOnDevice(context, text) })

    private val executor = Executors.newSingleThreadExecutor()

    fun detect(
        text: String,
        callback: (Result<HostLanguageDetection>) -> Unit,
    ) {
        executor.execute {
            callback(runCatching { detectSync(text) })
        }
    }

    fun detectLanguages(
        texts: List<String>,
        callback: (Result<List<HostLanguageDetection>>) -> Unit,
    ) {
        executor.execute {
            callback(runCatching { detectSync(texts) })
        }
    }

    fun detectSync(text: String): HostLanguageDetection {
        return detectSync(listOf(text)).single()
    }

    fun detectSync(texts: List<String>): List<HostLanguageDetection> {
        return texts.map { text ->
            val trimmed = text.trim()
            if (trimmed.isEmpty()) {
                undeterminedDetection()
            } else {
                classify(trimmed)
            }
        }
    }
}

internal fun undeterminedDetection(): HostLanguageDetection {
    return HostLanguageDetection(languageCode = null, confidence = 0.0)
}

private fun classifyOnDevice(context: Context, text: String): HostLanguageDetection {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        return undeterminedDetection()
    }

    val manager = context.getSystemService(TextClassificationManager::class.java)
        ?: return undeterminedDetection()
    val classifier = manager.textClassifier
    val request = TextLanguage.Request.Builder(text).build()
    val result = classifier.detectLanguage(request)
    if (result.localeHypothesisCount == 0) {
        return undeterminedDetection()
    }

    val locale = result.getLocale(0)
    val confidence = result.getConfidenceScore(locale).toDouble()
    return HostLanguageDetection(
        languageCode = locale.toLanguageTag(),
        confidence = confidence,
    )
}
