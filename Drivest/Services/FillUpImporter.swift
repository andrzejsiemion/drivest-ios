import Foundation
import SwiftData

/// Handles insertion and deduplication of FillUp records during import.
struct FillUpImporter {

    static func insert(
        _ backups: [FillUpBackup],
        into modelContext: ModelContext,
        vehicle: Vehicle,
        strategy: VehicleImporter.ConflictStrategy
    ) {
        for fb in backups {
            if strategy == .merge {
                let backupID = UUID(uuidString: fb.id)
                let exists = vehicle.fillUps.contains { $0.id == backupID }
                if exists { continue }
            }

            let f = FillUp(
                date: fb.date,
                pricePerLiter: fb.pricePerLiter,
                volume: fb.volume,
                totalCost: fb.totalCost,
                odometerReading: fb.odometerReading,
                isFullTank: fb.isFullTank,
                vehicle: vehicle,
                note: fb.note,
                fuelType: fb.fuelType.flatMap { FuelType(rawValue: $0) }
            )
            if let backupID = UUID(uuidString: fb.id) { f.id = backupID }
            f.efficiency = fb.efficiency
            f.currencyCode = fb.currencyCode
            f.exchangeRate = fb.exchangeRate
            f.discount = fb.discount
            f.photos = fb.photos.compactMap { Data(base64Encoded: $0) }
            modelContext.insert(f)
        }
    }
}
