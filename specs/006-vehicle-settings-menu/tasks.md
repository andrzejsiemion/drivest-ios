# Tasks: Vehicle Settings Menu

**Input**: Design documents from `specs/006-vehicle-settings-menu/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ui-contract.md ✅

**Organization**: Single user story — tasks are linear (one file change).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[US1]**: User Story 1 — Access Vehicle Management via Settings Menu

---

## Phase 1: Setup

**Purpose**: No project setup required — this is a modification to an existing, fully-initialized iOS project.

*No tasks needed.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No shared infrastructure changes required — no new models, services, or dependencies.

*No tasks needed.*

---

## Phase 3: User Story 1 - Access Vehicle Management via Settings Menu (Priority: P1) 🎯 MVP

**Goal**: Replace the standalone "+" toolbar button with a SwiftUI `Menu` (ellipsis icon) containing an "Add Vehicle" option. Preserve the empty state's direct "Add Vehicle" button.

**Independent Test**: Navigate to the Vehicles tab → tap `ellipsis.circle` icon in top-right → see "Add Vehicle" menu item → tap it → vehicle form sheet appears. Confirm no standalone "+" button is visible in the populated list toolbar.

### Implementation for User Story 1

- [x] T001 [US1] Replace toolbar `Button` with `Menu` containing "Add Vehicle" action in `Fuel/Views/VehicleListView.swift`

**Checkpoint**: After T001 — build and run on simulator. Verify:
1. Populated list: `ellipsis.circle` icon visible top-right; no `+` button
2. Tap menu → "Add Vehicle" option appears
3. Tap "Add Vehicle" → sheet presents correctly
4. Empty state: direct "Add Vehicle" button still visible; menu also available

---

## Phase 4: Polish & Cross-Cutting Concerns

- [ ] T002 [P] Verify layout on iPhone SE simulator (small screen — menu icon must not overlap navigation title)
- [ ] T003 [P] Verify layout on iPhone 15 Pro Max simulator (large screen)
- [ ] T004 [P] Verify Dark Mode renders `ellipsis.circle` icon correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 3)**: No dependencies — start immediately
- **Polish (Phase 4)**: Depends on T001 complete

### Within User Story 1

- T001 is a single atomic change; no internal dependencies

### Parallel Opportunities

- T002, T003, T004 (Polish) can all run in parallel after T001

---

## Parallel Example: Polish Phase

```
After T001 completes, launch simultaneously:
  Task T002: Verify iPhone SE layout
  Task T003: Verify iPhone 15 Pro Max layout
  Task T004: Verify Dark Mode
```

---

## Implementation Strategy

### MVP (This feature IS the MVP)

1. Complete T001 — single file edit
2. Validate at checkpoint
3. Run T002–T004 in parallel
4. Done

### T001 Detail

In `Fuel/Views/VehicleListView.swift`, change lines 48–56:

**Before**:
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

**After**:
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

---

## Notes

- Total tasks: 4 (1 implementation + 3 polish/verification)
- All existing functionality (sheet, empty state, swipe-delete, navigation) is unchanged
- No ViewModel, model, or service files are modified
- Constitution compliance: single-responsibility, SwiftUI-native, no new dependencies
