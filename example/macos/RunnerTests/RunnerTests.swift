import Cocoa
import FlutterMacOS
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
  }

  func testLanguageDetectorHandlesSequentialStrings() {
    let first = LanguageDetector.detect(text: "Hallo Welt, wie geht es dir heute?")
    let second = LanguageDetector.detect(text: "Hello world, how are you today?")

    XCTAssertEqual(first.languageCode, "de")
    XCTAssertEqual(second.languageCode, "en")
  }
}
