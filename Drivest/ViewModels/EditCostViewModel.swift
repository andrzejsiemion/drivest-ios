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
    var draftReminder: DraftReminder?

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
        self.draftReminder = costEntry.reminder?.toDraft()
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

        saveReminder()
        Persistence.save(modelContext)
    }

    private func saveReminder() {
        if let draft = draftReminder {
            if let existing = costEntry.reminder {
                existing.apply(draft)
                existing.categoryName = categoryName
            } else {
                let reminder = CostReminder(
                    categoryName: categoryName,
                    reminderType: draft.type,
                    intervalValue: draft.intervalValue,
                    intervalUnit: draft.intervalUnit,
                    leadValue: draft.leadValue,
                    leadUnit: draft.leadUnit,
                    originDate: draft.type == .timeBased ? date : nil,
                    originOdometer: draft.type == .distanceBased ? costEntry.vehicle?.currentOdometer : nil
                )
                reminder.vehicle = costEntry.vehicle
                modelContext.insert(reminder)
                costEntry.reminder = reminder
            }
        } else if costEntry.reminder != nil {
            modelContext.delete(costEntry.reminder!)
            costEntry.reminder = nil
        }
    }
}
