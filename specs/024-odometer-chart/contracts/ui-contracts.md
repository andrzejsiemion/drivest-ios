# UI Contracts: Odometer Chart

## Contract 1: OdometerChartView

**File**: `Fuel/Views/Components/OdometerChartView.swift`
**Type**: SwiftUI View component

### Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `points` | `[OdometerDataPoint]` | Yes | Sorted array of (date, odometer) pairs to plot |
| `unit` | `DistanceUnit` | Yes | Displayed on Y-axis label (km or mi) |
| `period` | `Binding<StatisticsTimePeriod>` | Yes | Currently selected time range; mutated by the segmented picker |

### Behaviour

- Renders a `LineMark` chart (Swift Charts) with `date` on X and `odometer` on Y.
- Displays a `Picker(.segmented)` above the chart for time-range selection (Last Month / Last Year / All Time).
- Y-axis auto-scales to the min/max of `points` with ~5% padding below minimum.
- When `points.isEmpty`: shows an empty-state message "No data for this period".
- When `points.count == 1`: renders a single dot (no line); no crash.
- Chart height: fixed at 220 pt (matches existing card heights in the app).

### Empty State

| Condition | Message shown |
|-----------|---------------|
| No fill-ups at all | "Add fill-ups to see odometer progress." |
| Fill-ups exist but none in selected period | "No data for this period." |

---

## Contract 2: SummaryViewModel — Chart Extension

**File**: `Fuel/ViewModels/SummaryViewModel.swift` (modified)

### New Properties

| Property | Type | Description |
|----------|------|-------------|
| `chartPeriod` | `StatisticsTimePeriod` | Selected time range; triggers `chartPoints` recompute on change |
| `chartPoints` | `[OdometerDataPoint]` | Derived from current vehicle's fill-ups filtered by `chartPeriod` |

### New Method

```
func loadChart(for vehicle: Vehicle?)
```

- Called alongside the existing `loadSummary(for:)`.
- Fetches vehicle's fill-ups, filters by `chartPeriod`, converts units, sorts by date.
- Sets `chartPoints`.

### Invariants

- `chartPoints` is always sorted ascending by `date`.
- All `odometer` values in `chartPoints` are in the vehicle's `effectiveDistanceUnit`.
- `chartPoints` is empty `[]` (never nil) when there is no data.

---

## Contract 3: SummaryTabView Integration

**File**: `Fuel/Views/ContentView.swift` (modified)

### Change

Add `OdometerChartView` as the **first section** in the existing `List` inside `SummaryTabView`, before the period summary rows. The chart section has no section header; it renders as a full-width card.

### Layout

```
SummaryTabView
├── TabHeaderView (existing)
├── VehiclePickerCard (existing)
└── List
    ├── Section { OdometerChartView(...) }   ← NEW
    ├── Section("Last Month") { ... }        (existing)
    ├── Section("Last Year") { ... }         (existing)
    └── Section("All Time") { ... }          (existing)
```

### Data Flow

- `viewModel.chartPeriod` bound to `OdometerChartView`'s `period` parameter.
- `viewModel.chartPoints` passed as `points`.
- `store.selectedVehicle?.effectiveDistanceUnit` passed as `unit`.
- `loadChart(for:)` called in same `onAppear` and `onChange` handlers that already call `loadSummary(for:)`.
