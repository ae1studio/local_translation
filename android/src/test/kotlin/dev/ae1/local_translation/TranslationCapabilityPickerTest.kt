package dev.ae1.local_translation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class TranslationCapabilityPickerTest {
    @Test
    fun pick_prefersOnDeviceOverDownloadable() {
        val capabilities = listOf(
            LanguagePairCapability("de", "en", TranslationCapabilityPicker.STATE_AVAILABLE_TO_DOWNLOAD),
            LanguagePairCapability("de", "en", TranslationCapabilityPicker.STATE_ON_DEVICE),
        )

        val picked = TranslationCapabilityPicker.pick(capabilities, "de", "en")

        assertEquals(TranslationCapabilityPicker.STATE_ON_DEVICE, picked?.state)
    }

    @Test
    fun pick_allowsDownloadableWhenNotInstalled() {
        val capabilities = listOf(
            LanguagePairCapability("de", "en", TranslationCapabilityPicker.STATE_AVAILABLE_TO_DOWNLOAD),
        )

        val picked = TranslationCapabilityPicker.pick(capabilities, "de", "en")

        assertEquals(TranslationCapabilityPicker.STATE_AVAILABLE_TO_DOWNLOAD, picked?.state)
    }

    @Test
    fun pick_ignoresUnusableStates() {
        val capabilities = listOf(
            LanguagePairCapability("de", "en", 4),
        )

        assertNull(TranslationCapabilityPicker.pick(capabilities, "de", "en"))
    }

    @Test
    fun pick_matchesLanguageTags() {
        val capabilities = listOf(
            LanguagePairCapability("en-US", "de-DE", TranslationCapabilityPicker.STATE_ON_DEVICE),
        )

        val picked = TranslationCapabilityPicker.pick(capabilities, "en", "de")

        assertEquals("en-US", picked?.sourceTag)
        assertEquals("de-DE", picked?.targetTag)
    }

    @Test
    fun downloadAction_opensSettingsWhenPackIsMissing() {
        assertEquals(
            TranslationCapabilityPicker.DownloadAction.OpenSettings,
            TranslationCapabilityPicker.downloadAction(
                TranslationCapabilityPicker.STATE_AVAILABLE_TO_DOWNLOAD,
            ),
        )
    }

    @Test
    fun downloadAction_waitsWhileDownloading() {
        assertEquals(
            TranslationCapabilityPicker.DownloadAction.Wait,
            TranslationCapabilityPicker.downloadAction(
                TranslationCapabilityPicker.STATE_DOWNLOADING,
            ),
        )
    }

    @Test
    fun downloadAction_isReadyWhenOnDevice() {
        assertEquals(
            TranslationCapabilityPicker.DownloadAction.Ready,
            TranslationCapabilityPicker.downloadAction(
                TranslationCapabilityPicker.STATE_ON_DEVICE,
            ),
        )
    }
}
