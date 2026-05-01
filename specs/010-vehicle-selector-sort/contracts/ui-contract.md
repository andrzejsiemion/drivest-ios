# UI Contract: Vehicle Selector & Sort Order

## VehiclePickerCard

A reusable card component displayed at the top of Fuel, Costs, and Statistics tabs.

### Layout

```
┌─────────────────────────────────────────────┐
│  [○ photo]  Vehicle Name          [chevron] │
│             52 354 km                        │
└─────────────────────────────────────────────┘
```

### Properties

| Property | Type | Description |
|---|---|---|
| `vehicle` | `Vehicle` | Vehicle to display |
| `currentOdometer` | `Double` | Computed max odometer reading |
| `isInteractive` | `Bool` | Show chevron and handle tap (true when >1 vehicle exists) |
| `onTap` | `() -> Void` | Called when card is tapped (opens vehicle picker sheet) |

### Visual States

| State | Behavior |
|---|---|
| Single vehicle | Card shown, no chevron, not tappable |
| Multiple vehicles | Card shown with chevron, tappable, opens picker sheet |
| No photo | Circular `car.fill` icon on accent color background |
| Has photo | Circular crop of vehicle photo |

---

## Vehicle Picker Sheet

Presented as a `.sheet` when `VehiclePickerCard` is tapped (multi-vehicle).

### Layout

```
┌─────────────────────────────────────────────┐
│  Select Vehicle                    [Done]   │
├─────────────────────────────────────────────┤
│  [○ photo]  Tesla Model 3          [✓]      │
│  [○ photo]  Volvo V90                       │
│  [○ photo]  BMW M3                          │
└─────────────────────────────────────────────┘
```

### Behavior

- Vehicles ordered per `VehicleSortOrder` preference
- Currently selected vehicle shows a checkmark
- Tapping a vehicle selects it, updates `VehicleSelectionStore.selectedVehicle`, and dismisses the sheet

---

## SettingsView — Vehicle Order Section

New section added to the existing `SettingsView`.

### Layout

```
Categories
  [existing category list...]

Vehicle Order
  Sort By        [Last Used ▾]     ← Picker row
  [Edit Order]                     ← Only shown when Sort By = Custom
```

### Sort By Options (Picker)

- Alphabetical
- Date Added
- Last Used (default)
- Custom

### Custom Order

When "Custom" is selected, an "Edit Order" button appears navigating to `VehicleReorderView`.

---

## VehicleReorderView

A full-screen list of vehicles with drag handles for reordering.

### Layout

```
< Back          Vehicle Order        [Done]

  ≡  Tesla Model 3
  ≡  Volvo V90
  ≡  BMW M3
```

- Drag handle (`≡`) on leading edge
- `.onMove` modifier enables drag-to-reorder
- New vehicles (not yet in custom list) appear at the bottom

---

## Tab Integration: Toolbar Changes

### Before (current)

- Single vehicle: Vehicle name in `.principal` toolbar area (small caps text)
- Multiple vehicles: `Picker` menu in `.principal` toolbar area

### After (this feature)

- `VehiclePickerCard` appears as the first section of the List (above fill-ups / costs / stats content)
- Toolbar `.principal` area is cleared (no vehicle name shown there)
- Ellipsis `···` menu remains in `.topBarTrailing`
