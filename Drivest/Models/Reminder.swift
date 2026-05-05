import Foundation
import SwiftData

enum ReminderType: String, Codable, CaseIterable {
    case date
    case distance
}

enum ReminderStatus: String {
    case pending
    case dueSoon
    case overdue
    case silenced
}

@Model
final class Reminder {
    var id: UUID
    var title: String
    var type: String
    var dueDate: Date?
    var leadDays: Int
    var targetOdometer: Double?
    var leadDistance: Double?
    var resetInterval: Double?
    var categoryName: String?
    var categoryIcon: String?
    var isSilenced: Bool
    var lastNotificationId: String?
    var leadNotificationSent: Bool = false
    var dueNotificationSent: Bool = false
    var notificationHour: Int = 9
    var notificationMinute: Int = 0
    var costEntryId: UUID?
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        title: String,
        type: ReminderType,
        dueDate: Date? = nil,
        leadDays: Int = 14,
        targetOdometer: Double? = nil,
        leadDistance: Double? = nil,
        resetInterval: Double? = nil,
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        vehicle: Vehicle? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type.rawValue
        self.dueDate = dueDate
        self.leadDays = leadDays
        self.targetOdometer = targetOdometer
        self.leadDistance = leadDistance
        self.resetInterval = resetInterval
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.isSilenced = false
        self.lastNotificationId = nil
        self.leadNotificationSent = false
        self.dueNotificationSent = false
        self.createdAt = Date()
        self.vehicle = vehicle
    }

    var reminderType: ReminderType {
        ReminderType(rawValue: type) ?? .date
    }
}
