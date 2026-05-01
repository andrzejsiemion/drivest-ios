# Data Model: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Branch**: `023-ev-energy-snapshot` | **Date**: 2026-04-25

---

## New SwiftData Models

### EnergySnapshot

**File**: `Fuel/Models/EnergySnapshot.swift`

Represents a single point-in-time reading fetched from a manufacturer API for an EV vehicle.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key; auto-generated |
| `fetchedAt` | `Date` | Timestamp of the fetch (not necessarily vehicle report time) |
| `odometerKm` | `Double` | Odometer in kilometres (raw from API; display conversion applied at UI) |
| `socPercent` | `Int?` | State of charge 0–100%; `nil` if API does not return SoC for this vehicle |
| `source` | `String` | API source: `"volvo"` or `"toyota"` |
| `vehicle` | `Vehicle` | Back-reference to owning vehicle |
| `createdAt` | `Date` | Record insertion timestamp |

**Uniqueness**: Vehicle + `fetchedAt` combination is logically unique (one fetch per scheduled slot), but not enforced by SwiftData constraint — duplicate prevention is the caller's responsibility.

**Purge rule**: Records where `fetchedAt < Date.now - 6 months` are deleted by `SnapshotPurgeService` on each app foreground.

**Relationships**:
- `@Relationship(deleteRule: .nullify, inverse: \EnergySnapshot.vehicle)` on `Vehicle.energySnapshots: [EnergySnapshot]`

---

### ElectricityBill

**File**: `Fuel/Models/ElectricityBill.swift`

Represents a user-entered electricity bill for an EV vehicle. Bills are implicitly ordered by `endDate` per vehicle to establish period boundaries.

| Field | Type | Notes |
|---|---|---|
| `id` | `UUID` | Primary key; auto-generated |
| `endDate` | `Date` | Bill end date (date only; time component ignored for period matching) |
| `totalKwh` | `Double` | Total kWh from electricity meter for this bill |
| `totalCost` | `Double` | Total cost in `currencyCode` |
| `currencyCode` | `String?` | ISO 4217 code; uses app default currency if nil |
| `distanceKm` | `Double?` | Calculated: end snapshot odometer − start snapshot odometer; `nil` if no data |
| `efficiencyKwhPer100km` | `Double?` | Calculated: `(totalKwh / distanceKm) × 100`; `nil` if no data |
| `costPerKm` | `Double?` | Calculated: `totalCost / distanceKm`; `nil` if no data |
| `hasSnapshotData` | `Bool` | `true` if calculation was possible; `false` if no suitable snapshots found |
| `startSnapshotId` | `UUID?` | ID of the snapshot used as period start (for traceability) |
| `endSnapshotId` | `UUID?` | ID of the snapshot used as period end (for traceability) |
| `vehicle` | `Vehicle` | Back-reference to owning vehicle |
| `createdAt` | `Date` | Record insertion timestamp |

**Reconciliation logic** (executed at save time by `BillReconciliationService`):
1. Find the most recent `ElectricityBill` for the same vehicle where `endDate < self.endDate` → `previousBill`
2. If no previous bill → mark `hasSnapshotData = false` (baseline entry)
3. Fetch snapshots in period `[previousBill.endDate ... self.endDate]` sorted by `fetchedAt`
4. `startSnapshot` = snapshot closest to `previousBill.endDate`; `endSnapshot` = snapshot closest to `self.endDate`
5. If either boundary is >7 days from its target date → `hasSnapshotData = false`
6. If `endSnapshot.odometerKm ≤ startSnapshot.odometerKm` → `hasSnapshotData = false`
7. Otherwise calculate and store all derived fields; set `hasSnapshotData = true`

**Relationships**:
- `@Relationship(deleteRule: .nullify, inverse: \ElectricityBill.vehicle)` on `Vehicle.electricityBills: [ElectricityBill]`

---

## Modifications to Existing Models

### Vehicle (additions)

**File**: `Fuel/Models/Vehicle.swift`

```swift
@Relationship(deleteRule: .cascade, inverse: \EnergySnapshot.vehicle)
var energySnapshots: [EnergySnapshot]

@Relationship(deleteRule: .cascade, inverse: \ElectricityBill.vehicle)
var electricityBills: [ElectricityBill]

/// True when primary fuelType is .ev (feature gating).
var isEV: Bool { fuelType == .ev }
```

---

## UserDefaults Configuration Keys (not SwiftData)

These are stored as `@AppStorage` / `UserDefaults` entries. No migration needed.

| Key | Type | Default | Purpose |
|---|---|---|---|
| `snapshotFetchEnabled` | `Bool` | `true` | Master toggle for background fetch |
| `snapshotFetchFrequency` | `String` | `"daily"` | Raw value of `FetchFrequency` enum |
| `snapshotFetchHour` | `Int` | `5` | Hour of first fetch (0–23) |
| `snapshotFetchMinute` | `Int` | `0` | Minute of first fetch (0–59) |
| `snapshotLastFetchAt` | `Double` | `0` | `timeIntervalSince1970` of last successful fetch |
| `snapshotFailures_<vehicleID>` | `Int` | `0` | Consecutive failure counter per vehicle UUID |

---

## Enums

### FetchFrequency

**File**: `Fuel/Models/FetchFrequency.swift` (new, or appended to `AppPreferences.swift`)

```swift
enum FetchFrequency: String, CaseIterable {
    case daily        // 1× per day
    case twiceDaily   // 2× per day (every 12h)
    case every6Hours  // 4× per day
    case every12Hours // 2× per day (alias, same as twiceDaily interval-wise)
}
```

`intervalSeconds` computed property returns the BGAppRefreshTask minimum interval to submit.

---

## ModelContainer Update

**File**: `Fuel/FuelApp.swift`

```swift
container = try ModelContainer(for: Vehicle.self, FillUp.self, CostEntry.self, CostCategory.self,
                               EnergySnapshot.self, ElectricityBill.self)
```

SwiftData auto-migrates; no version migration descriptor needed for additive schema changes.

---

## Backup Codable Update

**File**: `Fuel/Services/BackupCodable.swift`

Add `EnergySnapshotBackup` and `ElectricityBillBackup` structs. Extend `BackupEnvelope` with `energySnapshots: [EnergySnapshotBackup]` and `electricityBills: [ElectricityBillBackup]`. Update `VehicleExporter` and `VehicleImporter` accordingly.
