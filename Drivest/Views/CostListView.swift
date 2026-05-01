import SwiftUI
import SwiftData

struct CostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VehicleSelectionStore.self) private var store
    @Query private var vehicles: [Vehicle]
    @State private var viewModel: CostListViewModel?
    @State private var showAddCost = false
    @State private var showSettings = false
    @State private var showVehiclePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Costs", showSettings: $showSettings)

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
                            actionLabel: "Open Settings",
                            systemImage: "wrench.and.screwdriver"
                        ) {
                            showSettings = true
                        }
                    } else if let vm = viewModel {
                        if vm.costEntries.isEmpty {
                            EmptyStateView(
                                title: "No Costs Yet",
                                message: "Tap + to log your first vehicle expense.",
                                actionLabel: "Add Cost",
                                systemImage: "wrench.and.screwdriver"
                            ) {
                                showAddCost = true
                            }
                        } else {
                            List {
                                ForEach(vm.groupedCostEntries, id: \.key) { month, entries in
                                    Section(month) {
                                        ForEach(entries, id: \.id) { entry in
                                            NavigationLink(value: entry.id) {
                                                CostRow(entry: entry)
                                            }
                                        }
                                    }
                                }
                            }
                            .navigationDestination(for: UUID.self) { id in
                                if let entry = vm.costEntries.first(where: { $0.id == id }) {
                                    CostDetailView(costEntry: entry)
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
                                    showAddCost = true
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
            .sheet(isPresented: $showAddCost) {
                AddCostView(vehicle: store.selectedVehicle ?? vehicles.first) {
                    viewModel?.fetchCosts(for: store.selectedVehicle)
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
                viewModel?.fetchCosts(for: store.selectedVehicle)
            }
        }
    }

    private func setupIfNeeded() {
        if viewModel == nil {
            viewModel = CostListViewModel(modelContext: modelContext)
        }
        store.restoreSelection(from: vehicles)
        viewModel?.fetchCosts(for: store.selectedVehicle)
    }

}

private struct CostRow: View {
    let entry: CostEntry

    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""

    private var entryCurrencySymbol: String? {
        CurrencyDefinition.symbol(for: entry.currencyCode ?? defaultCurrencyCode)
    }
    private var defaultSymbol: String? {
        CurrencyDefinition.symbol(for: defaultCurrencyCode)
    }
    private var convertedAmount: Double? {
        entry.convertedAmount(defaultCurrencyCode: defaultCurrencyCode)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.categoryIcon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let reminder = entry.reminder, !reminder.isSilenced {
                    ReminderStatusBadge(reminder: reminder, vehicle: entry.vehicle)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let converted = convertedAmount, let symbol = defaultSymbol {
                    Text("≈ \(String(format: "%.2f", converted)) \(symbol)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Group {
                    if let symbol = entryCurrencySymbol {
                        Text(String(format: "%.2f", entry.amount) + " " + symbol)
                    } else {
                        Text(String(format: "%.2f", entry.amount))
                    }
                }
                .font(.headline)
                .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ReminderStatusBadge: View {
    let reminder: CostReminder
    let vehicle: Vehicle?

    private let evaluationService = ReminderEvaluationService()

    private var currentOdometer: Double? {
        guard let v = vehicle, !v.fillUps.isEmpty else { return nil }
        return v.currentOdometer
    }

    private var status: ReminderStatus {
        evaluationService.status(
            for: reminder,
            context: ReminderContext(currentDate: Date(), currentOdometer: currentOdometer)
        )
    }

    private var label: String {
        switch reminder.reminderType {
        case .timeBased:
            guard let due = evaluationService.nextDueDate(for: reminder) else { return "" }
            let days = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
            if days < 0 { return String(localized: "Overdue") }
            if days == 0 { return String(localized: "Due today") }
            let comps = Calendar.current.dateComponents([.year, .month], from: Date(), to: due)
            if let y = comps.year, y > 0 { return y == 1 ? String(localized: "In 1 year") : "In \(y) years" }
            if let m = comps.month, m > 0 { return m == 1 ? String(localized: "In 1 month") : "In \(m) months" }
            return days == 1 ? String(localized: "In 1 day") : "In \(days) days"
        case .distanceBased:
            guard let due = evaluationService.nextDueOdometer(for: reminder),
                  let current = currentOdometer else { return "" }
            let remaining = Int(due - current)
            if remaining <= 0 { return String(localized: "Overdue") }
            return "In \(remaining) km"
        }
    }

    private var color: Color {
        switch status {
        case .pending:  return .secondary
        case .dueSoon:  return .orange
        case .overdue:  return .red
        case .silenced: return .secondary
        }
    }

    private var icon: String {
        status == .overdue ? "clock.badge.exclamationmark" : "clock"
    }

    var body: some View {
        if !label.isEmpty {
            HStack(spacing: 3) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption2)
            .foregroundStyle(color)
        }
    }
}
