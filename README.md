# local_translation

On device translation and language detection for Flutter.

iOS uses Apple's [Translation](https://developer.apple.com/documentation/Translation/translating-text-within-your-app) and NaturalLanguage frameworks.

- `isSupported()` is `true` only on **iOS 18+ physical devices**. It is `false` on older iOS, the iOS Simulator.
- Translation may prompt the user to download language models.

Call `isSupported()` before `translate` or `translateBatch`. Language detection can still run when translation is unavailable.

## Usage

```dart
final translation = LocalTranslation();

if (!await translation.isSupported()) {
  return;
}

final detection = await translation.detectLanguage('Hallo Welt');

final detections = await translation.detectLanguages([
  'Hallo Welt',
  'Guten Morgen',
]);

final one = await translation.translate(
  'Hallo Welt',
  targetLanguage: 'en',
);

final many = await translation.translateBatch(
  ['Hallo Welt', 'Wie geht es dir?'],
  sourceLanguage: 'de',
  targetLanguage: 'en',
);
```

`sourceLanguage` is optional. When omitted, the plugin auto detects.

## Regenerating Pigeon

```sh
dart run pigeon --input pigeons/local_translation_api.dart
```
