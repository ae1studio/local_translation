#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#endif

public class LocalTranslationPlugin: NSObject, FlutterPlugin, LocalTranslationHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LocalTranslationPlugin()
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    LocalTranslationHostApiSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func isSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
    if #available(iOS 18.0, macOS 15.0, *) {
      #if targetEnvironment(simulator)
        completion(.success(false))
      #else
        completion(.success(true))
      #endif
    } else {
      completion(.success(false))
    }
  }

  func detectLanguage(
    text: String,
    completion: @escaping (Result<HostLanguageDetection, Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      completion(.success(LanguageDetector.detect(text: text)))
    }
  }

  func detectLanguages(
    texts: [String],
    completion: @escaping (Result<[HostLanguageDetection], Error>) -> Void
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      completion(.success(LanguageDetector.detect(texts: texts)))
    }
  }

  func translate(
    request: HostTranslateRequest,
    completion: @escaping (Result<HostTranslationResult, Error>) -> Void
  ) {
    guard let text = request.text, let targetLanguage = request.targetLanguage else {
      completion(.failure(Self.missingArgument("Missing text or target language")))
      return
    }
    #if canImport(Translation)
      if #available(iOS 18.0, macOS 15.0, *) {
        Task { @MainActor in
          do {
            let value = try await TranslationSessionHost.shared.translate(
              text: text,
              sourceLanguage: request.sourceLanguage,
              targetLanguage: targetLanguage
            )
            completion(.success(value))
          } catch {
            completion(.failure(Self.mapError(error)))
          }
        }
        return
      }
    #endif
    completion(.failure(Self.unsupportedPlatform))
  }

  func translateBatch(
    request: HostTranslateBatchRequest,
    completion: @escaping (Result<[HostTranslationResult], Error>) -> Void
  ) {
    guard let texts = request.texts, let targetLanguage = request.targetLanguage else {
      completion(.failure(Self.missingArgument("Missing texts or target language")))
      return
    }
    #if canImport(Translation)
      if #available(iOS 18.0, macOS 15.0, *) {
        Task { @MainActor in
          do {
            let value = try await TranslationSessionHost.shared.translateBatch(
              texts: texts,
              sourceLanguage: request.sourceLanguage,
              targetLanguage: targetLanguage
            )
            completion(.success(value))
          } catch {
            completion(.failure(Self.mapError(error)))
          }
        }
        return
      }
    #endif
    completion(.failure(Self.unsupportedPlatform))
  }

  private static let unsupportedPlatform = PigeonError(
    code: "unsupportedPlatform",
    message: "Translation requires iOS 18 or later on a physical device, or macOS 15 or later",
    details: nil
  )

  private static func missingArgument(_ message: String) -> PigeonError {
    PigeonError(code: "unknown", message: message, details: nil)
  }

  private static func mapError(_ error: Error) -> PigeonError {
    if let pigeonError = error as? PigeonError {
      return pigeonError
    }
    let message = error.localizedDescription
    let lower = message.lowercased()
    if lower.contains("cancel") || lower.contains("dismiss") {
      return PigeonError(code: "cancelled", message: message, details: nil)
    }
    if lower.contains("unsupported") || lower.contains("language") {
      return PigeonError(code: "unsupportedLanguagePair", message: message, details: nil)
    }
    return PigeonError(code: "unknown", message: message, details: nil)
  }
}
