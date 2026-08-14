import 'package:flutter_test/flutter_test.dart';
import 'package:local_translation/local_translation.dart';
import 'package:local_translation/src/local_translation_pigeon.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeLocalTranslationPlatform extends LocalTranslationPlatform
    with MockPlatformInterfaceMixin {
  String? lastSourceLanguage;
  String? lastTargetLanguage;
  List<String> lastTexts = const [];
  bool translateBatchCalled = false;
  bool translateCalled = false;

  bool detectLanguageCalled = false;
  bool detectLanguagesCalled = false;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<LanguageDetection> detectLanguage(String text) async {
    detectLanguageCalled = true;
    lastTexts = [text];
    return LanguageDetection(languageCode: 'de', confidence: 0.9);
  }

  @override
  Future<List<LanguageDetection>> detectLanguages(List<String> texts) async {
    detectLanguagesCalled = true;
    lastTexts = texts;
    return [
      for (final text in texts)
        LanguageDetection(languageCode: 'de', confidence: 0.9),
    ];
  }

  @override
  Future<TranslationResult> translate(
    String text, {
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    translateCalled = true;
    lastTexts = [text];
    lastSourceLanguage = sourceLanguage;
    lastTargetLanguage = targetLanguage;
    return TranslationResult(
      sourceText: text,
      translatedText: 'T:$text',
      sourceLanguage: sourceLanguage ?? 'de',
      targetLanguage: targetLanguage,
    );
  }

  @override
  Future<List<TranslationResult>> translateBatch(
    List<String> texts, {
    String? sourceLanguage,
    required String targetLanguage,
  }) async {
    translateBatchCalled = true;
    lastTexts = texts;
    lastSourceLanguage = sourceLanguage;
    lastTargetLanguage = targetLanguage;
    return [
      for (final text in texts)
        TranslationResult(
          sourceText: text,
          translatedText: 'T:$text',
          sourceLanguage: sourceLanguage ?? 'de',
          targetLanguage: targetLanguage,
        ),
    ];
  }
}

void main() {
  final LocalTranslationPlatform initialPlatform =
      LocalTranslationPlatform.instance;

  test('PigeonLocalTranslation is the default instance', () {
    expect(initialPlatform, isA<PigeonLocalTranslation>());
  });

  group('LocalTranslation', () {
    late FakeLocalTranslationPlatform fake;
    late LocalTranslation plugin;

    setUp(() {
      fake = FakeLocalTranslationPlatform();
      LocalTranslationPlatform.instance = fake;
      plugin = LocalTranslation();
    });

    tearDown(() {
      LocalTranslationPlatform.instance = initialPlatform;
    });

    test('detectLanguage routes a single string', () async {
      final result = await plugin.detectLanguage('Hallo Welt');

      expect(fake.detectLanguageCalled, isTrue);
      expect(fake.detectLanguagesCalled, isFalse);
      expect(fake.lastTexts, ['Hallo Welt']);
      expect(result.languageCode, 'de');
    });

    test('translate routes a single string', () async {
      final result = await plugin.translate(
        'Hallo Welt',
        sourceLanguage: 'de',
        targetLanguage: 'en',
      );

      expect(fake.translateCalled, isTrue);
      expect(fake.translateBatchCalled, isFalse);
      expect(fake.lastTexts, ['Hallo Welt']);
      expect(fake.lastSourceLanguage, 'de');
      expect(fake.lastTargetLanguage, 'en');
      expect(result.translatedText, 'T:Hallo Welt');
    });

    test('translate passes a null source language for auto-detect', () async {
      await plugin.translate('Hallo Welt', targetLanguage: 'en');
      expect(fake.lastSourceLanguage, isNull);
    });

    test('translateBatch preserves order', () async {
      final results = await plugin.translateBatch([
        'Hallo Welt',
        'Guten Morgen',
        'Wie geht es dir?',
      ], targetLanguage: 'en');

      expect(fake.translateBatchCalled, isTrue);
      expect(fake.translateCalled, isFalse);
      expect(results.map((result) => result.sourceText), [
        'Hallo Welt',
        'Guten Morgen',
        'Wie geht es dir?',
      ]);
      expect(results.map((result) => result.translatedText), [
        'T:Hallo Welt',
        'T:Guten Morgen',
        'T:Wie geht es dir?',
      ]);
    });
  });

  group('LocalTranslationException', () {
    test('maps platform codes', () {
      expect(
        LocalTranslationException.codeFromString('unsupportedPlatform'),
        LocalTranslationErrorCode.unsupportedPlatform,
      );
      expect(
        LocalTranslationException.codeFromString('unsupportedLanguagePair'),
        LocalTranslationErrorCode.unsupportedLanguagePair,
      );
      expect(
        LocalTranslationException.codeFromString('cancelled'),
        LocalTranslationErrorCode.cancelled,
      );
      expect(
        LocalTranslationException.codeFromString('nope'),
        LocalTranslationErrorCode.unknown,
      );
    });
  });
}
