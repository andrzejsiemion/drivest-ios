# Data Model: Vehicle Settings Menu

**Feature**: Move "Add Vehicle" button into a top-right contextual menu
**Date**: 2026-04-20

## No Data Model Changes

This feature is a pure UI relocation. No new entities, fields, relationships, or state transitions are introduced.

The existing `VehicleViewModel` and `Vehicle` model remain unchanged.

## Existing State Relevant to Feature

| State Variable | Owner | Purpose | Change? |
|---------------|-------|---------|---------|
| `showAddVehicle: Bool` | `VehicleListView` | Controls presentation of add vehicle sheet | None — retained |
| `vehicles: [Vehicle]` | `VehicleViewModel` | Drives empty vs populated view branch | None |

No new state variables are needed. The `showAddVehicle` toggle continues to be set to `true` — it is now triggered from inside the `Menu` button instead of a standalone toolbar button.
