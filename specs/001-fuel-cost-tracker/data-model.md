# Data Model: Fuel Cost Tracker

**Date**: 2026-04-19
**Storage**: SwiftData (iOS 17+)

## Entities

### Vehicle

| Field | Type | Constraints |
|-------|------|-------------|
| id | UUID | Primary key, auto-generated |
| name | String | Required, non-empty |
| initialOdometer | Double | Required, >= 0 |
| lastUsedAt | Date | Updated on each fill-up save |
| createdAt | Date | Auto-set on creation |

**Relationships**:
- `fillUps`: One-to-many → FillUp (cascade delete)

**Ordering**: By `lastUsedAt` descending (most recently used first)

### FillUp

| Field | Type | Constraints |
|-------|------|-------------|
| id | UUID | Primary key, auto-generated |
| date | Date | Required, defaults to now |
| pricePerLiter | Double | Required, > 0 |
| volume | Double | Required, > 0 (liters) |
| totalCost | Double | Required, > 0 |
| odometerReading | Double | Required, > previous entry for same vehicle |
| isFullTank | Bool | Required, defaults to true |
| efficiency | Double? | Nullable — computed on save for full-tank entries |
| createdAt | Date | Auto-set on creation |

**Relationships**:
- `vehicle`: Many-to-one → Vehicle (required)

**Ordering**: By `date` descending (most recent first)

**Validation rules**:
- `odometerReading` MUST be > the most recent previous fill-up's
  odometer for the same vehicle
- `totalCost` ≈ `pricePerLiter × volume` (auto-calculated, not
  independently validated since user enters two of three)
- `efficiency` is set only when `isFullTank == true` and a previous
  full-tank entry exists for the same vehicle

## Efficiency Computation (derived field)

When saving a FillUp where `isFullTank == true`:

1. Find the previous FillUp for the same vehicle where
   `isFullTank == true` (call it `prevFull`)
2. If `prevFull` exists:
   - Collect all FillUps between `prevFull` and current (exclusive of
     `prevFull`, inclusive of current), ordered by date
   - `totalFuel` = sum of `volume` for all collected entries
   - `distance` = current `odometerReading` - `prevFull.odometerReading`
   - `efficiency` = (`totalFuel` / `distance`) × 100
3. If no `prevFull` exists: `efficiency` = nil

## State Transitions

### FillUp Lifecycle

```
[New] → (validate fields) → [Saved]
[Saved] → (edit) → [Updated] → (recompute efficiency) → [Saved]
[Saved] → (delete) → [Deleted] → (recompute next full-tank efficiency) → done
```

On delete: if deleted entry was a full-tank entry, the next full-tank
entry's efficiency MUST be recalculated (or set to nil if no prior
full-tank remains).

### Vehicle Lifecycle

```
[New] → (set name + initial odometer) → [Active]
[Active] → (edit name/odometer) → [Active]
[Active] → (delete) → [Deleted] (cascades all fill-ups)
```

## Indexes (query optimization)

- FillUp: compound index on (`vehicle`, `date` DESC) for history list
- FillUp: compound index on (`vehicle`, `isFullTank`, `date` DESC) for
  efficiency lookups
- Vehicle: index on `lastUsedAt` DESC for vehicle selector ordering
