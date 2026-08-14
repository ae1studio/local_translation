# local_translation

On device translation and language detection for Flutter.

## Platform support

### iOS and macOS

Apple's [Translation](https://developer.apple.com/documentation/Translation/translating-text-within-your-app) and NaturalLanguage frameworks.

- `isSupported()` is `true` on **iOS 18+ physical devices** and **macOS 15+**. It is `false` on older OS versions and the iOS Simulator.
- Translation may prompt the user to download language models.

### Android

Android's [TranslationManager](https://developer.android.com/reference/android/view/translation/TranslationManager) and [TextClassifier](https://developer.android.com/reference/android/view/textclassifier/TextClassifier) APIs.

- `isSupported()` is `true` on **Android 12+** when the device provides an on device `TranslationService`. This is mainly available on Pixel devices with Live Translate. Many emulators and OEM phones return `false`.
- Language detection works on **API 29+** even when translation is unavailable.
- Language models are managed by the system. The first translation may trigger a download via the OEM translation service.

Call `isSupported()` before `translate` or `translateBatch`. Language detection can still run when translation is unavailable.

## Supported languages

Pass BCP 47 language tags as `sourceLanguage` and `targetLanguage`.

### Apple Translate languages

Translation uses the same languages as Apple's [Translate app](https://support.apple.com/guide/iphone/translate-text-voice-and-conversations-iphd74cb450f/ios).

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

Not every source/target pair is supported. For example, translating between English variants or into the same language is rejected. Language models must be downloaded on the device before use (this is prompted when trying to translate a string for the first time). Apple may add languages in future iOS and macOS releases; see [iOS feature availability](https://www.apple.com/ios/feature-availability/) and [`LanguageAvailability`](https://developer.apple.com/documentation/translation/languageavailability).

### Android language pairs

Supported language pairs depend on the device's translation service. Use `isSupported()` to check availability. On Pixel devices, languages can be managed in **Settings > System > Live Translate**.

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
