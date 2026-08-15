import Flutter
import UIKit
import XCTest

@testable import local_translation

class RunnerTests: XCTestCase {
  func testIsSupportedDoesNotCrash() {
    let plugin = LocalTranslationPlugin()
    let expectation = expectation(description: "isSupported")
    plugin.isSupported { result in
      if case .failure(let error) = result {
        XCTFail("isSupported failed: \(error)")
      }
      expectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPlannerCreatesConfigurationOnTheFirstRequest() {
    XCTAssertEqual(
      TranslationSessionPlanner.configurationUpdate(
        hasExistingConfiguration: false,
        existingSourceTag: nil,
        existingTargetTag: nil,
        sourceTag: "de",
        targetTag: "en"
      ),
      .create
    )
  }

  func testPlannerInvalidatesTheSameLanguagePair() {
    XCTAssertEqual(
      TranslationSessionPlanner.configurationUpdate(
        hasExistingConfiguration: true,
        existingSourceTag: "de",
        existingTargetTag: "en",
        sourceTag: "de",
        targetTag: "en"
      ),
      .invalidate
    )
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
    XCTAssertEqual(
      TranslationSessionPlanner.configurationUpdate(
        hasExistingConfiguration: true,
        existingSourceTag: "de",
        existingTargetTag: "en",
        sourceTag: "fr",
        targetTag: "en"
      ),
      .create
    )
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

  func testLanguageDetectorHandlesBlankText() {
    let empty = LanguageDetector.detect(text: "")
    let whitespace = LanguageDetector.detect(text: "  \n\t")

    XCTAssertNil(empty.languageCode)
    XCTAssertEqual(empty.confidence, 0)
    XCTAssertNil(whitespace.languageCode)
    XCTAssertEqual(whitespace.confidence, 0)
  }

  func testLanguageDetectorPreservesBatchOrder() {
    let results = LanguageDetector.detect(texts: [
      "Hallo Welt, wie geht es dir heute?",
      "",
      "Hello world, how are you today?",
    ])

    XCTAssertEqual(results.count, 3)
    XCTAssertNil(results[1].languageCode)
    XCTAssertEqual(results[1].confidence, 0)
    if results[0].languageCode != nil || results[2].languageCode != nil {
      XCTAssertNotEqual(results[0].languageCode, results[2].languageCode)
    }
  }
}
