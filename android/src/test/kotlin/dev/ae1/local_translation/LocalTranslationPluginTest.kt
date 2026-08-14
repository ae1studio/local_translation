package dev.ae1.local_translation

import kotlin.test.Test
import kotlin.test.assertFalse

internal class LocalTranslationPluginTest {
    @Test
    fun isSupported_returnsFalse() {
        val plugin = LocalTranslationPlugin()
        assertFalse(plugin.isSupported())
    }
}
