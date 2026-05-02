import SwiftUI
import SwiftData

struct FillUpListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VehicleSelectionStore.self) private var store
    @Query private var vehicles: [Vehicle]
    @State private var listViewModel: FillUpListViewModel?
    @State private var showAddFillUp = false
    @State private var showSettings = false
    @State private var showVehiclePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Fuel", showSettings: $showSettings)

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

                ZStack {
                    if vehicles.isEmpty {
                        EmptyStateView(
                            title: "No Vehicle",
                            message: "Go to Settings to add your first vehicle.",
                            actionLabel: "Open Settings"
                        ) { showSettings = true }
                    } else if let vm = listViewModel {
                        let fillUpsAreValid = vm.lastFetchedVehicleID.map { id in
                            vehicles.contains(where: { $0.id == id })
                        } ?? false
                        if vm.fillUps.isEmpty || !fillUpsAreValid {
                            EmptyStateView(
                                title: "No Fill-Ups",
                                message: "Tap + to log your first fuel fill-up.",
                                actionLabel: "Add Fill-Up"
                            ) {
                                showAddFillUp = true
                            }
                        } else {
                            let fuelUnitAbbreviation = vehicles
                                .first(where: { $0.id == vm.lastFetchedVehicleID })?
                                .fuelUnit?.abbreviation ?? "L"
                            List {
                                ForEach(vm.groupedFillUps, id: \.key) { month, fillUps in
                                    Section(month) {
                                        ForEach(fillUps, id: \.id) { fillUp in
                                            let index = vm.fillUps.firstIndex(where: { $0.id == fillUp.id }) ?? 0
                                            let previousOdometer = index + 1 < vm.fillUps.count ? vm.fillUps[index + 1].odometerReading : nil
                                            NavigationLink(value: fillUp.id) {
                                                FillUpRow(
                                                    fillUp: fillUp,
                                                    fuelUnitAbbreviation: fuelUnitAbbreviation,
                                                    isOnlyEntry: vm.fillUps.count == 1,
                                                    distanceSinceLastFillUp: previousOdometer.map { fillUp.odometerReading - $0 }
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .navigationDestination(for: UUID.self) { fillUpId in
                                if let fillUp = vm.fillUps.first(where: { $0.id == fillUpId }) {
                                    FillUpDetailView(fillUp: fillUp)
                                }
                            }
                        }
                    }

                    if !vehicles.isEmpty {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button {
                                    showAddFillUp = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                        .shadow(radius: 4, y: 2)
                                }
                                .padding(.trailing, 24)
                                .padding(.bottom, 24)
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
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showAddFillUp) {
                AddFillUpView(
                    viewModel: AddFillUpViewModel(
                        modelContext: modelContext,
                        vehicle: store.selectedVehicle ?? vehicles.first
                    ),
                    vehicles: vehicles
                ) {
                    listViewModel?.fetchFillUps(for: store.selectedVehicle)
                }
            }
            .onAppear { setupIfNeeded() }
            .onChange(of: vehicles) {
                setupIfNeeded()
                if let selected = store.selectedVehicle, !vehicles.contains(selected) {
                    store.selectedVehicle = vehicles.first
                }
                if store.selectedVehicle == nil {
                    store.selectedVehicle = vehicles.first
                }
            }
            .onChange(of: store.selectedVehicle) {
                listViewModel?.fetchFillUps(for: store.selectedVehicle)
            }
        }
    }

    private func setupIfNeeded() {
        if listViewModel == nil {
            listViewModel = FillUpListViewModel(modelContext: modelContext)
        }
        store.restoreSelection(from: vehicles)
        listViewModel?.fetchFillUps(for: store.selectedVehicle)
    }

}

private struct FillUpRow: View {
    let fillUp: FillUp
    let fuelUnitAbbreviation: String
    let isOnlyEntry: Bool
    var distanceSinceLastFillUp: Double? = nil

    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""

    private var convertedCost: Double? { fillUp.convertedCost(defaultCurrencyCode: defaultCurrencyCode) }
    private var displayCost: Double { fillUp.effectiveCost }
    private var defaultSymbol: String? { CurrencyDefinition.symbol(for: defaultCurrencyCode) }
    private var fillUpCurrencySymbol: String? { CurrencyDefinition.symbol(for: fillUp.currencyCode ?? defaultCurrencyCode) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(fillUp.date, style: .date)
                    .font(.headline)
                Text(fillUp.date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let converted = convertedCost, let symbol = defaultSymbol {
                    Text("≈ \(String(format: "%.2f", converted)) \(symbol)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Group {
                    if let symbol = fillUpCurrencySymbol {
                        Text(String(format: "%.2f", displayCost) + " " + symbol)
                    } else {
                        Text(String(format: "%.2f", displayCost))
                    }
                }
                .font(.headline)
                .foregroundStyle(.primary)
            }
            HStack {
                let unit = fuelUnitAbbreviation
                let priceStr: String = {
                    if let symbol = fillUpCurrencySymbol {
                        return String(format: "%.2f %@/\(unit)", fillUp.pricePerLiter, symbol)
                    }
                    return String(format: "%.2f/\(unit)", fillUp.pricePerLiter)
                }()
                Text(String(format: "%.2f \(unit) @ ", fillUp.volume) + priceStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f km", fillUp.odometerReading))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                EfficiencyBadge(efficiency: fillUp.efficiency, isOnlyEntry: isOnlyEntry)
                if !fillUp.isFullTank {
                    Text("Partial")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
                Spacer()
                if let dist = distanceSinceLastFillUp, dist > 0 {
                    Text(String(format: "+%.0f km", dist))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            if let note = fillUp.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
