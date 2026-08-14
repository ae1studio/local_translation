package dev.ae1.local_translation

import kotlin.test.Test
import kotlin.test.assertEquals

internal class TranslationBatchPlannerTest {
    @Test
    fun group_keepsLanguageBucketsAndUnknownItems() {
        val texts = listOf("Hallo", "Hello", " ", "Guten Morgen")
        val detections = listOf(
            HostLanguageDetection("de", 0.9),
            HostLanguageDetection("en", 0.8),
            undeterminedDetection(),
            HostLanguageDetection("de", 0.85),
        )

        val groups = TranslationBatchPlanner.group(texts, detections)

        assertEquals(listOf("de", "en"), groups.byLanguage.keys.toList())
        assertEquals(listOf(0, 3), groups.byLanguage.getValue("de").map { it.index })
        assertEquals(listOf("Hallo", "Guten Morgen"), groups.byLanguage.getValue("de").map { it.text })
        assertEquals(listOf(1), groups.byLanguage.getValue("en").map { it.index })
        assertEquals(listOf(2), groups.unknown.map { it.index })
        assertEquals(listOf(" "), groups.unknown.map { it.text })
    }
}
