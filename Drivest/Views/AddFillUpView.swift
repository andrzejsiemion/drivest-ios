import SwiftUI
import SwiftData

struct AddFillUpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @State private var viewModel: AddFillUpViewModel
    @State private var selectedCurrencyCode: String = ""

    let vehicles: [Vehicle]
    var onSave: (() -> Void)?

    init(viewModel: AddFillUpViewModel, vehicles: [Vehicle], onSave: (() -> Void)? = nil) {
        _viewModel = State(wrappedValue: viewModel)
        self.vehicles = vehicles
        self.onSave = onSave
    }

    private var configuredCurrencies: [String] {
        [defaultCurrencyCode].filter { !$0.isEmpty }
        + AppPreferences.additionalCurrencies.map(\.code)
    }

    private var activeCurrencyCode: String {
        selectedCurrencyCode.isEmpty ? defaultCurrencyCode : selectedCurrencyCode
    }

    private var activeCurrencySymbol: String? { CurrencyDefinition.symbol(for: activeCurrencyCode) }

    private var activeRate: Double { AppPreferences.rate(for: activeCurrencyCode) }

    var body: some View {
        let vm = viewModel
        let f = vm.fields
        NavigationStack {
            Form {
                        Section {
                            if vehicles.count > 1 {
                                Picker("Vehicle", selection: Binding(
                                    get: { vm.selectedVehicle },
                                    set: { vm.selectedVehicle = $0 }
                                )) {
                                    ForEach(vehicles, id: \.id) { v in
                                        Text(v.name).tag(Optional(v))
                                    }
                                }
                                .onChange(of: vm.selectedVehicle) { vm.onVehicleChanged() }
                            }

                            HStack {
                                Text("Odometer").foregroundStyle(.secondary)
                                Spacer()
                                let lastOdo = vm.selectedVehicle.map { $0.currentOdometer }
                                let placeholder = lastOdo.map { String(format: "%.0f", $0) } ?? "0"
                                TextField(placeholder, text: Binding(
                                    get: { f.odometerText },
                                    set: { f.odometerText = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                if vm.selectedVehicle?.vin != nil,
                                   vm.selectedVehicle?.make?.lowercased() == "volvo",
                                   KeychainService.load(for: KeychainService.volvoRefreshToken) != nil {
                                    Button {
                                        Task { await vm.fetchVolvoOdometer() }
                                    } label: {
                                        if f.volvoService.isFetching {
                                            ProgressView().scaleEffect(0.75)
                                        } else {
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.tint)
                                }
                                if vm.selectedVehicle?.vin != nil,
                                   vm.selectedVehicle?.make?.lowercased() == "toyota",
                                   ToyotaAPIConstants.isConfigured {
                                    Button {
                                        Task { await vm.fetchToyotaOdometer() }
                                    } label: {
                                        if f.toyotaService.isFetching {
                                            ProgressView().scaleEffect(0.75)
                                        } else {
                                            Image(systemName: "arrow.down.circle")
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.tint)
                                }
                                Text(vm.selectedVehicle?.effectiveDistanceUnit.abbreviation ?? "km")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                            if let fetchError = f.volvoService.fetchError {
                                Text(fetchError).font(.caption).foregroundStyle(.red)
                            }
                            if let fetchError = f.toyotaService.fetchError {
                                Text(fetchError).font(.caption).foregroundStyle(.red)
                            }

                            if let error = f.validationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        Section("Fuel") {
                            ReceiptScanButton { price, volume, total, image in
                                if let price { f.pricePerLiterText = price }
                                if let volume { f.volumeText = volume }
                                if let total { f.totalCostText = total }
                                if let image, let raw = image.jpegData(compressionQuality: 1.0),
                                   let compressed = ImageCompressor.compress(raw) {
                                    f.selectedPhotos.append(compressed)
                                }
                                let setCount = [price, volume, total].compactMap { $0 }.count
                                if setCount == 2 {
                                    if price != nil && volume != nil {
                                        f.onFieldEdited(.pricePerLiter); f.onFieldEdited(.volume)
                                    } else if price != nil && total != nil {
                                        f.onFieldEdited(.pricePerLiter); f.onFieldEdited(.totalCost)
                                    } else {
                                        f.onFieldEdited(.volume); f.onFieldEdited(.totalCost)
                                    }
                                }
                            }

                            Picker("Fuel Type", selection: Binding(
                                get: { f.selectedFuelType },
                                set: { f.selectedFuelType = $0 }
                            )) {
                                Text("Not set").tag(FuelType?.none)
                                ForEach(FuelType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(FuelType?.some(type))
                                }
                            }

                            HStack {
                                Text("Price per Unit")
                                    .foregroundStyle(.secondary)
                                if configuredCurrencies.count > 1 {
                                    currencyMenu
                                }
                                Spacer()
                                TextField("0.000", text: Binding(
                                    get: { f.pricePerLiterText },
                                    set: {
                                        f.pricePerLiterText = $0
                                        f.onFieldEdited(.pricePerLiter)
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                if let symbol = activeCurrencySymbol {
                                    Text(symbol)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            HStack {
                                Text("Volume")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: Binding(
                                    get: { f.volumeText },
                                    set: {
                                        f.volumeText = $0
                                        f.onFieldEdited(.volume)
                                    }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                Text(vm.selectedVehicle?.fuelUnit?.abbreviation ?? "L")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .trailing, spacing: 4) {
                                HStack {
                                    Text("Total Cost")
                                        .foregroundStyle(.secondary)
                                    if configuredCurrencies.count > 1 {
                                        currencyMenu
                                    }
                                    Spacer()
                                    TextField("0.00", text: Binding(
                                        get: { f.totalCostText },
                                        set: {
                                            f.totalCostText = $0
                                            f.onFieldEdited(.totalCost)
                                        }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    if let symbol = activeCurrencySymbol {
                                        Text(symbol)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if activeCurrencyCode != defaultCurrencyCode,
                                   !activeCurrencyCode.isEmpty,
                                   let total = f.totalCost,
                                   let defaultSymbol = CurrencyDefinition.symbol(for: defaultCurrencyCode) {
                                    let converted = total * activeRate
                                    Text("≈ \(String(format: "%.2f", converted)) \(defaultSymbol)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("Approximately \(String(format: "%.2f", converted)) \(defaultSymbol)")
                                }
                            }
                        }

                        Section {
                            HStack {
                                Text("Discount")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("0.00", text: Binding(
                                    get: { f.discountText },
                                    set: { f.discountText = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                if let symbol = activeCurrencySymbol {
                                    Text(symbol)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Toggle("Full Tank", isOn: Binding(
                                get: { f.isFullTank },
                                set: { f.isFullTank = $0 }
                            ))
                        }

                        Section("Date") {
                            DatePicker(
                                "Date",
                                selection: Binding(
                                    get: { f.date },
                                    set: { f.date = $0 }
                                ),
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }

                        Section("Note (Optional)") {
                            TextField("Add a note...", text: Binding(
                                get: { f.noteText },
                                set: { newValue in
                                    f.noteText = String(newValue.prefix(200))
                                }
                            ), axis: .vertical)
                            .lineLimit(5...5)
                            .textInputAutocapitalization(.never)

                            if !f.noteText.isEmpty {
                                Text("\(f.noteText.count)/200")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }

                        PhotoAttachmentSection(photos: Binding(
                            get: { f.selectedPhotos },
                            set: { f.selectedPhotos = $0 }
                        ))
            }
            .navigationTitle("Add Fill-Up")
            .onAppear {
                if selectedCurrencyCode.isEmpty { selectedCurrencyCode = defaultCurrencyCode }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let isDefault = activeCurrencyCode == defaultCurrencyCode || activeCurrencyCode.isEmpty
                        let code = activeCurrencyCode.isEmpty ? nil : activeCurrencyCode
                        let rate: Double? = isDefault ? (code != nil ? 1.0 : nil) : activeRate
                        if vm.save(currencyCode: code, exchangeRate: rate) {
                            onSave?()
                            dismiss()
                        }
                    }
                    .disabled(!vm.isValid)
                }
            }
        }
    }

    @ViewBuilder
    private var currencyMenu: some View {
        Menu {
            ForEach(configuredCurrencies, id: \.self) { code in
                Button(code) { selectedCurrencyCode = code }
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
