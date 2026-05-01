# Research: Vehicle Selector & Sort Order

## Shared App State in SwiftUI + SwiftData

**Decision**: Use an `@Observable` class (`VehicleSelectionStore`) injected at app root via `.environment(VehicleSelectionStore.self)` and accessed in views via `@Environment(VehicleSelectionStore.self)`.

**Rationale**: The selected vehicle and sort preference must survive tab switches without being re-initialized. SwiftData's `@Query` is per-view and cannot be shared. A root-injected `@Observable` object lives for the app lifecycle and is the iOS 17+ idiomatic solution for shared mutable state.

**Alternatives considered**:
- `@AppStorage` / `UserDefaults` directly in views: Not suitable for `Vehicle` objects (not `Codable` without custom logic).
- Singleton (static): Violates testability and SwiftUI environment patterns.
- `@EnvironmentObject` (older API): Works but `@Observable` + `@Environment` is the modern iOS 17+ replacement.

---

## Vehicle Sort Order Persistence

**Decision**: Store the sort preference as a raw `String` in `UserDefaults` (via `@AppStorage` in `VehicleSelectionStore`). Store custom order as a JSON-encoded `[UUID]` array in `UserDefaults`.

**Rationale**: Sort preference is a lightweight user preference, not relational data. SwiftData would be overkill. `UserDefaults` is appropriate, instant, and survives app restarts.

**Alternatives considered**:
- SwiftData `Settings` model: Over-engineered for a single enum value.
- iCloud `NSUbiquitousKeyValueStore`: Cloud sync is out of scope (constitution: offline-first).

---

## Odometer Display on Vehicle Card

**Decision**: Compute current odometer from the vehicle's fill-ups: take the maximum `odometerReading` among all `FillUp` records. Fall back to `vehicle.initialOdometer` if no fill-ups exist.

**Rationale**: `Vehicle` has no dedicated `currentOdometer` property. The highest odometer reading from fill-ups is always the most recent. `initialOdometer` serves as the baseline.

**Alternatives considered**:
- Adding a `currentOdometer` property to the `Vehicle` model: Schema change required; computed property is simpler and does not require migration.
- Tracking odometer separately: Unnecessary complexity.

---

## Vehicle Selector Card Placement

**Decision**: Place `VehiclePickerCard` as a custom header above the `List` content area using a `VStack` wrapping the entire `NavigationStack` body, or as the first `Section` inside the `List` (without title). The card spans full width, is tappable (when multiple vehicles exist), shows a sheet picker on tap.

**Rationale**: Placing it inside a `List Section` is the simplest integration — it blends with existing iOS list styling and requires no layout restructuring. Removing the current toolbar `Picker` cleans up the navigation bar.

**Alternatives considered**:
- `.safeAreaInset(edge: .top)`: Overlays content; would require padding adjustments on the list.
- Navigation bar `principal` item: Too constrained in size for a rich card.

---

## Custom Vehicle Reorder UX

**Decision**: When "Custom" sort is selected in Settings, the Vehicle Order row in SettingsView shows an "Edit Order" button that navigates to a dedicated `VehicleReorderView` with drag-to-reorder list (`.onMove` modifier).

**Rationale**: The `SettingsView` already uses a `List` with category management. Adding a similar reorder screen for vehicles is consistent with established patterns. The `.onMove` modifier is SwiftUI-native, requires no third-party dependencies.

**Alternatives considered**:
- Inline reordering within the vehicle picker sheet: Mixing data display with settings is confusing.
- Long-press + drag within the main tab: Too complex and undiscoverable.

---

## Selected Vehicle Persistence Across Restarts

**Decision**: Store the last selected vehicle's `UUID` in `UserDefaults`. On app launch, `VehicleSelectionStore` restores the selection by matching the stored ID against the loaded vehicle list.

**Rationale**: Simple and reliable. UUID is `Codable`-compatible with `UserDefaults` via `String(uuid)`.

**Alternatives considered**:
- Re-select `vehicles.first` on every launch: Breaks user expectation if they always use vehicle B but B is not first.
