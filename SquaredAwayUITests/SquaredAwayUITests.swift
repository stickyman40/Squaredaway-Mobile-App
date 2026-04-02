//
//  SquaredAwayUITests.swift
//  SquaredAwayUITests
//
//  Created by Jayland stitt on 3/23/26.
//

import XCTest

final class SquaredAwayUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testFuelCheckLaunchesFromUITestEntryPoint() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SKIP_SPLASH", "UITEST_AUTHENTICATED", "UITEST_SHOW_FUEL_CHECK"]
        app.launch()

        XCTAssertTrue(app.buttons["fuel-check-tab-fuel-check"].waitForExistence(timeout: 8), "Fuel Check tab button did not appear after opening the feature.")
        XCTAssertTrue(app.buttons["fuel-check-tab-chow-log"].waitForExistence(timeout: 8), "Chow Log tab button did not appear after opening Fuel Check.")
        XCTAssertTrue(app.descendants(matching: .any)["fuel-check-scan-button"].waitForExistence(timeout: 8), "Fuel Check scan CTA did not appear.")
    }

    @MainActor
    func testPTLaunchesFromUITestEntryPoint() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SKIP_SPLASH", "UITEST_AUTHENTICATED", "UITEST_SHOW_PT"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["pt-summary-current-weight"].waitForExistence(timeout: 8), "PT current weight summary did not appear.")
        XCTAssertTrue(app.buttons["pt-quick-action-log-workout"].waitForExistence(timeout: 8), "PT log workout quick action did not appear.")
        XCTAssertTrue(app.buttons["pt-quick-action-pt-score"].waitForExistence(timeout: 8), "PT score quick action did not appear.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
