package dev.ae1.local_translation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class Bcp47MatcherTest {
    @Test
    fun matches_languageOnly() {
        assertTrue(Bcp47Matcher.matches("en", "en-US"))
        assertTrue(Bcp47Matcher.matches("en-US", "en"))
    }

    @Test
    fun matches_rejectsDifferentLanguages() {
        assertFalse(Bcp47Matcher.matches("de", "en"))
    }

    @Test
    fun matches_respectsRegionWhenBothPresent() {
        assertFalse(Bcp47Matcher.matches("en-GB", "en-US"))
        assertTrue(Bcp47Matcher.matches("en-GB", "en-GB"))
    }

    @Test
    fun matches_respectsScriptWhenBothPresent() {
        assertFalse(Bcp47Matcher.matches("zh-Hans", "zh-Hant"))
        assertTrue(Bcp47Matcher.matches("zh-Hans", "zh-Hans"))
    }

    @Test
    fun matches_isCaseInsensitive() {
        assertTrue(Bcp47Matcher.matches("EN", "en-US"))
        assertTrue(Bcp47Matcher.matches("zh-hans", "zh-Hans-CN"))
    }

    @Test
    fun matches_numericRegion() {
        assertTrue(Bcp47Matcher.matches("es-419", "es-419"))
        assertFalse(Bcp47Matcher.matches("es-419", "es-ES"))
    }
}
