import XCTest

final class FillUpFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    func testCompleteFlowAddVehicleAndFillUp() throws {
        // Step 1: Add a vehicle (empty state should show)
        let addVehicleButton = app.buttons["Add Vehicle"]
        if addVehicleButton.waitForExistence(timeout: 3) {
            addVehicleButton.tap()
        } else {
            // If vehicles exist, go to vehicle list
            app.buttons["car.2"].tap()
            app.buttons["plus"].tap()
        }

        // Fill vehicle form
        let nameField = app.textFields["Vehicle Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("My Car")

        let odometerField = app.textFields["Initial Odometer (km)"]
        odometerField.tap()
        odometerField.typeText("50000")

        app.buttons["Save"].tap()

        // Step 2: Add a fill-up
        // Wait for the main screen then tap "+"
        let addButton = app.buttons["plus"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        // Fill the form
        let priceField = app.textFields["Price per Liter"]
        XCTAssertTrue(priceField.waitForExistence(timeout: 3))
        priceField.tap()
        priceField.typeText("1.55")

        let volumeField = app.textFields["Volume (Liters)"]
        volumeField.tap()
        volumeField.typeText("42")

        let odometerFillField = app.textFields["Odometer Reading (km)"]
        odometerFillField.tap()
        odometerFillField.typeText("50500")

        app.buttons["Save"].tap()

        // Step 3: Verify fill-up appears in list
        XCTAssertTrue(app.staticTexts["42.00 L @ 1.550/L"].waitForExistence(timeout: 3))
    }
}
