# Data Model: Vehicle Tab

**Date**: 2026-04-20
**Storage**: SwiftData (iOS 17+)

## Entities

### Vehicle (enhanced)

Extends the existing Vehicle entity with optional fields for unit preferences and vehicle metadata.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| id | UUID | PK, auto-generated | Stable identifier |
| name | String | Required, non-empty | User-assigned label |
| make | String? | Optional | Manufacturer (e.g., "Toyota") |
| model | String? | Optional | Model name (e.g., "Corolla") |
| descriptionText | String? | Optional | Free-text notes about the vehicle |
| distanceUnit | DistanceUnit? | Optional, nil for legacy | km or miles |
| fuelType | FuelType? | Optional, nil for legacy | PB95, PB98, Diesel, LPG, EV, CNG |
| fuelUnit | FuelUnit? | Optional, nil for legacy | liters, gallons, kWh |
| efficiencyDisplayFormat | EfficiencyDisplayFormat? | Optional, nil for legacy | User's preferred efficiency format |
| initialOdometer | Double | Required, ≥ 0 | Starting odometer |
| lastUsedAt | Date | Required, auto-set | Updated on fill-up save |
| createdAt | Date | Required, auto-set | Audit field |

**Relationships**:
- `fillUps: [FillUp]` — one-to-many, cascade delete

**Validation Rules**:
- `name` must be non-empty after trimming whitespace
- `initialOdometer` must be ≥ 0
- If `fuelType` is EV, `fuelUnit` must be kWh (or nil)
- If `fuelType` is non-EV, `fuelUnit` must be liters or gallons (or nil)

**Default Behavior** (nil fields):
- When any unit field is nil, the app defaults to: km, liters, L/100km
- Fill-up forms for unconfigured vehicles use these defaults
- Users can set fields at any time via Edit

---

## Enumerations

### FuelType

| Case | Raw Value | Description |
|------|-----------|-------------|
| pb95 | "pb95" | Unleaded 95 octane |
| pb98 | "pb98" | Unleaded 98 octane |
| diesel | "diesel" | Diesel fuel |
| lpg | "lpg" | Liquefied petroleum gas |
| ev | "ev" | Electric vehicle |
| cng | "cng" | Compressed natural gas |

**Compatibility mapping** → FuelUnit:
- EV → [kWh]
- All others → [liters, gallons]

---

### DistanceUnit

| Case | Raw Value | Description |
|------|-----------|-------------|
| kilometers | "km" | Metric distance |
| miles | "mi" | Imperial distance |

---

### FuelUnit

| Case | Raw Value | Description |
|------|-----------|-------------|
| liters | "l" | Metric volume |
| gallons | "gal" | Imperial/US volume |
| kilowattHours | "kwh" | Energy (EV only) |

---

### EfficiencyDisplayFormat

| Case | Raw Value | Description | Formula |
|------|-----------|-------------|---------|
| litersPer100km | "l100km" | Liters per 100 km | (fuel_L / distance_km) × 100 |
| kwhPer100km | "kwh100km" | kWh per 100 km | (energy_kWh / distance_km) × 100 |
| mpg | "mpg" | Miles per gallon (US) | distance_mi / fuel_gal |
| kmPerLiter | "kml" | Kilometers per liter | distance_km / fuel_L |

---

## Entity Relationship Diagram

```
┌─────────────────────────────┐         ┌──────────────────┐
│         Vehicle             │ 1     * │     FillUp       │
│─────────────────────────────│─────────│──────────────────│
│ id: UUID                    │         │ id: UUID         │
│ name: String                │         │ date: Date       │
│ make: String?               │         │ pricePerLiter    │
│ model: String?              │         │ volume           │
│ descriptionText: String?    │         │ totalCost        │
│ distanceUnit: DistanceUnit? │         │ odometerReading  │
│ fuelType: FuelType?         │         │ isFullTank       │
│ fuelUnit: FuelUnit?         │         │ efficiency?      │
│ efficiencyDisplayFormat:    │         │ createdAt        │
│   EfficiencyDisplayFormat?  │         │                  │
│ initialOdometer: Double     │         │                  │
│ lastUsedAt: Date            │         │                  │
│ createdAt: Date             │         │                  │
└─────────────────────────────┘         └──────────────────┘
```

## Migration Notes

- SwiftData handles lightweight migration automatically for new optional fields
- No manual migration code needed — existing Vehicle records get nil for all new fields
- No data transformation required on upgrade
