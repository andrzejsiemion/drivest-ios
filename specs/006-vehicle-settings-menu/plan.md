# Implementation Plan: Vehicle Settings Menu

**Branch**: `007-vehicle-settings-menu` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/006-vehicle-settings-menu/spec.md`

## Summary

Move the "Add Vehicle" action from a standalone `+` toolbar button into a SwiftUI `Menu` (ellipsis icon) in the top-right corner of the Vehicles tab. The empty state's direct "Add Vehicle" button is preserved. This is a single-file UI change with no data model or ViewModel modifications.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (existing)
**Storage**: SwiftData (no changes)
**Testing**: XCTest / XCUITest
**Target Platform**: iOS 17+
**Project Type**: Mobile app (SwiftUI, MVVM)
**Performance Goals**: N/A — UI-only change
**Constraints**: Must not alter any existing behaviour except button placement
**Scale/Scope**: 1 file modified (`Fuel/Views/VehicleListView.swift`)

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Single-file, single-responsibility change |
| II. Simple UX | ✅ Pass | Toolbar decluttered; empty state preserved as onboarding path |
| III. Responsive Design | ✅ Pass | SwiftUI `Menu` adapts to all device sizes automatically |
| IV. Minimal Dependencies | ✅ Pass | No new dependencies; `Menu` is SwiftUI-native |
| iOS Platform Constraints | ✅ Pass | `Menu` available iOS 14+; target is iOS 17+ |

**Gate**: No violations — implementation approved.

## Project Structure

### Documentation (this feature)

```text
specs/006-vehicle-settings-menu/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0: icon & component decisions
├── data-model.md        # Phase 1: no model changes confirmed
├── contracts/
│   └── ui-contract.md   # Phase 1: toolbar UI contract
└── tasks.md             # Phase 2 output (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
Fuel/
├── Views/
│   └── VehicleListView.swift   ← ONLY FILE MODIFIED
├── ViewModels/
│   └── VehicleViewModel.swift  (no changes)
└── Models/
    └── Vehicle.swift           (no changes)
```

**Structure Decision**: Single project, SwiftUI mobile app. Only `VehicleListView.swift` is touched — the toolbar `ToolbarItem` is replaced from a plain `Button` to a `Menu`.

## Implementation Approach

### Change: Replace toolbar button with Menu

**Current code** (`VehicleListView.swift`, lines 48–56):
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showAddVehicle = true
        } label: {
            Image(systemName: "plus")
        }
    }
}
```

**Target code**:
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button {
                showAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

No other changes required. The `showAddVehicle` sheet binding, `VehicleFormView` presentation, and `EmptyStateView` all remain unchanged.

## Complexity Tracking

No constitution violations — table not required.
