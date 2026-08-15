#if canImport(Translation)
  import Combine
  import SwiftUI
  import Translation
  #if os(iOS)
    import UIKit
  #elseif os(macOS)
    import AppKit
  #endif
#endif

#if canImport(Translation)
  @available(iOS 18.0, macOS 15.0, *)
  @MainActor
  final class TranslationSessionHost {
    static let shared = TranslationSessionHost()

    private let model = TranslationHostModel()
    #if os(iOS)
      private var hostingController: UIHostingController<TranslationHostView>?
    #elseif os(macOS)
      private var hostingController: NSHostingController<TranslationHostView>?
    #endif
    private var appearWaiter: CheckedContinuation<Void, Never>?
    private var viewAppeared = false
    private var tail: Task<Void, Never>?

    func translate(
      text: String,
      sourceLanguage: String?,
      targetLanguage: String
    ) async throws -> HostTranslationResult {
      try await enqueue {
        try await self.performTranslate(
          text: text,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage
        )
      }
    }

    func translateBatch(
      texts: [String],
      sourceLanguage: String?,
      targetLanguage: String
    ) async throws -> [HostTranslationResult] {
      try await enqueue {
        try await self.performTranslateBatch(
          texts: texts,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage
        )
      }
    }

    private func enqueue<T>(
      _ work: @escaping @MainActor () async throws -> T
    ) async throws -> T {
      let previous = tail
      let task = Task { @MainActor in
        await previous?.value
        return try await work()
      }
      tail = Task { @MainActor in
        _ = try? await task.value
      }
      return try await task.value
    }

    private func performTranslate(
      text: String,
      sourceLanguage: String?,
      targetLanguage: String
    ) async throws -> HostTranslationResult {
      let source = sourceLanguage.map { Locale.Language(identifier: $0) }
      let target = Locale.Language(identifier: targetLanguage)
      return try await withSession(source: source, target: target) { session in
        let response = try await session.translate(text)
        return HostTranslationResult(
          sourceText: text,
          translatedText: response.targetText,
          sourceLanguage: Self.languageTag(response.sourceLanguage) ?? sourceLanguage,
          targetLanguage: Self.languageTag(response.targetLanguage) ?? targetLanguage
        )
      }
    }

    private func performTranslateBatch(
      texts: [String],
      sourceLanguage: String?,
      targetLanguage: String
    ) async throws -> [HostTranslationResult] {
      if texts.isEmpty {
        return []
      }
      if let sourceLanguage {
        return try await translateSameLanguage(
          texts: texts,
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage
        )
      }

      let detections = LanguageDetector.detect(texts: texts)
      var groups: [String: [(Int, String)]] = [:]
      var unknown: [(Int, String)] = []
      for (index, text) in texts.enumerated() {
        if let code = detections[index].languageCode {
          groups[code, default: []].append((index, text))
        } else {
          unknown.append((index, text))
        }
      }

      var results = [HostTranslationResult?](repeating: nil, count: texts.count)
      for (code, items) in groups {
        let translated = try await translateSameLanguage(
          texts: items.map(\.1),
          sourceLanguage: code,
          targetLanguage: targetLanguage
        )
        for (offset, item) in items.enumerated() {
          results[item.0] = translated[offset]
        }
      }
      for (index, text) in unknown {
        results[index] = try await performTranslate(
          text: text,
          sourceLanguage: nil,
          targetLanguage: targetLanguage
        )
      }
      return try results.map { result in
        guard let result else {
          throw PigeonError(
            code: "unknown",
            message: "Missing translation result",
            details: nil
          )
        }
        return result
      }
    }

    private func translateSameLanguage(
      texts: [String],
      sourceLanguage: String,
      targetLanguage: String
    ) async throws -> [HostTranslationResult] {
      let source = Locale.Language(identifier: sourceLanguage)
      let target = Locale.Language(identifier: targetLanguage)
      return try await withSession(source: source, target: target) { session in
        let requests = texts.enumerated().map { index, text in
          TranslationSession.Request(sourceText: text, clientIdentifier: String(index))
        }
        let responses = try await session.translations(from: requests)
        return zip(texts, responses).map { text, response in
          HostTranslationResult(
            sourceText: text,
            translatedText: response.targetText,
            sourceLanguage: Self.languageTag(response.sourceLanguage) ?? sourceLanguage,
            targetLanguage: Self.languageTag(response.targetLanguage) ?? targetLanguage
          )
        }
      }
    }

    private func withSession<T>(
      source: Locale.Language?,
      target: Locale.Language,
      operation: @escaping (TranslationSession) async throws -> T
    ) async throws -> T {
      try await attachIfNeeded()
      return try await withCheckedThrowingContinuation { continuation in
        var resumed = false
        func resume(_ result: Result<T, Error>) {
          guard !resumed else { return }
          resumed = true
          continuation.resume(with: result)
        }
        model.sessionHandler = { session in
          do {
            if source != nil {
              try await session.prepareTranslation()
            }
            let value = try await operation(session)
            resume(.success(value))
          } catch {
            resume(.failure(error))
          }
        }
        model.source = source
        model.target = target
        model.generation += 1
      }
    }

    static func languageTag(_ language: Locale.Language?) -> String? {
      language?.minimalIdentifier
    }

    private func attachIfNeeded() async throws {
      if hostingController == nil {
        model.onAppear = { [weak self] in
          guard let self else { return }
          self.viewAppeared = true
          self.appearWaiter?.resume()
          self.appearWaiter = nil
        }
        try Self.attachHost(TranslationHostView(model: model), storingIn: &hostingController)
      }
      if !viewAppeared {
        await withCheckedContinuation { continuation in
          if viewAppeared {
            continuation.resume()
          } else {
            appearWaiter = continuation
          }
        }
      }
    }

    #if os(iOS)
      private static func attachHost(
        _ view: TranslationHostView,
        storingIn hostingController: inout UIHostingController<TranslationHostView>?
      ) throws {
        guard let root = rootViewController() else {
          throw PigeonError(
            code: "unknown",
            message: "No root view controller available for translation",
            details: nil
          )
        }
        let host = PassthroughHostingController(rootView: view)
        host.view.backgroundColor = .clear
        host.view.isOpaque = false
        host.definesPresentationContext = true
        host.view.frame = root.view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        root.addChild(host)
        root.view.addSubview(host.view)
        host.didMove(toParent: root)
        hostingController = host
      }

      private static func rootViewController() -> UIViewController? {
        let windows = UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
        let window = windows.first(where: \.isKeyWindow) ?? windows.first
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController {
          controller = presented
        }
        return controller
      }

      private final class PassthroughHostingController<Content: View>: UIHostingController<Content> {
        override func viewDidLoad() {
          super.viewDidLoad()
          view.backgroundColor = .clear
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
          let hit = super.hitTest(point, with: event)
          return hit === view ? nil : hit
        }
      }
    #elseif os(macOS)
      private static func attachHost(
        _ view: TranslationHostView,
        storingIn hostingController: inout NSHostingController<TranslationHostView>?
      ) throws {
        guard let contentView = rootContentView() else {
          throw PigeonError(
            code: "unknown",
            message: "No window available for translation",
            details: nil
          )
        }
        let host = NSHostingController(rootView: view)
        host.view.wantsLayer = true
        host.view.layer?.backgroundColor = NSColor.clear.cgColor
        host.view.frame = contentView.bounds
        host.view.autoresizingMask = [.width, .height]
        contentView.addSubview(host.view)
        hostingController = host
      }

      private static func rootContentView() -> NSView? {
        let windows = NSApplication.shared.windows
        let window = windows.first(where: \.isKeyWindow) ?? windows.first
        return window?.contentView
      }
    #endif
  }

  @available(iOS 18.0, macOS 15.0, *)
  final class TranslationHostModel: ObservableObject {
    @Published var generation = 0
    var source: Locale.Language?
    var target: Locale.Language = Locale.Language(identifier: "en")
    var sessionHandler: ((TranslationSession) async -> Void)?
    var onAppear: (() -> Void)?
  }

  @available(iOS 18.0, macOS 15.0, *)
  struct TranslationHostView: View {
    @ObservedObject var model: TranslationHostModel
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
      Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onAppear { model.onAppear?() }
        .onChange(of: model.generation) { _, generation in
          guard generation > 0 else { return }
          applyConfiguration()
        }
        .translationTask(configuration) { session in
          let handler = model.sessionHandler
          model.sessionHandler = nil
          await handler?(session)
        }
    }

    private func applyConfiguration() {
      let update = TranslationSessionPlanner.configurationUpdate(
        hasExistingConfiguration: configuration != nil,
        existingSourceTag: TranslationSessionHost.languageTag(configuration?.source),
        existingTargetTag: TranslationSessionHost.languageTag(configuration?.target),
        sourceTag: TranslationSessionHost.languageTag(model.source),
        targetTag: TranslationSessionHost.languageTag(model.target)
      )
      switch update {
      case .invalidate:
        guard var existing = configuration else { return }
        existing.invalidate()
        configuration = existing
      case .create:
        configuration = TranslationSession.Configuration(
          source: model.source,
          target: model.target
        )
      }
    }
  }
#endif
