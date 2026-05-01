# Research: Vehicle Cost Categories

**Feature**: Non-fuel cost tracking on the Costs tab
**Date**: 2026-04-20

## Decision 1: Data Persistence — SwiftData

- **Decision**: Use SwiftData (`@Model`) for `CostEntry`, consistent with `FillUp` and `Vehicle`
- **Rationale**: The app already uses SwiftData exclusively. Adding a new `@Model` class is automatic lightweight migration in iOS 17+ — no migration plan file required for adding new models. The model container simply includes `CostEntry.self` alongside existing models.
- **Alternatives considered**:
  - UserDefaults — rejected; unsuitable for relational data
  - Custom file storage — rejected; violates principle IV (prefer Apple frameworks)

## Decision 2: CostCategory as Enum

- **Decision**: `CostCategory` is a Swift `enum` conforming to `String`, `Codable`, `CaseIterable`, and `Identifiable`
- **Rationale**: Fixed set of 7 predefined values. Enum ensures type safety and exhaustive handling. Follows the same pattern as `FuelType` in the existing codebase.
- **Categories**: Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets
- **Alternatives considered**:
  - Store as free-text String — rejected; allows inconsistent values, makes grouping/filtering unreliable
  - Separate `CostCategory` SwiftData model — rejected; overcomplicated for a fixed list; user-defined categories are out of scope

## Decision 3: Vehicle Relationship

- **Decision**: Add `@Relationship(deleteRule: .cascade, inverse: \CostEntry.vehicle) var costEntries: [CostEntry]` to `Vehicle`
- **Rationale**: Mirrors the existing `fillUps` relationship pattern exactly. Cascade delete ensures orphaned entries are cleaned up when a vehicle is removed.
- **Alternatives considered**:
  - No inverse relationship — rejected; SwiftData requires inverse relationships for proper graph management

## Decision 4: Costs Tab Content — Replace VehicleListView

- **Decision**: Replace `VehicleListView` in the Costs tab with a new `CostListView`. `VehicleListView` remains in the codebase but is no longer tab-mounted.
- **Rationale**: Spec explicitly says the Costs tab should show non-fuel cost entries. Vehicle management access is outside this feature's scope.
- **Note**: Vehicle management is still accessible via `VehicleListView` — it is not deleted, just unmounted from the tab. A future feature can re-expose it (e.g., from the Fuel tab toolbar or Settings).
- **Alternatives considered**:
  - Keep VehicleListView in Costs tab and add costs as a section — rejected; spec says no fuel info on Costs tab, and mixing vehicle management with cost tracking creates a confusing UX

## Decision 5: ViewModel Architecture

- **Decision**: Two ViewModels — `CostListViewModel` (list + delete) and `AddCostViewModel` (form + save)
- **Rationale**: Mirrors the existing `FillUpListViewModel` / `AddFillUpViewModel` split. Single responsibility per VM. `@Observable` pattern throughout.
- **Alternatives considered**:
  - One combined ViewModel — rejected; violates Single Responsibility, makes the list view heavier

## Decision 6: SwiftData Migration

- **Decision**: No migration plan file required — automatic lightweight migration
- **Rationale**: iOS 17 SwiftData handles adding new `@Model` types and new relationships to existing models automatically. The `modelContainer(for:)` call simply includes `CostEntry.self`.
- **Alternatives considered**:
  - Explicit `SchemaMigrationPlan` — rejected; unnecessary for additive-only schema changes

## Summary of Files

| File | Status | Purpose |
|------|--------|---------|
| `Fuel/Models/CostCategory.swift` | NEW | Enum: Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets |
| `Fuel/Models/CostEntry.swift` | NEW | SwiftData model: id, date, category, amount, note?, vehicle? |
| `Fuel/ViewModels/CostListViewModel.swift` | NEW | Fetch and delete cost entries per vehicle |
| `Fuel/ViewModels/AddCostViewModel.swift` | NEW | Form state and save logic for new cost entry |
| `Fuel/Views/CostListView.swift` | NEW | Costs tab list + empty state + delete |
| `Fuel/Views/AddCostView.swift` | NEW | Add cost entry form sheet |
| `Fuel/Models/Vehicle.swift` | MODIFIED | Add `costEntries` relationship |
| `Fuel/FuelApp.swift` | MODIFIED | Add `CostEntry.self` to model container |
| `Fuel/Views/ContentView.swift` | MODIFIED | Replace `VehicleListView` with `CostListView` in Costs tab |
