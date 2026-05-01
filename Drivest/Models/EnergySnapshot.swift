import Foundation
import SwiftData

@Model
final class EnergySnapshot {
    var id: UUID
    var fetchedAt: Date
    var odometerKm: Double
    var socPercent: Int?
    var source: String
    var createdAt: Date

    @Relationship(inverse: \Vehicle.energySnapshots)
    var vehicle: Vehicle?

    init(fetchedAt: Date, odometerKm: Double, socPercent: Int?, source: String, vehicle: Vehicle) {
        self.id = UUID()
        self.fetchedAt = fetchedAt
        self.odometerKm = odometerKm
        self.socPercent = socPercent
        self.source = source
        self.vehicle = vehicle
        self.createdAt = Date()
    }
}
