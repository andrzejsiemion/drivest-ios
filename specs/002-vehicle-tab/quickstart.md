# Quickstart: Vehicle Tab Feature

**Date**: 2026-04-20
**Branch**: `002-vehicle-tab`

## Prerequisites

- Xcode 15.0+ (for Swift 5.9 and iOS 17 SDK)
- macOS Sonoma 14.0+
- iPhone Simulator or physical device running iOS 17.0+

## Setup

1. Switch to the feature branch:
   ```bash
   cd fuel
   git checkout 002-vehicle-tab
   ```

2. Open the Xcode project:
   ```bash
   open Fuel.xcodeproj
   ```

3. Build and run (⌘R). No package resolution or configuration needed.

## What This Feature Changes

### New Files
- `Fuel/Models/FuelType.swift` — Fuel type enum (PB95, PB98, Diesel, LPG, EV, CNG)
- `Fuel/Models/DistanceUnit.swift` — Distance unit enum (km, miles)
- `Fuel/Models/FuelUnit.swift` — Fuel unit enum (liters, gallons, kWh)
- `Fuel/Models/EfficiencyDisplayFormat.swift` — Display format enum (L/100km, kWh/100km, MPG, km/L)
- `Fuel/Views/ContentView.swift` — TabView container (3 tabs)
- `Fuel/Views/VehicleDetailView.swift` — Vehicle detail screen
- `Fuel/Views/VehicleFormView.swift` — Shared add/edit form
- `Fuel/Views/Components/FuelUnitPicker.swift` — Filtered picker component

### Modified Files
- `Fuel/FuelApp.swift` — Entry point now uses ContentView (TabView)
- `Fuel/Models/Vehicle.swift` — New optional fields added
- `Fuel/ViewModels/VehicleViewModel.swift` — Enhanced CRUD
- `Fuel/Views/VehicleListView.swift` — Updated list cells
- `Fuel/Services/EfficiencyCalculator.swift` — Multi-format display support

## Running Tests

```bash
xcodebuild test -project Fuel.xcodeproj -scheme Fuel -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Key Patterns

- **Filtered pickers**: FuelUnitPicker accepts a FuelType binding and shows only compatible units
- **Nil-safe defaults**: All code paths handle nil unit fields gracefully, defaulting to km/liters/L100km
- **Shared form**: VehicleFormView works for both add (new Vehicle) and edit (existing Vehicle) flows
- **TabView navigation**: ContentView wraps History, Vehicles, Summary as peer tabs
