import Cocoa
import FlutterMacOS
import XCTest

@testable import local_translation

class RunnerTests: XCTestCase {
  func testIsSupportedDoesNotCrash() {
    let plugin = LocalTranslationPlugin()
    XCTAssertNoThrow(try plugin.isSupported())
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
