import Foundation
import Observation
import SwiftData

@Observable
final class AddBillViewModel {
    var startDate: Date
    var endDate: Date = Date()

    init(startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()) {
        self.startDate = startDate
    }
    var totalKwhText: String = ""
    var totalCostText: String = ""
    var isSaving = false

    var isValid: Bool {
        guard let kwh = totalKwhText.parseDouble(), kwh > 0 else { return false }
        guard let cost = totalCostText.parseDouble(), cost >= 0 else { return false }
        return true
    }

    func save(for vehicle: Vehicle, currencyCode: String?, context: ModelContext) -> Bool {
        guard let kwh  = totalKwhText.parseDouble(),
              let cost = totalCostText.parseDouble()
        else { return false }

        isSaving = true
        defer { isSaving = false }

        let bill = ElectricityBill(
            startDate: startDate,
            endDate: endDate,
            totalKwh: kwh,
            totalCost: cost,
            currencyCode: currencyCode,
            vehicle: vehicle
        )

        let allBills = vehicle.electricityBills.sorted { $0.endDate < $1.endDate }
        let previousBill = allBills.last(where: { $0.endDate < endDate })
        let snapshots = vehicle.energySnapshots

        let result = BillReconciliationService.reconcile(
            bill: bill,
            snapshots: snapshots,
            previousBill: previousBill
        )
        bill.distanceKm              = result.distanceKm
        bill.efficiencyKwhPer100km   = result.efficiencyKwhPer100km
        bill.costPerKm               = result.costPerKm
        bill.hasSnapshotData         = result.hasSnapshotData
        bill.startSnapshotId         = result.startSnapshotId
        bill.endSnapshotId           = result.endSnapshotId

        context.insert(bill)
        try? context.save()
        return true
    }
}
