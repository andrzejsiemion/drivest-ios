# Implementation Plan: Enhanced Fill-Up Form

**Branch**: `004-enhanced-fillup-form` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-enhanced-fillup-form/spec.md`

## Summary

Enhance the existing fill-up form with a reordered layout (vehicle → odometer → fuel type → price → volume → total → full tank → note), fuel type prefill from vehicle settings, and an optional 200-character note field. The FillUp entity gains `note` and `fuelType` fields.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (Apple frameworks only)
**Storage**: SwiftData (local on-device)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: Fill-up logging under 20 seconds; fuel type prefill instant on vehicle change
**Constraints**: Fully offline, zero third-party packages
**Scale/Scope**: Modifies existing form view + view model; adds 2 fields to FillUp model

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | Enhances existing form; single responsibility maintained |
| II. Simple UX | PASS | Fewer taps via prefill; clear field order; note is optional |
| III. Responsive Design | PASS | SwiftUI Form adapts; no hardcoded dimensions |
| IV. Minimal Dependencies | PASS | No new dependencies |
| iOS Platform Constraints | PASS | iOS 17+, SwiftUI, SwiftData, MVVM |
| Development Workflow | PASS | Feature branch active |

No violations.

## Project Structure

### Documentation (this feature)

```text
specs/004-enhanced-fillup-form/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (changes to existing structure)

```text
Fuel/
├── Models/
│   └── FillUp.swift                   # UPDATE: Add note: String? and fuelType: FuelType? fields
├── ViewModels/
│   └── AddFillUpViewModel.swift       # UPDATE: Add fuel type prefill logic, note field, reorder
├── Views/
│   ├── AddFillUpView.swift            # UPDATE: Reorder form sections, add fuel type picker + note field
│   └── FillUpListView.swift           # UPDATE: Display note in fill-up row (if present)
└── Services/
    └── (no changes)
```

**Structure Decision**: Pure enhancement of existing files. No new files needed.
