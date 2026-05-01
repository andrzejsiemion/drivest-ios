import Foundation
import SwiftData
import Observation

@Observable
final class CostListViewModel {
    private let modelContext: ModelContext
    private var currentVehicle: Vehicle?
    var costEntries: [CostEntry] = []
    private(set) var groupedCostEntries: [(key: String, values: [CostEntry])] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func groupByMonth(_ items: [CostEntry]) -> [(key: String, values: [CostEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        var seen = Set<String>()
        var keys: [String] = []
        var dict: [String: [CostEntry]] = [:]
        for item in items {
            let key = formatter.string(from: item.date)
            dict[key, default: []].append(item)
            if seen.insert(key).inserted { keys.append(key) }
        }
        return keys.map { (key: $0, values: dict[$0]!) }
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
        costEntries = (try? modelContext.fetch(descriptor)) ?? []
        groupedCostEntries = groupByMonth(costEntries)
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
