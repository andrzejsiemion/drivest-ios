import SwiftUI
import SwiftData

struct VehicleRemindersView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var modelContext

    private let evaluationService = ReminderEvaluationService()

    private var currentOdometer: Double? {
        vehicle.fillUps.isEmpty ? nil : vehicle.currentOdometer
    }

    private var remindersByStatus: [(ReminderStatus, [CostReminder])] {
        let context = ReminderContext(currentDate: Date(), currentOdometer: currentOdometer)
        let categorized: [(CostReminder, ReminderStatus)] = vehicle.reminders.map { reminder in
            (reminder, evaluationService.status(for: reminder, context: context))
        }
        let order: [ReminderStatus] = [.overdue, .dueSoon, .pending, .silenced]
        return order.compactMap { status in
            let matching = categorized.filter { $0.1 == status }.map { $0.0 }
            return matching.isEmpty ? nil : (status, matching)
        }
    }

    var body: some View {
        List {
            if vehicle.reminders.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Reminders"),
                    systemImage: "bell.slash",
                    description: Text(String(localized: "Add one from a cost entry to track recurring expenses."))
                )
            } else {
                ForEach(remindersByStatus, id: \.0) { status, reminders in
                    Section(status.displayLabel) {
                        ForEach(reminders, id: \.id) { reminder in
                            NavigationLink {
                                ReminderDetailView(reminder: reminder, vehicle: vehicle)
                            } label: {
                                ReminderRow(
                                    reminder: reminder,
                                    status: status,
                                    evaluationService: evaluationService
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Reminders"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Row

private struct ReminderRow: View {
    let reminder: CostReminder
    let status: ReminderStatus
    let evaluationService: ReminderEvaluationService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.vehicle.flatMap { _ in reminder.reminderType == .timeBased ? "calendar" : "gauge.with.dots.needle.50percent" } ?? "bell")
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(LocalizedStringKey(reminder.categoryName))
                        .font(.headline)
                    Spacer()
                    statusPill
                }
                dueLine
                    .font(.caption)
                    .foregroundStyle(.secondary)
                intervalLine
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusPill: some View {
        Text(status.displayLabel)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var dueLine: some View {
        switch reminder.reminderType {
        case .timeBased:
            if let date = evaluationService.nextDueDate(for: reminder) {
                Text(String(localized: "Due \(date.formatted(date: .abbreviated, time: .omitted))"))
            }
        case .distanceBased:
            if let odo = evaluationService.nextDueOdometer(for: reminder) {
                Text(String(localized: "Due at \(Int(odo)) km"))
            }
        }
    }

    @ViewBuilder
    private var intervalLine: some View {
        switch reminder.reminderType {
        case .timeBased:
            Text(String(localized: "Every \(reminder.intervalValue) \(reminder.intervalUnit.displayName), \(reminder.leadValue) days notice"))
        case .distanceBased:
            Text(String(localized: "Every \(reminder.intervalValue) km, \(reminder.leadValue) km notice"))
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .blue
        case .dueSoon: return .orange
        case .overdue: return .red
        case .silenced: return .secondary
        }
    }
}

// MARK: - Detail / Edit

struct ReminderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReminderViewModel?
    @State private var showDeleteConfirmation = false

    let reminder: CostReminder
    let vehicle: Vehicle

    private var currentOdometer: Double? {
        vehicle.fillUps.isEmpty ? nil : vehicle.currentOdometer
    }

    var body: some View {
        Form {
            if let vm = viewModel {
                ReminderFormSection(
                    draft: Binding(
                        get: { vm.draft },
                        set: { vm.draft = $0 ?? .defaultTimeBased }
                    ),
                    costEntryDate: reminder.originDate ?? Date(),
                    costEntryOdometer: currentOdometer
                )

                Section {
                    Button(reminder.isSilenced ? String(localized: "Re-enable Reminder") : String(localized: "Silence Reminder")) {
                        vm.toggleSilence()
                        dismiss()
                    }
                    .foregroundStyle(reminder.isSilenced ? .blue : .orange)

                    Button(String(localized: "Delete Reminder"), role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
        }
        .navigationTitle(reminder.categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Save")) {
                    viewModel?.save()
                    dismiss()
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ReminderViewModel(modelContext: modelContext, reminder: reminder, currentOdometer: currentOdometer)
            }
        }
        .confirmationDialog(
            String(localized: "Delete Reminder?"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                viewModel?.delete()
                dismiss()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "This will permanently remove the reminder. The cost entry will not be affected."))
        }
    }
}
