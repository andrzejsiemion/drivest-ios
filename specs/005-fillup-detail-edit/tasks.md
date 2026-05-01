# Tasks: Fill-Up Detail & Edit

**Input**: Design documents from `specs/005-fillup-detail-edit/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested. Test tasks omitted.

**Organization**: Tasks grouped by user story.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: User Story 1 - View Fill-Up Details (Priority: P1) 🎯 MVP

**Goal**: Users tap a fill-up row in history to see a detail screen with all fields

**Independent Test**: Add fill-ups → Tap one in list → Detail screen shows date, vehicle, odometer, fuel type, price, volume, total, full tank, efficiency, note

### Implementation for User Story 1

- [x] T001 [P] [US1] Create FillUpDetailView showing all FillUp fields in a read-only List with labeled sections: date/time, vehicle name, odometer, fuel type (if set), price per unit, volume, total cost, full tank status, efficiency (if calculated), and note (if present). Include an "Edit" toolbar button. File: Fuel/Views/FillUpDetailView.swift
- [x] T002 [US1] Update FillUpRow in FillUpListView to wrap each row in a NavigationLink that pushes to FillUpDetailView, passing the FillUp. Add navigationDestination for FillUp in Fuel/Views/FillUpListView.swift
- [x] T003 [US1] Add FillUpDetailView.swift to the Xcode project build sources in Fuel.xcodeproj/project.pbxproj

**Checkpoint**: User Story 1 functional — tapping a fill-up shows full detail screen

---

## Phase 2: User Story 2 - Edit a Fill-Up (Priority: P2)

**Goal**: Users can edit an existing fill-up from the detail screen

**Independent Test**: Detail screen → Edit → Change price → Total auto-recalculates → Save → Updated values in detail + history list

### Implementation for User Story 2

- [x] T004 [P] [US2] Create EditFillUpViewModel that: (a) initializes with an existing FillUp and pre-populates all text fields, (b) includes the same auto-calculation logic as AddFillUpViewModel, (c) validates odometer against both previous AND next fill-ups by date, (d) on save: updates the FillUp entity, calls EfficiencyCalculator.recalculateAll for the vehicle, saves context. File: Fuel/ViewModels/EditFillUpViewModel.swift
- [x] T005 [P] [US2] Create EditFillUpView with a Form matching AddFillUpView layout but: no vehicle picker (show vehicle name as read-only text), all other fields editable and pre-populated, Cancel/Save toolbar buttons. File: Fuel/Views/EditFillUpView.swift
- [x] T006 [US2] Wire FillUpDetailView's Edit button to present EditFillUpView as a sheet, passing the FillUp and refreshing the detail view on dismiss in Fuel/Views/FillUpDetailView.swift
- [x] T007 [US2] Add EditFillUpViewModel.swift and EditFillUpView.swift to the Xcode project build sources in Fuel.xcodeproj/project.pbxproj

**Checkpoint**: Both user stories functional — fill-ups can be viewed in detail and edited

---

## Phase 3: Polish & Cross-Cutting Concerns

- [x] T008 Verify efficiency recalculation after edit: change volume on a full-tank entry, save, confirm efficiency updates for that entry and subsequent entries in Fuel/Views/FillUpDetailView.swift
- [x] T009 Verify nil-safe display: view detail of a legacy fill-up (no note, no fuelType) — confirm no crashes or broken layout in Fuel/Views/FillUpDetailView.swift

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1 (Phase 1)**: No dependencies — can start immediately
- **US2 (Phase 2)**: Depends on US1 (detail screen must exist for Edit button)
- **Polish (Phase 3)**: Depends on both user stories

### User Story Dependencies

- **US1**: Independent — creates FillUpDetailView + list navigation
- **US2**: Depends on US1 (edit is launched from detail screen)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Detail view + list navigation
2. **STOP and VALIDATE**: Tap fill-up → All data visible
3. Deploy/demo if ready

### Incremental Delivery

1. US1 → Detail screen (MVP)
2. US2 → Edit capability
3. Polish → Edge case verification

---

## Notes

- No model changes needed — operates on existing FillUp entity
- EditFillUpViewModel duplicates auto-calc logic from AddFillUpViewModel (acceptable for ~30 lines; extracting a shared protocol is optional future cleanup)
- Vehicle is NOT editable on edit (per spec assumption)
