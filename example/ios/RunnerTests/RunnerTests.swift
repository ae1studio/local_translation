import Flutter
import UIKit
import XCTest

@testable import local_translation

class RunnerTests: XCTestCase {
  func testIsSupportedDoesNotCrash() {
    let plugin = LocalTranslationPlugin()
    XCTAssertNoThrow(try plugin.isSupported())
  }
}
