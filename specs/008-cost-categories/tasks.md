# Tasks: Vehicle Cost Categories

**Input**: Design documents from `specs/008-cost-categories/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ui-contract.md ✅

**Organization**: 3 user stories — foundational model work first, then incrementally add US1 (log cost), US2 (per-vehicle filter), US3 (category summary).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[US1]**: Log a Non-Fuel Vehicle Cost
- **[US2]**: View Costs Per Vehicle
- **[US3]**: View Cost Summary by Category

---

## Phase 1: Setup

No project setup required — existing iOS project.

*No tasks needed.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: New data model and app container setup. ALL user stories depend on this phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Create `CostCategory` enum (Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets) in `Fuel/Models/CostCategory.swift`
- [x] T002 [P] Create `CostEntry` SwiftData `@Model` (id, date, category, amount, note?, vehicle?, createdAt) in `Fuel/Models/CostEntry.swift`
- [x] T003 Add `costEntries: [CostEntry]` cascade-delete relationship to `Vehicle` in `Fuel/Models/Vehicle.swift` (depends on T002)
- [x] T004 Add `CostEntry.self` to the `modelContainer` array in `Fuel/FuelApp.swift` (depends on T002)

**Checkpoint**: Build succeeds — SwiftData schema includes `CostEntry`. No runtime changes yet.

---

## Phase 3: User Story 1 - Log a Non-Fuel Vehicle Cost (Priority: P1) 🎯 MVP

**Goal**: Users can add, view, and delete non-fuel cost entries on the Costs tab. Empty state guides first-time use.

**Independent Test**: Tap Costs tab → see empty state → tap "Add Cost" → select "Insurance", enter amount, tap Save → entry appears in list with category and amount → swipe to delete → entry removed.

### Implementation for User Story 1

- [x] T005 [P] [US1] Create `CostListViewModel` (`@Observable`, fetch all cost entries for a vehicle, delete method) in `Fuel/ViewModels/CostListViewModel.swift`
- [x] T006 [P] [US1] Create `AddCostViewModel` (`@Observable`, form state: category, amountText, date, noteText; `isValid`, `save()`) in `Fuel/ViewModels/AddCostViewModel.swift`
- [x] T007 [US1] Create `AddCostView` (sheet: Form with category Picker, amount TextField, DatePicker, optional note TextField; Cancel/Save toolbar buttons) in `Fuel/Views/AddCostView.swift` (depends on T006)
- [x] T008 [US1] Create `CostListView` (NavigationStack with ZStack layout, floating "+" button, vehicle name in toolbar, EmptyStateView with wrench icon, swipe-to-delete, `setupIfNeeded()` pattern matching FillUpListView) in `Fuel/Views/CostListView.swift` (depends on T005, T007)
- [x] T009 [US1] Replace `VehicleListView()` with `CostListView()` in the Costs tab in `Fuel/Views/ContentView.swift` (depends on T008)

**Checkpoint**: Build and run. Costs tab shows empty state → add entry → entry listed → swipe delete works.

---

## Phase 4: User Story 2 - View Costs Per Vehicle (Priority: P2)

**Goal**: When multiple vehicles exist, a vehicle picker in the Costs tab toolbar filters cost entries to the selected vehicle.

**Independent Test**: With 2 vehicles and cost entries for each, switch vehicle in picker — list updates to show only that vehicle's costs.

### Implementation for User Story 2

- [x] T010 [US2] Add `@Query` vehicle list and `selectedVehicle` state to `CostListView`; `.principal` toolbar shows `Picker` when `vehicles.count > 1`, static vehicle name `Text` when count == 1; `onChange(of: vehicles)` sets `selectedVehicle` when nil (fixes @Query async load race); update `CostListViewModel.fetchCosts(for:)` to filter by vehicle — in `Fuel/Views/CostListView.swift` and `Fuel/ViewModels/CostListViewModel.swift` (depends on T008, T005)

**Checkpoint**: With 2+ vehicles, picker appears in Costs toolbar; switching vehicle filters the list correctly.

---

## Phase 5: User Story 3 - View Cost Summary by Category (Priority: P3)

**Goal**: A "Total" section at the top of the Costs list shows the sum of all cost entries for the selected vehicle.

**Independent Test**: With entries across multiple categories, the Total section shows the correct sum. Adding or deleting entries updates the total.

### Implementation for User Story 3

- [x] T011 [US3] Add a "Total" `Section` to the `List` in `CostListView` displaying `LabeledContent("Total Spent") { formatted total }` computed from `CostListViewModel.totalAmount` — in `Fuel/Views/CostListView.swift` and `Fuel/ViewModels/CostListViewModel.swift` (depends on T010)

**Checkpoint**: Total section visible above cost entries; value matches sum of all displayed entries.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T012 [P] Add `systemImage` parameter to `EmptyStateView` (default `"fuelpump"`) and pass `"wrench.and.screwdriver"` in `CostListView` empty states — in `Fuel/Views/Components/EmptyStateView.swift` and `Fuel/Views/CostListView.swift`
- [ ] T013 [P] Verify cost list, add form, and delete all work correctly in Dark Mode
- [ ] T014 [P] Verify vehicle picker appears/hides correctly with 1 vs 2+ vehicles

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 2 (Foundational)
    └─▶ Phase 3 (US1) — BLOCKS all story phases
            └─▶ Phase 4 (US2) — depends on CostListView + ViewModel from US1
                    └─▶ Phase 5 (US3) — depends on vehicle filtering from US2
                            └─▶ Phase 6 (Polish)
```

### Within Phase 2 (Foundational)

- T001, T002 → parallel (different files)
- T003 → after T002 (needs CostEntry type)
- T004 → after T002 (needs CostEntry type)

### Within Phase 3 (US1)

- T005, T006 → parallel (different files)
- T007 → after T006 (needs AddCostViewModel)
- T008 → after T005 + T007 (needs both ViewModel and AddCostView)
- T009 → after T008 (needs CostListView)

### Parallel Opportunities

```
Phase 2: T001 ‖ T002 → then T003 ‖ T004
Phase 3: T005 ‖ T006 → T007 → T008 → T009
Phase 6: T012 ‖ T013 ‖ T014
```

---

## Parallel Example: Phase 2

```
Launch simultaneously:
  Task T001: Create CostCategory.swift
  Task T002: Create CostEntry.swift

After both complete, launch simultaneously:
  Task T003: Update Vehicle.swift (add relationship)
  Task T004: Update FuelApp.swift (add to container)
```

---

## Implementation Strategy

### MVP (User Story 1 Only — P1)

1. Complete Phase 2: T001 → T002 → T003 ‖ T004
2. Complete Phase 3: T005 ‖ T006 → T007 → T008 → T009
3. **Validate checkpoint**: Costs tab fully functional for single-vehicle users
4. Stop here if needed — US1 alone is a shippable increment

### Full Delivery

1. MVP (above) → validate US1
2. Phase 4 (T010): Add vehicle picker — validate US2
3. Phase 5 (T011): Add total summary — validate US3
4. Phase 6 (T012–T014): Polish

---

## Notes

- Total tasks: 14 (4 foundational + 5 US1 + 1 US2 + 1 US3 + 3 polish)
- `VehicleListView` is NOT deleted — it remains in the codebase, just unmounted from the Costs tab
- `AddCostViewModel.save()` must set `entry.vehicle = selectedVehicle` before inserting
- Currency formatting should follow the same pattern used in `FillUpListView` (e.g., `String(format: "%.2f", amount)`)
- `CostCategory` raw values should be lowercase strings matching the enum case names for `Codable` compatibility
