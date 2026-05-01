import Foundation

enum FetchFrequency: String, CaseIterable {
    case daily
    case twiceDaily
    case every6Hours
    case every12Hours

    var displayName: String {
        switch self {
        case .daily:       return "Daily"
        case .twiceDaily:  return "Twice a Day"
        case .every6Hours: return "Every 6 Hours"
        case .every12Hours: return "Every 12 Hours"
        }
    }

    var intervalSeconds: TimeInterval {
        switch self {
        case .daily:        return 24 * 3600
        case .twiceDaily:   return 12 * 3600
        case .every6Hours:  return 6 * 3600
        case .every12Hours: return 12 * 3600
        }
    }
}
