import Foundation

enum DistanceUnit: String, Codable, CaseIterable {
    case kilometers = "km"
    case miles = "mi"

    private static let kmToMiles = 0.621371
    private static let milesToKm = 1.60934

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }

    var abbreviation: String {
        rawValue
    }

    /// Converts a value in kilometers to this unit.
    func fromKm(_ km: Double) -> Double {
        switch self {
        case .kilometers: return km
        case .miles: return km * Self.kmToMiles
        }
    }
}
