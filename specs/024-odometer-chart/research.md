# Research: Odometer Chart on Statistics Page

## Decision 1: Charting Library

**Decision**: Use Apple's native **Swift Charts** framework (iOS 16+, stable on iOS 17+).

**Rationale**: The constitution explicitly mandates "prefer Apple-provided frameworks (SwiftUI, CoreData, Charts) over third-party equivalents." Swift Charts is already named as an approved framework. The minimum deployment target is iOS 17.0, where Charts is fully mature and supports `LineMark`, axis customisation, and interactive selection out of the box. No additional package dependency is introduced.

**Alternatives considered**:
- **swift-charts (third-party)** — Rejected: violates Principle IV (Minimal Dependencies); no justifiable advantage over Apple Charts on iOS 17.
- **Custom Canvas/Path drawing** — Rejected: high implementation cost with no user-facing benefit; Charts achieves the same result in fewer lines.

---

## Decision 2: Time Range Selector

**Decision**: Reuse the existing **`StatisticsTimePeriod`** enum (`.month`, `.year`, `.allTime`) already present at `Fuel/Models/StatisticsTimePeriod.swift`. Use a **`Picker` with `.segmented` style** placed above the chart.

**Rationale**: The enum already covers all three required time-range options from the spec (Last Month, Last Year, All Time) and is used elsewhere in the app, ensuring consistency. A segmented control is the standard iOS pattern for mutually exclusive time-range selection and is immediately recognisable to users.

**Alternatives considered**:
- **New enum** — Rejected: duplication; `StatisticsTimePeriod` already exists with identical cases.
- **Date range picker** — Rejected: over-engineering; spec requires only three fixed ranges.

---

## Decision 3: Data Source

**Decision**: Derive chart data points directly from **`vehicle.fillUps`** — each point is `(date: FillUp.date, odometer: FillUp.odometerReading)`. No new data model entities required.

**Rationale**: FillUp already carries both `date: Date` and `odometerReading: Double`. Sorting by date gives a naturally ordered series for a line chart. Filtering by `StatisticsTimePeriod` reuses existing date-range logic.

**Alternatives considered**:
- **Dedicated snapshot model** — Rejected: overkill; fill-ups are already the canonical odometer record in the app.

---

## Decision 4: Architecture Placement

**Decision**: Add an **`OdometerChartView`** SwiftUI component (new file at `Fuel/Views/Components/OdometerChartView.swift`) and extend **`SummaryViewModel`** with chart-specific computed properties.

**Rationale**: The chart is a read-only derived view of existing fill-up data — no new storage, no new service layer. Keeping chart data computation in `SummaryViewModel` (or a small extension file) maintains the existing MVVM pattern. Extracting the chart UI into a dedicated component keeps `ContentView.swift`/`SummaryTabView` at a manageable size.

**Alternatives considered**:
- **Separate `OdometerChartViewModel`** — Viable but unnecessary; chart state (selected time range, computed points) is lightweight and fits naturally alongside `PeriodStats` in `SummaryViewModel`.
- **Inline in `ContentView.swift`** — Rejected: would further bloat an already large file.

---

## Decision 5: Y-Axis Auto-Scaling

**Decision**: Let **Swift Charts auto-scale** the Y-axis by default (`chartYScale(domain: .automatic)`). Manually set a small bottom padding (5% below the min value) so the line is never flush with the axis edge.

**Rationale**: Swift Charts automatically fits the domain to the visible data when no explicit domain is set. Adding a small padding improves readability. This satisfies SC-003 (Y-axis within 5% margin, no clipping) with zero extra logic.

---

## Decision 6: Distance Unit Handling

**Decision**: Use `vehicle.effectiveDistanceUnit` to label the Y-axis and convert odometer values at display time (divide km by 1.60934 for miles-configured vehicles).

**Rationale**: Existing pattern used throughout the app (`effectiveDistanceUnit` falls back to `.kilometers`). No raw conversion in the model — display-layer only.
