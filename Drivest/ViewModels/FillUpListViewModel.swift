import Foundation
import SwiftData
import Observation
import os

@Observable
final class FillUpListViewModel {
    private let modelContext: ModelContext

    var fillUps: [FillUp] = []
    private(set) var groupedFillUps: [(key: String, values: [FillUp])] = []
    var selectedVehicle: Vehicle?
    private(set) var lastFetchedVehicleID: UUID? = nil
    var fetchError: String?

    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "FillUpListViewModel")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func groupByMonth(_ items: [FillUp]) -> [(key: String, values: [FillUp])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        var seen = Set<String>()
        var keys: [String] = []
        var dict: [String: [FillUp]] = [:]
        for item in items {
            let key = formatter.string(from: item.date)
            dict[key, default: []].append(item)
            if seen.insert(key).inserted { keys.append(key) }
        }
        return keys.map { (key: $0, values: dict[$0]!) }
    }

    func fetchFillUps(for vehicle: Vehicle?) {
        lastFetchedVehicleID = vehicle?.id
        selectedVehicle = vehicle
        guard let vehicle else {
            fillUps = []
            groupedFillUps = []
            return
        }

        let descriptor = FetchDescriptor<FillUp>(
            predicate: FillUp.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            fillUps = try modelContext.fetch(descriptor)
            fetchError = nil
        } catch {
            log.error("FillUp fetch failed: \(error.localizedDescription)")
            fetchError = "Failed to load fill-ups."
            fillUps = []
        }
        groupedFillUps = groupByMonth(fillUps)
    }

    func deleteFillUp(_ fillUp: FillUp) {
        let vehicle = fillUp.vehicle
        modelContext.delete(fillUp)
        fillUps.removeAll { $0.id == fillUp.id }

        if let vehicle {
            EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: fillUps)
        }

        Persistence.save(modelContext)
        groupedFillUps = groupByMonth(fillUps)
    }

    func deleteFillUps(at offsets: IndexSet) {
        let toDelete = offsets.map { fillUps[$0] }
        let vehicle = toDelete.first?.vehicle
        for fillUp in toDelete {
            modelContext.delete(fillUp)
        }
        fillUps.removeAll { item in toDelete.contains(where: { $0.id == item.id }) }
        if let vehicle {
            EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: fillUps)
        }
        Persistence.save(modelContext)
        groupedFillUps = groupByMonth(fillUps)
    }
}
