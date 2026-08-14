import 'language_detection.dart';
import 'local_translation_platform.dart';
import 'translation_result.dart';

class LocalTranslation {
  Future<bool> isSupported() {
    return LocalTranslationPlatform.instance.isSupported();
  }

  Future<LanguageDetection> detectLanguage(String text) {
    return LocalTranslationPlatform.instance.detectLanguage(text);
  }

  Future<List<LanguageDetection>> detectLanguages(List<String> texts) {
    return LocalTranslationPlatform.instance.detectLanguages(texts);
  }

  Future<TranslationResult> translate(
    String text, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    return LocalTranslationPlatform.instance.translate(
      text,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  Future<List<TranslationResult>> translateBatch(
    List<String> texts, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    return LocalTranslationPlatform.instance.translateBatch(
      texts,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }
}
