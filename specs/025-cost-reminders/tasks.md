# Tasks: Cost Reminders

**Input**: Design documents from `specs/025-cost-reminders/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story for independent implementation and testing.
**Tests**: Not requested — no test tasks generated.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: New model, enums, and pure service — all independent of UI. Must be complete before any view work.

- [X] T001 Create `CostReminder` SwiftData model with all fields and enums (`ReminderType`, `ReminderIntervalUnit`, `ReminderLeadUnit`, `ReminderStatus`) in `Drivest/Models/CostReminder.swift`
- [X] T002 Add optional `reminder: CostReminder?` relationship (deleteRule: `.cascade`) to `CostEntry` in `Drivest/Models/CostEntry.swift`
- [X] T003 Add `reminders: [CostReminder]` relationship (deleteRule: `.cascade`) to `Vehicle` in `Drivest/Models/Vehicle.swift`
- [X] T004 Create pure `ReminderEvaluationService` with `status(for:context:)` method and `ReminderContext` struct in `Drivest/Services/ReminderEvaluationService.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: ViewModel layer and shared UI component used by all three user stories.

**⚠️ CRITICAL**: Phase 1 must be complete before this phase begins.

- [X] T005 Create `ReminderFormSection` SwiftUI View (toggle + inline form for type/interval/lead) accepting `Binding<CostReminder?>`, `costEntryDate: Date`, and `costEntryOdometer: Double?` in `Drivest/Views/Components/ReminderFormSection.swift`
- [X] T006 Extend `AddCostViewModel` to hold a draft `CostReminder?`, expose `reminderResetCandidate: CostReminder?` for the confirmation dialog, and add `saveReminder(to:)` helper in `Drivest/ViewModels/AddCostViewModel.swift`
- [X] T007 Extend `EditCostViewModel` to load the existing `CostReminder?` from the cost entry and persist changes on save in `Drivest/ViewModels/EditCostViewModel.swift`

**Checkpoint**: Foundation ready — user story UI work can now begin.

---

## Phase 3: User Story 1 — Set Time-Based Cost Reminder (Priority: P1) 🎯 MVP

**Goal**: User can attach a time-based reminder (interval in days/months/years + lead days) to a cost entry during creation or editing, and the reminder is persisted.

**Independent Test**: Add an insurance cost entry with a 1-year / 14-day reminder → confirm `CostReminder` is saved and linked to vehicle; reopen cost entry edit screen and verify reminder fields are pre-populated.

### Implementation for User Story 1

- [X] T008 [P] [US1] Embed `ReminderFormSection` into `AddCostView` / `AddCostForm` for new cost entries in `Drivest/Views/AddCostView.swift`
- [X] T009 [P] [US1] Embed `ReminderFormSection` into `EditCostView` for existing cost entries in `Drivest/Views/EditCostView.swift`
- [X] T010 [US1] Wire `ReminderFormSection` bindings to `AddCostViewModel` draft reminder; persist `CostReminder` on save in `Drivest/ViewModels/AddCostViewModel.swift`
- [X] T011 [US1] Wire `ReminderFormSection` bindings to `EditCostViewModel` reminder; persist updates on save in `Drivest/ViewModels/EditCostViewModel.swift`
- [X] T012 [US1] Implement reminder reset `confirmationDialog` in `AddCostView`: detect matching active reminder on same vehicle when saving a same-category cost entry, show "Reset Reminder?" prompt in `Drivest/Views/AddCostView.swift`

**Checkpoint**: User Story 1 independently testable. Time-based reminders can be created, saved, and re-opened.

---

## Phase 4: User Story 2 — Set Distance-Based Cost Reminder (Priority: P2)

**Goal**: User can attach a distance-based reminder (interval in km + lead km) to a cost entry. When the vehicle's odometer reaches the trigger threshold, a badge appears on the vehicle card.

**Independent Test**: Add an oil change cost entry with a 10 000 km / 500 km reminder → confirm saved with correct trigger odometer; record a fill-up past the trigger odometer → reopen the app and verify the vehicle card shows a badge.

### Implementation for User Story 2

- [X] T013 [US2] Add `hasDueReminders(evaluationService:)` computed helper to `Vehicle` (or extract to `ReminderEvaluationService`) that returns `Bool` — true if any non-silenced reminder is `.dueSoon` or `.overdue` in `Drivest/Models/Vehicle.swift`
- [X] T014 [US2] Add badge overlay to the vehicle card in `VehicleListView`: small accent dot at top-trailing corner of `VehiclePhotoView` when `hasDueReminders == true` in `Drivest/Views/VehicleListView.swift`
- [X] T015 [US2] Ensure `ReminderFormSection` disables distance type option with explanatory caption when `costEntryOdometer == nil` in `Drivest/Views/Components/ReminderFormSection.swift`

**Checkpoint**: User Story 2 independently testable. Distance-based reminders created; badge visible on vehicle card when due.

---

## Phase 5: User Story 3 — View and Manage Reminders (Priority: P3)

**Goal**: User can navigate to a per-vehicle reminders list from the vehicle detail screen, view all reminders with status, edit interval/lead, silence, re-enable, and delete reminders.

**Independent Test**: With at least one reminder created (from US1 or US2), navigate to vehicle detail → tap Reminders → verify list shows category, status badge, due date/odometer; edit lead time → save → verify recalculated date; delete a reminder → verify removed.

### Implementation for User Story 3

- [X] T016 [P] [US3] Create `ReminderViewModel` observable object holding a `CostReminder` with `save()`, `delete()`, `toggleSilence()` methods in `Drivest/ViewModels/ReminderViewModel.swift`
- [X] T017 [P] [US3] Create `VehicleRemindersView` list view showing all reminders for a vehicle grouped by status (Due/Overdue first, Pending, Silenced last); each row shows category icon, name, status pill, due date or due odometer, interval summary in `Drivest/Views/VehicleRemindersView.swift`
- [X] T018 [US3] Create `ReminderDetailView` (or inline edit sheet within `VehicleRemindersView`) for editing interval, lead, silencing/re-enabling, and deleting a reminder in `Drivest/Views/VehicleRemindersView.swift`
- [X] T019 [US3] Add `NavigationLink("Reminders")` entry to `VehicleDetailView` pointing to `VehicleRemindersView(vehicle:)` in `Drivest/Views/VehicleDetailView.swift`

**Checkpoint**: All three user stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Localization keys, empty states, and validation edge cases that span all stories.

- [X] T020 [P] Add localization keys for all new user-visible strings (reminder type labels, status labels, form section header, dialog title/message, empty state text) to `Drivest/Resources/Localizable.xcstrings`
- [X] T021 [P] Add empty state to `VehicleRemindersView` when no reminders exist: "No reminders set. Add one from a cost entry." with a prompt label in `Drivest/Views/VehicleRemindersView.swift`
- [X] T022 Validate `ReminderFormSection` steppers: interval minimum = 1, lead minimum = 0; ensure Save in `AddCostView`/`EditCostView` is not blocked by reminder form state in `Drivest/Views/Components/ReminderFormSection.swift`
- [X] T023 Verify VoiceOver accessibility labels on reminder status pills, badge overlay, and form controls across all new views (manual audit per constitution)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion
- **Phase 3 (US1)**: Depends on Phase 2 completion
- **Phase 4 (US2)**: Depends on Phase 1 completion; T013–T015 are independent of Phase 3
- **Phase 5 (US3)**: Depends on Phase 2 completion; T016–T017 can start in parallel with Phase 3
- **Phase 6 (Polish)**: Depends on all Phases 3–5 complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 only — no dependency on US2 or US3
- **US2 (P2)**: Depends on Phase 1 only (needs model + service for badge); independent of US1 and US3
- **US3 (P3)**: Depends on Phase 2 (needs ViewModel) — independent of US1 and US2 for list/edit; benefits from US1/US2 for realistic data

### Within Each User Story

- Models and services before ViewModels
- ViewModels before Views
- Embedding before wiring bindings

### Parallel Opportunities

- T001–T004 (Phase 1): All touch different files — run in parallel
- T008–T009 (US1): Different files — run in parallel
- T016–T017 (US3): Different files — run in parallel
- T020–T021 (Polish): Different concerns — run in parallel
- US2 badge work (T013–T015) can run alongside US1 ViewModel wiring

---

## Parallel Example: Phase 1

```
Task: T001 — Create CostReminder.swift
Task: T002 — Extend CostEntry.swift
Task: T003 — Extend Vehicle.swift
Task: T004 — Create ReminderEvaluationService.swift
```

## Parallel Example: User Story 1 (embedding step)

```
Task: T008 — Embed ReminderFormSection in AddCostView
Task: T009 — Embed ReminderFormSection in EditCostView
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Model + Service
2. Complete Phase 2: ViewModel extensions + ReminderFormSection
3. Complete Phase 3: US1 — time-based reminder in add/edit cost flow
4. **STOP and VALIDATE**: Create insurance reminder, re-open entry, confirm persisted
5. Ship or demo MVP

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Phase 3 (US1) → Time-based reminders working ✅
3. Phase 4 (US2) → Distance-based + vehicle card badge ✅
4. Phase 5 (US3) → Reminders management list ✅
5. Phase 6 → Polish, localization, accessibility ✅

---

## Notes

- `[P]` tasks touch different files with no cross-task dependencies
- `ReminderEvaluationService` has no SwiftData dependency — pure Swift, easily unit-testable if tests are added later
- The `confirmationDialog` in T012 should only appear when a non-silenced active reminder exists for that category+vehicle combination
- Odometer for distance-based reminders uses `vehicle.currentOdometer` (already computed from fill-ups)
- No new third-party packages required
