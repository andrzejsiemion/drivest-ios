# Tasks: UI Polish Improvements

**Input**: Design documents from `specs/014-ui-polish/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

*(No setup tasks required — no new files, no new dependencies, no project structure changes.)*

---

## Phase 2: Foundational

*(No foundational prerequisites — all three user stories are independent and can be implemented in any order.)*

---

## Phase 3: User Story 1 — Fuel Price Precision per Currency (Priority: P1) 🎯 MVP

**Goal**: Fill-up list rows display price per litre with 2 decimal places for PLN (and all non-EUR currencies) and 3 decimal places for EUR

**Independent Test**: Add a fill-up in PLN at 6.459/L → list shows "6.46/L". Add a fill-up in EUR at 1.699/L → list shows "1.699/L". Add a fill-up with no currency → list shows "%.2f" format.

### Implementation for User Story 1

- [X] T001 [US1] In `FillUpRow.body`, replace the hardcoded `"%.2f L @ %.3f/L"` format string in `Fuel/Views/FillUpListView.swift` — compute a `priceFormat` constant as `fillUp.currencyCode == "EUR" ? "%.3f" : "%.2f"` and use `String(format: "%.2f L @ \(priceFormat)/L", fillUp.volume, fillUp.pricePerLiter)` so EUR shows 3 decimal places and all other currencies (including nil) show 2 decimal places

**Checkpoint**: EUR fill-ups show 3dp price; all other fill-ups show 2dp price. Legacy entries unchanged.

---

## Phase 4: User Story 2 — Settings Inline Category Management (Priority: P2)

**Goal**: Remove the misleading `+` button from the Settings navigation bar; provide an "Add Category" row inline at the bottom of the Categories section

**Independent Test**: Open Settings → no `+` in top nav bar. Scroll to Categories → "Add Category" row visible at bottom. Tap it → AddCategoryView sheet opens. Existing delete/reorder still works.

### Implementation for User Story 2

- [X] T002 [US2] Remove the `ToolbarItem(placement: .primaryAction)` block (the `+` button) from `SettingsView.toolbar` in `Fuel/Views/SettingsView.swift`
- [X] T003 [US2] Add a `Button` row at the end of the Categories `Section` in `SettingsView`, after the `ForEach`/`.onDelete` block, with label `Label("Add Category", systemImage: "plus.circle.fill")` that sets `showAddCategory = true` — in `Fuel/Views/SettingsView.swift`

**Checkpoint**: `+` gone from nav bar. "Add Category" row visible in Categories section. Tapping opens same sheet as before.

---

## Phase 5: User Story 3 — Fill-Up Detail Compact Layout (Priority: P3)

**Goal**: Eliminate the three redundant label pairs in Fill-Up Details (Date/Date, Vehicle/Vehicle, Odometer/Reading) by merging them into a single compact section

**Independent Test**: Open any fill-up detail. "Date" appears once. "Vehicle" appears once. "Odometer" label (not "Reading") appears once. All values still displayed. No section header that echoes the row label.

### Implementation for User Story 3

- [X] T004 [US3] In `FillUpDetailView.body`, replace the three separate `Section("Date")`, `Section("Vehicle")`, and `Section("Odometer")` blocks with a single `Section { }` (no header) containing three `LabeledContent` rows: `LabeledContent("Date")`, `LabeledContent("Vehicle", value: vehicle.name)`, and `LabeledContent("Odometer")` — rename the existing "Reading" label to "Odometer" — in `Fuel/Views/FillUpDetailView.swift`

**Checkpoint**: Fill-Up Details shows a clean compact info group at top with Date, Vehicle, Odometer each appearing exactly once.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T005 Build the project and confirm zero errors (`xcodebuild`) across all modified files
- [X] T006 [P] Verify fill-up list renders correctly on iPhone SE simulator (small screen — price with symbol fits in one line)
- [X] T007 [P] Verify fill-up list and detail render correctly on iPhone 17 Pro Max simulator (large screen)

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1, US2, US3**: Fully independent — each touches a different file. All three can be implemented in parallel.
- **Polish (Phase 6)**: Depends on all three stories being complete.

### Parallel Opportunities

- T001, T002+T003, T004 can all run in parallel (different files)
- T006 and T007 can run in parallel (different simulators)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001: Update price format in `FillUpListView.swift`
2. **STOP and VALIDATE**: Add EUR fill-up, verify 3dp; add PLN fill-up, verify 2dp
3. Demo if ready

### Incremental Delivery

1. T001 → Price precision ✓
2. T002–T003 → Settings clean-up ✓
3. T004 → Detail compaction ✓
4. T005–T007 → Build + device check ✓

### Parallel Team Strategy

All three user stories can be assigned to different developers simultaneously — zero file overlap.

---

## Notes

- T001: `fillUp.currencyCode` is `String?`; `nil != "EUR"` evaluates to `true` so legacy entries safely use 2dp
- T002+T003: `showAddCategory` state and `AddCategoryView` sheet are unchanged — only the trigger location moves
- T004: The `if let vehicle = fillUp.vehicle` guard moves into the combined section (not lost)
- No model changes, no ViewModel changes, no new files
