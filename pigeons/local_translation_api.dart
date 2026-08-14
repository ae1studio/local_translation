import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    swiftOut:
        'ios/local_translation/Sources/local_translation/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    kotlinOut: 'android/src/main/kotlin/dev/ae1/local_translation/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'dev.ae1.local_translation',
    ),
    dartPackageName: 'local_translation',
  ),
)
class HostLanguageDetection {
  String? languageCode;
  double? confidence;
}

class HostTranslationResult {
  String? sourceText;
  String? translatedText;
  String? sourceLanguage;
  String? targetLanguage;
}

class HostTranslateRequest {
  String? text;
  String? sourceLanguage;
  String? targetLanguage;
}

class HostTranslateBatchRequest {
  List<String>? texts;
  String? sourceLanguage;
  String? targetLanguage;
}

@HostApi()
abstract class LocalTranslationHostApi {
  bool isSupported();

  @async
  HostLanguageDetection detectLanguage(String text);

  @async
  List<HostLanguageDetection> detectLanguages(List<String> texts);

  @async
  HostTranslationResult translate(HostTranslateRequest request);

  @async
  List<HostTranslationResult> translateBatch(HostTranslateBatchRequest request);
}
