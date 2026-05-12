import Foundation
import CoreLocation

/// Contract for any model that can carry a captured GPS location.
///
/// Adopters store the four optional fields directly (SwiftData `@Model` keeps
/// them flat on the entity). The protocol extension provides the shared
/// helpers, so adopting types add no implementation themselves.
protocol GeoLocatable: AnyObject {
    var latitude: Double? { get set }
    var longitude: Double? { get set }
    var locationAccuracy: Double? { get set }
    var locationCapturedAt: Date? { get set }
}

extension GeoLocatable {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var hasLocation: Bool { latitude != nil && longitude != nil }

    func applyLocation(_ location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        locationAccuracy = location.horizontalAccuracy
        locationCapturedAt = location.timestamp
    }

    func clearLocation() {
        latitude = nil
        longitude = nil
        locationAccuracy = nil
        locationCapturedAt = nil
    }
}
