import XCTest
import SwiftData
@testable import Fuel

final class EfficiencyCalculatorTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Vehicle.self, FillUp.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testFullTankToFullTank() throws {
        let vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)

        let fillUp1 = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp1)

        let fillUp2 = FillUp(
            pricePerLiter: 1.55,
            volume: 45,
            totalCost: 69.75,
            odometerReading: 11000,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp2)

        try context.save()

        let allFillUps = [fillUp1, fillUp2]
        let efficiency = EfficiencyCalculator.calculateEfficiency(
            for: fillUp2,
            allFillUps: allFillUps
        )

        // 45L / 500km * 100 = 9.0 L/100km
        XCTAssertNotNil(efficiency)
        XCTAssertEqual(efficiency!, 9.0, accuracy: 0.1)
    }

    func testPartialFillAccumulation() throws {
        let vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)

        let fillUp1 = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10000,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp1)

        let partial = FillUp(
            pricePerLiter: 1.60,
            volume: 20,
            totalCost: 32,
            odometerReading: 10300,
            isFullTank: false,
            vehicle: vehicle
        )
        context.insert(partial)

        let fillUp3 = FillUp(
            pricePerLiter: 1.55,
            volume: 30,
            totalCost: 46.50,
            odometerReading: 10600,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp3)

        try context.save()

        let allFillUps = [fillUp1, partial, fillUp3]
        let efficiency = EfficiencyCalculator.calculateEfficiency(
            for: fillUp3,
            allFillUps: allFillUps
        )

        // (20 + 30)L / 600km * 100 = 8.33 L/100km
        XCTAssertNotNil(efficiency)
        XCTAssertEqual(efficiency!, 8.33, accuracy: 0.1)
    }

    func testSingleEntryReturnsNil() throws {
        let vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)

        let fillUp = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp)
        try context.save()

        let efficiency = EfficiencyCalculator.calculateEfficiency(
            for: fillUp,
            allFillUps: [fillUp]
        )

        XCTAssertNil(efficiency)
    }

    func testPartialFillReturnsNil() throws {
        let vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)

        let fillUp = FillUp(
            pricePerLiter: 1.50,
            volume: 20,
            totalCost: 30,
            odometerReading: 10500,
            isFullTank: false,
            vehicle: vehicle
        )
        context.insert(fillUp)
        try context.save()

        let efficiency = EfficiencyCalculator.calculateEfficiency(
            for: fillUp,
            allFillUps: [fillUp]
        )

        XCTAssertNil(efficiency)
    }

    func testRecalculateAllAfterDelete() throws {
        let vehicle = Vehicle(name: "Test Car", initialOdometer: 10000)
        context.insert(vehicle)

        let fillUp1 = FillUp(
            pricePerLiter: 1.50,
            volume: 40,
            totalCost: 60,
            odometerReading: 10000,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp1)

        let fillUp2 = FillUp(
            pricePerLiter: 1.55,
            volume: 50,
            totalCost: 77.50,
            odometerReading: 10500,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp2)

        let fillUp3 = FillUp(
            pricePerLiter: 1.60,
            volume: 45,
            totalCost: 72,
            odometerReading: 11000,
            isFullTank: true,
            vehicle: vehicle
        )
        context.insert(fillUp3)
        try context.save()

        // Remove middle entry and recalculate
        let remainingFillUps = [fillUp1, fillUp3]
        EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: remainingFillUps)

        // fillUp3: 45L / 1000km * 100 = 4.5 L/100km
        XCTAssertNil(fillUp1.efficiency)
        XCTAssertEqual(fillUp3.efficiency!, 4.5, accuracy: 0.1)
    }
}
