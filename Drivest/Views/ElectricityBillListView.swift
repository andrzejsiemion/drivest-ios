import SwiftUI

struct ElectricityBillListView: View {
    let vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BillListViewModel()
    @State private var showAddBill = false

    var body: some View {
        Group {
            if viewModel.bills.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Bills Yet",
                    systemImage: "doc.text",
                    description: Text("Add your first electricity bill to start tracking efficiency.")
                )
            } else {
                List {
                    ForEach(viewModel.bills, id: \.persistentModelID) { bill in
                        NavigationLink {
                            ElectricityBillDetailView(bill: bill)
                        } label: {
                            BillRowView(bill: bill)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteBill(viewModel.bills[index], context: modelContext)
                        }
                    }
                }
            }
        }
        .navigationTitle("Electricity Bills")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddBill = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            viewModel.load(for: vehicle, context: modelContext)
        }
        .sheet(isPresented: $showAddBill) {
            AddElectricityBillView(vehicle: vehicle)
                .onDisappear {
                    viewModel.load(for: vehicle, context: modelContext)
                }
        }
    }
}

private struct BillRowView: View {
    let bill: ElectricityBill

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.endDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kWh", bill.totalKwh))
                    .font(.subheadline)
                    .monospacedDigit()
                if let efficiency = bill.efficiencyKwhPer100km {
                    Text(String(format: "%.2f kWh/100km", efficiency))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusLabel: String {
        if bill.hasSnapshotData { return NSLocalizedString("Calculated", comment: "") }
        let hasPreviousBill = (bill.vehicle?.electricityBills.count ?? 0) > 1
        return hasPreviousBill
            ? NSLocalizedString("No snapshot data", comment: "")
            : NSLocalizedString("Baseline", comment: "")
    }

    private var statusColor: Color {
        bill.hasSnapshotData ? .green : .secondary
    }
}
