import Foundation
import Observation
import SwiftData

@Observable
final class SnapshotHistoryViewModel {
    var sections: [(monthLabel: String, snapshots: [EnergySnapshot])] = []
    var isLoading = false
    var errorMessage: String?

    func load(for vehicle: Vehicle, context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let vehicleID = vehicle.persistentModelID
        let descriptor = FetchDescriptor<EnergySnapshot>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor) else { return }

        let vehicleSnapshots = all.filter { $0.vehicle?.persistentModelID == vehicleID }
        sections = group(snapshots: vehicleSnapshots)
    }

    func deleteSnapshot(_ snapshot: EnergySnapshot, context: ModelContext) {
        context.delete(snapshot)
        try? context.save()
        sections = sections.compactMap { section in
            let remaining = section.snapshots.filter { $0.persistentModelID != snapshot.persistentModelID }
            return remaining.isEmpty ? nil : (monthLabel: section.monthLabel, snapshots: remaining)
        }
    }

    func triggerManualFetch(for vehicle: Vehicle, context: ModelContext) async {
        do {
            try await SnapshotFetchService.shared.fetch(vehicle: vehicle, context: context)
            load(for: vehicle, context: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func group(snapshots: [EnergySnapshot]) -> [(monthLabel: String, snapshots: [EnergySnapshot])] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "LLLL yyyy"

        var grouped: [(monthLabel: String, snapshots: [EnergySnapshot])] = []
        var currentLabel = ""
        var currentGroup: [EnergySnapshot] = []

        for snapshot in snapshots {
            let label = formatter.string(from: snapshot.fetchedAt)
            if label != currentLabel {
                if !currentGroup.isEmpty {
                    grouped.append((monthLabel: currentLabel, snapshots: currentGroup))
                }
                currentLabel = label
                currentGroup = [snapshot]
            } else {
                currentGroup.append(snapshot)
            }
        }
        if !currentGroup.isEmpty {
            grouped.append((monthLabel: currentLabel, snapshots: currentGroup))
        }
        return grouped
    }
}
