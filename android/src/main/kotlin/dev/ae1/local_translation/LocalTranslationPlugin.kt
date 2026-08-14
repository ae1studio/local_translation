package dev.ae1.local_translation

import io.flutter.embedding.engine.plugins.FlutterPlugin

class LocalTranslationPlugin :
    FlutterPlugin,
    LocalTranslationHostApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        LocalTranslationHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        LocalTranslationHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun isSupported(): Boolean = false

    override fun detectLanguage(
        text: String,
        callback: (Result<HostLanguageDetection>) -> Unit
    ) {
        callback(Result.failure(unsupported()))
    }

    override fun detectLanguages(
        texts: List<String>,
        callback: (Result<List<HostLanguageDetection>>) -> Unit
    ) {
        callback(Result.failure(unsupported()))
    }

    override fun translate(
        request: HostTranslateRequest,
        callback: (Result<HostTranslationResult>) -> Unit
    ) {
        callback(Result.failure(unsupported()))
    }

    override fun translateBatch(
        request: HostTranslateBatchRequest,
        callback: (Result<List<HostTranslationResult>>) -> Unit
    ) {
        callback(Result.failure(unsupported()))
    }

    private fun unsupported(): FlutterError {
        return FlutterError(
            "unsupportedPlatform",
            "Translation is not implemented on Android yet",
            null
        )
    }
}
