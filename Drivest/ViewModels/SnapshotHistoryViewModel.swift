import Foundation
import Observation
import SwiftData
import os

@Observable
final class SnapshotHistoryViewModel {
    var sections: [(monthLabel: String, snapshots: [EnergySnapshot])] = []
    var isLoading = false
    var errorMessage: String?

    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "SnapshotHistoryViewModel")

    func load(for vehicle: Vehicle, context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let vehicleID = vehicle.persistentModelID
        let descriptor = FetchDescriptor<EnergySnapshot>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        do {
            let all = try context.fetch(descriptor)
            let vehicleSnapshots = all.filter { $0.vehicle?.persistentModelID == vehicleID }
            let grouped = MonthGrouper.group(vehicleSnapshots, dateKeyPath: \.fetchedAt)
            sections = grouped.map { (monthLabel: $0.key, snapshots: $0.values) }
            errorMessage = nil
        } catch {
            log.error("Snapshot fetch failed: \(error.localizedDescription)")
            errorMessage = "Failed to load snapshots."
            sections = []
        }
    }

    func deleteSnapshot(_ snapshot: EnergySnapshot, context: ModelContext) {
        context.delete(snapshot)
        Persistence.save(context)
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
}
