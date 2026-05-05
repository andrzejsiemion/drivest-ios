import SwiftUI
import SwiftData

struct ReminderListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ReminderListViewModel?
    @State private var showAddForm = false
    @State private var reminderToEdit: Reminder?

    let vehicle: Vehicle

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.reminders.isEmpty {
                    ContentUnavailableView {
                        Label(String(localized: "No Reminders"), systemImage: "bell.slash")
                    } description: {
                        Text("Tap + to add a reminder for this vehicle.")
                    }
                } else {
                    List {
                        ForEach(vm.reminders, id: \.id) { reminder in
                            ReminderRow(reminder: reminder, status: vm.status(for: reminder))
                                .contentShape(Rectangle())
                                .onTapGesture { reminderToEdit = reminder }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        vm.delete(reminder)
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if reminder.isSilenced {
                                        Button {
                                            vm.reEnable(reminder)
                                        } label: {
                                            Label(String(localized: "Re-enable"), systemImage: "bell")
                                        }
                                        .tint(.blue)
                                    } else {
                                        Button {
                                            vm.silence(reminder)
                                        } label: {
                                            Label(String(localized: "Silence"), systemImage: "bell.slash")
                                        }
                                        .tint(.gray)
                                    }

                                    let status = vm.status(for: reminder)
                                    if status == .overdue || status == .dueSoon {
                                        Button {
                                            Task { await vm.markAsDone(reminder) }
                                        } label: {
                                            Label(String(localized: "Done"), systemImage: "checkmark.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Reminders"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ReminderListViewModel(modelContext: modelContext, vehicle: vehicle)
            }
            viewModel?.loadReminders()
        }
        .sheet(isPresented: $showAddForm) {
            viewModel?.loadReminders()
        } content: {
            ReminderFormView(vehicle: vehicle)
        }
        .sheet(item: $reminderToEdit) { reminder in
            ReminderFormView(vehicle: vehicle, reminder: reminder)
                .onDisappear { viewModel?.loadReminders() }
        }
    }
}

// MARK: - Row

private struct ReminderRow: View {
    let reminder: Reminder
    let status: ReminderStatus

    var body: some View {
        HStack {
            if let icon = reminder.categoryIcon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ReminderStatusBadge(status: status)
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        switch reminder.reminderType {
        case .date:
            if let date = reminder.dueDate {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
            return ""
        case .distance:
            if let target = reminder.targetOdometer {
                return String(format: "%.0f km", target)
            }
            return ""
        }
    }
}

extension Reminder: Identifiable {}
