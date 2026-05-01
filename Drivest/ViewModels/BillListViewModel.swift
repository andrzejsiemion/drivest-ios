import Foundation
import Observation
import SwiftData

@Observable
final class BillListViewModel {
    var bills: [ElectricityBill] = []
    var isLoading = false

    func load(for vehicle: Vehicle, context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let vehicleID = vehicle.persistentModelID
        let descriptor = FetchDescriptor<ElectricityBill>(
            sortBy: [SortDescriptor(\.endDate, order: .reverse)]
        )
        guard let all = try? context.fetch(descriptor) else { return }
        bills = all.filter { $0.vehicle?.persistentModelID == vehicleID }
    }

    func deleteBill(_ bill: ElectricityBill, context: ModelContext) {
        context.delete(bill)
        try? context.save()
        bills.removeAll { $0.persistentModelID == bill.persistentModelID }
    }
}
