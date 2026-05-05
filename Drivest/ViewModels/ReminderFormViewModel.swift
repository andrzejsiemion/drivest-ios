import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ReminderFormViewModel {
    private let modelContext: ModelContext
    let vehicle: Vehicle
    let existingReminder: Reminder?

    var title: String = ""
    var type: ReminderType = .date
    var dueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var leadDays: Int = 14
    var targetOdometerText: String = ""
    var leadDistanceText: String = ""
    var resetIntervalText: String = ""
    var categoryName: String?
    var categoryIcon: String?

    init(modelContext: ModelContext, vehicle: Vehicle, reminder: Reminder? = nil) {
        self.modelContext = modelContext
        self.vehicle = vehicle
        self.existingReminder = reminder

        if let r = reminder {
            title = r.title
            type = r.reminderType
            dueDate = r.dueDate ?? dueDate
            leadDays = r.leadDays
            let unit = vehicle.effectiveDistanceUnit
            if let target = r.targetOdometer {
                targetOdometerText = String(format: "%.0f", unit.fromKm(target))
            }
            if let lead = r.leadDistance {
                leadDistanceText = String(format: "%.0f", unit.fromKm(lead))
            }
            if let interval = r.resetInterval {
                if r.reminderType == .date {
                    resetIntervalText = String(format: "%.0f", interval)
                } else {
                    resetIntervalText = String(format: "%.0f", unit.fromKm(interval))
                }
            }
            categoryName = r.categoryName
            categoryIcon = r.categoryIcon
        } else {
            let defaultTarget = vehicle.currentOdometer + vehicle.effectiveDistanceUnit.fromKm(15000)
            targetOdometerText = String(format: "%.0f", defaultTarget)
            leadDistanceText = String(format: "%.0f", vehicle.effectiveDistanceUnit.fromKm(500))
        }
    }

    var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        switch type {
        case .date:
            return true
        case .distance:
            guard let target = targetOdometerText.parseDouble(), target > 0 else { return false }
            return true
        }
    }

    func save() async -> Bool {
        guard isValid else { return false }

        await ReminderNotificationService.shared.requestPermission()

        let reminder = existingReminder ?? Reminder(title: "", type: type, vehicle: vehicle)
        reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.type = type.rawValue
        reminder.leadDays = leadDays
        reminder.categoryName = categoryName
        reminder.categoryIcon = categoryIcon

        let unit = vehicle.effectiveDistanceUnit

        switch type {
        case .date:
            reminder.dueDate = dueDate
            reminder.targetOdometer = nil
            reminder.leadDistance = nil
            if let interval = resetIntervalText.parseDouble(), interval > 0 {
                reminder.resetInterval = interval
            } else {
                reminder.resetInterval = 365
            }
        case .distance:
            reminder.dueDate = nil
            let target = targetOdometerText.parseDouble() ?? 0
            reminder.targetOdometer = toKm(target, unit: unit)
            let lead = leadDistanceText.parseDouble() ?? 0
            reminder.leadDistance = toKm(lead, unit: unit)
            if let interval = resetIntervalText.parseDouble(), interval > 0 {
                reminder.resetInterval = toKm(interval, unit: unit)
            } else {
                reminder.resetInterval = toKm(target - unit.fromKm(vehicle.currentOdometer), unit: unit)
            }
        }

        if existingReminder == nil {
            modelContext.insert(reminder)
        }

        Persistence.save(modelContext)

        // Schedule notification
        ReminderNotificationService.shared.cancelNotification(for: reminder)
        if reminder.reminderType == .date {
            await ReminderNotificationService.shared.scheduleNotification(for: reminder, vehicle: vehicle)
        }

        return true
    }

    private func toKm(_ value: Double, unit: DistanceUnit) -> Double {
        switch unit {
        case .kilometers: return value
        case .miles: return value / 0.621371
        }
    }
}
