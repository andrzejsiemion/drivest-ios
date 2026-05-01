# UI Contract: Vehicles Tab Toolbar

**Feature**: Vehicle Settings Menu
**Date**: 2026-04-20

## Toolbar: Populated State

```
NavigationBar("Vehicles")
└── .topBarTrailing
    └── Menu
        ├── label: Image(systemName: "ellipsis.circle")
        └── items:
            └── Button("Add Vehicle") → presents VehicleFormView sheet
```

### Rules

- The standalone `+` button MUST NOT appear when the vehicle list is populated.
- The `ellipsis.circle` menu icon MUST always be visible in the top-right toolbar when the list has ≥1 vehicle.
- Tapping "Add Vehicle" in the menu MUST present the same `VehicleFormView` sheet as before.

## Toolbar: Empty State

```
NavigationBar("Vehicles")
└── .topBarTrailing
    └── Menu
        ├── label: Image(systemName: "ellipsis.circle")
        └── items:
            └── Button("Add Vehicle") → presents VehicleFormView sheet

Body:
└── EmptyStateView
    ├── title: "No Vehicles"
    ├── message: "Add your first vehicle to start tracking fuel costs."
    └── actionButton: "Add Vehicle" → presents VehicleFormView sheet
```

### Rules

- When `vehicles.isEmpty`, the `EmptyStateView` MUST show a direct "Add Vehicle" button (unchanged behaviour).
- The toolbar menu MUST also be present in the empty state — both paths lead to the same sheet.

## Transition Contract

| User Action | Result |
|-------------|--------|
| Tap `ellipsis.circle` icon | Menu expands with "Add Vehicle" item |
| Tap "Add Vehicle" in menu | `showAddVehicle = true` → sheet presented |
| Tap "Add Vehicle" in empty state | `showAddVehicle = true` → sheet presented |
| Dismiss sheet | `showAddVehicle = false` |
