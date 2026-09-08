import XCTest

final class MobileLayoutTests: XCTestCase {
  @MainActor
  func testCopyAndEndpointDialog() {
    let app = XCUIApplication()
    app.launchArguments = ["-BuzzPreviewHome"]
    app.launch()
    let copy = app.buttons["Copy Setup Message"]
    XCTAssertTrue(copy.waitForExistence(timeout: 10))
    XCTAssertTrue(copy.isHittable)
    copy.tap()
    XCTAssertTrue(app.buttons["Copied Setup Message"].waitForExistence(timeout: 2))
    app.buttons["More"].tap()
    app.buttons["Show endpoint"].tap()
    let done = app.buttons["Done"]
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    XCTAssertTrue(done.isHittable)
    done.tap()
    XCTAssertTrue(done.waitForNonExistence(timeout: 5))
    app.buttons["More"].tap()
    app.buttons["Show endpoint"].tap()
    XCTAssertTrue(done.waitForExistence(timeout: 5))
    done.tap()
    XCTAssertTrue(done.waitForNonExistence(timeout: 5))
  }
  @MainActor
  func testUnpairedLaunchCanPreviewWithoutConnecting() {
    let app = XCUIApplication()
    app.launchArguments = ["-BuzzPreviewUnpaired"]
    app.launch()
    XCTAssertTrue(app.staticTexts["Connect an agent"].waitForExistence(timeout: 10))
    XCTAssertFalse(app.buttons["Get started"].exists)
    app.buttons["More"].tap()
    app.buttons["Preview Screens"].tap()
    XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Waiting on you"].firstMatch.waitForExistence(timeout: 5))
    let copyButtons = app.buttons.matching(
      NSPredicate(format: "label == %@ AND enabled == true", "Copy Setup Message")
    ).allElementsBoundByIndex
    XCTAssertTrue(copyButtons.contains { $0.isHittable })
    XCTAssertTrue(app.staticTexts["Preview"].exists)
    app.buttons["Done"].tap()
    XCTAssertTrue(app.buttons["Done"].waitForNonExistence(timeout: 5))
  }
}
