# Tasks: Fuel Cost Tracker

**Input**: Design documents from `specs/001-fuel-cost-tracker/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Xcode project initialization and basic structure

- [x] T001 Create Xcode project "Fuel" with iOS 17.0 deployment target, SwiftUI lifecycle in Fuel/FuelApp.swift
- [x] T002 [P] Create folder structure: Fuel/Models/, Fuel/ViewModels/, Fuel/Views/, Fuel/Views/Components/, Fuel/Services/, Fuel/Resources/
- [x] T003 [P] Create test targets: FuelTests/ (XCTest) and FuelUITests/ (XCUITest)
- [x] T004 [P] Configure Assets.xcassets with accent color and app icon placeholder in Fuel/Resources/Assets.xcassets

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: SwiftData models and core services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Create Vehicle SwiftData model with fields: id (UUID), name (String), initialOdometer (Double), lastUsedAt (Date), createdAt (Date), and fillUps relationship (cascade delete) in Fuel/Models/Vehicle.swift
- [x] T006 [P] Create FillUp SwiftData model with fields: id (UUID), date (Date), pricePerLiter (Double), volume (Double), totalCost (Double), odometerReading (Double), isFullTank (Bool default true), efficiency (Double optional), createdAt (Date), and vehicle relationship in Fuel/Models/FillUp.swift
- [x] T007 Configure ModelContainer with Vehicle and FillUp schemas in Fuel/FuelApp.swift (inject into environment)
- [x] T008 Implement EfficiencyCalculator service with method to compute L/100km using full-tank-to-full-tank accumulation algorithm in Fuel/Services/EfficiencyCalculator.swift
- [x] T009 [P] Create EmptyStateView component accepting title, message, and action button label in Fuel/Views/Components/EmptyStateView.swift
- [x] T010 [P] Create EfficiencyBadge component displaying L/100km value (or "—" when nil) in Fuel/Views/Components/EfficiencyBadge.swift

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Log a Fuel Fill-Up (Priority: P1) 🎯 MVP

**Goal**: User can add, view, edit, and delete fuel fill-up entries for any vehicle

**Independent Test**: Open app → add vehicle → tap "+" → enter fill-up data → save → see entry in history list

### Implementation for User Story 1

- [x] T011 [US1] Implement VehicleViewModel (@Observable) with CRUD operations (add, edit, delete vehicle) and "last used" query in Fuel/ViewModels/VehicleViewModel.swift
- [x] T012 [US1] Implement AddFillUpViewModel (@Observable) with auto-calculation logic (two-of-three: price×volume=total), field validation, odometer monotonic check, and save with efficiency computation in Fuel/ViewModels/AddFillUpViewModel.swift
- [x] T013 [US1] Implement FillUpListViewModel (@Observable) with @Query for fill-ups sorted by date desc, filtered by selected vehicle, and delete/edit support in Fuel/ViewModels/FillUpListViewModel.swift
- [x] T014 [P] [US1] Create VehicleListView with add/edit/delete vehicle UI, shown on first launch or from settings in Fuel/Views/VehicleListView.swift
- [x] T015 [US1] Create AddFillUpView as a sheet with: vehicle picker (default last used), date picker (default now), price/liter field, volume field, total cost field (auto-calc), odometer field, full-tank toggle (default on), and Save button in Fuel/Views/AddFillUpView.swift
- [x] T016 [US1] Create FillUpListView as the home screen with: navigation title, list of fill-ups showing date/volume/cost/efficiency badge, floating "+" overlay button triggering AddFillUpView sheet, empty state when no entries, swipe-to-delete in Fuel/Views/FillUpListView.swift
- [x] T017 [US1] Wire FillUpListView as root view in FuelApp.swift with NavigationStack and vehicle filtering

**Checkpoint**: User Story 1 fully functional — can add vehicles, log fill-ups, view history, edit and delete entries

---

## Phase 4: User Story 2 — View Fuel Efficiency (Priority: P2)

**Goal**: User sees L/100km calculated for each full-tank entry and average efficiency in summary

**Independent Test**: Log two full-tank fill-ups with different odometer readings → efficiency badge shows correct L/100km on second entry

### Implementation for User Story 2

- [x] T018 [US2] Enhance FillUpListView to display EfficiencyBadge on each fill-up row showing computed efficiency or "—" for partial/first entries in Fuel/Views/FillUpListView.swift
- [x] T019 [US2] Add efficiency recalculation on fill-up edit and delete (cascade recompute next full-tank entry) in Fuel/ViewModels/FillUpListViewModel.swift
- [x] T020 [US2] Add "needs second fill-up" hint in EfficiencyBadge when only one fill-up exists for a vehicle in Fuel/Views/Components/EfficiencyBadge.swift

**Checkpoint**: Efficiency calculation working — displays correctly for full-tank entries, handles partial fill accumulation

---

## Phase 5: User Story 3 — View Expense Summary (Priority: P3)

**Goal**: User sees monthly spending breakdown and total fuel costs with average efficiency

**Independent Test**: Log fill-ups across multiple months → navigate to summary → see monthly totals matching manual addition

### Implementation for User Story 3

- [x] T021 [US3] Implement SummaryViewModel (@Observable) with monthly aggregation (total cost, total volume, average efficiency, fill-up count) and all-time totals in Fuel/ViewModels/SummaryViewModel.swift
- [x] T022 [US3] Create SummaryView with: monthly cost bar chart (Swift Charts), monthly breakdown list (month name, total cost, total liters, avg efficiency), all-time totals section, empty state in Fuel/Views/SummaryView.swift
- [x] T023 [US3] Add navigation bar button on FillUpListView linking to SummaryView in Fuel/Views/FillUpListView.swift

**Checkpoint**: All user stories independently functional — full expense tracking with efficiency and summaries

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality, accessibility, and responsive design validation

- [x] T024 [P] Add Dynamic Type support verification — ensure all text uses scalable fonts and layouts adapt in all views
- [x] T025 [P] Add Dark Mode support — verify all custom colors have dark variants in Fuel/Resources/Assets.xcassets
- [x] T026 [P] Add VoiceOver accessibility labels to all interactive elements (buttons, badges, form fields) across all views
- [x] T027 [P] Verify landscape orientation layout on iPhone and iPad — fix any clipping or overflow issues
- [x] T028 Write unit tests for EfficiencyCalculator: full-tank-to-full-tank, partial fill accumulation, single entry (nil), delete cascade in FuelTests/EfficiencyCalculatorTests.swift
- [x] T029 [P] Write unit tests for AddFillUpViewModel: auto-calculation logic, validation rules, odometer check in FuelTests/AddFillUpViewModelTests.swift
- [x] T030 [P] Write unit tests for SummaryViewModel: monthly aggregation accuracy, empty state in FuelTests/SummaryViewModelTests.swift
- [x] T031 Write UI test for complete fill-up flow: launch → add vehicle → add fill-up → verify in list in FuelUITests/FillUpFlowUITests.swift
- [x] T032 Run quickstart.md verification checklist end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on Phase 3 (builds on FillUpListView and efficiency logic)
- **User Story 3 (Phase 5)**: Depends on Phase 2 only (can run in parallel with US2)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — No dependencies on other stories
- **User Story 2 (P2)**: Enhances US1 views — depends on US1 completion
- **User Story 3 (P3)**: Can start after Foundational — independent of US1/US2 (only reads data)

### Within Each User Story

- ViewModels before Views (Views depend on ViewModel interface)
- Core logic before UI integration
- Story complete before moving to next priority

### Parallel Opportunities

- T002, T003, T004 can run in parallel (Setup phase)
- T005, T006 can run in parallel (Models)
- T009, T010 can run in parallel (Components)
- T014 can run in parallel with T015 (different view files)
- T024, T025, T026, T027 can run in parallel (independent quality checks)
- T028, T029, T030 can run in parallel (independent test files)
- US3 (Phase 5) can run in parallel with US2 (Phase 4) if desired

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test fill-up logging independently
5. App is usable as a basic fuel log

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → MVP (fuel logging)
3. Add User Story 2 → Test independently → Efficiency tracking
4. Add User Story 3 → Test independently → Expense summaries
5. Polish → Production-ready quality

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
