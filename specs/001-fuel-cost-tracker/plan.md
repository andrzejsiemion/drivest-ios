# Implementation Plan: Fuel Cost Tracker

**Branch**: `001-fuel-cost-tracker` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-fuel-cost-tracker/spec.md`

## Summary

A local-first iOS app for tracking vehicle fuel expenses and calculating consumption efficiency. Users log fill-ups (price, volume, odometer), view history sorted by date, and see monthly expense summaries and L/100km efficiency calculations. Multi-vehicle support with "last used" default selection. Built with SwiftUI + SwiftData following MVVM architecture.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, Charts (Apple frameworks only)
**Storage**: SwiftData (local on-device persistence)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: Fill-up logging in under 30 seconds from app launch; 60 fps UI
**Constraints**: Fully offline-capable, no server dependency, max 5 third-party packages (currently 0)
**Scale/Scope**: Single-user local app, ~5 screens, data volume limited to user's personal fill-up history

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | MVVM separation in place; single-responsibility per file |
| II. Simple UX | PASS | Single list home + floating "+" + nav bar summary; all actions within 2 taps |
| III. Responsive Design | PASS | SwiftUI adaptive containers; Dynamic Type and safe areas |
| IV. Minimal Dependencies | PASS | Zero third-party dependencies; all Apple frameworks |
| iOS Platform Constraints | PASS | iOS 17+, Swift 5.9, SwiftUI, SwiftData, MVVM |
| Development Workflow | PASS | Feature branch active; tests required before merge |

No violations. Complexity Tracking section not needed.

## Project Structure

### Documentation (this feature)

```text
specs/001-fuel-cost-tracker/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Fuel/
├── FuelApp.swift              # App entry point, SwiftData container setup
├── Models/
│   ├── Vehicle.swift          # Vehicle entity (@Model)
│   └── FillUp.swift           # FillUp entity (@Model)
├── ViewModels/
│   ├── VehicleViewModel.swift     # Vehicle CRUD operations
│   ├── FillUpListViewModel.swift  # Fill-up history & filtering
│   ├── AddFillUpViewModel.swift   # Fill-up form logic & auto-calc
│   └── SummaryViewModel.swift     # Expense aggregation & efficiency stats
├── Views/
│   ├── FillUpListView.swift       # Home screen (history list)
│   ├── AddFillUpView.swift        # Fill-up entry form
│   ├── VehicleListView.swift      # Vehicle management
│   ├── SummaryView.swift          # Monthly/total expense summary
│   └── Components/
│       ├── EmptyStateView.swift   # Empty state guidance
│       └── EfficiencyBadge.swift  # L/100km display component
├── Services/
│   └── EfficiencyCalculator.swift # L/100km calculation logic
└── Resources/
    └── (assets, localizations)

FuelTests/                         # Unit tests (XCTest)
FuelUITests/                       # UI tests (XCUITest)
```

**Structure Decision**: Single iOS project following standard Xcode/SwiftUI conventions with MVVM layering. Already scaffolded and matches constitution requirements.
