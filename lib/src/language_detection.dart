/// Detected language for a string of text.
class LanguageDetection {
  /// Creates a detection result.
  const LanguageDetection({this.languageCode, required this.confidence});

  /// BCP 47 language tag, or `null` when the language could not be determined.
  final String? languageCode;

  /// Confidence from `0.0` (none) to `1.0` (certain).
  final double confidence;
}
