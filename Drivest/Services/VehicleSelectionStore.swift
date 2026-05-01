import Foundation
import SwiftData
import Observation

// MARK: - AdditionalCurrency

struct AdditionalCurrency: Codable, Identifiable, Equatable {
    var code: String
    var rate: Double   // 1 unit of this currency = `rate` units of default currency
    var rateSource: RateSource
    var rateUpdatedAt: Date?
    var id: String { code }

    enum RateSource: String, Codable { case nbp, manual }

    init(code: String, rate: Double, rateSource: RateSource = .nbp, rateUpdatedAt: Date? = nil) {
        self.code = code
        self.rate = rate
        self.rateSource = rateSource
        self.rateUpdatedAt = rateUpdatedAt
    }

    // Migration: old entries had no rateSource/rateUpdatedAt → default to .manual
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decode(String.self, forKey: .code)
        rate = try c.decode(Double.self, forKey: .rate)
        rateSource = (try? c.decode(RateSource.self, forKey: .rateSource)) ?? .manual
        rateUpdatedAt = try? c.decode(Date.self, forKey: .rateUpdatedAt)
    }
}

// MARK: - AppPreferences

struct AppPreferences {
    static var defaultCurrency: String {
        get { UserDefaults.standard.string(forKey: "defaultCurrency") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultCurrency") }
    }
    static var additionalCurrencies: [AdditionalCurrency] {
        get {
            if let data = UserDefaults.standard.data(forKey: "additionalCurrencies"),
               let decoded = try? JSONDecoder().decode([AdditionalCurrency].self, from: data) {
                return decoded
            }
            // Migrate from old single-secondary setup
            let old = UserDefaults.standard.string(forKey: "secondaryCurrency") ?? ""
            let rate = UserDefaults.standard.double(forKey: "exchangeRate")
            if !old.isEmpty {
                return [AdditionalCurrency(code: old, rate: rate > 0 ? rate : 1.0)]
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "additionalCurrencies")
            }
        }
    }
    static func rate(for code: String) -> Double {
        additionalCurrencies.first { $0.code == code }?.rate ?? 1.0
    }

    static var nbpLastFetchDate: Date? {
        get { UserDefaults.standard.object(forKey: "nbpLastFetchDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "nbpLastFetchDate") }
    }

    /// Apply fetched rates (code → mid vs PLN) respecting per-currency source flags.
    /// `defaultMidPLN` is 1.0 when the default currency is PLN; otherwise the mid of the default currency.
    static func applyNBPRates(_ rates: [String: Double], defaultMidPLN: Double, fetchDate: Date) {
        var currencies = additionalCurrencies
        for i in currencies.indices {
            guard currencies[i].rateSource == .nbp else { continue }
            if let mid = rates[currencies[i].code] {
                currencies[i].rate = mid / defaultMidPLN
                currencies[i].rateUpdatedAt = fetchDate
            }
        }
        additionalCurrencies = currencies
        nbpLastFetchDate = Date()
    }

    static var vehicleSortOrder: VehicleSortOrder {
        get { VehicleSortOrder(rawValue: UserDefaults.standard.string(forKey: "vehicleSortOrder") ?? "") ?? .lastUsed }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "vehicleSortOrder") }
    }
    static var customVehicleOrder: [String] {
        get { UserDefaults.standard.stringArray(forKey: "customVehicleOrder") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "customVehicleOrder") }
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

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
