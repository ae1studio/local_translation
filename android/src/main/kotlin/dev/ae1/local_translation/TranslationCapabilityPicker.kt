package dev.ae1.local_translation

internal data class LanguagePairCapability(
    val sourceTag: String,
    val targetTag: String,
    val state: Int,
)

internal object TranslationCapabilityPicker {
    const val STATE_AVAILABLE_TO_DOWNLOAD = 1
    const val STATE_DOWNLOADING = 2
    const val STATE_ON_DEVICE = 3

    fun pick(
        capabilities: List<LanguagePairCapability>,
        sourceLanguage: String,
        targetLanguage: String,
    ): LanguagePairCapability? {
        val matches = capabilities.filter { capability ->
            isUsable(capability.state) &&
                Bcp47Matcher.matches(sourceLanguage, capability.sourceTag) &&
                Bcp47Matcher.matches(targetLanguage, capability.targetTag)
        }
        return matches.firstOrNull { it.state == STATE_ON_DEVICE } ?: matches.firstOrNull()
    }

    fun isUsable(state: Int): Boolean {
        return state == STATE_ON_DEVICE ||
            state == STATE_AVAILABLE_TO_DOWNLOAD ||
            state == STATE_DOWNLOADING
    }

    fun downloadAction(state: Int?): DownloadAction {
        return when (state) {
            STATE_ON_DEVICE -> DownloadAction.Ready
            STATE_AVAILABLE_TO_DOWNLOAD -> DownloadAction.OpenSettings
            STATE_DOWNLOADING -> DownloadAction.Wait
            else -> DownloadAction.Unsupported
        }
    }

    enum class DownloadAction {
        Ready,
        OpenSettings,
        Wait,
        Unsupported,
    }
}
