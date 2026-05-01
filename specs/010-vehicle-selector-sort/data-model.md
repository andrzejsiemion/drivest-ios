# Data Model: Vehicle Selector & Sort Order

## No SwiftData Schema Changes

This feature introduces **no new SwiftData models** and **no changes to existing models**. All new state is runtime (shared `@Observable` store) or `UserDefaults`-based preferences.

---

## New Runtime Entity: VehicleSelectionStore

An `@Observable` class injected at app root. Not persisted in SwiftData.

| Property | Type | Description |
|---|---|---|
| `selectedVehicle` | `Vehicle?` | Currently active vehicle, shared across all tabs |
| `sortOrder` | `VehicleSortOrder` | Current sort preference (persisted via UserDefaults) |
| `customOrder` | `[UUID]` | Vehicle IDs in user-defined sequence (persisted via UserDefaults) |
| `selectedVehicleID` | `String` (UserDefaults) | UUID string of last selected vehicle (for restart restoration) |

**Lifecycle**: Created once in `FuelApp.init()`, injected via `.environment()`.

---

## New Value Type: VehicleSortOrder

A Swift `enum` (not a SwiftData model).

| Case | Raw Value | Description |
|---|---|---|
| `.alphabetical` | `"alphabetical"` | A–Z by vehicle name |
| `.dateAdded` | `"dateAdded"` | Chronological by `vehicle.createdAt` |
| `.lastUsed` | `"lastUsed"` | Most recently selected vehicle first |
| `.custom` | `"custom"` | User-defined drag order |

Persisted as a `String` rawValue in `UserDefaults` key `"vehicleSortOrder"`.

---

## Derived Computation: Current Odometer

Computed on `Vehicle`, not stored:

```
currentOdometer = max(fillUp.odometerReading for fillUp in vehicle.fillUps)
                  OR vehicle.initialOdometer if fillUps is empty
```

Displayed on the `VehiclePickerCard`.

---

## UserDefaults Keys Summary

| Key | Type | Description |
|---|---|---|
| `"vehicleSortOrder"` | `String` | Raw value of `VehicleSortOrder` |
| `"customVehicleOrder"` | `Data` (JSON) | Encoded `[UUID]` for custom order |
| `"selectedVehicleID"` | `String` | UUID of last selected vehicle |
