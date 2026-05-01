import Foundation

/// Shared state that survives the onOpenURL → view render gap.
/// FuelApp sets pendingURL; ContentView observes and clears it.
@Observable final class ImportCoordinator {
    var pendingURL: URL? = nil
}
