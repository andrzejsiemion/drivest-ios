# Tasks: Enhanced Fill-Up Form

**Input**: Design documents from `specs/004-enhanced-fillup-form/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested. Test tasks omitted.

**Organization**: Tasks grouped by user story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: FillUp model extension that MUST be complete before user story work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T001 Add optional note: String? and fuelType: FuelType? fields to FillUp model in Fuel/Models/FillUp.swift
- [x] T002 Update FillUp initializer to accept optional note and fuelType parameters (defaulting to nil) in Fuel/Models/FillUp.swift

**Checkpoint**: FillUp model can store note and fuel type data

---

## Phase 2: User Story 1 - Log Fill-Up with Prefilled Vehicle Data (Priority: P1) 🎯 MVP

**Goal**: Fill-up form shows reordered fields with fuel type prefilled from vehicle settings

**Independent Test**: Select vehicle with fuel type "Diesel" → Form shows "Diesel" prefilled → Change vehicle → Fuel type updates → Save → Entry in history

### Implementation for User Story 1

- [x] T003 [US1] Add fuelType and note state properties to AddFillUpViewModel. Add logic to prefill fuelType from selected vehicle's fuelType on init and when vehicle changes in Fuel/ViewModels/AddFillUpViewModel.swift
- [x] T004 [US1] Update AddFillUpViewModel save method to pass fuelType and note to FillUp constructor in Fuel/ViewModels/AddFillUpViewModel.swift
- [x] T005 [US1] Reorder AddFillUpView form sections to: Vehicle selector → Odometer → Fuel Type (editable Picker, prefilled) → Price per unit → Volume → Total Cost → Full Tank toggle → Note field. Add FuelType picker using FuelType.allCases in Fuel/Views/AddFillUpView.swift
- [x] T006 [US1] Wire vehicle change in AddFillUpView to trigger fuel type prefill update: when selectedVehicle changes, set fuelType to vehicle.fuelType (or nil if not configured) in Fuel/Views/AddFillUpView.swift

**Checkpoint**: User Story 1 fully functional — fill-up form has new layout with fuel type prefill

---

## Phase 3: User Story 2 - Optional Notes on Fill-Ups (Priority: P2)

**Goal**: Users can add/view optional notes on fill-ups

**Independent Test**: Add fill-up with note "Highway trip" → View in history → Note text visible → Add fill-up without note → No note indicator

### Implementation for User Story 2

- [x] T007 [US2] Add note TextField to AddFillUpView form (below Full Tank toggle) with placeholder "Add a note (optional)" and 200-character limit with visible counter in Fuel/Views/AddFillUpView.swift
- [x] T008 [US2] Update FillUpRow in FillUpListView to display note text (when present) as a secondary line below the existing row content in Fuel/Views/FillUpListView.swift

**Checkpoint**: Both user stories functional — fill-ups can be logged with prefilled fuel type and optional notes

---

## Phase 4: Polish & Cross-Cutting Concerns

- [x] T009 Ensure fuel type prefill handles nil gracefully: when vehicle has no fuel type configured, fuel type picker shows "Not set" and is fully editable in Fuel/Views/AddFillUpView.swift
- [x] T010 Verify that existing fill-ups (without note/fuelType) display correctly in history — no crashes or blank fields for nil values in Fuel/Views/FillUpListView.swift

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — model changes first
- **User Story 1 (Phase 2)**: Depends on Foundational (FillUp model must have new fields)
- **User Story 2 (Phase 3)**: Depends on Foundational; can run in parallel with US1 but touches same files
- **Polish (Phase 4)**: Depends on both user stories

### User Story Dependencies

- **User Story 1 (P1)**: Needs FillUp.fuelType field → Foundational
- **User Story 2 (P2)**: Needs FillUp.note field → Foundational. Touches AddFillUpView (same as US1) so best done sequentially after US1.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (model fields)
2. Complete Phase 2: User Story 1 (reorder + prefill)
3. **STOP and VALIDATE**: Fuel type prefills correctly, form order matches spec
4. Deploy/demo if ready

### Incremental Delivery

1. Foundational → FillUp model extended
2. User Story 1 → Prefilled form (MVP)
3. User Story 2 → Notes support
4. Polish → Nil handling, legacy compatibility

---

## Notes

- All tasks modify existing files — no new files needed
- AddFillUpView.swift is touched by both US1 and US2 — must be done sequentially
- SwiftData lightweight migration handles new optional fields automatically
