import Foundation
import SwiftData
import Observation

@Observable
final class ReminderViewModel {
    private let modelContext: ModelContext
    let reminder: CostReminder
    private let evaluationService = ReminderEvaluationService()

    var draft: DraftReminder
    var currentStatus: ReminderStatus

    init(modelContext: ModelContext, reminder: CostReminder, currentOdometer: Double?) {
        self.modelContext = modelContext
        self.reminder = reminder
        self.draft = reminder.toDraft()
        let context = ReminderContext(
            currentDate: Date(),
            currentOdometer: currentOdometer
        )
        self.currentStatus = evaluationService.status(for: reminder, context: context)
    }

    var nextDueDateDisplay: Date? {
        evaluationService.nextDueDate(for: reminder)
    }

    var nextDueOdometerDisplay: Double? {
        evaluationService.nextDueOdometer(for: reminder)
    }

    var intervalSummary: String {
        switch reminder.reminderType {
        case .timeBased:
            return String(localized: "Every \(reminder.intervalValue) \(reminder.intervalUnit.displayName), \(reminder.leadValue) days notice")
        case .distanceBased:
            return String(localized: "Every \(reminder.intervalValue) km, \(reminder.leadValue) km notice")
        }
    }

    func save() {
        reminder.apply(draft)
        Persistence.save(modelContext)
    }

    func toggleSilence() {
        reminder.isSilenced.toggle()
        Persistence.save(modelContext)
    }

    func delete() {
        modelContext.delete(reminder)
        Persistence.save(modelContext)
    }
}
