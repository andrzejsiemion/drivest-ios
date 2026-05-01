import Foundation
import SwiftData

enum ReminderType: String, Codable, CaseIterable {
    case timeBased
    case distanceBased

    var displayName: String {
        switch self {
        case .timeBased: return String(localized: "Time")
        case .distanceBased: return String(localized: "Distance")
        }
    }
}

enum ReminderIntervalUnit: String, Codable {
    case days
    case months
    case years
    case kilometers

    var displayName: String {
        switch self {
        case .days: return String(localized: "Days")
        case .months: return String(localized: "Months")
        case .years: return String(localized: "Years")
        case .kilometers: return "km"
        }
    }
}

enum ReminderLeadUnit: String, Codable {
    case days
    case kilometers

    var displayName: String {
        switch self {
        case .days: return String(localized: "days before")
        case .kilometers: return "km before"
        }
    }
}

/// Transient value type used while editing reminder settings in the form.
/// Converted to a persisted `CostReminder` on save.
struct DraftReminder {
    var type: ReminderType = .timeBased
    var intervalValue: Int = 1
    var intervalUnit: ReminderIntervalUnit = .years
    var leadValue: Int = 14
    var leadUnit: ReminderLeadUnit = .days

    static let defaultTimeBased = DraftReminder(
        type: .timeBased, intervalValue: 1, intervalUnit: .years, leadValue: 14, leadUnit: .days
    )
    static let defaultDistanceBased = DraftReminder(
        type: .distanceBased, intervalValue: 10000, intervalUnit: .kilometers, leadValue: 500, leadUnit: .kilometers
    )
}

@Model
final class CostReminder {
    var id: UUID
    var categoryName: String
    var reminderType: ReminderType
    var intervalValue: Int
    var intervalUnit: ReminderIntervalUnit
    var leadValue: Int
    var leadUnit: ReminderLeadUnit
    var originDate: Date?
    var originOdometer: Double?
    var isSilenced: Bool
    var createdAt: Date
    var vehicle: Vehicle?

    init(
        categoryName: String,
        reminderType: ReminderType,
        intervalValue: Int,
        intervalUnit: ReminderIntervalUnit,
        leadValue: Int,
        leadUnit: ReminderLeadUnit,
        originDate: Date? = nil,
        originOdometer: Double? = nil
    ) {
        self.id = UUID()
        self.categoryName = categoryName
        self.reminderType = reminderType
        self.intervalValue = intervalValue
        self.intervalUnit = intervalUnit
        self.leadValue = leadValue
        self.leadUnit = leadUnit
        self.originDate = originDate
        self.originOdometer = originOdometer
        self.isSilenced = false
        self.createdAt = Date()
    }

    /// Applies values from a draft, used when the user edits via the form.
    func apply(_ draft: DraftReminder) {
        reminderType = draft.type
        intervalValue = draft.intervalValue
        intervalUnit = draft.intervalUnit
        leadValue = draft.leadValue
        leadUnit = draft.leadUnit
    }

    /// Creates a `DraftReminder` populated from the current reminder's values.
    func toDraft() -> DraftReminder {
        DraftReminder(
            type: reminderType,
            intervalValue: intervalValue,
            intervalUnit: intervalUnit,
            leadValue: leadValue,
            leadUnit: leadUnit
        )
    }
}
