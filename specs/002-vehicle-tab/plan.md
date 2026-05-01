# Implementation Plan: Vehicle Tab

**Branch**: `002-vehicle-tab` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/002-vehicle-tab/spec.md`

## Summary

Extend the existing Fuel Tracker app with a dedicated Vehicle tab (second position in a three-tab layout) that allows users to manage vehicles with enhanced properties: make, model, description, distance units, fuel type, fuel units, and efficiency display format. Pre-existing vehicles retain nil fields until manually edited. Fuel unit options are filtered by fuel type (kWh for EV only).

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (Apple frameworks only)
**Storage**: SwiftData (local on-device persistence)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: Vehicle list renders within 1 second; vehicle creation under 45 seconds
**Constraints**: Fully offline-capable, no server dependency, zero third-party packages
**Scale/Scope**: Extension of existing app; adds ~3 new views, enhances 1 existing model, adds 4 enums

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | New enums and optional fields follow Swift conventions; single-responsibility maintained |
| II. Simple UX | PASS | Vehicle tab is 1 tap from root; add/edit forms have single primary action; filtered pickers reduce confusion |
| III. Responsive Design | PASS | SwiftUI List/Form adapt to all sizes; no hardcoded dimensions needed |
| IV. Minimal Dependencies | PASS | Zero new dependencies; uses SwiftUI/SwiftData only |
| iOS Platform Constraints | PASS | iOS 17+, Swift 5.9, SwiftUI, SwiftData, MVVM |
| Development Workflow | PASS | Feature branch `002-vehicle-tab` active |

No violations. Complexity Tracking not needed.

## Project Structure

### Documentation (this feature)

```text
specs/002-vehicle-tab/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (changes to existing structure)

```text
Fuel/
├── FuelApp.swift                      # UPDATE: Add TabView with 3 tabs
├── Models/
│   ├── Vehicle.swift                  # UPDATE: Add optional fields + enums
│   ├── FuelType.swift                 # NEW: FuelType enum
│   ├── DistanceUnit.swift             # NEW: DistanceUnit enum
│   ├── FuelUnit.swift                 # NEW: FuelUnit enum
│   └── EfficiencyDisplayFormat.swift  # NEW: EfficiencyDisplayFormat enum
├── ViewModels/
│   └── VehicleViewModel.swift         # UPDATE: CRUD for enhanced vehicle model
├── Views/
│   ├── ContentView.swift              # NEW: TabView container (History, Vehicles, Summary)
│   ├── VehicleListView.swift          # UPDATE: Enhanced list with make/model/fuel type display
│   ├── VehicleDetailView.swift        # NEW: Vehicle detail/view screen
│   ├── VehicleFormView.swift          # NEW: Add/Edit form with filtered pickers
│   └── Components/
│       └── FuelUnitPicker.swift       # NEW: Filtered picker based on fuel type
├── Services/
│   └── EfficiencyCalculator.swift     # UPDATE: Support multiple display formats
└── Resources/

FuelTests/
├── VehicleModelTests.swift            # NEW: Vehicle field validation tests
├── FuelTypeFilterTests.swift          # NEW: Fuel unit filtering logic tests
└── EfficiencyDisplayTests.swift       # NEW: Format conversion tests
```

**Structure Decision**: Extends existing MVVM iOS project. New enums live in Models/. Form view is shared for add/edit flows. ContentView wraps the existing views in a TabView.
