package dev.ae1.local_translation

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class LanguageDetectorTest {
    @Test
    fun detectSync_returnsEmptyForBlankText() {
        val detector = LanguageDetector { error("should not classify blank text") }

        val empty = detector.detectSync("")
        val whitespace = detector.detectSync("   \n\t")

        assertEquals(null, empty.languageCode)
        assertEquals(0.0, empty.confidence)
        assertEquals(null, whitespace.languageCode)
        assertEquals(0.0, whitespace.confidence)
    }

    @Test
    fun detectSync_preservesBatchOrder() {
        val detector = LanguageDetector { text ->
            when {
                text.startsWith("Hallo") -> HostLanguageDetection("de", 0.9)
                text.startsWith("Hello") -> HostLanguageDetection("en", 0.8)
                else -> error("unexpected text: $text")
            }
        }

        val results = detector.detectSync(
            listOf(
                "Hallo Welt, wie geht es dir heute?",
                "Hello world, how are you today?",
                "",
            ),
        )

        assertEquals(listOf("de", "en", null), results.map { it.languageCode })
        assertEquals(0.0, results[2].confidence)
    }

    @Test
    fun detect_invokesCallback() {
        val detector = LanguageDetector { HostLanguageDetection("fr", 0.7) }
        val result = awaitResult<HostLanguageDetection> { callback ->
            detector.detect("Bonjour le monde") { callback(it) }
        }

        assertEquals("fr", result.getOrThrow().languageCode)
        assertEquals(0.7, result.getOrThrow().confidence)
    }
}

internal fun <T> awaitResult(
    timeoutSeconds: Long = 5,
    block: ((Result<T>) -> Unit) -> Unit,
): Result<T> {
    val latch = CountDownLatch(1)
    var value: Result<T>? = null
    block { result ->
        value = result
        latch.countDown()
    }
    assertTrue(latch.await(timeoutSeconds, TimeUnit.SECONDS), "timed out waiting for result")
    return requireNotNull(value)
}
