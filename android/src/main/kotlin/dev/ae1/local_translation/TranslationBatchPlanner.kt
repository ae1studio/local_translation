package dev.ae1.local_translation

internal data class IndexedText(
    val index: Int,
    val text: String,
)

internal data class TranslationBatchGroups(
    val byLanguage: Map<String, List<IndexedText>>,
    val unknown: List<IndexedText>,
)

internal object TranslationBatchPlanner {
    fun group(
        texts: List<String>,
        detections: List<HostLanguageDetection>,
    ): TranslationBatchGroups {
        val groups = linkedMapOf<String, MutableList<IndexedText>>()
        val unknown = mutableListOf<IndexedText>()

        texts.forEachIndexed { index, text ->
            val code = detections[index].languageCode
            val item = IndexedText(index, text)
            if (code != null) {
                groups.getOrPut(code) { mutableListOf() }.add(item)
            } else {
                unknown.add(item)
            }
        }

        return TranslationBatchGroups(
            byLanguage = groups,
            unknown = unknown,
        )
    }
}
