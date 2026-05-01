# Implementation Plan: Fill-Up Detail & Edit

**Branch**: `005-fillup-detail-edit` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/005-fillup-detail-edit/spec.md`

## Summary

Add a fill-up detail screen accessible by tapping a history row, showing all fields. Include an Edit button that presents the fill-up data in an editable form (reusing the add form layout). On save, validate odometer ordering and recalculate efficiency for the edited and subsequent entries.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (Apple frameworks only)
**Storage**: SwiftData (local on-device)
**Testing**: XCTest; XCUITest
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: Detail screen loads <1s; edit save + recalculation <1s
**Constraints**: Fully offline, zero third-party packages
**Scale/Scope**: 1 new detail view, 1 new edit view (or reuse form), updates to list view navigation

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | Detail and edit views follow MVVM; single responsibility |
| II. Simple UX | PASS | Single tap to detail; Edit button in toolbar; familiar form |
| III. Responsive Design | PASS | SwiftUI List/Form; no hardcoded dimensions |
| IV. Minimal Dependencies | PASS | No new dependencies |
| iOS Platform Constraints | PASS | iOS 17+, SwiftUI, SwiftData, MVVM |
| Development Workflow | PASS | Feature branch active |

No violations.

## Project Structure

### Documentation (this feature)

```text
specs/005-fillup-detail-edit/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── tasks.md
```

### Source Code (changes to existing structure)

```text
Fuel/
├── Views/
│   ├── FillUpListView.swift           # UPDATE: Add NavigationLink on rows
│   ├── FillUpDetailView.swift         # NEW: Read-only detail screen
│   └── EditFillUpView.swift           # NEW: Edit form (pre-populated)
├── ViewModels/
│   └── EditFillUpViewModel.swift      # NEW: Edit logic with validation + recalc
└── Services/
    └── EfficiencyCalculator.swift     # No changes (reuse existing recalculateAll)
```

**Structure Decision**: New detail + edit views. Edit view model handles pre-population, validation, save, and efficiency recalculation.
