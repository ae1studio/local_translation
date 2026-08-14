package dev.ae1.local_translation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs

internal class LocalTranslationPluginTest {
    @Test
    fun isSupported_returnsFalseWithoutEngine() {
        val plugin = LocalTranslationPlugin()
        val result = awaitResult<Boolean> { callback ->
            plugin.isSupported { callback(it) }
        }

        assertFalse(result.getOrThrow())
    }

    @Test
    fun detectLanguage_failsWithoutEngine() {
        val plugin = LocalTranslationPlugin()
        val result = awaitResult<HostLanguageDetection> { callback ->
            plugin.detectLanguage("Hallo Welt") { callback(it) }
        }

        val error = result.exceptionOrNull()
        assertIs<FlutterError>(error)
        assertEquals("unsupportedPlatform", error.code)
    }

    @Test
    fun detectLanguages_failsWithoutEngine() {
        val plugin = LocalTranslationPlugin()
        val result = awaitResult<List<HostLanguageDetection>> { callback ->
            plugin.detectLanguages(listOf("Hallo Welt")) { callback(it) }
        }

        val error = result.exceptionOrNull()
        assertIs<FlutterError>(error)
        assertEquals("unsupportedPlatform", error.code)
    }

    @Test
    fun translate_failsWithoutEngine() {
        val plugin = LocalTranslationPlugin()
        val result = awaitResult<HostTranslationResult> { callback ->
            plugin.translate(
                HostTranslateRequest(
                    text = "Hallo Welt",
                    sourceLanguage = "de",
                    targetLanguage = "en",
                ),
            ) { callback(it) }
        }

        val error = result.exceptionOrNull()
        assertIs<FlutterError>(error)
        assertEquals("unsupportedPlatform", error.code)
    }

    @Test
    fun translateBatch_failsWithoutEngine() {
        val plugin = LocalTranslationPlugin()
        val result = awaitResult<List<HostTranslationResult>> { callback ->
            plugin.translateBatch(
                HostTranslateBatchRequest(
                    texts = listOf("Hallo Welt"),
                    sourceLanguage = "de",
                    targetLanguage = "en",
                ),
            ) { callback(it) }
        }

        val error = result.exceptionOrNull()
        assertIs<FlutterError>(error)
        assertEquals("unsupportedPlatform", error.code)
    }
}
