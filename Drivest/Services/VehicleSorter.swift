import Foundation

/// Pure, stateless vehicle sorting. No UserDefaults access.
enum VehicleSorter {
    static func sorted(_ vehicles: [Vehicle], by order: VehicleSortOrder, customOrder: [UUID]) -> [Vehicle] {
        switch order {
        case .lastUsed:
            return vehicles.sorted { $0.lastUsedAt > $1.lastUsedAt }
        case .alphabetical:
            return vehicles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            return vehicles.sorted { $0.createdAt < $1.createdAt }
        case .custom:
            return vehicles.sorted { a, b in
                let indexA = customOrder.firstIndex(of: a.id) ?? Int.max
                let indexB = customOrder.firstIndex(of: b.id) ?? Int.max
                return indexA < indexB
            }
        }
    }
}
