import SwiftUI
import MapKit

/// Modal map sheet for manually adjusting the captured fill-up location.
/// Standard iOS "drop a pin" pattern: a fixed pin sits at the screen centre
/// and the user pans the map underneath. Tapping "Use This Location" returns
/// the map's current centre coordinate via `onPick`.
struct LocationPickerSheet: View {
    let initialCoordinate: CLLocationCoordinate2D
    let onPick: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var currentCenter: CLLocationCoordinate2D

    init(initialCoordinate: CLLocationCoordinate2D,
         onPick: @escaping (CLLocationCoordinate2D) -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onPick = onPick
        let region = MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
        )
        _cameraPosition = State(initialValue: .region(region))
        _currentCenter = State(initialValue: initialCoordinate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition)
                    .onMapCameraChange(frequency: .continuous) { ctx in
                        currentCenter = ctx.camera.centerCoordinate
                    }
                    .ignoresSafeArea(edges: .bottom)

                // Fixed pin overlay at screen centre.
                VStack(spacing: 0) {
                    Image(systemName: "mappin")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.red)
                        .shadow(radius: 2)
                    // A small offset so the pin's "tip" sits on the centre rather
                    // than the centre dot landing on the pin's middle.
                    Spacer().frame(height: 36)
                }
                .allowsHitTesting(false)

                // Coordinate read-out at the top.
                VStack {
                    Text(String(format: "%.5f, %.5f", currentCenter.latitude, currentCenter.longitude))
                        .font(.footnote.monospacedDigit())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.top, 8)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .navigationTitle("Adjust Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use This Location") {
                        onPick(currentCenter)
                        dismiss()
                    }
                }
            }
        }
    }
}
