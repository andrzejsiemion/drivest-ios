import SwiftUI
import CoreLocation

/// Three-state row used in form contexts to show GPS capture progress.
/// Hidden when permission is denied/restricted (silent-failure UX from 033).
/// Reusable for any view holding a `LocationService` — pass its published
/// `authorizationStatus`, `lastLocation`, `isRefreshing`, and a closure to
/// trigger a manual refresh (mirrors the Volvo/Toyota odometer pattern).
struct LocationCaptureStatusRow: View {
    let authorizationStatus: CLAuthorizationStatus
    let lastLocation: CLLocation?
    var isRefreshing: Bool = false
    var onRefresh: (() -> Void)? = nil
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        switch authorizationStatus {
        case .denied, .restricted:
            EmptyView()
        default:
            if let loc = lastLocation {
                capturedRow(loc)
            } else {
                acquiringRow
            }
        }
    }

    private var acquiringRow: some View {
        HStack(spacing: 8) {
            Text("Location").foregroundStyle(.secondary)
            Spacer()
            ProgressView().scaleEffect(0.75)
            Text("Acquiring location…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func capturedRow(_ loc: CLLocation) -> some View {
        HStack(spacing: 6) {
            Text("Location").foregroundStyle(.secondary)
            Spacer()
            Text(String(format: "%.4f, %.4f", loc.coordinate.latitude, loc.coordinate.longitude))
                .font(.callout.monospacedDigit())
            if loc.horizontalAccuracy > 0 {
                Text(String(format: "±%.0f m", loc.horizontalAccuracy))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let onRefresh {
                Button {
                    onRefresh()
                } label: {
                    if isRefreshing {
                        ProgressView().scaleEffect(0.75)
                    } else {
                        Image(systemName: "mappin.circle.fill")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .disabled(isRefreshing)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.3) { onLongPress?() }
    }
}
