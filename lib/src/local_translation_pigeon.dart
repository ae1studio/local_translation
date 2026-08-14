import 'package:flutter/services.dart';

import 'language_detection.dart';
import 'local_translation_exception.dart';
import 'local_translation_platform.dart';
import 'messages.g.dart';
import 'translation_result.dart';

class PigeonLocalTranslation extends LocalTranslationPlatform {
  PigeonLocalTranslation({LocalTranslationHostApi? api})
    : _api = api ?? LocalTranslationHostApi();

  final LocalTranslationHostApi _api;

  @override
  Future<bool> isSupported() {
    return _run(() => _api.isSupported());
  }

  @override
  Future<LanguageDetection> detectLanguage(String text) {
    return _run(() async {
      final result = await _api.detectLanguage(text);
      return _toLanguageDetection(result);
    });
  }

  @override
  Future<List<LanguageDetection>> detectLanguages(List<String> texts) {
    return _run(() async {
      final results = await _api.detectLanguages(texts);
      return [for (final result in results) _toLanguageDetection(result)];
    });
  }

  @override
  Future<TranslationResult> translate(
    String text, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    return _run(() async {
      final result = await _api.translate(
        HostTranslateRequest(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      );
      return _toTranslationResult(result);
    });
  }

  @override
  Future<List<TranslationResult>> translateBatch(
    List<String> texts, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    return _run(() async {
      final results = await _api.translateBatch(
        HostTranslateBatchRequest(
          texts: texts,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
      );
      return [for (final result in results) _toTranslationResult(result)];
    });
  }

  LanguageDetection _toLanguageDetection(HostLanguageDetection result) {
    return LanguageDetection(
      languageCode: result.languageCode,
      confidence: result.confidence ?? 0,
    );
  }

  TranslationResult _toTranslationResult(HostTranslationResult result) {
    return TranslationResult(
      sourceText: result.sourceText ?? '',
      translatedText: result.translatedText ?? '',
      sourceLanguage: result.sourceLanguage,
      targetLanguage: result.targetLanguage ?? '',
    );
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on LocalTranslationException {
      rethrow;
    } on PlatformException catch (error) {
      throw LocalTranslationException(
        code: LocalTranslationException.codeFromString(error.code),
        message: error.message ?? error.code,
      );
    }
  }
}
