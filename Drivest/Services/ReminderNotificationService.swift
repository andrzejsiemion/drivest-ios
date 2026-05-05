import Foundation
import UserNotifications
import SwiftData

@MainActor
final class ReminderNotificationService {
    static let shared = ReminderNotificationService()
    private init() {}

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleNotification(for reminder: Reminder, vehicle: Vehicle) async {
        guard !reminder.isSilenced else { return }

        let status = ReminderEvaluationService.status(for: reminder, currentOdometer: vehicle.currentOdometer)

        switch status {
        case .pending:
            // Not yet in lead window — schedule for the lead date/distance
            scheduleLeadNotification(for: reminder, vehicle: vehicle)
        case .dueSoon:
            // In lead window — fire lead notification if not already sent
            if !reminder.leadNotificationSent {
                await fireNotification(
                    for: reminder,
                    vehicle: vehicle,
                    identifier: "reminder-lead-\(reminder.id.uuidString)",
                    body: leadBody(for: reminder, vehicle: vehicle)
                )
                reminder.leadNotificationSent = true
            }
        case .overdue:
            // Past due — fire due notification if not already sent
            if !reminder.dueNotificationSent {
                await fireNotification(
                    for: reminder,
                    vehicle: vehicle,
                    identifier: "reminder-due-\(reminder.id.uuidString)",
                    body: dueBody(for: reminder, vehicle: vehicle)
                )
                reminder.dueNotificationSent = true
            }
        case .silenced:
            break
        }
    }

    /// Schedule a future calendar notification for when the lead window begins (date reminders only)
    private func scheduleLeadNotification(for reminder: Reminder, vehicle: Vehicle) {
        guard reminder.reminderType == .date,
              let notifDate = ReminderEvaluationService.notificationDate(for: reminder),
              notifDate > Date() else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = "reminder-lead-\(reminder.id.uuidString)"

        // Cancel any existing scheduled notification
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = makeContent(for: reminder, vehicle: vehicle,
                                   body: leadBody(for: reminder, vehicle: vehicle))

        var components = Calendar.current.dateComponents([.year, .month, .day], from: notifDate)
        components.hour = reminder.notificationHour
        components.minute = reminder.notificationMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        Task { try? await center.add(request) }
        reminder.lastNotificationId = identifier
    }

    private func fireNotification(for reminder: Reminder, vehicle: Vehicle, identifier: String, body: String) async {
        let center = UNUserNotificationCenter.current()

        // Cancel any previous scheduled notification for this reminder
        if let existingId = reminder.lastNotificationId {
            center.removePendingNotificationRequests(withIdentifiers: [existingId])
        }

        let content = makeContent(for: reminder, vehicle: vehicle, body: body)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
        reminder.lastNotificationId = identifier
    }

    private func makeContent(for reminder: Reminder, vehicle: Vehicle, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = body
        content.sound = .default
        var userInfo: [String: String] = [
            "vehicleId": vehicle.id.uuidString,
            "reminderId": reminder.id.uuidString
        ]
        if let costEntryId = reminder.costEntryId {
            userInfo["costEntryId"] = costEntryId.uuidString
        }
        content.userInfo = userInfo
        return content
    }

    private func leadBody(for reminder: Reminder, vehicle: Vehicle) -> String {
        String(localized: "Due for \(vehicle.name)")
    }

    private func dueBody(for reminder: Reminder, vehicle: Vehicle) -> String {
        if reminder.reminderType == .distance {
            return String(localized: "Odometer threshold reached for \(vehicle.name)")
        }
        return String(localized: "Due for \(vehicle.name)")
    }

    func cancelNotification(for reminder: Reminder) {
        guard let notifId = reminder.lastNotificationId else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifId])
        reminder.lastNotificationId = nil
    }

    func cancelAllNotifications(for vehicle: Vehicle) {
        let ids = vehicle.reminders.compactMap(\.lastNotificationId)
        guard !ids.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    func evaluateDistanceReminders(for vehicle: Vehicle, currentOdometer: Double, context: ModelContext) async {
        let distanceReminders = vehicle.reminders.filter {
            $0.reminderType == .distance && !$0.isSilenced
        }

        for reminder in distanceReminders {
            await scheduleNotification(for: reminder, vehicle: vehicle)
        }
    }

    /// Reset notification flags when a reminder is created or edited
    func resetNotificationFlags(for reminder: Reminder) {
        reminder.leadNotificationSent = false
        reminder.dueNotificationSent = false
    }
}
