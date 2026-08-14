import Foundation
import NaturalLanguage

enum LanguageDetector {
  static func detect(text: String) -> HostLanguageDetection {
    detect(texts: [text])[0]
  }

  static func detect(texts: [String]) -> [HostLanguageDetection] {
    let recognizer = NLLanguageRecognizer()
    return texts.map { text in
      recognizer.reset()
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty {
        return HostLanguageDetection(languageCode: nil, confidence: 0)
      }
      recognizer.processString(text)
      let languageCode = recognizer.dominantLanguage?.rawValue
      let confidence = recognizer.languageHypotheses(withMaximum: 1).values.first ?? 0
      return HostLanguageDetection(languageCode: languageCode, confidence: confidence)
    }
  }
}
