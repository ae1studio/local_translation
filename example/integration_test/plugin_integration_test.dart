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
}
