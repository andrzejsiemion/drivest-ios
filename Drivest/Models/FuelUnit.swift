import Foundation

enum FuelUnit: String, Codable, CaseIterable {
    case liters = "l"
    case gallons = "gal"
    case kilowattHours = "kwh"

    var displayName: String {
        switch self {
        case .liters: return "Liters"
        case .gallons: return "Gallons"
        case .kilowattHours: return "kWh"
        }
    }

    var abbreviation: String {
        switch self {
        case .liters: return "L"
        case .gallons: return "gal"
        case .kilowattHours: return "kWh"
        }
    }
}
