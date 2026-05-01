import Foundation

enum VehicleSortOrder: String, CaseIterable, Identifiable {
    case lastUsed     = "lastUsed"
    case alphabetical = "alphabetical"
    case dateAdded    = "dateAdded"
    case custom       = "custom"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lastUsed:     return "Last Used"
        case .alphabetical: return "Alphabetical"
        case .dateAdded:    return "Date Added"
        case .custom:       return "Custom"
        }
    }
}
