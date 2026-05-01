import Foundation

enum BillReconciliationService {

    struct ReconciliationResult {
        let distanceKm: Double?
        let efficiencyKwhPer100km: Double?
        let costPerKm: Double?
        let hasSnapshotData: Bool
        let startSnapshotId: UUID?
        let endSnapshotId: UUID?
    }

    static func reconcile(
        bill: ElectricityBill,
        snapshots: [EnergySnapshot],
        previousBill: ElectricityBill?
    ) -> ReconciliationResult {
        guard let previousBill else {
            return ReconciliationResult(
                distanceKm: nil, efficiencyKwhPer100km: nil, costPerKm: nil,
                hasSnapshotData: false, startSnapshotId: nil, endSnapshotId: nil
            )
        }

        let periodStart = previousBill.endDate
        let periodEnd   = bill.endDate
        let sevenDays: TimeInterval = 7 * 24 * 3600

        let startSnapshot = closestSnapshot(in: snapshots, to: periodStart)
        let endSnapshot   = closestSnapshot(in: snapshots, to: periodEnd)

        guard let start = startSnapshot, let end = endSnapshot else {
            return ReconciliationResult(
                distanceKm: nil, efficiencyKwhPer100km: nil, costPerKm: nil,
                hasSnapshotData: false, startSnapshotId: nil, endSnapshotId: nil
            )
        }

        guard abs(start.fetchedAt.timeIntervalSince(periodStart)) <= sevenDays,
              abs(end.fetchedAt.timeIntervalSince(periodEnd)) <= sevenDays else {
            return ReconciliationResult(
                distanceKm: nil, efficiencyKwhPer100km: nil, costPerKm: nil,
                hasSnapshotData: false, startSnapshotId: start.id, endSnapshotId: end.id
            )
        }

        let distanceKm = end.odometerKm - start.odometerKm
        guard distanceKm > 0 else {
            return ReconciliationResult(
                distanceKm: nil, efficiencyKwhPer100km: nil, costPerKm: nil,
                hasSnapshotData: false, startSnapshotId: start.id, endSnapshotId: end.id
            )
        }

        let efficiencyKwhPer100km = (bill.totalKwh / distanceKm) * 100
        let costPerKm = bill.totalCost / distanceKm

        return ReconciliationResult(
            distanceKm: distanceKm,
            efficiencyKwhPer100km: efficiencyKwhPer100km,
            costPerKm: costPerKm,
            hasSnapshotData: true,
            startSnapshotId: start.id,
            endSnapshotId: end.id
        )
    }

    private static func closestSnapshot(in snapshots: [EnergySnapshot], to date: Date) -> EnergySnapshot? {
        snapshots.min(by: {
            abs($0.fetchedAt.timeIntervalSince(date)) < abs($1.fetchedAt.timeIntervalSince(date))
        })
    }
}
