import Foundation
import SwiftData

/// Handles insertion and deduplication of CostEntry records during import.
struct CostImporter {

    static func insert(
        _ backups: [CostEntryBackup],
        into modelContext: ModelContext,
        vehicle: Vehicle,
        strategy: VehicleImporter.ConflictStrategy
    ) {
        for cb in backups {
            if strategy == .merge {
                let backupID = UUID(uuidString: cb.id)
                let exists = vehicle.costEntries.contains { $0.id == backupID }
                if exists { continue }
            }

            let categoryName = cb.categoryName ?? cb.title
            let categoryIcon = lookupCategoryIcon(name: categoryName, in: modelContext)

            let entry = CostEntry(
                date: cb.date,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                amount: cb.amount,
                note: cb.note
            )
            if let backupID = UUID(uuidString: cb.id) { entry.id = backupID }
            entry.currencyCode = cb.currencyCode
            entry.exchangeRate = cb.exchangeRate
            entry.vehicle = vehicle
            entry.photos = cb.attachments.compactMap { Data(base64Encoded: $0) }
            modelContext.insert(entry)
        }
    }

    private static func lookupCategoryIcon(name: String, in modelContext: ModelContext) -> String {
        let descriptor = FetchDescriptor<CostCategory>(
            predicate: #Predicate { $0.name == name }
        )
        if let found = try? modelContext.fetch(descriptor), let category = found.first {
            return category.iconName
        }
        return "tag.fill"
    }
}
