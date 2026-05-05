import Foundation
import SwiftData
import Observation

@Observable
final class EditCostViewModel {
    private let modelContext: ModelContext
    let costEntry: CostEntry

    var date: Date
    var categoryName: String
    var categoryIcon: String
    var amountText: String
    var noteText: String
    var selectedPhotos: [Data]
    var selectedAttachmentData: [Data]
    var selectedAttachmentNames: [String]
    var exchangeRateText: String

    var createReminder: Bool = false
    var reminderType: ReminderType = .date
    var reminderDueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    var reminderLeadDays: Int = 14
    var reminderDistanceInterval: Int = 5000
    var reminderLeadDistance: Int = 500
    var reminderNotificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    private(set) var existingReminder: Reminder?

    init(modelContext: ModelContext, costEntry: CostEntry) {
        self.modelContext = modelContext
        self.costEntry = costEntry
        self.date = costEntry.date
        self.categoryName = costEntry.categoryName
        self.categoryIcon = costEntry.categoryIcon
        self.amountText = String(format: "%.2f", costEntry.amount)
        self.noteText = costEntry.note ?? ""
        self.selectedPhotos = costEntry.allPhotos
        self.selectedAttachmentData = costEntry.attachmentData
        self.selectedAttachmentNames = costEntry.attachmentNames
        if let rate = costEntry.exchangeRate {
            self.exchangeRateText = String(format: "%.4f", rate)
        } else {
            self.exchangeRateText = ""
        }

        // Load existing reminder matching this cost's category
        if let vehicle = costEntry.vehicle,
           let reminder = vehicle.reminders.first(where: { $0.costEntryId == costEntry.id }) {
            self.existingReminder = reminder
            self.createReminder = true
            self.reminderType = reminder.reminderType
            if let dueDate = reminder.dueDate {
                self.reminderDueDate = dueDate
            }
            self.reminderLeadDays = reminder.leadDays
            var timeComps = DateComponents()
            timeComps.hour = reminder.notificationHour
            timeComps.minute = reminder.notificationMinute
            if let time = Calendar.current.date(from: timeComps) {
                self.reminderNotificationTime = time
            }
            if reminder.reminderType == .distance {
                let unit = vehicle.effectiveDistanceUnit
                if let target = reminder.targetOdometer {
                    let remaining = unit.fromKm(target) - vehicle.currentOdometer
                    self.reminderDistanceInterval = Int(max(0, remaining))
                }
                if let lead = reminder.leadDistance {
                    self.reminderLeadDistance = Int(unit.fromKm(lead))
                }
            }
        }
    }

    var hasSecondaryCurrency: Bool {
        guard let code = costEntry.currencyCode, !code.isEmpty else { return false }
        return code != AppPreferences.defaultCurrency
    }

    var exchangeRate: Double? { exchangeRateText.parseDouble() }

    var amount: Double? { amountText.parseDouble() }

    var isValid: Bool {
        guard (amount ?? 0) > 0 else { return false }
        if hasSecondaryCurrency && (exchangeRate ?? 0) <= 0 { return false }
        return true
    }

    func save() {
        guard let amount else { return }
        costEntry.date = date
        costEntry.categoryName = categoryName
        costEntry.categoryIcon = categoryIcon
        costEntry.amount = amount
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        costEntry.note = trimmed.isEmpty ? nil : trimmed
        costEntry.photos = selectedPhotos
        costEntry.photoData = nil
        costEntry.attachmentData = selectedAttachmentData
        costEntry.attachmentNames = selectedAttachmentNames
        if hasSecondaryCurrency { costEntry.exchangeRate = exchangeRate }

        if let vehicle = costEntry.vehicle {
            if createReminder {
                let reminder = existingReminder ?? Reminder(title: categoryName, type: reminderType, vehicle: vehicle)
                reminder.title = categoryName
                reminder.type = reminderType.rawValue
                reminder.categoryName = categoryName
                reminder.categoryIcon = categoryIcon
                reminder.leadDays = reminderLeadDays
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderNotificationTime)
                reminder.notificationHour = timeComponents.hour ?? 9
                reminder.notificationMinute = timeComponents.minute ?? 0

                if reminderType == .date {
                    reminder.dueDate = reminderDueDate
                    reminder.targetOdometer = nil
                    reminder.leadDistance = nil
                    reminder.resetInterval = 365
                } else {
                    reminder.dueDate = nil
                    let unit = vehicle.effectiveDistanceUnit
                    let interval = Double(reminderDistanceInterval)
                    if interval > 0 {
                        let intervalKm = unit == .miles ? interval / 0.621371 : interval
                        let currentKm = unit == .miles ? vehicle.currentOdometer / 0.621371 : vehicle.currentOdometer
                        reminder.targetOdometer = currentKm + intervalKm
                        reminder.resetInterval = intervalKm
                        let lead = Double(reminderLeadDistance)
                        let leadKm = unit == .miles ? lead / 0.621371 : lead
                        reminder.leadDistance = leadKm
                    }
                }

                if existingReminder == nil {
                    reminder.costEntryId = costEntry.id
                    modelContext.insert(reminder)
                }

                Task { @MainActor in
                    await ReminderNotificationService.shared.requestPermission()
                    ReminderNotificationService.shared.cancelNotification(for: reminder)
                    ReminderNotificationService.shared.resetNotificationFlags(for: reminder)
                    await ReminderNotificationService.shared.scheduleNotification(for: reminder, vehicle: vehicle)
                }
            } else if let existing = existingReminder {
                // User toggled off — delete the reminder
                Task { @MainActor in
                    ReminderNotificationService.shared.cancelNotification(for: existing)
                }
                modelContext.delete(existing)
                existingReminder = nil
            }
        }

        Persistence.save(modelContext)
    }
}
