# Research: Rename Bottom Tab Labels

**Feature**: Rename bottom tab bar labels ("History"→"Fuel", "Vehicles"→"Costs", "Summary"→"Statistics")
**Date**: 2026-04-20

## Decision 1: Scope of Renaming

- **Decision**: Rename both tab labels AND matching navigation titles inside each tab
- **Rationale**: If the tab reads "Fuel" but tapping it opens a screen titled "History", the inconsistency is confusing and looks like a bug. Navigation titles should mirror tab names for a coherent experience.
- **Affected navigation titles**:
  - `FillUpListView.swift` line 78: `.navigationTitle("History")` → `.navigationTitle("Fuel")`
  - `ContentView.swift` line 45: `.navigationTitle("Summary")` → `.navigationTitle("Statistics")`
  - `SummaryView.swift` line 100: `.navigationTitle("Summary")` → `.navigationTitle("Statistics")`
- **Alternatives considered**:
  - Change tab labels only — rejected; creates label mismatch between tab and screen title
  - Change navigation titles only — rejected; does not address the user request

## Decision 2: "Vehicles" tab → "Costs"

- **Decision**: Rename the "Vehicles" tab label to "Costs". The navigation title inside VehicleListView (`"Vehicles"` at line 42) is also updated to "Costs" for consistency.
- **Rationale**: Same reasoning as Decision 1 — tab and screen title must match.
- **Note**: Internal Swift type names (`VehicleListView`, `VehicleViewModel`, etc.) are NOT renamed — this is a display string change only.

## Decision 3: Costs Tab Icon

- **Decision**: Replace `car.2` with `wrench.and.screwdriver` for the Costs tab
- **Rationale**: The "Costs" label encompasses vehicle running costs broadly (fuel, maintenance, etc.), not just the vehicle itself. A tools/wrench icon better represents cost/maintenance context than a car silhouette. Matches the user's reference design.
- **Alternatives considered**:
  - Keep `car.2` — rejected; car icon implies "Vehicles" (the old label), not costs
  - `dollarsign.circle` — rejected; too generic/financial, doesn't fit the maintenance/vehicle context
  - `wrench` (single) — rejected; `wrench.and.screwdriver` is a closer match to the reference image

## Decision 4: String Literals vs Localisation

- **Decision**: Update raw string literals directly (no localisation file changes)
- **Rationale**: The project has no evidence of a `Localizable.strings` or `String Catalog` file. Strings are hardcoded throughout. Introducing localisation is out of scope for this feature.
- **Alternatives considered**:
  - Add `Localizable.strings` — rejected; out of scope, would introduce significant scope creep

## Summary of All Files to Modify

| File | Change |
|------|--------|
| `Fuel/Views/ContentView.swift` | Tab labels: "History"→"Fuel", "Vehicles"→"Costs", "Summary"→"Statistics"; Costs icon: `car.2`→`wrench.and.screwdriver`; navigation title "Summary"→"Statistics" |
| `Fuel/Views/FillUpListView.swift` | Navigation title: "History"→"Fuel" |
| `Fuel/Views/VehicleListView.swift` | Navigation title: "Vehicles"→"Costs" |
| `Fuel/Views/SummaryView.swift` | Navigation title: "Summary"→"Statistics" |
| `Fuel/Views/FillUpListView.swift` | Empty state message referencing "Vehicles tab" — leave unchanged (refers to tab content, not label) |
