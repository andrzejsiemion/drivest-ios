import Foundation

enum EfficiencyDisplayFormat: String, Codable, CaseIterable {
    case litersPer100km = "l100km"
    case kwhPer100km = "kwh100km"
    case mpg = "mpg"
    case kmPerLiter = "kml"

    var displayName: String {
        switch self {
        case .litersPer100km: return "L/100km"
        case .kwhPer100km: return "kWh/100km"
        case .mpg: return "MPG"
        case .kmPerLiter: return "km/L"
        }
    }

    /// Formats a base efficiency value (L/100km) into the display format.
    func format(baseLitersPer100km: Double) -> String {
        let value = convert(baseLitersPer100km: baseLitersPer100km)
        switch self {
        case .litersPer100km:
            return String(format: "%.1f L/100km", value)
        case .kwhPer100km:
            return String(format: "%.1f kWh/100km", value)
        case .mpg:
            return String(format: "%.1f MPG", value)
        case .kmPerLiter:
            return String(format: "%.1f km/L", value)
        }
    }

    /// Converts base L/100km to the target unit value.
    func convert(baseLitersPer100km: Double) -> Double {
        guard baseLitersPer100km > 0 else { return 0 }
        switch self {
        case .litersPer100km:
            return baseLitersPer100km
        case .kwhPer100km:
            // Approximate: 1 liter gasoline ≈ 8.9 kWh energy equivalent
            return baseLitersPer100km * 8.9
        case .mpg:
            // L/100km to MPG (US): 235.215 / L/100km
            return 235.215 / baseLitersPer100km
        case .kmPerLiter:
            // L/100km to km/L: 100 / L/100km
            return 100.0 / baseLitersPer100km
        }
    }
}
