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
    var draftReminder: DraftReminder? = nil

    /// Set after save when an existing active reminder matches the new entry's category.
    /// The view should present a reset confirmation dialog when this is non-nil.
    var reminderResetCandidate: CostReminder? = nil

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

        if let draft = draftReminder {
            let reminder = CostReminder(
                categoryName: category.name,
                reminderType: draft.type,
                intervalValue: draft.intervalValue,
                intervalUnit: draft.intervalUnit,
                leadValue: draft.leadValue,
                leadUnit: draft.leadUnit,
                originDate: draft.type == .timeBased ? date : nil,
                originOdometer: draft.type == .distanceBased ? vehicle.currentOdometer : nil
            )
            reminder.vehicle = vehicle
            modelContext.insert(reminder)
            entry.reminder = reminder
        }

        modelContext.insert(entry)
        Persistence.save(modelContext)

        // Check for a matching active reminder on the vehicle (excluding the one just created).
        reminderResetCandidate = vehicle.reminders.first {
            $0.categoryName == category.name && !$0.isSilenced && $0.id != entry.reminder?.id
        }
    }

    /// Resets the candidate reminder's origin to the just-saved entry's values, then clears the candidate.
    func confirmReminderReset(originDate: Date, originOdometer: Double?) {
        guard let candidate = reminderResetCandidate else { return }
        if candidate.reminderType == .timeBased {
            candidate.originDate = originDate
        } else {
            candidate.originOdometer = originOdometer
        }
        candidate.isSilenced = false
        Persistence.save(modelContext)
        reminderResetCandidate = nil
    }

    /// Keeps the existing reminder unchanged and clears the candidate.
    func dismissReminderReset() {
        reminderResetCandidate = nil
    }
}
