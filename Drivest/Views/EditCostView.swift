import SwiftUI
import SwiftData

struct EditCostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @Query(sort: \CostCategory.sortOrder) private var categories: [CostCategory]
    @State private var viewModel: EditCostViewModel?

    let costEntry: CostEntry

    private var currentOdometer: Double? {
        guard let vehicle = costEntry.vehicle, !vehicle.fillUps.isEmpty else { return nil }
        return vehicle.currentOdometer
    }

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

                        PhotoAttachmentSection(photos: $vm.selectedPhotos)

                        FileAttachmentSection(
                            attachmentData: $vm.selectedAttachmentData,
                            attachmentNames: $vm.selectedAttachmentNames
                        )

                        ReminderFormSection(
                            draft: $vm.draftReminder,
                            costEntryDate: vm.date,
                            costEntryOdometer: currentOdometer
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
