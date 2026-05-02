import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(VehicleSelectionStore.self) private var store

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Manage Vehicles") {
                        VehicleListView()
                    }
                }

                Section("Vehicle Order") {
                    @Bindable var bindableStore = store
                    Picker("Sort By", selection: $bindableStore.sortOrder) {
                        ForEach(VehicleSortOrder.allCases) { order in
                            Text(LocalizedStringKey(order.label)).tag(order)
                        }
                    }
                    if store.sortOrder == .custom {
                        NavigationLink("Edit Order") {
                            VehicleReorderView()
                        }
                    }
                }

                Section("Manage") {
                    NavigationLink("Currency") {
                        CurrencyManagementView()
                    }
                    NavigationLink("Categories") {
                        CategoriesManagementView()
                    }
                    NavigationLink("Integrations") {
                        IntegrationsView()
                    }
                }

                Section("Language") {
                    Button {
                        if let url = URL(string: "app-settings:") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Text("App Language")
                            Spacer()
                            Text(Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.primary)
                }

                Section("About") {
                    NavigationLink("About Drivest") {
                        AboutView()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct CurrencyManagementView: View {
    @Environment(NBPExchangeRateService.self) private var nbpService

    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""

    @State private var additionalCurrencies: [AdditionalCurrency] = AppPreferences.additionalCurrencies
    @FocusState private var focusedCurrencyCode: String?
    @State private var showAddCurrencyPicker = false

    var body: some View {
        Form {
            Section("Default Currency") {
                Picker("Default Currency", selection: $defaultCurrencyCode) {
                    Text("None").tag("")
                    ForEach(CurrencyDefinition.allCurrencies) { currency in
                        Text("\(currency.code) – \(currency.name)").tag(currency.code)
                    }
                }
                .onChange(of: defaultCurrencyCode) { _, newDefault in
                    additionalCurrencies.removeAll { $0.code == newDefault }
                    AppPreferences.additionalCurrencies = additionalCurrencies
                }
            }

            Section {
                ForEach($additionalCurrencies) { $currency in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(currency.code).frame(width: 44, alignment: .leading)
                            Spacer()
                            Text("1 \(currency.code) =")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            TextField("rate", value: $currency.rate, format: .number.precision(.fractionLength(4)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($focusedCurrencyCode, equals: currency.code)
                            Text(defaultCurrencyCode.isEmpty ? "—" : defaultCurrencyCode)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                        HStack(spacing: 8) {
                            if currency.rateSource == .manual {
                                Label("Manual", systemImage: "pencil")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                                Button("Reset to NBP") {
                                    currency.rateSource = .nbp
                                    AppPreferences.additionalCurrencies = additionalCurrencies
                                    Task { await nbpService.fetch() }
                                }
                                .font(.caption2)
                            } else if let updated = currency.rateUpdatedAt {
                                Label {
                                    Text(updated, format: .dateTime.day().month().year())
                                } icon: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onDelete { idx in
                    additionalCurrencies.remove(atOffsets: idx)
                    AppPreferences.additionalCurrencies = additionalCurrencies
                }
                Button("Add Currency") { showAddCurrencyPicker = true }
                    .disabled(defaultCurrencyCode.isEmpty)
                Button {
                    Task { await nbpService.fetch() }
                } label: {
                    HStack {
                        Text("Refresh Rates Now")
                        if nbpService.isFetching {
                            Spacer()
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                }
                .disabled(nbpService.isFetching || additionalCurrencies.isEmpty)
                if let err = nbpService.fetchError {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
            } header: {
                HStack {
                    Text("Additional Currencies")
                    Spacer()
                    if nbpService.isFetching {
                        ProgressView().scaleEffect(0.7)
                    } else if let date = AppPreferences.nbpLastFetchDate {
                        Text(date, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            additionalCurrencies = AppPreferences.additionalCurrencies
        }
        .onChange(of: focusedCurrencyCode) { editedCode, _ in
            guard let code = editedCode else { return }
            if let i = additionalCurrencies.firstIndex(where: { $0.code == code }) {
                additionalCurrencies[i].rateSource = .manual
                additionalCurrencies[i].rateUpdatedAt = Date()
            }
            AppPreferences.additionalCurrencies = additionalCurrencies
        }
        .onChange(of: nbpService.isFetching) { _, isFetching in
            if !isFetching {
                additionalCurrencies = AppPreferences.additionalCurrencies
            }
        }
        .sheet(isPresented: $showAddCurrencyPicker) {
            CurrencyPickerSheet(
                excluded: [defaultCurrencyCode] + additionalCurrencies.map(\.code)
            ) { code in
                additionalCurrencies.append(AdditionalCurrency(code: code, rate: 1.0, rateSource: .nbp))
                AppPreferences.additionalCurrencies = additionalCurrencies
                showAddCurrencyPicker = false
                Task { await nbpService.fetch() }
            } onCancel: {
                showAddCurrencyPicker = false
            }
        }
    }
}

private struct CategoriesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CostCategory.sortOrder) private var categories: [CostCategory]
    @State private var showAddCategory = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Label(LocalizedStringKey(category.name), systemImage: category.iconName)
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView { name, iconName in
                let nextOrder = (categories.map(\.sortOrder).max() ?? -1) + 1
                let category = CostCategory(name: name, iconName: iconName, sortOrder: nextOrder)
                modelContext.insert(category)
                Persistence.save(modelContext)
            }
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
        Persistence.save(modelContext)
    }
}

private struct VehicleReorderView: View {
    @Environment(VehicleSelectionStore.self) private var store
    @Query private var vehicles: [Vehicle]
    @State private var orderedVehicles: [Vehicle] = []

    var body: some View {
        List {
            ForEach(orderedVehicles, id: \.id) { vehicle in
                HStack {
                    VehiclePhotoView(photoData: vehicle.photoData, size: 32)
                    Text(vehicle.name)
                }
            }
            .onMove { source, destination in
                orderedVehicles.move(fromOffsets: source, toOffset: destination)
                store.updateCustomOrder(orderedVehicles)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Vehicle Order")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            orderedVehicles = store.sortedVehicles(vehicles)
        }
    }
}

private struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "tag.fill"

    let onSave: (String, String) -> Void

    private let icons: [String] = [
        "tag.fill",
        "shield.fill",
        "wrench.fill",
        "hammer.fill",
        "road.lanes",
        "drop.fill",
        "parkingsign",
        "exclamationmark.octagon.fill",
        "fuelpump.fill",
        "bolt.fill",
        "flame.fill",
        "car.fill",
        "steeringwheel",
        "creditcard.fill",
        "cart.fill",
        "bicycle",
        "tram.fill",
        "airplane",
        "cross.fill",
        "house.fill",
        "doc.fill",
        "star.fill",
        "clock.fill",
        "bag.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                        .textInputAutocapitalization(.never)
                }
                Section("Icon") {
                    let columns = Array(repeating: GridItem(.flexible()), count: 6)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .background(selectedIcon == icon ? Color.accentColor : Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, selectedIcon)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

private struct AboutView: View {
    @Environment(\.openURL) private var openURL

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        List {
            Section {
                VStack(spacing: 6) {
                    Image("AppLogo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(Color.accentColor)
                    Text("Drivest")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Author") {
                LabeledContent("Developer", value: "Andrzej Siemion")
                Button {
                    openURL(URL(string: "https://drivest.app")!)
                } label: {
                    HStack {
                        Text("Website")
                        Spacer()
                        Text("drivest.app")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                Button {
                    openURL(URL(string: "https://github.com/andrzejsiemion")!)
                } label: {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Text("@andrzejsiemion")
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }

            Section("Support") {
                Text("Drivest is free and open source. If you find it useful, consider starring the project on GitHub.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Legal") {
                Button {
                    openURL(URL(string: "https://drivest.app/privacy")!)
                } label: {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                LabeledContent("License", value: "MIT")
                Button {
                    openURL(URL(string: "https://github.com/andrzejsiemion/drivest/blob/main/LICENSE")!)
                } label: {
                    HStack {
                        Text("View License")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                Button {
                    openURL(URL(string: "https://github.com/andrzejsiemion/drivest-ios")!)
                } label: {
                    HStack {
                        Text("Source Code")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CurrencyPickerSheet: View {
    let excluded: [String]
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    private var available: [CurrencyDefinition] {
        CurrencyDefinition.allCurrencies.filter { !excluded.contains($0.code) }
    }

    var body: some View {
        NavigationStack {
            List(available) { currency in
                Button {
                    onSelect(currency.code)
                } label: {
                    VStack(alignment: .leading) {
                        Text(currency.code).fontWeight(.semibold)
                        Text(currency.name).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Add Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
        }
    }
}
