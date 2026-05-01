import Foundation
import SwiftData

struct EfficiencyCalculator {
    /// Calculates L/100km for a full-tank fill-up by accumulating fuel
    /// from all fills since the previous full-tank entry for the same vehicle.
    /// Returns nil if no previous full-tank entry exists.
    static func calculateEfficiency(
        for fillUp: FillUp,
        allFillUps: [FillUp]
    ) -> Double? {
        guard fillUp.isFullTank, let vehicle = fillUp.vehicle else {
            return nil
        }

        let vehicleFillUps = allFillUps
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.date < $1.date }

        guard let currentIndex = vehicleFillUps.firstIndex(where: { $0.id == fillUp.id }) else {
            return nil
        }

        // Find previous full-tank entry
        var previousFullTankIndex: Int?
        for i in stride(from: currentIndex - 1, through: 0, by: -1) {
            if vehicleFillUps[i].isFullTank {
                previousFullTankIndex = i
                break
            }
        }

        guard let prevIndex = previousFullTankIndex else {
            return nil
        }

        let previousFullTank = vehicleFillUps[prevIndex]
        let distance = fillUp.odometerReading - previousFullTank.odometerReading

        guard distance > 0 else {
            return nil
        }

        // Sum fuel from all fills between previous full tank (exclusive) and current (inclusive)
        var totalFuel: Double = 0
        for i in (prevIndex + 1)...currentIndex {
            totalFuel += vehicleFillUps[i].volume
        }

        return (totalFuel / distance) * 100
    }

    /// Recalculates efficiency for all full-tank entries of a vehicle.
    /// Call after editing or deleting a fill-up.
    static func recalculateAll(for vehicle: Vehicle, allFillUps: [FillUp]) {
        let vehicleFillUps = allFillUps
            .filter { $0.vehicle?.id == vehicle.id }
            .sorted { $0.date < $1.date }

        for fillUp in vehicleFillUps {
            if fillUp.isFullTank {
                fillUp.efficiency = calculateEfficiency(
                    for: fillUp,
                    allFillUps: vehicleFillUps
                )
            } else {
                fillUp.efficiency = nil
            }
        }
    }

    /// Formats an efficiency value (stored as L/100km) using the vehicle's preferred display format.
    static func formatEfficiency(_ baseLitersPer100km: Double?, for vehicle: Vehicle?) -> String {
        guard let value = baseLitersPer100km else {
            return "—"
        }
        let format = vehicle?.effectiveEfficiencyFormat ?? .litersPer100km
        return format.format(baseLitersPer100km: value)
    }
}
