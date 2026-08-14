class TranslationResult {
  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    this.sourceLanguage,
    required this.targetLanguage,
  });

  final String sourceText;
  final String translatedText;
  final String? sourceLanguage;
  final String targetLanguage;
}
