import SwiftUI

/// Shared row for the Detail view of any `GeoLocatable` entity.
/// Renders nothing when the entity has no captured coordinates.
///
/// Used by `FillUpDetailView`. Will be reused by `CostDetailView` once that
/// entity adopts `GeoLocatable`.
struct LocationRow: View {
    let entity: any GeoLocatable

    var body: some View {
        if let lat = entity.latitude, let lon = entity.longitude {
            LabeledContent("Location") {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.5f, %.5f", lat, lon))
                        .font(.callout.monospacedDigit())
                    if let accuracy = entity.locationAccuracy, accuracy > 0 {
                        Text(String(format: "±%.0f m", accuracy))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
