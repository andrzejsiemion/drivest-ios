# Tasks: Odometer Chart on Statistics Page

**Input**: Design documents from `specs/024-odometer-chart/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅ quickstart.md ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify Swift Charts is importable; no new packages to add (Apple framework).

- [X] T001 Verify Swift Charts framework availability — open Xcode, confirm `import Charts` compiles in a test file then remove it (no file change needed; Charts is bundled with iOS 16+ SDK already present)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The `OdometerDataPoint` value type and `SummaryViewModel` chart extensions are shared by both user stories. Must be complete before either story can be built.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 Create `OdometerDataPoint` struct in `Fuel/Models/OdometerDataPoint.swift` — value type with `date: Date` and `odometer: Double` fields; no persistence annotation
- [X] T003 Add `chartPeriod: StatisticsTimePeriod` property (default `.allTime`) and `chartPoints: [OdometerDataPoint]` property to `SummaryViewModel` in `Fuel/ViewModels/SummaryViewModel.swift`
- [X] T004 Add `loadChart(for vehicle: Vehicle?)` method to `SummaryViewModel` in `Fuel/ViewModels/SummaryViewModel.swift` — filters vehicle's fill-ups by `chartPeriod` date range, converts odometer to `vehicle.effectiveDistanceUnit` (divide by 1.60934 for miles), sorts ascending by date, maps to `[OdometerDataPoint]`, assigns to `chartPoints`

**Checkpoint**: `SummaryViewModel` can compute chart data — both user stories can now proceed.

---

## Phase 3: User Story 1 — View Odometer Progress Over Time (Priority: P1) 🎯 MVP

**Goal**: A line chart of odometer readings vs. time appears on the Statistics page for the selected vehicle, with auto-scaled Y-axis and appropriate empty states.

**Independent Test**: Navigate to Statistics tab with a vehicle that has ≥2 fill-ups → line chart is visible with correct km/mi values and readable date labels on X-axis; switch to a vehicle with 0 fill-ups → empty state message appears.

### Implementation for User Story 1

- [X] T005 [US1] Create `OdometerChartView` struct in `Fuel/Views/Components/OdometerChartView.swift` — SwiftUI View accepting `points: [OdometerDataPoint]`, `unit: DistanceUnit`, `period: Binding<StatisticsTimePeriod>`; renders a Swift Charts `Chart` with `LineMark(x: .value("Date", point.date), y: .value(unit.abbreviation, point.odometer))` over `points`; chart height 220pt; Y-axis auto-scale with `.chartYScale(domain: .automatic)`; X-axis date labels using `.chartXAxis`
- [X] T006 [US1] Add empty-state handling to `OdometerChartView` in `Fuel/Views/Components/OdometerChartView.swift` — when `points.isEmpty` show `ContentUnavailableView`-style VStack with bolt/chart icon and message "Add fill-ups to see odometer progress." (zero fill-ups case handled separately from period-filter empty case — see T011)
- [X] T007 [US1] Embed `OdometerChartView` as first `Section` in the `List` inside `SummaryTabView` in `Fuel/Views/ContentView.swift` — pass `points: viewModel.chartPoints`, `unit: store.selectedVehicle?.effectiveDistanceUnit ?? .kilometers`, `period: $viewModel.chartPeriod`; no section header
- [X] T008 [US1] Call `viewModel.loadChart(for: store.selectedVehicle)` in the existing `onAppear` handler in `SummaryTabView` in `Fuel/Views/ContentView.swift` — alongside the existing `loadSummary` call
- [X] T009 [US1] Call `viewModel.loadChart(for: store.selectedVehicle)` in the existing `onChange(of: store.selectedVehicle)` handler in `SummaryTabView` in `Fuel/Views/ContentView.swift` — ensures chart updates when vehicle changes

**Checkpoint**: US1 fully functional — line chart visible with real data, empty state works, vehicle switch updates chart.

---

## Phase 4: User Story 2 — Adjust the Time Range (Priority: P2)

**Goal**: A segmented picker above the chart lets the user select Last Month / Last Year / All Time; the chart and axes update immediately.

**Independent Test**: With chart visible, tap each time-range segment in turn → chart data and X-axis span update to match the selected period; selecting a period with no data shows "No data for this period." message.

### Implementation for User Story 2

- [X] T010 [US2] Add `Picker` (`.pickerStyle(.segmented)`) above the `Chart` in `OdometerChartView` in `Fuel/Views/Components/OdometerChartView.swift` — iterates `StatisticsTimePeriod.chartCases` (see T011), bound to `period`; placed in a `VStack` wrapping the existing chart body
- [X] T011 [US2] Add a `chartCases` static property to `StatisticsTimePeriod` in `Fuel/Models/StatisticsTimePeriod.swift` returning `[.month, .year, .allTime]` — used by the picker to enumerate the three display options; also add a `chartLabel: String` computed property returning localised display names ("Last Month", "Last Year", "All Time")
- [X] T012 [US2] Add period-filter empty state to `OdometerChartView` in `Fuel/Views/Components/OdometerChartView.swift` — when `points.isEmpty` AND the parent has fill-ups (i.e. period filter is the cause), show "No data for this period." message; distinguish from the zero-fill-ups case by receiving a `hasFillUps: Bool` parameter passed from the parent
- [X] T013 [US2] Update `SummaryTabView` in `Fuel/Views/ContentView.swift` to pass `hasFillUps: viewModel.chartPoints.isEmpty && (store.selectedVehicle?.fillUps.isEmpty == false)` — wait, simpler: pass `hasFillUps: !(store.selectedVehicle?.fillUps.isEmpty ?? true)` to `OdometerChartView`
- [X] T014 [US2] Call `viewModel.loadChart(for: store.selectedVehicle)` inside an `onChange(of: viewModel.chartPeriod)` handler in `SummaryTabView` in `Fuel/Views/ContentView.swift` — ensures chart recomputes when user taps a different time-range segment
- [X] T015 [US2] Add Polish translations for new strings in `Fuel/Resources/Localizable.xcstrings` — "Last Month" (already exists ✅), "Last Year" (already exists ✅), "All Time" (already exists ✅); add if missing: "No data for this period." → "Brak danych dla tego okresu.", "Add fill-ups to see odometer progress." → "Dodaj tankowania, aby zobaczyć postęp licznika."

**Checkpoint**: US1 + US2 complete — chart renders, time-range picker works, all empty states handled, Polish strings present.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, Dark Mode verification, localisation final check, landscape layout.

- [X] T016 [P] Verify `OdometerChartView` renders correctly in Dark Mode in `Fuel/Views/Components/OdometerChartView.swift` — use system semantic colours only (no hardcoded `Color.white` / `Color.black`); Swift Charts uses adaptive colours by default
- [X] T017 [P] Verify chart is usable in landscape on iPhone SE (small screen) — chart height 220pt remains fully visible above the fold without scroll in `Fuel/Views/Components/OdometerChartView.swift`
- [ ] T018 Run all 5 quickstart scenarios from `specs/024-odometer-chart/quickstart.md` manually and confirm each passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — verify Charts availability immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — T002 → T003 → T004 (sequential, same file for T003/T004)
- **US1 (Phase 3)**: Depends on Phase 2 (T002, T004) — T005 → T006 (same file, sequential) → T007, T008, T009 (ContentView, can be done together)
- **US2 (Phase 4)**: Depends on Phase 3 — T010, T011 in parallel → T012, T013, T014 sequential → T015
- **Polish (Phase 5)**: Depends on Phase 4

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational phase — independently testable
- **US2 (P2)**: Depends on US1 (`OdometerChartView` must exist before adding the picker to it)

### Parallel Opportunities

- T003 and T002 can be done simultaneously (different files)
- T008 and T009 can be written at the same time (same file, same `onAppear`/`onChange` block)
- T010 and T011 can be done simultaneously (different files)
- T016 and T017 can be verified in parallel

---

## Parallel Example: Foundational Phase

```text
Parallel batch:
  Task T002: Create OdometerDataPoint.swift (Models/)
  Task T003: Add chart properties to SummaryViewModel.swift (ViewModels/)
Then sequential:
  Task T004: Add loadChart() to SummaryViewModel.swift
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002 → T003 → T004)
3. Complete Phase 3: User Story 1 (T005 → T006 → T007 → T008 → T009)
4. **STOP and VALIDATE**: Line chart visible with real data; empty state works; vehicle switch updates chart
5. Ship as MVP — users get chart visibility immediately

### Incremental Delivery

1. MVP as above (US1) → chart visible, no time-range control yet (defaults to All Time)
2. Add US2 (T010–T015) → time-range picker enabled
3. Polish (T016–T018) → accessibility and layout verified

---

## Notes

- No new Swift Package Manager dependencies — Swift Charts is bundled with the iOS SDK
- `StatisticsTimePeriod` already exists; only `chartCases` and `chartLabel` extensions are new
- `OdometerDataPoint` is a plain struct (no `@Model`) — zero SwiftData migration risk
- Polish translations for "Last Month", "Last Year", "All Time" already exist in `Localizable.xcstrings`
- Commit after each phase checkpoint
