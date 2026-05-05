import SwiftUI
import SwiftData

struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CostCategory.sortOrder) private var categories: [CostCategory]
    @State private var viewModel: ReminderFormViewModel?

    let vehicle: Vehicle
    var reminder: Reminder?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    Form {
                        Section {
                            TextField(String(localized: "Title"), text: Bindable(vm).title)
                        }

                        Section {
                            Picker(String(localized: "Type"), selection: Bindable(vm).type) {
                                Text(String(localized: "Date")).tag(ReminderType.date)
                                Text(String(localized: "Distance")).tag(ReminderType.distance)
                            }
                            .pickerStyle(.segmented)
                        }

                        if vm.type == .date {
                            Section(String(localized: "Date")) {
                                DatePicker(
                                    String(localized: "Due Date"),
                                    selection: Bindable(vm).dueDate,
                                    displayedComponents: .date
                                )
                                Stepper(
                                    String(localized: "Remind \(vm.leadDays) days before"),
                                    value: Bindable(vm).leadDays,
                                    in: 0...30
                                )
                            }

                            Section(String(localized: "Recurrence")) {
                                TextField(
                                    String(localized: "Reset interval (days)"),
                                    text: Bindable(vm).resetIntervalText
                                )
                                .keyboardType(.numberPad)
                                Text(String(localized: "Days to advance when marked as done. Default: 365"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if vm.type == .distance {
                            Section(String(localized: "Distance")) {
                                TextField(
                                    String(localized: "Target odometer (\(vehicle.effectiveDistanceUnit.abbreviation))"),
                                    text: Bindable(vm).targetOdometerText
                                )
                                .keyboardType(.decimalPad)
                                TextField(
                                    String(localized: "Lead distance (\(vehicle.effectiveDistanceUnit.abbreviation))"),
                                    text: Bindable(vm).leadDistanceText
                                )
                                .keyboardType(.decimalPad)
                            }

                            Section(String(localized: "Recurrence")) {
                                TextField(
                                    String(localized: "Reset interval (\(vehicle.effectiveDistanceUnit.abbreviation))"),
                                    text: Bindable(vm).resetIntervalText
                                )
                                .keyboardType(.decimalPad)
                                Text(String(localized: "Distance to advance when marked as done."))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section(String(localized: "Category")) {
                            Picker(String(localized: "Category"), selection: Binding(
                                get: { vm.categoryName },
                                set: { newValue in
                                    vm.categoryName = newValue
                                    vm.categoryIcon = categories.first(where: { $0.name == newValue })?.iconName
                                }
                            )) {
                                Text(String(localized: "None")).tag(String?.none)
                                ForEach(categories, id: \.id) { cat in
                                    Label(cat.name, systemImage: cat.iconName).tag(Optional(cat.name))
                                }
                            }
                        }
                    }
                    .navigationTitle(reminder == nil ? String(localized: "Add Reminder") : String(localized: "Edit Reminder"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "Cancel")) { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "Save")) {
                                Task {
                                    if await vm.save() {
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(!vm.isValid)
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ReminderFormViewModel(
                        modelContext: modelContext,
                        vehicle: vehicle,
                        reminder: reminder
                    )
                }
            }
        }
    }
}
