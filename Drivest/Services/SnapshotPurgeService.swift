import Foundation
import SwiftData

enum SnapshotPurgeService {
    static func purgeExpired(context: ModelContext) {
        guard let cutoff = Calendar.current.date(byAdding: .month, value: -6, to: Date()) else { return }
        let predicate = #Predicate<EnergySnapshot> { $0.fetchedAt < cutoff }
        let descriptor = FetchDescriptor<EnergySnapshot>(predicate: predicate)
        guard let expired = try? context.fetch(descriptor) else { return }
        for snapshot in expired {
            context.delete(snapshot)
        }
        try? context.save()
    }
}
