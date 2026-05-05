import Foundation
import SwiftData
import Observation

// MARK: - VehicleSelectionStore

@Observable
final class VehicleSelectionStore {
    var selectedVehicle: Vehicle?
    var sortOrder: VehicleSortOrder {
        didSet { AppPreferences.vehicleSortOrder = sortOrder }
    }
    var customOrder: [UUID] {
        didSet { saveCustomOrder() }
    }

    init() {
        self.sortOrder = AppPreferences.vehicleSortOrder
        self.customOrder = Self.loadCustomOrder()
    }

    func sortedVehicles(_ vehicles: [Vehicle]) -> [Vehicle] {
        switch sortOrder {
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

    func selectVehicle(_ vehicle: Vehicle, modelContext: ModelContext? = nil) {
        selectedVehicle = vehicle
        vehicle.lastUsedAt = Date()
        if let ctx = modelContext { Persistence.save(ctx) }
        UserDefaults.standard.set(vehicle.id.uuidString, forKey: "selectedVehicleID")
    }

    func restoreSelection(from vehicles: [Vehicle]) {
        guard selectedVehicle == nil else { return }
        if let storedID = UserDefaults.standard.string(forKey: "selectedVehicleID"),
           let uuid = UUID(uuidString: storedID),
           let match = vehicles.first(where: { $0.id == uuid }) {
            selectedVehicle = match
        } else {
            selectedVehicle = sortedVehicles(vehicles).first
        }
    }

    func updateCustomOrder(_ vehicles: [Vehicle]) {
        customOrder = vehicles.map(\.id)
    }

    private func saveCustomOrder() {
        let strings = customOrder.map(\.uuidString)
        if let data = try? JSONEncoder().encode(strings) {
            UserDefaults.standard.set(data, forKey: "customVehicleOrder")
        }
    }

    private static func loadCustomOrder() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: "customVehicleOrder"),
              let strings = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return strings.compactMap { UUID(uuidString: $0) }
    }
}
