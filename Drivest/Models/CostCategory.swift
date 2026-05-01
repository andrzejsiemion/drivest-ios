import Foundation
import SwiftData

@Model
final class CostCategory {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    var isBuiltIn: Bool

    init(name: String, iconName: String, sortOrder: Int, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
    }

    static let defaults: [(name: String, icon: String)] = [
        ("Insurance", "shield.fill"),
        ("Service", "wrench.fill"),
        ("Tolls", "road.lanes"),
        ("Wash", "drop.fill"),
        ("Parking", "parkingsign"),
        ("Maintenance", "hammer.fill"),
        ("Tickets", "exclamationmark.octagon.fill"),
    ]
}
