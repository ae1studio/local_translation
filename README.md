# local_translation

On device translation and language detection for Flutter.

iOS uses Apple's [Translation](https://developer.apple.com/documentation/Translation/translating-text-within-your-app) and NaturalLanguage frameworks.

- `isSupported()` is `true` only on **iOS 18+ physical devices**. It is `false` on older iOS, the iOS Simulator.
- Translation may prompt the user to download language models.

Call `isSupported()` before `translate` or `translateBatch`. Language detection can still run when translation is unavailable.

## Supported languages

Translation uses the same languages as Apple's [Translate app](https://support.apple.com/guide/iphone/translate-text-voice-and-conversations-iphd74cb450f/ios). Pass BCP 47 language tags as `sourceLanguage` and `targetLanguage`.

| Language | Tag |
| --- | --- |
| Arabic | `ar` |
| Dutch | `nl` |
| English (United Kingdom) | `en-GB` |
| English (United States) | `en` |
| French (France) | `fr` |
| German (Germany) | `de` |
| Hindi | `hi` |
| Indonesian | `id` |
| Italian (Italy) | `it` |
| Japanese | `ja` |
| Korean | `ko` |
| Mandarin Chinese (China mainland) | `zh-Hans` |
| Mandarin Chinese (Taiwan) | `zh-Hant` |
| Polish | `pl` |
| Portuguese (Brazil) | `pt-BR` |
| Russian | `ru` |
| Spanish (Spain) | `es` |
| Thai | `th` |
| Turkish | `tr` |
| Ukrainian | `uk` |
| Vietnamese | `vi` |

Not every source/target pair is supported. For example, translating between English variants or into the same language is rejected. Language models must be downloaded on the device before use (this is prompted when trying to translate a string for the first time). Apple may add languages in future iOS releases; see [iOS feature availability](https://www.apple.com/ios/feature-availability/) and [`LanguageAvailability`](https://developer.apple.com/documentation/translation/languageavailability).

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
