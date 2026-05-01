# UI Contract: Cost Category Settings

## ··· Ellipsis Menu (all 3 tabs)

All three tabs (Fuel, Costs, Statistics) expose an ellipsis menu via `Image(systemName: "ellipsis.circle")` in `.topBarTrailing`. This menu MUST contain:

```
Menu items (in order):
  1. "Settings"        systemImage: "gearshape"
  2. "Manage Vehicles" systemImage: "car.2"
```

Tapping "Settings" → presents `SettingsView` as a sheet.
Tapping "Manage Vehicles" → presents `VehicleListView` as a sheet (existing behaviour, unchanged).

---

## SettingsView

**Presentation**: Sheet (`.sheet(isPresented:)`)
**Navigation**: `NavigationStack` with title "Settings"
**Toolbar**: `ToolbarItem(.confirmationAction)` — "Done" button dismisses the sheet

### Content

```
Form {
    Section("Cost Categories") {
        ForEach(CostCategory.allCases) { category in
            Toggle(isOn: binding_for_category) {
                Label(category.displayName, systemImage: category.systemImageName)
            }
        }
    }
}
```

- Categories listed in `CostCategory.allCases` order (Insurance → Service → Tolls → Wash → Parking → Maintenance → Tickets)
- Each row: SF Symbol icon + display name on the left, toggle on the right
- Toggle state: ON = enabled (appears in Add Cost picker), OFF = disabled (hidden from picker)
- Toggle changes take effect immediately — no Save button needed

---

## AddCostView — Category Picker (modified)

The Category `Picker` inside `AddCostView` MUST source its options from `store.enabledCategories` (read from `@Environment(CategorySettingsStore.self)`) rather than `CostCategory.allCases`.

**All categories enabled** (normal case):
```
Picker shows: Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets
```

**Some categories disabled**:
```
Picker shows: only enabled categories (same order, gaps removed)
```

**All categories disabled** (edge case):
```
Section("Category") replaces Picker with:
  Text("No categories available.")
      .foregroundStyle(.secondary)
  Text("Enable categories in Settings (···).")
      .font(.caption)
      .foregroundStyle(.secondary)
Save button remains disabled (isValid = false when no category selectable)
```

---

## State Invariants

- `CategorySettingsStore` is the single source of truth — all views reading it reflect the same state
- Disabling a category never modifies or hides existing `CostEntry` records in `CostListView`
- Default on first launch: all 7 categories enabled (`disabledCategories` = empty)
