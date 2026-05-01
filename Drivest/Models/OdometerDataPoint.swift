import Foundation

struct OdometerDataPoint: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let odometer: Double
}
