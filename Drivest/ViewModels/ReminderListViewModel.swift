import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ReminderListViewModel {
    private let modelContext: ModelContext
    let vehicle: Vehicle

    var reminders: [Reminder] = []

    init(modelContext: ModelContext, vehicle: Vehicle) {
        self.modelContext = modelContext
        self.vehicle = vehicle
    }

    func loadReminders() {
        let currentOdometer = vehicle.currentOdometer
        let sorted = vehicle.reminders.sorted { a, b in
            let sa = ReminderEvaluationService.status(for: a, currentOdometer: currentOdometer)
            let sb = ReminderEvaluationService.status(for: b, currentOdometer: currentOdometer)
            return sa.sortOrder < sb.sortOrder
        }
        reminders = sorted
    }

    func status(for reminder: Reminder) -> ReminderStatus {
        ReminderEvaluationService.status(for: reminder, currentOdometer: vehicle.currentOdometer)
    }

    func silence(_ reminder: Reminder) {
        reminder.isSilenced = true
        ReminderNotificationService.shared.cancelNotification(for: reminder)
        Persistence.save(modelContext)
        loadReminders()
    }

    func reEnable(_ reminder: Reminder) {
        reminder.isSilenced = false
        Persistence.save(modelContext)
        loadReminders()
    }

    func markAsDone(_ reminder: Reminder) async {
        switch reminder.reminderType {
        case .date:
            if let interval = reminder.resetInterval {
                reminder.dueDate = Calendar.current.date(byAdding: .day, value: Int(interval), to: Date())
            } else {
                reminder.dueDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
            }
        case .distance:
            if let interval = reminder.resetInterval, let current = reminder.targetOdometer {
                reminder.targetOdometer = current + interval
            }
        }

        reminder.isSilenced = false
        ReminderNotificationService.shared.cancelNotification(for: reminder)
        reminder.lastNotificationId = nil

        // Reschedule notification for date-based reminders
        if reminder.reminderType == .date {
            await ReminderNotificationService.shared.scheduleNotification(for: reminder, vehicle: vehicle)
        }

        Persistence.save(modelContext)
        loadReminders()
    }

    func delete(_ reminder: Reminder) {
        ReminderNotificationService.shared.cancelNotification(for: reminder)
        modelContext.delete(reminder)
        Persistence.save(modelContext)
        loadReminders()
    }
}

extension ReminderStatus {
    var sortOrder: Int {
        switch self {
        case .overdue: 0
        case .dueSoon: 1
        case .pending: 2
        case .silenced: 3
        }
    }
}
