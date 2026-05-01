# Implementation Plan: Statistics Time Filter

**Branch**: `011-statistics-time-filter` | **Date**: 2026-04-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/011-statistics-time-filter/spec.md`

## Summary

Add a time filter control to the Statistics tab allowing users to view fuel spending statistics for preset periods (week, month, year, all time) or a custom date range. The filter uses a segmented control UI pattern and filters data at the SwiftData query level for efficiency.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, Charts (all Apple frameworks)
**Storage**: SwiftData (local persistence, existing)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iOS)
**Performance Goals**: Statistics update within 1 second of filter change
**Constraints**: Offline-capable, no server dependency
**Scale/Scope**: Single screen change (Statistics tab), 1 new file + 2 modified files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Single-responsibility enum for time period, minimal ViewModel change |
| II. Simple UX | ✅ Pass | Single-tap filter switching, inline date pickers (no extra navigation) |
| III. Responsive Design | ✅ Pass | Segmented control and DatePicker adapt to all device sizes natively |
| IV. Minimal Dependencies | ✅ Pass | Uses only Apple frameworks (SwiftUI, SwiftData) |
| iOS Platform Constraints | ✅ Pass | iOS 17+, Swift 5.9+, SwiftUI, SwiftData, MVVM |
| Development Workflow | ✅ Pass | Feature branch, single logical change |

**Post-Phase 1 Re-check**: All gates still pass. No new dependencies introduced. Navigation depth unchanged (filter is inline on existing screen).

## Project Structure

### Documentation (this feature)

```text
specs/011-statistics-time-filter/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── ui-contract.md   # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
Fuel/
├── Models/
│   └── StatisticsTimePeriod.swift   # NEW: Enum with date range computation
├── ViewModels/
│   └── SummaryViewModel.swift       # MODIFIED: Add period parameter to loadSummary
└── Views/
    └── ContentView.swift            # MODIFIED: Add filter UI to SummaryTabView
```

**Structure Decision**: Follows existing MVVM pattern. New enum goes in Models/ alongside other enums (DistanceUnit, FuelType, etc.). View changes are contained to the existing SummaryTabView in ContentView.swift.

## Complexity Tracking

No constitution violations. No complexity justification needed.

## Implementation Tasks

### Task 1: Create StatisticsTimePeriod enum
**File**: `Fuel/Models/StatisticsTimePeriod.swift` (NEW)
- Define enum with cases: `.week`, `.month`, `.year`, `.allTime`, `.custom(start: Date, end: Date)`
- Add `dateRange` computed property returning `(start: Date?, end: Date?)`
- Add `displayName` property for segmented control labels
- Register file in pbxproj

### Task 2: Update SummaryViewModel
**File**: `Fuel/ViewModels/SummaryViewModel.swift` (MODIFY)
- Change `loadSummary(for:)` signature to `loadSummary(for:period:)`
- Compute start/end dates from the period parameter
- Add date bounds to the `#Predicate` in the fetch descriptor
- Keep existing grouping and calculation logic unchanged

### Task 3: Update SummaryTabView UI
**File**: `Fuel/Views/ContentView.swift` (MODIFY)
- Add `@State private var selectedPeriod: StatisticsTimePeriod = .allTime`
- Add segmented `Picker` between VehiclePickerCard and statistics list
- Add conditional `DatePicker` controls for `.custom` case
- Wire `onChange(of: selectedPeriod)` to call `viewModel.loadSummary(for:period:)`
- Update existing `onChange(of: store.selectedVehicle)` to pass `selectedPeriod`
- Update `onAppear` to pass `selectedPeriod`
- Update empty state message for filtered periods

### Task 4: Update SummaryView (standalone)
**File**: `Fuel/Views/SummaryView.swift` (MODIFY)
- Update call to `loadSummary(for:period:)` with `.allTime` default (this view is a sheet, no filter needed)
