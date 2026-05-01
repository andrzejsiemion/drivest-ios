import SwiftUI
import SwiftData

struct EditFillUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @State private var viewModel: EditFillUpViewModel

    let fillUp: FillUp

    init(fillUp: FillUp, modelContext: ModelContext) {
        self.fillUp = fillUp
        _viewModel = State(wrappedValue: EditFillUpViewModel(modelContext: modelContext, fillUp: fillUp))
    }

    private var fillUpCurrencySymbol: String? {
        CurrencyDefinition.symbol(for: fillUp.currencyCode ?? defaultCurrencyCode)
    }

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            Form {
                        Section {
                            if let vehicle = fillUp.vehicle {
                                LabeledContent("Vehicle", value: vehicle.name)
                            }
                            DatePicker("Date", selection: $vm.date, displayedComponents: [.date, .hourAndMinute])
                            HStack {
                                Text("Odometer")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("0", text: $vm.odometerText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                if fillUp.vehicle?.vin != nil,
                                   fillUp.vehicle?.make?.lowercased() == "volvo",
                                   KeychainService.load(for: KeychainService.volvoRefreshToken) != nil {
                                    Button {
                                        Task { await vm.fetchVolvoOdometer() }
                                    } label: {
                                        if vm.volvoService.isFetching {
                                            ProgressView().scaleEffect(0.75)
                                        } else {
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.tint)
                                }
                                if fillUp.vehicle?.vin != nil,
                                   fillUp.vehicle?.make?.lowercased() == "toyota",
                                   ToyotaAPIConstants.isConfigured {
                                    Button {
                                        Task { await vm.fetchToyotaOdometer() }
                                    } label: {
                                        if vm.toyotaService.isFetching {
                                            ProgressView().scaleEffect(0.75)
                                        } else {
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.tint)
                                }
                                Text(fillUp.vehicle?.effectiveDistanceUnit.abbreviation ?? "km")
                                    .foregroundStyle(.secondary)
                            }
                            if let fetchError = vm.volvoService.fetchError {
                                Text(fetchError).font(.caption).foregroundStyle(.red)
                            }
                            if let fetchError = vm.toyotaService.fetchError {
                                Text(fetchError).font(.caption).foregroundStyle(.red)
                            }
                            if let error = vm.validationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        Section("Fuel") {
                            ReceiptScanButton { price, volume, total, image in
                                if let price { vm.pricePerLiterText = price }
                                if let volume { vm.volumeText = volume }
                                if let total { vm.totalCostText = total }
                                if let image, let raw = image.jpegData(compressionQuality: 1.0),
                                   let compressed = ImageCompressor.compress(raw) {
                                    vm.selectedPhotos.append(compressed)
                                }
                                let setCount = [price, volume, total].compactMap { $0 }.count
                                if setCount == 2 {
                                    if price != nil && volume != nil {
                                        vm.onFieldEdited(.pricePerLiter); vm.onFieldEdited(.volume)
                                    } else if price != nil && total != nil {
                                        vm.onFieldEdited(.pricePerLiter); vm.onFieldEdited(.totalCost)
                                    } else {
                                        vm.onFieldEdited(.volume); vm.onFieldEdited(.totalCost)
                                    }
                                }
                            }

                            Picker("Fuel Type", selection: $vm.selectedFuelType) {
                                Text("Not set").tag(FuelType?.none)
                                ForEach(FuelType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(FuelType?.some(type))
                                }
                            }

                            HStack {
                                Text("Price per Unit").foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: $vm.pricePerLiterText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: vm.pricePerLiterText) { vm.onFieldEdited(.pricePerLiter) }
                                if let symbol = fillUpCurrencySymbol {
                                    Text(symbol).font(.callout).foregroundStyle(.secondary)
                                }
                            }

                            HStack {
                                Text("Volume").foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: $vm.volumeText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: vm.volumeText) { vm.onFieldEdited(.volume) }
                            }

                            HStack {
                                Text("Total Cost").foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: $vm.totalCostText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: vm.totalCostText) { vm.onFieldEdited(.totalCost) }
                                if let symbol = fillUpCurrencySymbol {
                                    Text(symbol).font(.callout).foregroundStyle(.secondary)
                                }
                            }
                        }

                        Section {
                            HStack {
                                Text("Discount").foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: $vm.discountText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                if let symbol = fillUpCurrencySymbol {
                                    Text(symbol).font(.callout).foregroundStyle(.secondary)
                                }
                            }
                        }

                        if vm.hasSecondaryCurrency {
                            Section("Exchange Rate") {
                                HStack {
                                    if let code = fillUp.currencyCode, !defaultCurrencyCode.isEmpty {
                                        Text("\(code) → \(defaultCurrencyCode)").foregroundStyle(.secondary)
                                    } else {
                                        Text("Rate").foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    TextField("1.0000", text: $vm.exchangeRateText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }

                        Section {
                            Toggle("Full Tank", isOn: $vm.isFullTank)
                        }

                        Section("Note") {
                            TextField("Add a note (optional)", text: $vm.noteText, axis: .vertical)
                                .lineLimit(1...3)
                                .textInputAutocapitalization(.never)
                                .onChange(of: vm.noteText) {
                                    if vm.noteText.count > 200 {
                                        vm.noteText = String(vm.noteText.prefix(200))
                                    }
                                }
                            if !vm.noteText.isEmpty {
                                Text("\(vm.noteText.count)/200")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }

                        PhotoAttachmentSection(photos: $vm.selectedPhotos)
            }
            .navigationTitle("Edit Fill-Up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if vm.save() { dismiss() }
                    }
                    .disabled(!vm.isValid)
                }
            }
        }
    }
}
