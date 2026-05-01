# Tasks: Statistics Time Filter

**Input**: Design documents from `specs/011-statistics-time-filter/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create the new model file and register it in the project

- [x] T001 Create `StatisticsTimePeriod` enum with cases `.week`, `.month`, `.year`, `.allTime`, `.custom(start: Date, end: Date)` in Fuel/Models/StatisticsTimePeriod.swift
- [x] T002 Add `dateRange` computed property returning `(start: Date?, end: Date?)` to `StatisticsTimePeriod` — use `Calendar.date(byAdding:)` for week (-7 days), month (-1 month), year (-1 year); `allTime` returns `(nil, nil)`; `custom` returns provided dates with auto-swap if start > end. File: Fuel/Models/StatisticsTimePeriod.swift
- [x] T003 Add `displayName` computed property to `StatisticsTimePeriod` returning user-facing labels ("Week", "Month", "Year", "All Time", "Custom") in Fuel/Models/StatisticsTimePeriod.swift
- [x] T004 Register StatisticsTimePeriod.swift in Fuel.xcodeproj/project.pbxproj (PBXBuildFile, PBXFileReference, Models group, Sources build phase)

**Checkpoint**: New enum compiles and is available for use

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Update the ViewModel query layer to accept a time period parameter — MUST complete before any UI work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Change `SummaryViewModel.loadSummary(for:)` signature to `loadSummary(for:period:)` accepting a `StatisticsTimePeriod` parameter in Fuel/ViewModels/SummaryViewModel.swift
- [x] T006 Add date filtering to the `#Predicate` in `loadSummary(for:period:)` — compute `startDate`/`endDate` from period's `dateRange` and add `>= startDate` / `<= endDate` conditions to the existing vehicle-scoped fetch descriptor in Fuel/ViewModels/SummaryViewModel.swift
- [x] T007 Update `SummaryView.onAppear` to pass `.allTime` as the period parameter to `loadSummary(for:period:)` in Fuel/Views/SummaryView.swift

**Checkpoint**: ViewModel accepts period parameter, all existing callers compile, data filtering works at query level

---

## Phase 3: User Story 1 — Quick Time Period Selection (Priority: P1) 🎯 MVP

**Goal**: Users can tap preset filter options (Week, Month, Year, All Time) to instantly filter statistics

**Independent Test**: Select each preset option and verify displayed statistics match the expected date range

### Implementation for User Story 1

- [x] T008 [US1] Add `@State private var selectedPeriod: StatisticsTimePeriod = .allTime` to `SummaryTabView` in Fuel/Views/ContentView.swift
- [x] T009 [US1] Add a segmented `Picker` with options Week/Month/Year/All Time between VehiclePickerCard and the statistics List in `SummaryTabView` — use `.pickerStyle(.segmented)` with `.background(Color(.systemGroupedBackground))` in Fuel/Views/ContentView.swift
- [x] T010 [US1] Wire `onChange(of: selectedPeriod)` to call `viewModel?.loadSummary(for: store.selectedVehicle, period: selectedPeriod)` in Fuel/Views/ContentView.swift
- [x] T011 [US1] Update existing `onChange(of: store.selectedVehicle)` and `onAppear` to pass `selectedPeriod` to `loadSummary(for:period:)` in Fuel/Views/ContentView.swift
- [x] T012 [US1] Update the section header from hardcoded "All Time" to reflect the active filter's `displayName` in `SummaryContentSection` in Fuel/Views/ContentView.swift
- [x] T013 [US1] Update empty state message to "No fill-ups in the selected period." when a filter is active (not `.allTime`) in Fuel/Views/ContentView.swift

**Checkpoint**: User can tap Week/Month/Year/All Time and statistics update immediately. MVP complete.

---

## Phase 4: User Story 2 — Custom Date Range Selection (Priority: P2)

**Goal**: Users can select "Custom" and pick start/end dates to define an arbitrary time range

**Independent Test**: Select "Custom", pick start and end dates, verify statistics reflect only fill-ups within that range

### Implementation for User Story 2

- [x] T014 [US2] Add "Custom" option to the segmented `Picker` alongside the preset options in Fuel/Views/ContentView.swift
- [x] T015 [US2] Add `@State private var customStartDate: Date` and `@State private var customEndDate: Date` to `SummaryTabView` (default to 30 days ago / today) in Fuel/Views/ContentView.swift
- [x] T016 [US2] Add conditional inline `DatePicker` controls for start and end dates — visible only when `selectedPeriod` is `.custom`; use `.datePickerStyle(.compact)` with animated reveal in Fuel/Views/ContentView.swift
- [x] T017 [US2] Wire custom date picker `onChange` handlers to update `selectedPeriod` to `.custom(start: customStartDate, end: customEndDate)` and reload summary in Fuel/Views/ContentView.swift
- [x] T018 [US2] Add date validation — auto-swap start/end if start > end (already in enum's `dateRange`, ensure UI reflects swapped values) in Fuel/Views/ContentView.swift

**Checkpoint**: User can select Custom, pick dates, and see filtered statistics. US1 + US2 both work.

---

## Phase 5: User Story 3 — Persistent Filter Selection (Priority: P3)

**Goal**: Selected filter persists across tab switches within the same app session

**Independent Test**: Select a filter, switch to another tab, return to Statistics, verify filter is still active

### Implementation for User Story 3

- [x] T019 [US3] Verify that `@State selectedPeriod` in `SummaryTabView` persists across tab switches — since `SummaryTabView` is a direct child of `TabView` in `ContentView`, `@State` naturally persists. Confirm by testing tab switching in Fuel/Views/ContentView.swift
- [x] T020 [US3] Verify that `selectedPeriod` resets to `.allTime` on fresh app launch — since `@State` initializer is `.allTime`, this is automatic. Confirm no `@AppStorage` or persistent storage is used for the filter in Fuel/Views/ContentView.swift

**Checkpoint**: Filter persists within session, resets on relaunch. All 3 user stories complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, responsiveness, and edge case handling

- [x] T021 Add accessibility labels to the segmented control options ("Last Week", "Last Month", "Last Year", "All Time", "Custom Range") in Fuel/Views/ContentView.swift
- [x] T022 Verify layout on iPhone SE (small) and iPhone 15 Pro Max (large) — ensure segmented control doesn't truncate and date pickers fit in Fuel/Views/ContentView.swift
- [x] T023 Verify Dark Mode renders correctly for the filter control and date pickers in Fuel/Views/ContentView.swift

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001-T004) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (T005-T007)
- **User Story 2 (Phase 4)**: Depends on Phase 3 (US1 provides the segmented picker that US2 extends)
- **User Story 3 (Phase 5)**: Depends on Phase 3 (needs the filter state to exist)
- **Polish (Phase 6)**: Depends on Phase 4 completion

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — independent
- **US2 (P2)**: Depends on US1 (extends the picker with a Custom option)
- **US3 (P3)**: Depends on US1 (verifies persistence of the filter state US1 creates)

### Within Each User Story

- Models → ViewModel → View (data flows down)
- Each story builds on the previous incrementally

### Parallel Opportunities

- T001, T002, T003 can be done in a single pass (same file)
- T005, T006 are sequential (same file, same method)
- T008–T013 are sequential (same file, building on each other)
- US3 tasks (T019, T020) are verification-only and can run in parallel

---

## Parallel Example: User Story 1

```bash
# All US1 tasks are in the same file (ContentView.swift) so they run sequentially:
T008 → T009 → T010 → T011 → T012 → T013
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (create StatisticsTimePeriod enum)
2. Complete Phase 2: Foundational (update ViewModel + SummaryView)
3. Complete Phase 3: User Story 1 (add segmented picker to SummaryTabView)
4. **STOP and VALIDATE**: Test preset filters independently
5. Demo if ready

### Incremental Delivery

1. Setup + Foundational → Enum + ViewModel ready
2. Add User Story 1 → Preset filters work → MVP!
3. Add User Story 2 → Custom date range works
4. Add User Story 3 → Verify session persistence
5. Polish → Accessibility, responsive layout, dark mode

---

## Notes

- All view changes are in a single file (ContentView.swift) so most tasks are sequential
- The enum (StatisticsTimePeriod) is the only new file; everything else is modifications
- SwiftData `#Predicate` handles date filtering at the query level (no in-memory filtering)
- `@State` provides session persistence for free; no extra storage mechanism needed
- pbxproj registration (T004) requires careful handling — use Python script for tab-indented file
