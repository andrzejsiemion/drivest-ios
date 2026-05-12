import SwiftUI

/// Adopter's one-liner: drop this where a detail view would otherwise render
/// `LocationRow(entity:)`. When the entity has coordinates, the row becomes a
/// tappable `NavigationLink` to `LocationMapView`. Otherwise nothing renders —
/// no row, no tap target — same as `LocationRow` alone.
struct LocationDetailLink: View {
    let entity: any GeoLocatable

    var body: some View {
        if entity.hasLocation {
            NavigationLink {
                LocationMapView(entity: entity)
            } label: {
                LocationRow(entity: entity)
            }
        }
    }
}
