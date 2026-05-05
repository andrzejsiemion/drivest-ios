import SwiftUI
import SwiftData

struct CostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VehicleSelectionStore.self) private var store
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @Query private var vehicles: [Vehicle]
    @State private var viewModel: CostListViewModel?
    @State private var showAddCost = false
    @State private var showSettings = false
    @State private var showVehiclePicker = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                                CostRow(entry: entry, vehicle: store.selectedVehicle)
                                            }
                                        }
                                    }
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
            .navigationDestination(for: UUID.self) { id in
                if let entry = try? modelContext.fetch(
                    FetchDescriptor<CostEntry>(predicate: #Predicate { $0.id == id })
                ).first {
                    CostDetailView(costEntry: entry)
                }
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
            .onChange(of: deepLinkRouter.pending) {
                if case .costDetail(let costEntryId) = deepLinkRouter.pending {
                    navigationPath = NavigationPath()
                    navigationPath.append(costEntryId)
                    deepLinkRouter.pending = nil
                }
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
    var vehicle: Vehicle? = nil

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

    private var matchingReminder: Reminder? {
        vehicle?.reminders.first(where: { $0.costEntryId == entry.id })
    }

    private var reminderStatus: ReminderStatus? {
        guard let r = matchingReminder else { return nil }
        return ReminderEvaluationService.status(for: r, currentOdometer: vehicle?.currentOdometer)
    }

    private var reminderColor: Color {
        switch reminderStatus {
        case .overdue: return .red
        case .dueSoon: return .orange
        default: return .secondary
        }
    }

    private var reminderIcon: String? {
        guard let r = matchingReminder else { return nil }
        return r.reminderType == .date ? "calendar.badge.clock" : "gauge.with.dots.needle.33percent"
    }

    private var reminderSubtitle: String? {
        guard let r = matchingReminder else { return nil }
        if r.reminderType == .date, let dueDate = r.dueDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            if days < 0 {
                return String(localized: "\(-days) days overdue")
            } else {
                return String(localized: "in \(days) days")
            }
        } else if r.reminderType == .distance, let target = r.targetOdometer {
            let unit = vehicle?.effectiveDistanceUnit ?? .kilometers
            let currentKm = unit == .miles ? (vehicle?.currentOdometer ?? 0) / 0.621371 : (vehicle?.currentOdometer ?? 0)
            let remaining = unit.fromKm(target - currentKm)
            if remaining <= 0 {
                return String(localized: "\(Int(-remaining)) \(unit.abbreviation) overdue")
            } else {
                return String(localized: "in \(Int(remaining)) \(unit.abbreviation)")
            }
        }
        return nil
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
                if let icon = reminderIcon, let subtitle = reminderSubtitle {
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                        Text(subtitle)
                    }
                    .font(.caption2)
                    .foregroundStyle(reminderColor)
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
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}
