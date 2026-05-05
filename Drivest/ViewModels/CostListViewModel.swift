import Foundation
import SwiftData
import Observation
import os

@Observable
final class CostListViewModel {
    private let modelContext: ModelContext
    private var currentVehicle: Vehicle?
    var costEntries: [CostEntry] = []
    private(set) var groupedCostEntries: [(key: String, values: [CostEntry])] = []
    var fetchError: String?

    private let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "CostListViewModel")

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchCosts(for vehicle: Vehicle?) {
        currentVehicle = vehicle
        guard let vehicle else {
            costEntries = []
            groupedCostEntries = []
            return
        }
        let descriptor = FetchDescriptor<CostEntry>(
            predicate: CostEntry.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            costEntries = try modelContext.fetch(descriptor)
            fetchError = nil
        } catch {
            log.error("Cost fetch failed: \(error.localizedDescription)")
            fetchError = "Failed to load costs."
            costEntries = []
        }
        groupedCostEntries = MonthGrouper.group(costEntries, dateKeyPath: \.date)
    }

    func deleteCost(_ entry: CostEntry) {
        modelContext.delete(entry)
        Persistence.save(modelContext)
        fetchCosts(for: currentVehicle)
    }

    var totalAmount: Double {
        costEntries.reduce(0) { $0 + $1.amount }
    }
}
