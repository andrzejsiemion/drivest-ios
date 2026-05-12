import Foundation
import CoreLocation
import Observation

/// Entity-agnostic wrapper around `CLLocationManager` for silent, single-form
/// GPS capture. The service starts updates on `start()` (after requesting
/// `When In Use` authorization if not yet determined) and stops them on
/// `stop()`. All failure paths — denied, restricted, unavailable, errors —
/// are silent no-ops: the service simply never publishes a `lastLocation`.
///
/// Callers should:
///   - call `start()` from `.onAppear` of the form view,
///   - read `lastLocation` at save time,
///   - call `stop()` from `.onDisappear`.
@MainActor
@Observable
final class LocationService: NSObject {
    private let manager: CLLocationManager
    private var isRunning = false

    var authorizationStatus: CLAuthorizationStatus
    var lastLocation: CLLocation?
    var isRefreshing: Bool = false

    override init() {
        let m = CLLocationManager()
        self.manager = m
        self.authorizationStatus = m.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 25
    }

    /// Start a silent location capture. Safe to call repeatedly.
    func start() {
        guard !isRunning else { return }
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Updates begin from the delegate once authorization is granted.
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            isRunning = true
        case .denied, .restricted:
            return
        @unknown default:
            return
        }
    }

    /// Stop the capture and release the manager's hold on GPS. Safe to call
    /// when not running.
    func stop() {
        guard isRunning else { return }
        manager.stopUpdatingLocation()
        isRunning = false
    }

    /// User-triggered refresh: temporarily bumps accuracy to best and waits
    /// for the next fix to land. Silent no-op when permission is denied or
    /// updates aren't running. The next `didUpdateLocations` resets accuracy
    /// back to the balanced default and clears `isRefreshing`.
    func refresh() {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        default:
            return
        }
        guard !isRefreshing else { return }
        isRefreshing = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        if isRunning {
            manager.requestLocation()
        } else {
            manager.startUpdatingLocation()
            isRunning = true
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if !self.isRunning {
                    self.manager.startUpdatingLocation()
                    self.isRunning = true
                }
            case .denied, .restricted, .notDetermined:
                self.stop()
            @unknown default:
                self.stop()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Keep the most recent fix with a usable horizontal accuracy.
        let best = locations
            .filter { $0.horizontalAccuracy >= 0 }
            .max(by: { $0.timestamp < $1.timestamp })
        guard let best else { return }
        Task { @MainActor in
            self.lastLocation = best
            if self.isRefreshing {
                self.isRefreshing = false
                self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent — spec FR-004 requires no error UI in the capture flow.
        // Clear the refresh-in-flight flag so the UI doesn't spin forever.
        Task { @MainActor in
            if self.isRefreshing {
                self.isRefreshing = false
                self.manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            }
        }
    }
}
