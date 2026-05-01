# Tasks: Vehicle Tab

**Input**: Design documents from `specs/002-vehicle-tab/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested in the feature specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Enum types and model extensions that all user stories depend on

- [x] T001 [P] Create FuelType enum (pb95, pb98, diesel, lpg, ev, cng) conforming to String, Codable, CaseIterable in Fuel/Models/FuelType.swift
- [x] T002 [P] Create DistanceUnit enum (kilometers, miles) conforming to String, Codable, CaseIterable in Fuel/Models/DistanceUnit.swift
- [x] T003 [P] Create FuelUnit enum (liters, gallons, kilowattHours) conforming to String, Codable, CaseIterable in Fuel/Models/FuelUnit.swift
- [x] T004 [P] Create EfficiencyDisplayFormat enum (litersPer100km, kwhPer100km, mpg, kmPerLiter) conforming to String, Codable, CaseIterable in Fuel/Models/EfficiencyDisplayFormat.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Vehicle model extension and TabView navigation that MUST be complete before user story work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Extend Vehicle model with optional fields (make: String?, model: String?, descriptionText: String?, distanceUnit: DistanceUnit?, fuelType: FuelType?, fuelUnit: FuelUnit?, efficiencyDisplayFormat: EfficiencyDisplayFormat?) in Fuel/Models/Vehicle.swift
- [x] T006 Add static compatibility mapping to FuelType: a computed property `compatibleFuelUnits: [FuelUnit]` returning [.kilowattHours] for .ev and [.liters, .gallons] for all others in Fuel/Models/FuelType.swift
- [x] T007 Create ContentView with TabView (3 tabs: History/FillUpListView, Vehicles/VehicleListView, Summary/SummaryView) in Fuel/Views/ContentView.swift
- [x] T008 Update FuelApp.swift to use ContentView as the root view instead of directly showing FillUpListView in Fuel/FuelApp.swift

**Checkpoint**: Foundation ready - TabView navigation works, Vehicle model has new optional fields, enums are defined

---

## Phase 3: User Story 1 - Add a New Vehicle (Priority: P1) 🎯 MVP

**Goal**: Users can navigate to the Vehicle tab and add a new vehicle with all enhanced fields

**Independent Test**: Navigate to Vehicles tab → Tap Add → Fill form (name + optional fields) → Save → Vehicle appears in list

### Implementation for User Story 1

- [x] T009 [P] [US1] Create FuelUnitPicker component that accepts a Binding<FuelType?> and filters displayed fuel units based on compatibility mapping in Fuel/Views/Components/FuelUnitPicker.swift
- [x] T010 [P] [US1] Create VehicleFormView with fields: name (TextField, required), make (TextField), model (TextField), descriptionText (TextField), distanceUnit (Picker), fuelType (Picker), fuelUnit (FuelUnitPicker), efficiencyDisplayFormat (Picker). Include validation (disable Save when name is empty) in Fuel/Views/VehicleFormView.swift
- [x] T011 [US1] Update VehicleViewModel to add a `createVehicle` method that accepts all new fields and persists via ModelContext in Fuel/ViewModels/VehicleViewModel.swift
- [x] T012 [US1] Update VehicleListView to display vehicles with name, make/model subtitle, and fuel type badge. Add toolbar button to present VehicleFormView in sheet for adding in Fuel/Views/VehicleListView.swift
- [x] T013 [US1] Add empty state to VehicleListView when no vehicles exist, prompting user to add their first vehicle in Fuel/Views/VehicleListView.swift

**Checkpoint**: User Story 1 fully functional — users can add vehicles with all fields via the Vehicle tab

---

## Phase 4: User Story 2 - Edit an Existing Vehicle (Priority: P2)

**Goal**: Users can view vehicle details and edit any field

**Independent Test**: Tap vehicle in list → See details → Tap Edit → Change a field → Save → Change persists in list

### Implementation for User Story 2

- [x] T014 [US2] Create VehicleDetailView showing all vehicle properties (name, make, model, description, distance units, fuel type, fuel units, efficiency format) with an Edit button in toolbar in Fuel/Views/VehicleDetailView.swift
- [x] T015 [US2] Update VehicleFormView to support edit mode: accept an optional existing Vehicle, pre-populate fields, and update (not create) on save in Fuel/Views/VehicleFormView.swift
- [x] T016 [US2] Update VehicleViewModel to add an `updateVehicle` method that saves modified fields in Fuel/ViewModels/VehicleViewModel.swift
- [x] T017 [US2] Wire VehicleListView row tap to navigate to VehicleDetailView in Fuel/Views/VehicleListView.swift
- [x] T018 [US2] Handle fuel type change in edit: when fuel type changes, reset fuelUnit if current selection is incompatible in Fuel/Views/VehicleFormView.swift

**Checkpoint**: User Stories 1 AND 2 work independently — vehicles can be added and edited

---

## Phase 5: User Story 3 - Delete a Vehicle (Priority: P3)

**Goal**: Users can delete a vehicle with confirmation, cascading to fill-ups

**Independent Test**: Swipe to delete → Confirmation dialog appears → Confirm → Vehicle and fill-ups removed → List updates

### Implementation for User Story 3

- [x] T019 [US3] Add swipe-to-delete action on VehicleListView rows with confirmation alert warning about fill-up data loss in Fuel/Views/VehicleListView.swift
- [x] T020 [US3] Update VehicleViewModel to add a `deleteVehicle` method (cascade delete handled by SwiftData relationship rule) in Fuel/ViewModels/VehicleViewModel.swift
- [x] T021 [US3] Handle deletion of the last vehicle: after delete, VehicleListView shows empty state in Fuel/Views/VehicleListView.swift

**Checkpoint**: All user stories independently functional — full vehicle CRUD via dedicated tab

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T022 [P] Update EfficiencyCalculator to support multiple display formats using vehicle's efficiencyDisplayFormat (with nil fallback to L/100km) in Fuel/Services/EfficiencyCalculator.swift
- [x] T023 [P] Ensure fill-up form and history views respect the selected vehicle's distance and fuel units (nil defaults to km/liters) in Fuel/Views/AddFillUpView.swift and Fuel/ViewModels/AddFillUpViewModel.swift
- [x] T024 Add warning when user changes distance/fuel units on a vehicle that already has fill-ups in Fuel/Views/VehicleFormView.swift
- [x] T025 Verify VoiceOver accessibility on VehicleFormView, VehicleDetailView, and VehicleListView — ensure all pickers and buttons are labeled in Fuel/Views/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - all enum files can be created in parallel
- **Foundational (Phase 2)**: Depends on Phase 1 (enums must exist before Vehicle model uses them)
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 → US2 → US3 is the recommended sequential order
  - US2 depends on US1 (VehicleFormView shared)
  - US3 is independent of US2 but benefits from US1's list view
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Creates VehicleFormView and list
- **User Story 2 (P2)**: Depends on US1 (reuses VehicleFormView in edit mode)
- **User Story 3 (P3)**: Depends on US1 (needs VehicleListView with rows to delete)

### Within Each User Story

- Components (FuelUnitPicker) before forms (VehicleFormView)
- ViewModel methods before view wiring
- Core functionality before edge case handling

### Parallel Opportunities

- T001-T004: All enum files in parallel
- T009-T010: FuelUnitPicker and VehicleFormView can start in parallel (picker feeds into form)
- T022-T023: Cross-cutting efficiency and unit display updates in parallel

---

## Parallel Example: Phase 1 Setup

```bash
# All enum files are independent — create in parallel:
Task: "Create FuelType enum in Fuel/Models/FuelType.swift"
Task: "Create DistanceUnit enum in Fuel/Models/DistanceUnit.swift"
Task: "Create FuelUnit enum in Fuel/Models/FuelUnit.swift"
Task: "Create EfficiencyDisplayFormat enum in Fuel/Models/EfficiencyDisplayFormat.swift"
```

## Parallel Example: User Story 1

```bash
# Component and form can start in parallel:
Task: "Create FuelUnitPicker in Fuel/Views/Components/FuelUnitPicker.swift"
Task: "Create VehicleFormView in Fuel/Views/VehicleFormView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (enums)
2. Complete Phase 2: Foundational (model extension + TabView)
3. Complete Phase 3: User Story 1 (add vehicle)
4. **STOP and VALIDATE**: Test adding a vehicle via the new tab
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready (TabView works, model extended)
2. Add User Story 1 → Test independently → MVP (vehicle creation)
3. Add User Story 2 → Test independently → Full edit capability
4. Add User Story 3 → Test independently → Complete CRUD
5. Polish phase → Efficiency format support, accessibility
6. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- SwiftData handles lightweight migration automatically for new optional Vehicle fields
- All nil-field paths must default to km/liters/L100km (backward compatibility)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
