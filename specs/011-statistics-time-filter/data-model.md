# Data Model: Statistics Time Filter

**Feature**: 011-statistics-time-filter
**Date**: 2026-04-21

## Entities

### StatisticsTimePeriod (Enum, not persisted)

Represents the user's selected time filter for the Statistics tab.

| Case | Description |
|------|-------------|
| `week` | Last 7 days from today |
| `month` | Last calendar month from today |
| `year` | Last calendar year from today |
| `allTime` | No date restriction (default) |
| `custom(start: Date, end: Date)` | User-defined date range |

**Behavior**:
- `dateRange` computed property returns `(start: Date?, end: Date?)` tuple
  - `allTime` returns `(nil, nil)` — no filtering
  - Preset periods compute start date relative to current date; end is `nil` (up to now)
  - `custom` returns the user-provided start/end dates

**Relationships**: None — this is view-layer state, not a SwiftData model.

**Validation**:
- For `custom`: start date must be ≤ end date. If violated, dates are swapped automatically.

## Existing Entities (Modified)

### SummaryViewModel

**Modified method**: `loadSummary(for:)` → `loadSummary(for:period:)`

New parameter `period: StatisticsTimePeriod` adds date bounds to the existing `#Predicate` when fetching fill-ups. The predicate gains optional `startDate` and `endDate` comparisons in addition to the existing `vehicleId` filter.

No changes to:
- `Vehicle` model
- `FillUp` model
- `MonthlySummary` struct
- Any other ViewModel or Model

## State Flow

```
SummaryTabView (@State selectedPeriod: StatisticsTimePeriod = .allTime)
    │
    ├── onChange(of: selectedPeriod) → viewModel.loadSummary(for: vehicle, period: selectedPeriod)
    ├── onChange(of: store.selectedVehicle) → viewModel.loadSummary(for: vehicle, period: selectedPeriod)
    │
    └── SummaryViewModel.loadSummary(for:period:)
         └── FetchDescriptor<FillUp> with vehicleId + date range predicate
```
