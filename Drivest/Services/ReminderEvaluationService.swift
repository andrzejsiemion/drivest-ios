import Foundation

struct ReminderContext {
    let currentDate: Date
    let currentOdometer: Double?
}

enum ReminderStatus {
    case pending
    case dueSoon
    case overdue
    case silenced

    var displayLabel: String {
        switch self {
        case .pending: return String(localized: "Pending")
        case .dueSoon: return String(localized: "Due Soon")
        case .overdue: return String(localized: "Overdue")
        case .silenced: return String(localized: "Silenced")
        }
    }

    var isDue: Bool { self == .dueSoon || self == .overdue }
}

struct ReminderEvaluationService {

    func status(for reminder: CostReminder, context: ReminderContext) -> ReminderStatus {
        if reminder.isSilenced { return .silenced }
        switch reminder.reminderType {
        case .timeBased:
            return timeBasedStatus(reminder: reminder, currentDate: context.currentDate)
        case .distanceBased:
            return distanceBasedStatus(reminder: reminder, currentOdometer: context.currentOdometer)
        }
    }

    func nextDueDate(for reminder: CostReminder) -> Date? {
        guard reminder.reminderType == .timeBased, let origin = reminder.originDate else { return nil }
        return addInterval(value: reminder.intervalValue, unit: reminder.intervalUnit, to: origin)
    }

    func nextDueOdometer(for reminder: CostReminder) -> Double? {
        guard reminder.reminderType == .distanceBased, let origin = reminder.originOdometer else { return nil }
        return origin + Double(reminder.intervalValue)
    }

    func hasDueReminders(for vehicle: Vehicle) -> Bool {
        let currentOdometer: Double? = vehicle.fillUps.isEmpty ? nil : vehicle.currentOdometer
        let context = ReminderContext(currentDate: Date(), currentOdometer: currentOdometer)
        return vehicle.reminders.contains { status(for: $0, context: context).isDue }
    }

    // MARK: - Private helpers

    private func timeBasedStatus(reminder: CostReminder, currentDate: Date) -> ReminderStatus {
        guard let origin = reminder.originDate,
              let nextDueDate = addInterval(value: reminder.intervalValue, unit: reminder.intervalUnit, to: origin),
              let triggerDate = Calendar.current.date(byAdding: .day, value: -reminder.leadValue, to: nextDueDate)
        else { return .pending }

        if currentDate >= nextDueDate { return .overdue }
        if currentDate >= triggerDate { return .dueSoon }
        return .pending
    }

    private func distanceBasedStatus(reminder: CostReminder, currentOdometer: Double?) -> ReminderStatus {
        guard let currentOdo = currentOdometer,
              let originOdo = reminder.originOdometer
        else { return .pending }

        let nextDueOdo = originOdo + Double(reminder.intervalValue)
        let triggerOdo = nextDueOdo - Double(reminder.leadValue)

        if currentOdo >= nextDueOdo { return .overdue }
        if currentOdo >= triggerOdo { return .dueSoon }
        return .pending
    }

    private func addInterval(value: Int, unit: ReminderIntervalUnit, to date: Date) -> Date? {
        let calendar = Calendar.current
        switch unit {
        case .days: return calendar.date(byAdding: .day, value: value, to: date)
        case .months: return calendar.date(byAdding: .month, value: value, to: date)
        case .years: return calendar.date(byAdding: .year, value: value, to: date)
        case .kilometers: return nil
        }
    }
}
