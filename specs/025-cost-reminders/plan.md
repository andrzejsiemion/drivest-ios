# Implementation Plan: Cost Reminders

**Branch**: `025-cost-reminders` | **Date**: 2026-04-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/025-cost-reminders/spec.md`

## Summary

Allow users to attach recurring cost reminders to any vehicle cost entry — either time-based (e.g. insurance due in 1 year, warn 14 days before) or distance-based (e.g. oil change every 10 000 km, warn 500 km before). Reminders surface as a badge on the vehicle card when triggered; a per-vehicle reminders list enables viewing, editing, silencing, and deleting reminders. No third-party dependencies; built entirely on SwiftData, SwiftUI, and Foundation.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, Foundation (Calendar, DateComponents)
**Storage**: SwiftData (`@Model` — new `CostReminder` entity; extensions to `CostEntry` and `Vehicle`)
**Testing**: XCTest (unit tests for `ReminderEvaluationService` and status state machine)
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (MVVM, SwiftUI)
**Performance Goals**: Status computation for all reminders on app launch < 16ms (negligible — pure in-memory math)
**Constraints**: Fully offline, no server dependency, no new third-party packages
**Scale/Scope**: Typically < 20 reminders per user across all vehicles

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | New `CostReminder` model and `ReminderEvaluationService` have single responsibilities; no dead code |
| II. Simple UX | PASS | Reminder toggle in cost entry form; badge on vehicle card; reminders list ≤ 3 taps from root |
| III. Responsive Design | PASS | SwiftUI adaptive layouts; no hardcoded dimensions |
| IV. Minimal Dependencies | PASS | Zero new third-party dependencies; Foundation Calendar covers all interval arithmetic |
| iOS Platform Constraints | PASS | SwiftData persistence; MVVM; iOS 17+ |

No gate violations.

## Project Structure

### Documentation (this feature)

```text
specs/025-cost-reminders/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── ui-contracts.md  ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit-tasks)
```

### Source Code Changes

```text
Drivest/
├── Models/
│   ├── CostEntry.swift              MODIFY — add optional `reminder: CostReminder?` relationship
│   ├── Vehicle.swift                MODIFY — add `reminders: [CostReminder]` cascade relationship
│   └── CostReminder.swift           NEW    — @Model with all reminder fields and enums
│
├── Services/
│   └── ReminderEvaluationService.swift  NEW — pure service: computes ReminderStatus from reminder + context
│
├── ViewModels/
│   ├── AddCostViewModel.swift       MODIFY — hold draft CostReminder; trigger reset dialog
│   ├── EditCostViewModel.swift      MODIFY — load/save existing CostReminder on cost entry
│   └── ReminderViewModel.swift      NEW    — ObservableObject for ReminderDetailView (edit/delete)
│
└── Views/
    ├── AddCostView.swift             MODIFY — embed ReminderFormSection
    ├── EditCostView.swift            MODIFY — embed ReminderFormSection
    ├── VehicleDetailView.swift       MODIFY — add "Reminders" NavigationLink
    ├── VehicleListView.swift         MODIFY — add badge overlay on vehicle card when hasDueReminders
    ├── Components/
    │   └── ReminderFormSection.swift NEW    — inline reminder toggle + form (embedded in cost views)
    └── VehicleRemindersView.swift    NEW    — list of reminders for a vehicle; edit/delete/re-enable
```

## Complexity Tracking

No violations requiring justification.
