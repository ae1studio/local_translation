enum LocalTranslationErrorCode {
  unsupportedPlatform,
  unsupportedLanguagePair,
  cancelled,
  unknown,
}

class LocalTranslationException implements Exception {
  const LocalTranslationException({required this.code, required this.message});

  final LocalTranslationErrorCode code;
  final String message;

  static LocalTranslationErrorCode codeFromString(String value) {
    switch (value) {
      case 'unsupportedPlatform':
        return LocalTranslationErrorCode.unsupportedPlatform;
      case 'unsupportedLanguagePair':
        return LocalTranslationErrorCode.unsupportedLanguagePair;
      case 'cancelled':
        return LocalTranslationErrorCode.cancelled;
      default:
        return LocalTranslationErrorCode.unknown;
    }
  }

  @override
  String toString() => 'LocalTranslationException($code): $message';
}
