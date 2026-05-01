# Research: Cost Category Settings

## Decision 1: Persistence mechanism for category preferences

**Decision**: UserDefaults (via a thin `@Observable` wrapper class), NOT SwiftData.

**Rationale**: Category enabled/disabled state is a small, fixed set of 7 booleans — a classic user-preferences use case. UserDefaults is the iOS-standard mechanism for this. SwiftData is designed for relational app data (entities, relationships, queries). Using a full `@Model` for 7 boolean flags would add schema migration surface area and querying overhead with no benefit. The constitution's "SwiftData or CoreData for local persistence" clause applies to app data; preferences follow the established iOS convention of UserDefaults.

**Alternatives considered**:
- SwiftData `@Model`: Rejected — overkill, adds schema version surface, no relationships needed.
- JSON file on disk: Rejected — more code than UserDefaults for no gain.
- In-memory only (no persistence): Rejected — spec requires persistence across launches (FR-006).

---

## Decision 2: Sharing preference state across views

**Decision**: An `@Observable` class `CategorySettingsStore` injected into the SwiftUI environment via `.environment()` at the app root (`FuelApp`), accessed in views via `@Environment(CategorySettingsStore.self)`.

**Rationale**: iOS 17's `@Observable` + SwiftUI environment (`@Environment(Type.self)`) is the modern replacement for `ObservableObject`/`@EnvironmentObject`. It provides:
- Single source of truth readable from any view in the hierarchy
- Automatic view invalidation when `disabledCategories` changes
- No global singleton — testable, injectable

**Alternatives considered**:
- `@AppStorage` directly in each view: Rejected — duplicates persistence logic, no single source of truth, harder to extend.
- Singleton pattern: Rejected — untestable, global mutable state.
- Pass as parameter through view hierarchy: Rejected — would require threading through FillUpListView → AddFillUpView chain for a concern that doesn't belong there.

---

## Decision 3: Where to apply category filtering

**Decision**: Filter applied in `AddCostView` (the View layer), reading enabled categories from `CategorySettingsStore` via `@Environment`. `AddCostViewModel` remains unaware of settings.

**Rationale**: Category visibility is presentation logic — it determines what appears in the UI picker, not what gets saved to the data store. Existing cost entries are never filtered (only the picker for new entries). Keeping the ViewModel clean of this UI concern follows the constitution's MVVM separation principle.

**Implementation note**: `AddCostView` passes `store.enabledCategories` to its `Picker`. If all categories are disabled, the form shows an inline message instead of the picker.

---

## Decision 4: Storage key and format

**Decision**: Store disabled categories as a `[String]` array in UserDefaults under the key `"disabledCostCategories"`. Stored values are the `CostCategory.rawValue` strings (e.g., `"tolls"`, `"wash"`).

**Rationale**: `CostCategory` raw values are lowercase strings, stable, and `Codable`. Storing disabled (rather than enabled) categories means an empty array = all enabled = correct default on first launch with no migration needed.

**Alternatives considered**:
- Store as comma-separated string: Rejected — requires manual parsing.
- Store as `Data` (JSON-encoded Set): Rejected — more code, `[String]` serialises directly via `UserDefaults.set(_:forKey:)`.
