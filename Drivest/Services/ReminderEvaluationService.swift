import Foundation

enum ReminderEvaluationService {

    static func status(for reminder: Reminder, currentDate: Date = Date(), currentOdometer: Double?) -> ReminderStatus {
        if reminder.isSilenced { return .silenced }

        switch reminder.reminderType {
        case .date:
            guard let dueDate = reminder.dueDate else { return .pending }
            if currentDate >= dueDate { return .overdue }
            if let notifDate = notificationDate(for: reminder), currentDate >= notifDate {
                return .dueSoon
            }
            return .pending

        case .distance:
            guard let target = reminder.targetOdometer, let odometer = currentOdometer else { return .pending }
            if odometer >= target { return .overdue }
            if let trigger = triggerOdometer(for: reminder), odometer >= trigger {
                return .dueSoon
            }
            return .pending
        }
    }

    static func notificationDate(for reminder: Reminder) -> Date? {
        guard reminder.reminderType == .date, let dueDate = reminder.dueDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: -reminder.leadDays, to: dueDate)
    }

    static func triggerOdometer(for reminder: Reminder) -> Double? {
        guard reminder.reminderType == .distance,
              let target = reminder.targetOdometer,
              let lead = reminder.leadDistance else { return nil }
        return target - lead
    }
}
