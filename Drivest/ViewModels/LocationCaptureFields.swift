import Foundation
import CoreLocation
import Observation

/// Form-side mirror of the four `GeoLocatable` fields. Owned by form-fields
/// classes via composition so any future entity (CostEntry, ElectricityBill,
/// ...) can adopt automatic GPS capture by adding a single line.
@MainActor
@Observable
final class LocationCaptureFields {
    var latitude: Double?
    var longitude: Double?
    var locationAccuracy: Double?
    var locationCapturedAt: Date?

    var hasLocation: Bool { latitude != nil && longitude != nil }

    func apply(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        locationAccuracy = location.horizontalAccuracy
        locationCapturedAt = location.timestamp
    }

    func clear() {
        latitude = nil
        longitude = nil
        locationAccuracy = nil
        locationCapturedAt = nil
    }

    /// Copy the captured location onto a model entity at save time.
    /// No-op if no fix has been observed yet.
    func writeTo(_ target: any GeoLocatable) {
        guard hasLocation else { return }
        target.latitude = latitude
        target.longitude = longitude
        target.locationAccuracy = locationAccuracy
        target.locationCapturedAt = locationCapturedAt
    }
}
