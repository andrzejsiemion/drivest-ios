import XCTest
import SwiftData
@testable import Fuel

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

        XCTAssertEqual(vm.totalCost, 0)
        XCTAssertEqual(vm.totalVolume, 0)
        XCTAssertEqual(vm.totalFillUps, 0)
        XCTAssertNil(vm.averageEfficiency)
        XCTAssertTrue(vm.monthlySummaries.isEmpty)
    }

    func testMonthlyAggregation() throws {
        let calendar = Calendar.current
        let jan = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let feb = calendar.date(from: DateComponents(year: 2026, month: 2, day: 10))!

        let fillUp1 = FillUp(
            date: jan,
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp1)

        let fillUp2 = FillUp(
            date: feb,
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

        XCTAssertEqual(vm.totalCost, 129.75, accuracy: 0.01)
        XCTAssertEqual(vm.totalVolume, 85, accuracy: 0.01)
        XCTAssertEqual(vm.totalFillUps, 2)
        XCTAssertEqual(vm.monthlySummaries.count, 2)

        // February should be first (most recent)
        let febSummary = vm.monthlySummaries.first { $0.month == 2 }
        XCTAssertNotNil(febSummary)
        XCTAssertEqual(febSummary!.totalCost, 69.75, accuracy: 0.01)
        XCTAssertEqual(febSummary?.fillUpCount, 1)

    }

    func testNilVehicleResetsData() {
        let vm = SummaryViewModel(modelContext: context)
        vm.loadSummary(for: nil)

        XCTAssertEqual(vm.totalCost, 0)
        XCTAssertTrue(vm.monthlySummaries.isEmpty)
    }
}
