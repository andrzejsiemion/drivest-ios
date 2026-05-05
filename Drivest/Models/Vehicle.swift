import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var name: String
    var make: String?
    var model: String?
    var descriptionText: String?
    var distanceUnit: DistanceUnit?
    var fuelType: FuelType?
    var fuelUnit: FuelUnit?
    var efficiencyDisplayFormat: EfficiencyDisplayFormat?
    var secondTankFuelType: FuelType?
    var secondTankFuelUnit: FuelUnit?
    var photoData: Data?
    var initialOdometer: Double
    var lastUsedAt: Date
    var createdAt: Date
    var vin: String?
    var registrationPlate: String?
    var volvoLastSyncAt: Date?
    var toyotaLastSyncAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \FillUp.vehicle)
    var fillUps: [FillUp]

    @Relationship(deleteRule: .cascade, inverse: \CostEntry.vehicle)
    var costEntries: [CostEntry]

    @Relationship(deleteRule: .cascade)
    var energySnapshots: [EnergySnapshot]

    @Relationship(deleteRule: .cascade)
    var electricityBills: [ElectricityBill]

    @Relationship(deleteRule: .cascade, inverse: \Reminder.vehicle)
    var reminders: [Reminder]

    init(name: String, initialOdometer: Double) {
        self.id = UUID()
        self.name = name
        self.initialOdometer = initialOdometer
        self.lastUsedAt = Date()
        self.createdAt = Date()
        self.fillUps = []
        self.costEntries = []
        self.energySnapshots = []
        self.electricityBills = []
        self.reminders = []
    }

    /// Returns the effective distance unit, falling back to kilometers for legacy vehicles.
    var effectiveDistanceUnit: DistanceUnit {
        distanceUnit ?? .kilometers
    }

    /// Returns the effective fuel unit, falling back to liters for legacy vehicles.
    var effectiveFuelUnit: FuelUnit {
        fuelUnit ?? .liters
    }

    /// Returns the effective efficiency display format, falling back to L/100km for legacy vehicles.
    var effectiveEfficiencyFormat: EfficiencyDisplayFormat {
        efficiencyDisplayFormat ?? .litersPer100km
    }

    /// Display string combining make and model.
    var makeModelDisplay: String? {
        let parts = [make, model].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// The highest odometer reading from all fill-ups, or initialOdometer if none.
    var currentOdometer: Double {
        fillUps.map(\.odometerReading).max() ?? initialOdometer
    }

    /// True when either the primary or second tank is electric — gates EV snapshot and bill features.
    var isEV: Bool { fuelType == .ev || secondTankFuelType == .ev }

    /// True when the vehicle has a supported maker integration (Volvo, Toyota) and a VIN.
    var hasConnectedOBD: Bool {
        guard let make = make?.lowercased(), let vin, !vin.isEmpty else { return false }
        return make == "volvo" || make == "toyota"
    }
}
