import Foundation

/// Shared protocol for any integration that can provide a live odometer reading.
protocol OdometerService: AnyObject {
    var isFetching: Bool { get }
    var fetchError: String? { get }
    func fetchOdometer(vin: String) async -> (km: Int, syncedAt: Date)?
}
