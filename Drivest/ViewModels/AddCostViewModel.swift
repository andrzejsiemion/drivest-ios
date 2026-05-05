import Foundation
import SwiftData
import Observation

@Observable
final class AddCostViewModel {
    private let modelContext: ModelContext
    var date: Date = Date()
    var selectedCategory: CostCategory?
    var amountText: String = ""
    var noteText: String = ""
    var selectedPhotos: [Data] = []
    var selectedAttachmentData: [Data] = []
    var selectedAttachmentNames: [String] = []
    var selectedVehicle: Vehicle?

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

    var amount: Double? { amountText.parseDouble() }

    var isValid: Bool {
        (amount ?? 0) > 0 && selectedVehicle != nil && selectedCategory != nil
    }

    init(modelContext: ModelContext, vehicle: Vehicle?) {
        self.modelContext = modelContext
        self.selectedVehicle = vehicle
    }

    func save(currencyCode: String? = nil, exchangeRate: Double? = nil) {
        guard let amount, let vehicle = selectedVehicle, let category = selectedCategory else { return }
        let entry = CostEntry(
            date: date,
            categoryName: category.name,
            categoryIcon: category.iconName,
            amount: amount,
            note: noteText.isEmpty ? nil : noteText
        )
        entry.vehicle = vehicle
        entry.currencyCode = currencyCode
        entry.exchangeRate = exchangeRate
        entry.photos = selectedPhotos
        entry.attachmentData = selectedAttachmentData
        entry.attachmentNames = selectedAttachmentNames

        modelContext.insert(entry)

        if createReminder, let vehicle = selectedVehicle {
            let reminder = Reminder(
                title: category.name,
                type: reminderType,
                dueDate: reminderType == .date ? reminderDueDate : nil,
                leadDays: reminderLeadDays,
                categoryName: category.name,
                categoryIcon: category.iconName,
                vehicle: vehicle
            )

            if reminderType == .date {
                reminder.resetInterval = 365
            } else {
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

            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderNotificationTime)
            reminder.notificationHour = timeComponents.hour ?? 9
            reminder.notificationMinute = timeComponents.minute ?? 0

            reminder.costEntryId = entry.id
            modelContext.insert(reminder)

            Task { @MainActor in
                await ReminderNotificationService.shared.requestPermission()
                await ReminderNotificationService.shared.scheduleNotification(for: reminder, vehicle: vehicle)
            }
        }

        Persistence.save(modelContext)
    }
}
