import Foundation
import SwiftData

enum FetchTrigger: String, Codable {
    case scheduled
    case manual
}

@Model
final class EnergySnapshot {
    var id: UUID
    var fetchedAt: Date
    var odometerKm: Double
    var socPercent: Int?
    var source: String
    var fetchTrigger: String = "scheduled"  // raw value of FetchTrigger
    var createdAt: Date

    @Relationship(inverse: \Vehicle.energySnapshots)
    var vehicle: Vehicle?

    init(fetchedAt: Date, odometerKm: Double, socPercent: Int?, source: String,
         fetchTrigger: FetchTrigger = .scheduled, vehicle: Vehicle) {
        self.id = UUID()
        self.fetchedAt = fetchedAt
        self.odometerKm = odometerKm
        self.socPercent = socPercent
        self.source = source
        self.fetchTrigger = fetchTrigger.rawValue
        self.vehicle = vehicle
        self.createdAt = Date()
    }
}
