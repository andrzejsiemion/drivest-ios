import XCTest
import SwiftData
@testable import Drivest

@MainActor
final class SummaryViewModelTests: XCTestCase {
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

    func testEmptyVehicleShowsZeros() {
        let vm = SummaryViewModel(modelContext: context)
        vm.loadSummary(for: vehicle)

        XCTAssertEqual(vm.allTime.totalCost, 0)
        XCTAssertEqual(vm.allTime.totalVolume, 0)
        XCTAssertEqual(vm.allTime.fillUpCount, 0)
        XCTAssertNil(vm.allTime.averageEfficiency)
        XCTAssertTrue(vm.allTime.isEmpty)
    }

    func testAggregatesAllTimeTotals() throws {
        // Two recent fill-ups so both fall within the last-year and last-month windows.
        let calendar = Calendar.current
        let now = Date()
        let recent1 = calendar.date(byAdding: .day, value: -5, to: now)!
        let recent2 = calendar.date(byAdding: .day, value: -1, to: now)!

        let fillUp1 = FillUp(
            date: recent1,
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp1)

        let fillUp2 = FillUp(
            date: recent2,
            pricePerLiter: 1.55,
            volume: 45,
            totalCost: 69.75,
            odometerReading: 11000,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp2)
        try context.save()

        let vm = SummaryViewModel(modelContext: context)
        vm.loadSummary(for: vehicle)

        XCTAssertEqual(vm.allTime.totalCost, 129.75, accuracy: 0.01)
        XCTAssertEqual(vm.allTime.totalVolume, 85, accuracy: 0.01)
        XCTAssertEqual(vm.allTime.fillUpCount, 2)
        XCTAssertFalse(vm.allTime.isEmpty)
    }

    func testNilVehicleResetsData() {
        let vm = SummaryViewModel(modelContext: context)
        vm.loadSummary(for: nil)

        XCTAssertEqual(vm.allTime.totalCost, 0)
        XCTAssertTrue(vm.allTime.isEmpty)
        XCTAssertTrue(vm.lastMonth.isEmpty)
        XCTAssertTrue(vm.lastYear.isEmpty)
    }
}
