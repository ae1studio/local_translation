import Flutter
import UIKit
import XCTest

@testable import local_translation

class RunnerTests: XCTestCase {
  func testIsSupportedDoesNotCrash() {
    let plugin = LocalTranslationPlugin()
    let expectation = expectation(description: "isSupported")
    plugin.isSupported { result in
      XCTAssertNoThrow(try result.get())
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPlannerInvalidatesTheSameLanguagePair() {
    XCTAssertTrue(
      TranslationSessionPlanner.isSamePair(
        existingSourceTag: "de",
        existingTargetTag: "en",
        sourceTag: "de",
        targetTag: "en"
      )
    )
  }

  func testPlannerCreatesANewSessionForADifferentPair() {
    XCTAssertFalse(
      TranslationSessionPlanner.isSamePair(
        existingSourceTag: "de",
        existingTargetTag: "en",
        sourceTag: "fr",
        targetTag: "en"
      )
    )
    XCTAssertFalse(
      TranslationSessionPlanner.isSamePair(
        existingSourceTag: nil,
        existingTargetTag: "en",
        sourceTag: "de",
        targetTag: "en"
      )
    )
  }

  func testLanguageDetectorHandlesSequentialStrings() {
    let first = LanguageDetector.detect(text: "Hallo Welt, wie geht es dir heute?")
    let second = LanguageDetector.detect(text: "Hello world, how are you today?")

    XCTAssertEqual(first.languageCode, "de")
    XCTAssertEqual(second.languageCode, "en")
    XCTAssertGreaterThan(first.confidence ?? 0, 0)
    XCTAssertGreaterThan(second.confidence ?? 0, 0)
  }

  func testLanguageDetectorPreservesBatchOrder() {
    let results = LanguageDetector.detect(texts: [
      "Hallo Welt, wie geht es dir heute?",
      "Hello world, how are you today?",
      "",
    ])

    XCTAssertEqual(results.map(\.languageCode), ["de", "en", nil])
    XCTAssertEqual(results[2].confidence, 0.0)
  }
}
