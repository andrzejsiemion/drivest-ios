# Data Model: Odometer Chart

## Existing Entities Used (no schema changes)

### FillUp *(existing — read-only for this feature)*

| Field | Type | Role in Chart |
|-------|------|---------------|
| `date` | `Date` | X-axis value (time) |
| `odometerReading` | `Double` | Y-axis value (distance in km) |
| `vehicle` | `Vehicle?` | Foreign key — used to filter to selected vehicle |

No new persistent fields. No SwiftData migrations required.

---

### Vehicle *(existing — read-only for this feature)*

| Field / Property | Type | Role in Chart |
|------------------|------|---------------|
| `effectiveDistanceUnit` | `DistanceUnit` | Determines Y-axis label (km vs mi) and display conversion |
| `fillUps` | `[FillUp]` | Source collection for chart data points |

---

## New Value Types (in-memory only — no persistence)

### OdometerDataPoint

A lightweight struct computed at view time. Never persisted.

| Field | Type | Description |
|-------|------|-------------|
| `date` | `Date` | Date of the fill-up (X-axis) |
| `odometer` | `Double` | Odometer reading converted to vehicle's display unit |

### ChartState (ViewModel property group)

Held in `SummaryViewModel`. Not persisted.

| Property | Type | Description |
|----------|------|-------------|
| `selectedPeriod` | `StatisticsTimePeriod` | Currently active time-range filter |
| `chartPoints` | `[OdometerDataPoint]` | Filtered, sorted, unit-converted data points |

---

## Derivation Logic

```
chartPoints = vehicle.fillUps
    .filter { fillUp.date is within selectedPeriod }
    .sorted { $0.date < $1.date }
    .map { OdometerDataPoint(date: $0.date, odometer: converted($0.odometerReading)) }
```

Conversion:
- `.kilometers` → value as-is
- `.miles` → value ÷ 1.60934

---

## StatisticsTimePeriod (existing enum — unchanged)

| Case | Date Range |
|------|-----------|
| `.month` | Last 30 days from now |
| `.year` | Last 365 days from now |
| `.allTime` | Earliest fill-up date → now |
