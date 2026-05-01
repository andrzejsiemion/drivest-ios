# Tasks: Vehicle Selector & Sort Order

**Input**: Design documents from `/specs/010-vehicle-selector-sort/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ui-contract.md ✓

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- No test tasks (not requested in spec)

---

## Phase 1: Setup

**Purpose**: Register new Swift files in Xcode project before any code is written.

- [X] T001 Register 3 new Swift files in Fuel.xcodeproj/project.pbxproj: VehicleSortOrder.swift (PBXBuildFile A10000080/PBXFileReference A20000080 → Models group A80000002), VehicleSelectionStore.swift (A10000081/A20000081 → Services group A80000004), VehiclePickerCard.swift (A10000082/A20000082 → Components group A80000007)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared infrastructure that all three user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Create VehicleSortOrder enum with cases alphabetical/dateAdded/lastUsed/custom, rawValue String, Identifiable, CaseIterable, and user-facing `label` computed property in Fuel/Models/VehicleSortOrder.swift
- [X] T003 Create VehicleSelectionStore @Observable class with properties: `selectedVehicle: Vehicle?`, `sortOrder: VehicleSortOrder` (UserDefaults key "vehicleSortOrder"), `customOrder: [UUID]` (UserDefaults key "customVehicleOrder" JSON-encoded), `selectedVehicleID: String` (UserDefaults key "selectedVehicleID"); implement `sortedVehicles(_ vehicles: [Vehicle]) -> [Vehicle]` returning vehicles sorted per sortOrder (lastUsed = by lastUsedAt desc, alphabetical = by name, dateAdded = by createdAt, custom = by customOrder position); implement `selectVehicle(_ vehicle: Vehicle)` updating selectedVehicle and persisting UUID; implement `restoreSelection(from vehicles: [Vehicle])` matching stored UUID; implement `updateCustomOrder(_ vehicles: [Vehicle])` encoding to UserDefaults in Fuel/Services/VehicleSelectionStore.swift
- [X] T004 Instantiate VehicleSelectionStore as a `private let store = VehicleSelectionStore()` in FuelApp and inject via `.environment(store)` on the WindowGroup in Fuel/FuelApp.swift

**Checkpoint**: Foundation ready — all tabs can now access VehicleSelectionStore via @Environment.

---

## Phase 3: User Story 1 — Rich Vehicle Selector Widget (Priority: P1) 🎯 MVP

**Goal**: Replace the plain-text toolbar vehicle name and Picker with a rich card component showing vehicle photo, name, and odometer at the top of each main tab.

**Independent Test**: Open the Fuel tab — a card appears below the navigation bar showing a circular vehicle photo (or car icon placeholder), bold vehicle name, odometer reading, and a chevron (if multiple vehicles). Tapping the card shows a sheet listing all vehicles.

### Implementation

- [X] T005 [US1] Create VehiclePickerCard view struct with parameters `vehicle: Vehicle`, `currentOdometer: Double`, `isInteractive: Bool`, `onTap: () -> Void`; layout: HStack with 64×64 circular photo (from vehicle.photoData or car.fill placeholder on accent background) + VStack(name bold/headline, odometer secondary caption) + Spacer + optional chevron.right; entire card wrapped in Button when isInteractive; card background Color(.secondarySystemGroupedBackground) with cornerRadius 12 and padding in Fuel/Views/Components/VehiclePickerCard.swift
- [X] T006 [US1] Update FillUpListView: add `@Environment(VehicleSelectionStore.self) private var store`; remove `@State private var selectedVehicle`; replace toolbar .principal Picker with nothing; add first Section (no title) inside List containing VehiclePickerCard(vehicle: store.selectedVehicle, currentOdometer: computedOdometer, isInteractive: vehicles.count > 1, onTap: { showVehiclePicker = true }); add `@State private var showVehiclePicker = false` and `.sheet(isPresented: $showVehiclePicker)` showing a NavigationStack List of vehicles (sorted via store.sortedVehicles) where tapping calls store.selectVehicle and dismisses; add helper `var computedOdometer: Double` returning max fill-up odometer or initialOdometer; update setupIfNeeded() to use store.selectedVehicle; update all references from selectedVehicle to store.selectedVehicle in Fuel/Views/FillUpListView.swift
- [X] T007 [US1] Apply the same VehiclePickerCard integration to CostListView: @Environment store, remove local selectedVehicle state, add card Section, add showVehiclePicker sheet, update all selectedVehicle references to store.selectedVehicle, add computedOdometer helper in Fuel/Views/CostListView.swift
- [X] T008 [US1] Apply the same VehiclePickerCard integration to SummaryTabView: @Environment store, add card as first Section in the List (or above existing content), add showVehiclePicker sheet, update viewModel.loadSummary to use store.selectedVehicle; add onChange(of: store.selectedVehicle) to reload summary in Fuel/Views/ContentView.swift

**Checkpoint**: All three tabs show the rich vehicle card. Tapping it presents a vehicle picker sheet. Single-vehicle users see the card without a chevron.

---

## Phase 4: User Story 2 — Shared Vehicle Selection Across Tabs (Priority: P2)

**Goal**: Selecting a vehicle on any tab updates the selection on all other tabs immediately.

**Independent Test**: Open Fuel tab, select Vehicle B (if multiple vehicles exist). Switch to Costs tab — Vehicle B's card is shown without needing any additional action.

**Note**: US2 is structurally complete once all tabs read from the same VehicleSelectionStore instance (done in US1). This phase adds launch restoration and verifies correct reactive behavior.

### Implementation

- [X] T009 [US2] Implement restoreSelection(from:) call in FuelApp after store creation: call store.restoreSelection(from: container.mainContext fetch of all vehicles) so the last-selected vehicle is pre-selected on cold launch in Fuel/FuelApp.swift
- [X] T010 [US2] Add onChange(of: store.selectedVehicle) handlers in FillUpListView and CostListView to refresh their respective data (fetchFillUps / fetchCosts) when the store's selection changes; this ensures list content updates reactively when selection changes on another tab in Fuel/Views/FillUpListView.swift and Fuel/Views/CostListView.swift
- [X] T011 [US2] Verify that when a vehicle is deleted (via VehicleListView), VehicleSelectionStore.selectedVehicle is updated to vehicles.first (or nil); add an onChange(of: vehicles) in each tab view that calls `if store.selectedVehicle == nil || !vehicles.contains(store.selectedVehicle!) { store.selectVehicle(vehicles.first ?? ...) }` to handle deletion gracefully in Fuel/Views/FillUpListView.swift, Fuel/Views/CostListView.swift, Fuel/Views/ContentView.swift

**Checkpoint**: Switching tabs preserves vehicle selection. Deleting the active vehicle auto-selects the next available one. App restart restores last selection.

---

## Phase 5: User Story 3 — Vehicle Sort Order Preference (Priority: P3)

**Goal**: Users can choose in Settings how vehicles appear in the picker list: Alphabetically, by Date Added, by Last Used, or in a Custom drag order.

**Independent Test**: Open Settings → Vehicle Order section shows Sort By picker with 4 options. Select "Alphabetical" — open the vehicle picker on the Fuel tab — vehicles are listed A–Z. Select "Custom" → Edit Order button appears → navigate to reorder screen → drag to reorder → return → picker shows custom order.

### Implementation

- [X] T012 [US3] Add Vehicle Order section to SettingsView after the Categories section: `Section("Vehicle Order")` containing a Picker("Sort By", selection: $store.sortOrder) with ForEach(VehicleSortOrder.allCases) showing order.label; below the picker, if store.sortOrder == .custom show a NavigationLink("Edit Order") to VehicleReorderView; requires adding `@Environment(VehicleSelectionStore.self) private var store` in Fuel/Views/SettingsView.swift
- [X] T013 [US3] Implement VehicleReorderView as a private struct at the bottom of SettingsView.swift: @Environment store, @Query all vehicles, compute display order from store.customOrder (vehicles not yet in customOrder appended at end); List with ForEach showing vehicle name + .onMove modifier that calls store.updateCustomOrder with the reordered array; toolbar Edit/Done button to toggle editMode in Fuel/Views/SettingsView.swift
- [X] T014 [US3] Update vehicle picker sheets in FillUpListView, CostListView, and SummaryTabView to display vehicles using store.sortedVehicles(vehicles) instead of the raw vehicles array, so the picker respects the sort preference in Fuel/Views/FillUpListView.swift, Fuel/Views/CostListView.swift, Fuel/Views/ContentView.swift

**Checkpoint**: All sort orders work in the vehicle picker. Custom order survives app restart. New vehicles added after setting custom order appear at the bottom.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T015 [P] Verify VehiclePickerCard renders correctly in Dark Mode on both small (iPhone SE) and large (iPhone 15 Pro Max) simulators
- [X] T016 [P] Verify empty state: when no vehicles exist, tabs show EmptyStateView (not a card); when all vehicles are deleted, card disappears and empty state appears
- [X] T017 Verify "Last Used" sort order: selectVehicle() in VehicleSelectionStore should update vehicle.lastUsedAt and save via modelContext so lastUsed ordering reflects actual selection history; if lastUsedAt update is missing, add modelContext to VehicleSelectionStore and call save after updating in Fuel/Services/VehicleSelectionStore.swift

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (pbxproj must exist for files to compile)
- **US1 (Phase 3)**: Depends on Phase 2 (VehiclePickerCard + store must exist)
- **US2 (Phase 4)**: Depends on Phase 3 (all tabs must use store before sharing works)
- **US3 (Phase 5)**: Depends on Phase 2 (store must exist); can run in parallel with US1/US2 for the SettingsView work, but picker sheet update (T014) depends on US1 completing
- **Polish (Phase 6)**: Depends on all prior phases

### Within Each Phase

- T002 (enum) can run in parallel with any other Phase 1 tasks
- T003 (store) must follow T002 (uses VehicleSortOrder)
- T004 (injection) must follow T003
- T005 (card component) can start as soon as Phase 2 completes
- T006, T007, T008 (tab integration) can run in parallel after T005

### Parallel Opportunities

```
Phase 2: T002 [P] ──→ T003 ──→ T004 (sequential chain)
Phase 3: T005 ──→ T006 [P]
                 T007 [P]   (T006/T007/T008 in parallel)
                 T008 [P]
Phase 6: T015 [P], T016 [P] (independent verifications)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Phase 1: Setup (pbxproj)
2. Complete Phase 2: Foundation (enum + store + injection)
3. Complete Phase 3: US1 (card component + tab integration)
4. **STOP and VALIDATE**: Rich card visible on all tabs, picker sheet works
5. Continue to US2 and US3

### Incremental Delivery

1. Phase 1+2 → compiles cleanly
2. Phase 3 → visually complete card on all tabs (MVP)
3. Phase 4 → selection persists across tabs and app restarts
4. Phase 5 → sort order preference in Settings
5. Phase 6 → polish verified

---

## Notes

- [P] tasks = different files, no blocking dependencies
- VehicleSelectionStore needs access to ModelContext only if updating vehicle.lastUsedAt — check if this is needed in T017
- SourceKit may show transient "Cannot find X in scope" errors after each edit — these are indexing artifacts, not real compiler errors; build in Xcode to verify
- The pbxproj group IDs (A80000002, A80000004, A80000007) must match the existing Models, Services, and Components groups — verify against current pbxproj before inserting
