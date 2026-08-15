package dev.ae1.local_translation

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.concurrent.Executors

class LocalTranslationPlugin :
    FlutterPlugin,
    ActivityAware,
    LocalTranslationHostApi {
    private var languageDetector: LanguageDetector? = null
    private var onDeviceTranslator: OnDeviceTranslator? = null
    private val executor = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val context = flutterPluginBinding.applicationContext
        val detector = LanguageDetector(context)
        languageDetector = detector
        onDeviceTranslator = OnDeviceTranslator(context, detector)
        LocalTranslationHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        LocalTranslationHostApi.setUp(binding.binaryMessenger, null)
        onDeviceTranslator?.close()
        languageDetector = null
        onDeviceTranslator = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        onDeviceTranslator?.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        onDeviceTranslator?.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onDeviceTranslator?.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDeviceTranslator?.activity = null
    }

    override fun isSupported(callback: (Result<Boolean>) -> Unit) {
        executor.execute {
            val translator = onDeviceTranslator
            if (translator == null) {
                callback(Result.success(false))
                return@execute
            }
            callback(runCatching { translator.isSupported() })
        }
    }

    override fun detectLanguage(
        text: String,
        callback: (Result<HostLanguageDetection>) -> Unit,
    ) {
        val detector = languageDetector
        if (detector == null) {
            callback(Result.failure(unsupported()))
            return
        }
        detector.detect(text, callback)
    }

    override fun detectLanguages(
        texts: List<String>,
        callback: (Result<List<HostLanguageDetection>>) -> Unit,
    ) {
        val detector = languageDetector
        if (detector == null) {
            callback(Result.failure(unsupported()))
            return
        }
        detector.detectLanguages(texts, callback)
    }

    override fun translate(
        request: HostTranslateRequest,
        callback: (Result<HostTranslationResult>) -> Unit,
    ) {
        val translator = onDeviceTranslator
        if (translator == null) {
            callback(Result.failure(unsupported()))
            return
        }
        translator.translate(request, callback)
    }

    override fun translateBatch(
        request: HostTranslateBatchRequest,
        callback: (Result<List<HostTranslationResult>>) -> Unit,
    ) {
        val translator = onDeviceTranslator
        if (translator == null) {
            callback(Result.failure(unsupported()))
            return
        }
        translator.translateBatch(request, callback)
    }

    private fun unsupported(): FlutterError {
        return FlutterError(
            "unsupportedPlatform",
            "Translation is not available",
            null,
        )
    }
}
