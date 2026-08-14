package dev.ae1.local_translation

import android.icu.util.ULocale

internal object Bcp47Matcher {
    fun matches(requested: String, specLocale: ULocale): Boolean {
        return matches(requested, specLocale.toLanguageTag())
    }

    fun matches(requested: String, specTag: String): Boolean {
        val requestedParts = parse(requested)
        val specParts = parse(specTag)
        if (!requestedParts.language.equals(specParts.language, ignoreCase = true)) {
            return false
        }

        if (
            requestedParts.script.isNotEmpty() &&
            specParts.script.isNotEmpty() &&
            !requestedParts.script.equals(specParts.script, ignoreCase = true)
        ) {
            return false
        }

        if (
            requestedParts.region.isNotEmpty() &&
            specParts.region.isNotEmpty() &&
            !requestedParts.region.equals(specParts.region, ignoreCase = true)
        ) {
            return false
        }

        return true
    }

    private fun parse(tag: String): TagParts {
        val segments = tag.split('-').filter { it.isNotEmpty() }
        if (segments.isEmpty()) {
            return TagParts(language = tag)
        }

        val language = segments[0]
        var script = ""
        var region = ""
        var index = 1
        if (index < segments.size && segments[index].length == 4) {
            script = segments[index]
            index += 1
        }
        if (index < segments.size && segments[index].length in 2..3) {
            region = segments[index]
        }

        return TagParts(language = language, script = script, region = region)
    }

    private data class TagParts(
        val language: String,
        val script: String = "",
        val region: String = "",
    )
}
