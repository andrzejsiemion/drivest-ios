import Foundation

enum FuelType: String, Codable, CaseIterable {
    case pb95 = "pb95"
    case pb98 = "pb98"
    case diesel = "diesel"
    case lpg = "lpg"
    case ev = "ev"
    case cng = "cng"

    var displayName: String {
        switch self {
        case .pb95: return "PB95"
        case .pb98: return "PB98"
        case .diesel: return "Diesel"
        case .lpg: return "LPG"
        case .ev: return "EV"
        case .cng: return "CNG"
        }
    }

    var compatibleFuelUnits: [FuelUnit] {
        switch self {
        case .ev:
            return [.kilowattHours]
        case .pb95, .pb98, .diesel, .lpg, .cng:
            return [.liters, .gallons]
        }
    }
}
