import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ImportCoordinator.self) private var importCoordinator
    @Environment(VehicleSelectionStore.self) private var store
    @Query private var allVehicles: [Vehicle]
    @State private var importData: Data? = nil
    @State private var importPreview: VehicleImporter.ImportPreview? = nil
    @State private var showImportConfirmation = false
    @State private var importError: String? = nil

    private var selectedVehicle: Vehicle? { store.selectedVehicle }
    private var hasEVVehicle: Bool { allVehicles.contains { $0.isEV } }

    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                FillUpListView()
                    .tabItem {
                        Label("Fuel", systemImage: "fuelpump")
                    }

                if hasEVVehicle {
                    EVTabView()
                        .tabItem {
                            Label("EV", systemImage: "bolt.car")
                        }
                }

                CostListView()
                    .tabItem {
                        Label("Costs", systemImage: "wrench.and.screwdriver")
                    }

                SummaryTabView()
                    .tabItem {
                        Label("Statistics", systemImage: "chart.bar")
                    }
            }

            EVSyncFailureBanner(vehicle: selectedVehicle)
        }
        .onChange(of: importCoordinator.pendingURL) { _, url in
            guard let url else { return }
            importCoordinator.pendingURL = nil
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            importData = data
            importPreview = try? VehicleImporter.preview(from: data, existingVehicles: allVehicles)
            if importPreview != nil { showImportConfirmation = true }
        }
        .sheet(isPresented: $showImportConfirmation) {
            if let preview = importPreview, let data = importData {
                ImportConfirmationSheet(preview: preview) { strategy in
                    do {
                        _ = try VehicleImporter.import(from: data, into: modelContext, existingVehicles: allVehicles, strategy: strategy)
                    } catch {
                        importError = error.localizedDescription
                    }
                    showImportConfirmation = false
                } onCancel: {
                    showImportConfirmation = false
                }
            }
        }
        .alert("Import Error", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
}

private struct EVTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(VehicleSelectionStore.self) private var store
    @Query private var vehicles: [Vehicle]
    @Query private var snapshots: [EnergySnapshot]
    @State private var showSettings = false
    @State private var showVehiclePicker = false
    @State private var showAddBill = false
    @State private var inProgressPeriod: EVPeriod? = nil

    private var evVehicles: [Vehicle] { vehicles.filter { $0.isEV } }
    private var selectedVehicle: Vehicle? { store.selectedVehicle }
    private var selectedIsEV: Bool { selectedVehicle?.isEV == true }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "EV", showSettings: $showSettings)

                if let vehicle = selectedVehicle {
                    VehiclePickerCard(
                        vehicle: vehicle,
                        currentOdometer: vehicle.currentOdometer,
                        isInteractive: evVehicles.count > 1 || !selectedIsEV,
                        onTap: { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { showVehiclePicker.toggle() } }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .background(Color(.systemGroupedBackground))
                    .opacity(selectedIsEV ? 1 : 0.5)
                }

                Group {
                    if !selectedIsEV {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "bolt.slash.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Not an EV")
                                .font(.headline)
                            Text("This vehicle doesn't support EV tracking. Select an EV vehicle using the picker above.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.horizontal, 32)
                    } else if let vehicle = selectedVehicle {
                        ZStack(alignment: .bottomTrailing) {
                            List {
                                if let period = inProgressPeriod {
                                    Section {
                                        InProgressPeriodRow(period: period, vehicle: vehicle)
                                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                    }
                                }

                                Section {
                                    NavigationLink("Snapshots") {
                                        EVSnapshotHistoryView(vehicle: vehicle)
                                    }
                                }
                            }

                            Button {
                                showAddBill = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                        .sheet(isPresented: $showAddBill) {
                            AddElectricityBillView(vehicle: vehicle)
                                .onDisappear { loadPeriod(for: vehicle) }
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if showVehiclePicker, !evVehicles.isEmpty {
                        EVVehicleDropdown(
                            vehicles: evVehicles,
                            selected: selectedIsEV ? selectedVehicle : nil,
                            isShowing: $showVehiclePicker
                        ) { vehicle in
                            store.selectedVehicle = vehicle
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .zIndex(showVehiclePicker ? 1 : 0)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                if let v = selectedVehicle, v.isEV { loadPeriod(for: v) }
            }
            .onChange(of: store.selectedVehicle) { _, newVehicle in
                if let newVehicle, newVehicle.isEV { loadPeriod(for: newVehicle) }
                else { inProgressPeriod = nil }
            }
            .onChange(of: snapshots) { _, _ in
                if let v = selectedVehicle, v.isEV { loadPeriod(for: v) }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, let v = selectedVehicle, v.isEV { loadPeriod(for: v) }
            }
        }
    }

    private func loadPeriod(for vehicle: Vehicle) {
        let bills = vehicle.electricityBills.sorted { $0.endDate < $1.endDate }
        let snapshots = vehicle.energySnapshots.sorted { $0.fetchedAt < $1.fetchedAt }
        inProgressPeriod = EVPeriod.build(from: bills, snapshots: snapshots).first { $0.isInProgress }
    }
}

private struct EVVehicleDropdown: View {
    let vehicles: [Vehicle]
    let selected: Vehicle?
    @Binding var isShowing: Bool
    let onSelect: (Vehicle) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(vehicles, id: \.id) { vehicle in
                Button {
                    onSelect(vehicle)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { isShowing = false }
                } label: {
                    HStack(spacing: 10) {
                        vehiclePhoto(vehicle)
                        Text(vehicle.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selected?.id == vehicle.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .font(.subheadline)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if vehicle.id != vehicles.last?.id {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private func vehiclePhoto(_ vehicle: Vehicle) -> some View {
        Group {
            if let data = vehicle.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}

private struct EVSyncFailureBanner: View {
    let vehicle: Vehicle?
    @Environment(\.scenePhase) private var scenePhase
    @State private var failureCount = 0
    @State private var isDismissed = false

    private var shouldShow: Bool {
        guard let vehicle, !isDismissed else { return false }
        return failureCount >= 3
    }

    var body: some View {
        if shouldShow, let vehicle {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Unable to sync \(vehicle.make ?? "EV") — reconnect in Integrations")
                    .font(.caption)
                Spacer()
                Button {
                    isDismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
            .onAppear { refreshCount() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshCount() }
            }
        }
    }

    private func refreshCount() {
        guard let vehicle else { failureCount = 0; return }
        failureCount = UserDefaults.standard.integer(forKey: "snapshotFailures_\(vehicle.id.uuidString)")
        if failureCount < 3 { isDismissed = false }
    }
}

struct SummaryTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VehicleSelectionStore.self) private var store
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @Query private var vehicles: [Vehicle]
    @State private var viewModel: SummaryViewModel?
    @State private var showSettings = false
    @State private var showVehiclePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Statistics", showSettings: $showSettings)

                if let vehicle = store.selectedVehicle, !vehicles.isEmpty {
                    VehiclePickerCard(
                        vehicle: vehicle,
                        currentOdometer: vehicle.currentOdometer,
                        isInteractive: vehicles.count > 1,
                        onTap: { withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { showVehiclePicker.toggle() } }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .background(Color(.systemGroupedBackground))
                }

                Group {
                    if let vm = viewModel {
                        if vm.allTime.isEmpty && vm.chartPoints.isEmpty {
                            EmptyStateView(
                                title: "No Data",
                                message: "Add fill-ups to see your expense summary.",
                                actionLabel: "Got it"
                            ) {}
                        } else {
                            List {
                                Section {
                                    OdometerChartView(
                                        points: vm.chartPoints,
                                        unit: store.selectedVehicle?.effectiveDistanceUnit ?? .kilometers,
                                        chartType: Binding(
                                            get: { vm.chartType },
                                            set: { vm.chartType = $0 }
                                        ),
                                        period: Binding(
                                            get: { vm.chartPeriod },
                                            set: { vm.chartPeriod = $0 }
                                        ),
                                        hasFillUps: !(store.selectedVehicle?.fillUps.isEmpty ?? true)
                                    )
                                }
                                SummaryContentSection(viewModel: vm, defaultCurrencyCode: defaultCurrencyCode)
                            }
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if showVehiclePicker, !vehicles.isEmpty {
                        VehicleDropdownOverlay(
                            vehicles: store.sortedVehicles(vehicles),
                            isShowing: $showVehiclePicker
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .zIndex(showVehiclePicker ? 1 : 0)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SummaryViewModel(modelContext: modelContext)
                }
                store.restoreSelection(from: vehicles)
                viewModel?.loadSummary(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
                viewModel?.loadChart(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
            }
            .onChange(of: vehicles) {
                if let selected = store.selectedVehicle, !vehicles.contains(selected) {
                    store.selectedVehicle = vehicles.first
                }
                if store.selectedVehicle == nil {
                    store.selectedVehicle = vehicles.first
                }
            }
            .onChange(of: store.selectedVehicle) {
                viewModel?.loadSummary(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
                viewModel?.loadChart(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
            }
            .onChange(of: viewModel?.chartPeriod) {
                viewModel?.loadChart(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
            }
            .onChange(of: viewModel?.chartType) {
                viewModel?.loadChart(for: store.selectedVehicle, defaultCurrencyCode: defaultCurrencyCode)
            }
        }
    }

}

private struct SummaryContentSection: View {
    let viewModel: SummaryViewModel
    let defaultCurrencyCode: String

    private var defaultSymbol: String? { CurrencyDefinition.symbol(for: defaultCurrencyCode) }
    private var stats: PeriodStats { viewModel.currentPeriodStats }

    private func costText(_ value: Double) -> String {
        if let symbol = defaultSymbol {
            return String(format: "%.2f %@", value, symbol)
        }
        return String(format: "%.2f", value)
    }

    var body: some View {
        Section(header: Text(viewModel.chartPeriod.chartLabel)) {
            if stats.isEmpty {
                Text(String(localized: "No fill-ups in this period"))
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent(String(localized: "Total Spent")) {
                    Text(costText(stats.totalCost)).fontWeight(.semibold)
                }
                LabeledContent(String(localized: "Total Fuel")) {
                    Text(String(format: "%.2f L", stats.totalVolume))
                }
                LabeledContent(String(localized: "Fill-Ups")) {
                    Text("\(stats.fillUpCount)")
                }
                if let avg = stats.averageEfficiency {
                    LabeledContent(String(localized: "Avg Efficiency")) {
                        Text(String(format: "%.1f L/100km", avg))
                    }
                }
            }
        }
    }
}
