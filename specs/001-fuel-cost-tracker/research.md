# Research: Fuel Cost Tracker

**Date**: 2026-04-19
**Branch**: `001-fuel-cost-tracker`

## Technology Decisions

### Storage: SwiftData

- **Decision**: Use SwiftData (iOS 17+) for local persistence
- **Rationale**: Native Apple framework, zero dependencies, seamless
  SwiftUI integration via `@Query` and `@Model` macros, automatic
  migration support, built on Core Data's proven storage engine.
- **Alternatives considered**:
  - Core Data: More verbose, requires manual context management.
    SwiftData is the modern replacement with identical storage backend.
  - SQLite (via GRDB or similar): Would add a third-party dependency,
    violating Principle IV. No benefit over SwiftData for this use case.
  - UserDefaults / JSON files: Not suitable for relational data with
    queries (filtering by vehicle, date ranges, aggregations).

### UI: SwiftUI

- **Decision**: Pure SwiftUI with no UIKit bridging
- **Rationale**: iOS 17 SwiftUI covers all needed UI patterns: lists,
  forms, sheets, navigation stacks, floating buttons (via overlay),
  charts. Constitution mandates SwiftUI-first.
- **Alternatives considered**:
  - UIKit: More boilerplate, not constitution-compliant unless SwiftUI
    is insufficient. No gaps identified for this feature set.

### Charts: Swift Charts

- **Decision**: Use Apple's Charts framework for expense visualizations
- **Rationale**: Native, zero-dependency bar/line charts for monthly
  spending and efficiency trends. Available iOS 16+.
- **Alternatives considered**:
  - Third-party charting (DGCharts): Adds dependency, violates
    Principle IV, no functional advantage for simple bar charts.

### Architecture: MVVM

- **Decision**: MVVM with `@Observable` ViewModels (iOS 17 Observation)
- **Rationale**: Constitution mandates MVVM. The `@Observable` macro
  eliminates `ObservableObject`/`@Published` boilerplate. ViewModels
  own business logic; Views are purely declarative.
- **Alternatives considered**:
  - TCA (The Composable Architecture): Heavy third-party dependency,
    steep learning curve, overkill for a small utility app.
  - MV (Model-View with no ViewModel): Insufficient separation for
    testability of efficiency calculation logic.

## Efficiency Calculation Algorithm

### Full-Tank-to-Full-Tank Method

The standard approach for accurate fuel consumption measurement:

1. User fills tank to full → records odometer (O₁)
2. User drives, may do 0..N partial fills (recording liters each time)
3. User fills tank to full again → records odometer (O₂)

**Formula**:
```
Total fuel = sum of all fills (including final full fill) since last full fill
Distance = O₂ - O₁
Efficiency = (Total fuel / Distance) × 100  → L/100km
```

**Edge cases**:
- First ever fill-up: no previous reference → efficiency = nil
- Only partial fills, no second full: efficiency not calculable yet
- Deleted intermediate fill-up: must recalculate from remaining data

### Implementation approach

- Store `isFullTank` boolean on each FillUp record
- On save of a full-tank entry, query backwards for all fills since
  the previous full-tank entry for the same vehicle
- Sum their volumes + current volume; compute distance from odometers
- Store computed efficiency on the current FillUp record

## Auto-Calculation (Two-of-Three Fields)

Three interrelated fields: pricePerLiter (P), volume (V), totalCost (T)
Relationship: T = P × V

**UX approach**: Track which two fields the user edited most recently.
The third is computed automatically. Use field focus tracking:
- When user edits P and V → compute T
- When user edits P and T → compute V
- When user edits V and T → compute P

If all three are filled and user edits one, recompute based on the
last two touched fields.

## SwiftData Considerations

- `@Model` classes with `@Relationship` for Vehicle → FillUp (cascade
  delete)
- Use `@Query` with `SortDescriptor` and `#Predicate` for filtered
  lists
- ModelContainer configured in App entry point with automatic schema
  migration
- No need for manual migration for v1 (first schema version)
