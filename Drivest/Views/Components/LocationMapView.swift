import SwiftUI
import MapKit

/// Read-only map showing a single pin at the entity's captured coordinate.
/// Generic over `GeoLocatable` so any future entity with GPS (CostEntry, ...)
/// reuses the same view by passing itself through.
struct LocationMapView: View {
    let entity: any GeoLocatable

    @State private var cameraPosition: MapCameraPosition

    init(entity: any GeoLocatable) {
        self.entity = entity
        if let coord = entity.coordinate {
            _cameraPosition = State(initialValue: .region(
                MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            ))
        } else {
            _cameraPosition = State(initialValue: .automatic)
        }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if let coord = entity.coordinate {
                Marker("", coordinate: coord)
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}
