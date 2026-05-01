import Foundation
import SwiftData

@Model
final class ElectricityBill {
    var id: UUID
    var startDate: Date?
    var endDate: Date
    var totalKwh: Double
    var totalCost: Double
    var currencyCode: String?
    var distanceKm: Double?
    var efficiencyKwhPer100km: Double?
    var costPerKm: Double?
    var hasSnapshotData: Bool
    var startSnapshotId: UUID?
    var endSnapshotId: UUID?
    var createdAt: Date

    @Relationship(inverse: \Vehicle.electricityBills)
    var vehicle: Vehicle?

    init(startDate: Date? = nil, endDate: Date, totalKwh: Double, totalCost: Double, currencyCode: String?, vehicle: Vehicle) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.totalKwh = totalKwh
        self.totalCost = totalCost
        self.currencyCode = currencyCode
        self.hasSnapshotData = false
        self.vehicle = vehicle
        self.createdAt = Date()
    }
}
