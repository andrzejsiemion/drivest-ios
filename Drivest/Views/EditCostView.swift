import SwiftUI
import SwiftData

struct EditCostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @Query(sort: \CostCategory.sortOrder) private var categories: [CostCategory]
    @State private var viewModel: EditCostViewModel?

    let costEntry: CostEntry

    var body: some View {
        NavigationStack {
            Group {
                if viewModel == nil {
                    ProgressView()
                        .onAppear {
                            viewModel = EditCostViewModel(modelContext: modelContext, costEntry: costEntry)
                        }
                } else if let vm = viewModel {
                    @Bindable var vm = vm
                    Form {
                        Section {
                            Picker(String(localized: "Category"), selection: Binding(
                                get: { categories.first(where: { $0.name == vm.categoryName && $0.iconName == vm.categoryIcon }) },
                                set: { if let c = $0 { vm.categoryName = c.name; vm.categoryIcon = c.iconName } }
                            )) {
                                ForEach(categories) { category in
                                    Label(LocalizedStringKey(category.name), systemImage: category.iconName).tag(Optional(category))
                                }
                            }
                        }

                        Section {
                            HStack {
                                Text(String(localized: "Amount")).foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: $vm.amountText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                if let code = costEntry.currencyCode,
                                   let symbol = CurrencyDefinition.symbol(for: code) {
                                    Text(symbol).font(.callout).foregroundStyle(.secondary)
                                }
                            }
                        }

                        Section(String(localized: "Date")) {
                            DatePicker(String(localized: "Date"), selection: $vm.date, displayedComponents: .date)
                        }

                        Section(String(localized: "Note (Optional)")) {
                            TextField(String(localized: "Add a note..."), text: $vm.noteText)
                                .textInputAutocapitalization(.never)
                        }

                        if vm.hasSecondaryCurrency {
                            Section(String(localized: "Exchange Rate")) {
                                HStack {
                                    if let code = costEntry.currencyCode, !defaultCurrencyCode.isEmpty {
                                        Text("\(code) → \(defaultCurrencyCode)").foregroundStyle(.secondary)
                                    } else {
                                        Text(String(localized: "Rate")).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    TextField("1.0000", text: $vm.exchangeRateText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                        Section(String(localized: "Reminder")) {
                            Toggle(String(localized: "Create Reminder"), isOn: $vm.createReminder)
                            if vm.createReminder {
                                Picker(String(localized: "Type"), selection: $vm.reminderType) {
                                    Text(String(localized: "Date")).tag(ReminderType.date)
                                    Text(String(localized: "Distance")).tag(ReminderType.distance)
                                }
                                .pickerStyle(.segmented)

                                DatePicker(
                                    String(localized: "Notification Time"),
                                    selection: $vm.reminderNotificationTime,
                                    displayedComponents: .hourAndMinute
                                )

                                if vm.reminderType == .date {
                                    ExpandableDatePickerRow(
                                        label: String(localized: "Due Date"),
                                        selection: $vm.reminderDueDate
                                    )
                                    DaysPickerRow(
                                        label: String(localized: "Remind days before"),
                                        value: $vm.reminderLeadDays
                                    )
                                }

                                if vm.reminderType == .distance {
                                    let unit = costEntry.vehicle?.effectiveDistanceUnit.abbreviation ?? "km"
                                    LabeledContent(String(localized: "Current odometer")) {
                                        Text(String(format: "%.0f %@", costEntry.vehicle?.currentOdometer ?? 0, unit))
                                            .foregroundStyle(.secondary)
                                    }
                                    DistancePickerRow(
                                        label: String(localized: "In how many \(unit)"),
                                        unit: unit,
                                        value: $vm.reminderDistanceInterval
                                    )
                                    DistancePickerRow(
                                        label: String(localized: "Remind \(unit) before"),
                                        unit: unit,
                                        value: $vm.reminderLeadDistance
                                    )
                                }
                            }
                        }

                        PhotoAttachmentSection(photos: $vm.selectedPhotos)

                        FileAttachmentSection(
                            attachmentData: $vm.selectedAttachmentData,
                            attachmentNames: $vm.selectedAttachmentNames
                        )

                    }
                }
            }
            .navigationTitle(String(localized: "Edit Cost"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        viewModel?.save()
                        dismiss()
                    }
                    .disabled(viewModel?.isValid != true)
                }
            }
        }
    }
}
