## 0.0.3

- Add Android support using the platform `TranslationManager` API (Android 12+).
- Language detection on Android uses `TextClassifier` (API 29+).
- Fixed issue with following requests.

## 0.0.2

- Add macOS support (macOS 15+ for translation).
- Share iOS and macOS native code under `darwin/` with Swift Package Manager.
- Fixed issue where reqesting a translation after a first request would cause the following requests to become stuck.

## 0.0.1

- Initial iOS translation and language detection API.
