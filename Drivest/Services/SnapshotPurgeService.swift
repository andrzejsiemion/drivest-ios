import Foundation
import SwiftData

enum SnapshotPurgeService {

    /// Keeps the last snapshot per calendar day per vehicle and removes
    /// any snapshot older than 2 years. Bills whose period falls outside
    /// the 2-year window are marked read-only via ElectricityBill.isLocked.
    static func purgeAndDeduplicate(context: ModelContext) {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<EnergySnapshot>()
        guard let all = try? context.fetch(descriptor) else { return }

        // Group by vehicle + calendar day
        var groups: [String: [EnergySnapshot]] = [:]
        for snapshot in all {
            let day = calendar.startOfDay(for: snapshot.fetchedAt)
            let vehicleId = snapshot.vehicle?.id.uuidString ?? "unknown"
            let key = "\(vehicleId)|\(day.timeIntervalSinceReferenceDate)"
            groups[key, default: []].append(snapshot)
        }

        let today = calendar.startOfDay(for: Date())
        var didDelete = false
        for var group in groups.values {
            // Sort newest first
            group.sort { $0.fetchedAt > $1.fetchedAt }
            // Keep all snapshots from today; deduplicate past days
            let groupDay = group.first.map { calendar.startOfDay(for: $0.fetchedAt) }
            guard groupDay != today else { continue }
            for duplicate in group.dropFirst() {
                context.delete(duplicate)
                didDelete = true
            }
            // Delete the keeper if it is older than 2 years
            if let keeper = group.first, keeper.fetchedAt < cutoff {
                context.delete(keeper)
                didDelete = true
            }
        }

        if didDelete { try? context.save() }
    }
}
