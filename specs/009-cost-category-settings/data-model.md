# Data Model: Cost Category Settings

## Existing Entities (unchanged)

- **CostCategory** (`Fuel/Models/CostCategory.swift`): Enum with 7 cases. No changes required.
- **CostEntry** (`Fuel/Models/CostEntry.swift`): SwiftData `@Model`. No changes required. Existing entries with disabled categories are never filtered from the list view.

---

## New: CategorySettingsStore

**File**: `Fuel/Models/CategorySettingsStore.swift`
**Type**: `@Observable` final class (not a SwiftData model)
**Persistence**: UserDefaults

### Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `disabledCategories` | `Set<String>` | `[]` | Raw values of disabled `CostCategory` cases. Empty = all enabled. |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `enabledCategories` | `[CostCategory]` | `CostCategory.allCases` filtered to exclude disabled entries, preserving declaration order. |
| `isEnabled(_ category:)` | `Bool` | Returns whether a given category is currently enabled. |

### Methods

| Method | Description |
|--------|-------------|
| `toggle(_ category: CostCategory)` | Enables a disabled category or disables an enabled one. Immediately persists to UserDefaults. |

### Persistence

- UserDefaults key: `"disabledCostCategories"`
- Stored as: `[String]` array of `CostCategory.rawValue` strings
- On init: reads from UserDefaults; empty array (first launch) = all categories enabled

### Relationships

- **Read by**: `AddCostView` (via `@Environment`) to populate the category picker
- **Read/written by**: `SettingsView` (via `@Environment`) to display toggles
- **Injected at**: `FuelApp` body via `.environment(CategorySettingsStore())`
- **No relationship** to SwiftData schema — purely a preferences store

---

## No Schema Migration Required

`CategorySettingsStore` uses UserDefaults exclusively and has no `@Model` definition. SwiftData schema is unchanged — no migration plan needed.
