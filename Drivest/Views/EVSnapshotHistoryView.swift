import SwiftUI
import SwiftData

struct EVSnapshotHistoryView: View {
    let vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @State private var periods: [EVPeriod] = []
    @State private var isFetchingNow = false

    var body: some View {
        let completedPeriods = periods.filter { !$0.isInProgress }

        Group {
            if completedPeriods.isEmpty {
                ContentUnavailableView(
                    "No Completed Periods",
                    systemImage: "bolt.car",
                    description: Text("Add your first electricity bill to see billing period data here.")
                )
            } else {
                List {
                    ForEach(completedPeriods) { period in
                        if let bill = period.bill {
                            NavigationLink {
                                ElectricityBillDetailView(bill: bill)
                            } label: {
                                CompletedPeriodRow(period: period, vehicle: vehicle)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                    }
                }
            }
        }
        .navigationTitle("Snapshots")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isFetchingNow = true
                    Task {
                        try? await SnapshotFetchService.shared.fetch(vehicle: vehicle, context: modelContext)
                        loadPeriods()
                        isFetchingNow = false
                    }
                } label: {
                    if isFetchingNow {
                        ProgressView().scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                }
                .disabled(isFetchingNow)
            }
        }
        .onAppear { loadPeriods() }
    }

    private func loadPeriods() {
        let bills = vehicle.electricityBills.sorted { $0.endDate < $1.endDate }
        let snapshots = vehicle.energySnapshots.sorted { $0.fetchedAt < $1.fetchedAt }
        periods = EVPeriod.build(from: bills, snapshots: snapshots)
    }
}

// MARK: - Period Model

struct EVPeriod: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date?
    let bill: ElectricityBill?
    let distanceKm: Double?
    let snapshotCount: Int
    let lastSnapshotDate: Date?

    var isInProgress: Bool { endDate == nil }

    static func build(from bills: [ElectricityBill], snapshots: [EnergySnapshot]) -> [EVPeriod] {
        var periods: [EVPeriod] = []

        if bills.isEmpty {
            guard !snapshots.isEmpty else { return [] }
            let startOdo = snapshots.first!.odometerKm
            let endOdo = snapshots.last!.odometerKm
            periods.append(EVPeriod(
                startDate: snapshots.first!.fetchedAt,
                endDate: nil,
                bill: nil,
                distanceKm: endOdo > startOdo ? endOdo - startOdo : nil,
                snapshotCount: snapshots.count,
                lastSnapshotDate: snapshots.last?.fetchedAt
            ))
        } else {
            // Completed periods between consecutive bills (first bill is baseline — no tile)
            for i in 1..<bills.count {
                let prev = bills[i - 1]
                let bill = bills[i]
                let periodSnaps = snapshots.filter {
                    $0.fetchedAt >= prev.endDate && $0.fetchedAt <= bill.endDate
                }
                periods.append(EVPeriod(
                    startDate: prev.endDate,
                    endDate: bill.endDate,
                    bill: bill,
                    distanceKm: bill.distanceKm,
                    snapshotCount: periodSnaps.count,
                    lastSnapshotDate: periodSnaps.last?.fetchedAt
                ))
            }

            // In-progress: snapshots after last bill
            let last = bills.last!
            let progressSnaps = snapshots.filter { $0.fetchedAt > last.endDate }
            let startOdo = progressSnaps.first?.odometerKm
            let endOdo = progressSnaps.last?.odometerKm
            let distance: Double? = (startOdo != nil && endOdo != nil && endOdo! > startOdo!)
                ? endOdo! - startOdo! : nil
            periods.append(EVPeriod(
                startDate: last.endDate,
                endDate: nil,
                bill: nil,
                distanceKm: distance,
                snapshotCount: progressSnaps.count,
                lastSnapshotDate: progressSnaps.last?.fetchedAt
            ))
        }

        return periods.reversed()
    }
}

// MARK: - Row: Completed Period

private struct CompletedPeriodRow: View {
    let period: EVPeriod
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateRangeLabel)
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                statBlock(value: formattedDistance, label: unit.abbreviation)
                if let kwh = period.bill?.totalKwh {
                    statBlock(value: String(format: "%.1f", kwh), label: "kWh")
                }
                if let eff = period.bill?.efficiencyKwhPer100km {
                    statBlock(value: String(format: "%.1f", eff), label: "kWh/100km")
                }
                if let costKm = period.bill?.costPerKm, let currency = period.bill?.currencyCode {
                    statBlock(value: String(format: "%.2f", costKm), label: "\(currency)/km")
                }
            }
        }
    }

    @ViewBuilder
    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.subheadline)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var dateRangeLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        let start = fmt.string(from: period.startDate)
        let end = period.endDate.map { fmt.string(from: $0) } ?? "—"
        return "\(start) – \(end)"
    }

    private var unit: DistanceUnit { vehicle.effectiveDistanceUnit }

    private var formattedDistance: String {
        guard let km = period.distanceKm else { return "—" }
        let value = unit == .miles ? km / 1.60934 : km
        return String(format: "%.0f", value)
    }
}

// MARK: - Row: In Progress

struct InProgressPeriodRow: View {
    let period: EVPeriod
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateRangeLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("In Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(formattedDistance)
                        .font(.subheadline)
                        .monospacedDigit()
                    Text(unit.abbreviation + " " + String(localized: "so far"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(period.snapshotCount)")
                        .font(.subheadline)
                        .monospacedDigit()
                    Text("snapshots")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var dateRangeLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return "\(fmt.string(from: period.startDate)) – \(String(localized: "Today"))"
    }

    private var unit: DistanceUnit { vehicle.effectiveDistanceUnit }

    private var formattedDistance: String {
        guard let km = period.distanceKm else { return "—" }
        let value = unit == .miles ? km / 1.60934 : km
        return String(format: "%.0f", value)
    }
}
