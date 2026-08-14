import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:local_translation/local_translation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('isSupported returns a boolean', (WidgetTester tester) async {
    final plugin = LocalTranslation();
    final supported = await plugin.isSupported();
    expect(supported, isA<bool>());
  });

  testWidgets('sequential translates complete', (WidgetTester tester) async {
    final plugin = LocalTranslation();
    if (!await plugin.isSupported()) {
      return;
    }

    Future<TranslationResult> translate(String text) {
      return plugin
          .translate(
            text,
            sourceLanguage: 'de',
            targetLanguage: 'en',
          )
          .timeout(const Duration(minutes: 2));
    }

    final first = await translate('Hallo Welt');
    final second = await translate('Guten Morgen');

    expect(first.translatedText, isNotEmpty);
    expect(second.translatedText, isNotEmpty);
    expect(first.sourceText, 'Hallo Welt');
    expect(second.sourceText, 'Guten Morgen');
  });
}
