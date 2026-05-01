import XCTest
import SwiftData
@testable import Fuel

final class AddFillUpViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var vehicle: Vehicle!

    override func setUpWithError() throws {
        let schema = Schema([Vehicle.self, FillUp.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
        vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)
        try context.save()
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        vehicle = nil
    }

    func testAutoCalculateTotalFromPriceAndVolume() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)

        vm.pricePerLiterText = "1.50"
        vm.onFieldEdited(.pricePerLiter)
        vm.volumeText = "40"
        vm.onFieldEdited(.volume)

        XCTAssertEqual(vm.totalCostText, "60.00")
    }

    func testAutoCalculateVolumeFromPriceAndTotal() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)

        vm.pricePerLiterText = "1.50"
        vm.onFieldEdited(.pricePerLiter)
        vm.totalCostText = "75"
        vm.onFieldEdited(.totalCost)

        XCTAssertEqual(vm.volumeText, "50.00")
    }

    func testAutoCalculatePriceFromVolumeAndTotal() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)

        vm.volumeText = "40"
        vm.onFieldEdited(.volume)
        vm.totalCostText = "60"
        vm.onFieldEdited(.totalCost)

        XCTAssertEqual(vm.pricePerLiterText, "1.500")
    }

    func testValidationFailsForEmptyFields() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)
        XCTAssertFalse(vm.isValid)
    }

    func testValidationPassesForCompleteFields() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)
        vm.pricePerLiterText = "1.50"
        vm.volumeText = "40"
        vm.totalCostText = "60"
        vm.odometerText = "10500"
        XCTAssertTrue(vm.isValid)
    }

    func testOdometerMustBeGreaterThanPrevious() throws {
        // Insert a previous fill-up
        let previous = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(previous)
        try context.save()

        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)
        vm.odometerText = "10400"

        XCTAssertFalse(vm.validateOdometer())
        XCTAssertNotNil(vm.validationError)
    }

    func testOdometerValidWhenGreaterThanPrevious() throws {
        let previous = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(previous)
        try context.save()

        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)
        vm.odometerText = "10800"

        XCTAssertTrue(vm.validateOdometer())
        XCTAssertNil(vm.validationError)
    }

    func testFullTankDefaultsToTrue() {
        let vm = AddFillUpViewModel(modelContext: context, vehicle: vehicle)
        XCTAssertTrue(vm.isFullTank)
    }
}
