import SwiftUI
import SwiftData

struct AddCostView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @Query(sort: \CostCategory.sortOrder) private var categories: [CostCategory]
    @State private var viewModel: AddCostViewModel?
    @State private var selectedCurrencyCode: String = ""

    let vehicle: Vehicle?
    let onSave: () -> Void

    private var configuredCurrencies: [String] {
        [defaultCurrencyCode].filter { !$0.isEmpty }
        + AppPreferences.additionalCurrencies.map(\.code)
    }

    private var activeCurrencyCode: String {
        selectedCurrencyCode.isEmpty ? defaultCurrencyCode : selectedCurrencyCode
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    AddCostForm(
                        viewModel: vm,
                        categories: categories,
                        configuredCurrencies: configuredCurrencies,
                        activeCurrencyCode: activeCurrencyCode,
                        onSelectCurrency: { selectedCurrencyCode = $0 }
                    )
                        .navigationTitle(String(localized: "Add Cost"))
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(String(localized: "Cancel")) { dismiss() }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button(String(localized: "Save")) {
                                    let isDefault = activeCurrencyCode == defaultCurrencyCode || activeCurrencyCode.isEmpty
                                    let code = activeCurrencyCode.isEmpty ? nil : activeCurrencyCode
                                    let rate: Double? = isDefault ? (code != nil ? 1.0 : nil) : AppPreferences.rate(for: activeCurrencyCode)
                                    vm.save(currencyCode: code, exchangeRate: rate)
                                    if vm.reminderResetCandidate == nil {
                                        onSave()
                                        dismiss()
                                    }
                                }
                                .disabled(!vm.isValid)
                            }
                        }
                        .confirmationDialog(
                            String(localized: "Reset Reminder?"),
                            isPresented: Binding(
                                get: { vm.reminderResetCandidate != nil },
                                set: { if !$0 { vm.dismissReminderReset() } }
                            ),
                            titleVisibility: .visible
                        ) {
                            Button(String(localized: "Reset Reminder")) {
                                vm.confirmReminderReset(
                                    originDate: vm.date,
                                    originOdometer: vehicle?.currentOdometer
                                )
                                onSave()
                                dismiss()
                            }
                            Button(String(localized: "Keep Existing"), role: .cancel) {
                                vm.dismissReminderReset()
                                onSave()
                                dismiss()
                            }
                        } message: {
                            if let candidate = vm.reminderResetCandidate {
                                Text(String(localized: "You recorded a new \(candidate.categoryName). Reset the reminder from this entry?"))
                            }
                        }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AddCostViewModel(modelContext: modelContext, vehicle: vehicle)
            }
            if viewModel?.selectedCategory == nil {
                viewModel?.selectedCategory = categories.first
            }
            if selectedCurrencyCode.isEmpty { selectedCurrencyCode = defaultCurrencyCode }
        }
        .onChange(of: categories) {
            if viewModel?.selectedCategory == nil {
                viewModel?.selectedCategory = categories.first
            }
        }
    }
}

private struct AddCostForm: View {
    @Bindable var viewModel: AddCostViewModel
    let categories: [CostCategory]
    let configuredCurrencies: [String]
    let activeCurrencyCode: String
    let onSelectCurrency: (String) -> Void

    private var currentOdometer: Double? {
        guard let vehicle = viewModel.selectedVehicle, !vehicle.fillUps.isEmpty else { return nil }
        return vehicle.currentOdometer
    }

    var body: some View {
        Form {
            Section(String(localized: "Category")) {
                if categories.isEmpty {
                    Text(String(localized: "No categories available."))
                        .foregroundStyle(.secondary)
                    Text(String(localized: "Add categories in Settings (···)."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker(String(localized: "Category"), selection: $viewModel.selectedCategory) {
                        ForEach(categories) { category in
                            Label(LocalizedStringKey(category.name), systemImage: category.iconName)
                                .tag(Optional(category))
                        }
                    }
                }
            }

            Section(String(localized: "Amount")) {
                HStack {
                    TextField("0.00", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                    if configuredCurrencies.count > 1 {
                        Menu {
                            ForEach(configuredCurrencies, id: \.self) { code in
                                Button(code) { onSelectCurrency(code) }
                            }
                        } label: {
                            Text(activeCurrencyCode.isEmpty ? "—" : activeCurrencyCode)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.tint.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(String(localized: "Date")) {
                DatePicker(String(localized: "Date"), selection: $viewModel.date, displayedComponents: .date)
            }

            Section(String(localized: "Note (Optional)")) {
                TextField(String(localized: "Add a note..."), text: $viewModel.noteText, axis: .vertical)
                    .lineLimit(5...5)
                    .textInputAutocapitalization(.never)
            }

            PhotoAttachmentSection(photos: $viewModel.selectedPhotos)

            FileAttachmentSection(
                attachmentData: $viewModel.selectedAttachmentData,
                attachmentNames: $viewModel.selectedAttachmentNames
            )

            ReminderFormSection(
                draft: $viewModel.draftReminder,
                costEntryDate: viewModel.date,
                costEntryOdometer: currentOdometer
            )
        }
    }
}
