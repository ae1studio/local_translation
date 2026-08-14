import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'language_detection.dart';
import 'local_translation_pigeon.dart';
import 'translation_result.dart';

abstract class LocalTranslationPlatform extends PlatformInterface {
  LocalTranslationPlatform() : super(token: _token);

  static final Object _token = Object();

  static LocalTranslationPlatform _instance = PigeonLocalTranslation();

  static LocalTranslationPlatform get instance => _instance;

  static set instance(LocalTranslationPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }

  Future<LanguageDetection> detectLanguage(String text) {
    throw UnimplementedError('detectLanguage() has not been implemented.');
  }

  Future<List<LanguageDetection>> detectLanguages(List<String> texts) {
    throw UnimplementedError('detectLanguages() has not been implemented.');
  }

  Future<TranslationResult> translate(
    String text, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    throw UnimplementedError('translate() has not been implemented.');
  }

  Future<List<TranslationResult>> translateBatch(
    List<String> texts, {
    String? sourceLanguage,
    required String targetLanguage,
  }) {
    throw UnimplementedError('translateBatch() has not been implemented.');
  }
}
