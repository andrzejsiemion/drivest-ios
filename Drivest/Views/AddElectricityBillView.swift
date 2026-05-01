import SwiftUI

struct AddElectricityBillView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""

    let vehicle: Vehicle
    @State private var viewModel: AddBillViewModel

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        let lastBillEndDate = vehicle.electricityBills
            .map(\.endDate)
            .max()
        let startDate: Date
        if let lastEnd = lastBillEndDate,
           let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: lastEnd) {
            startDate = nextDay
        } else {
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }
        _viewModel = State(initialValue: AddBillViewModel(startDate: startDate))
    }

    private var currencySymbol: String? {
        CurrencyDefinition.symbol(for: defaultCurrencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start Date", selection: $viewModel.startDate, in: ...viewModel.endDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                }

                Section("Electricity") {
                    HStack {
                        Text("Total kWh from Meter").foregroundStyle(.secondary)
                        Spacer()
                        TextField("0.0", text: $viewModel.totalKwhText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kWh").foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Cost").foregroundStyle(.secondary)
                        Spacer()
                        TextField("0.00", text: $viewModel.totalCostText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        if let symbol = currencySymbol {
                            Text(symbol).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Bill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(for: vehicle, currencyCode: defaultCurrencyCode.isEmpty ? nil : defaultCurrencyCode, context: modelContext) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}
