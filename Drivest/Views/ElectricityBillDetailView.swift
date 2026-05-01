import SwiftUI

struct ElectricityBillDetailView: View {
    let bill: ElectricityBill

    private var distanceUnit: DistanceUnit {
        bill.vehicle?.effectiveDistanceUnit ?? .kilometers
    }

    private var currencySymbol: String {
        CurrencyDefinition.symbol(for: bill.currencyCode ?? "") ?? bill.currencyCode ?? ""
    }

    var body: some View {
        Form {
            Section("Billing Period") {
                LabeledContent("End Date", value: bill.endDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Total kWh (Meter)", value: String(format: "%.2f kWh", bill.totalKwh))
                LabeledContent("Total Cost", value: String(format: "%@ %.2f", currencySymbol, bill.totalCost))
            }

            if bill.hasSnapshotData {
                Section("Calculated Efficiency") {
                    if let distance = bill.distanceKm {
                        let displayDistance = distanceUnit == .miles ? distance / 1.60934 : distance
                        LabeledContent("Distance", value: String(format: "%.0f %@", displayDistance, distanceUnit.abbreviation))
                    }
                    if let efficiency = bill.efficiencyKwhPer100km {
                        LabeledContent("Efficiency", value: String(format: "%.2f kWh/100km", efficiency))
                    }
                    if let costPerKm = bill.costPerKm {
                        LabeledContent("Cost per km", value: String(format: "%@ %.4f", currencySymbol, costPerKm))
                    }
                }
            } else {
                Section {
                    if bill.distanceKm == nil && bill.efficiencyKwhPer100km == nil {
                        let previousBillExists = (bill.vehicle?.electricityBills.count ?? 0) > 1
                        if previousBillExists {
                            Label("No snapshot data available for this period", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        } else {
                            Label("This is your baseline bill — efficiency will be calculated from your next bill", systemImage: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bill Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
