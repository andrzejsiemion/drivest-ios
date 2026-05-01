# Tasks: Rename Bottom Tab Labels

**Input**: Design documents from `specs/007-rename-bottom-tabs/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ui-contract.md ✅

**Organization**: Single user story — 7 string literal changes across 4 files. Tasks are [P] (parallelizable) where files are independent.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[US1]**: User Story 1 — Renamed Bottom Tab Labels

---

## Phase 1: Setup

No project setup required — modification to an existing, fully-initialized iOS project.

*No tasks needed.*

---

## Phase 2: Foundational (Blocking Prerequisites)

No shared infrastructure changes required.

*No tasks needed.*

---

## Phase 3: User Story 1 - Renamed Bottom Tab Labels (Priority: P1) 🎯 MVP

**Goal**: Replace all 7 display string literals ("History", "Vehicles", "Summary") with the new labels ("Fuel", "Costs", "Statistics") across tab items and navigation titles.

**Independent Test**: Launch the app → bottom tab bar shows "Fuel", "Costs", "Statistics" → tap each tab → navigation title inside each tab matches the tab label.

### Implementation for User Story 1

- [x] T001 [P] [US1] Rename tab labels "History"→"Fuel", "Vehicles"→"Costs", "Summary"→"Statistics" and navigationTitle "Summary"→"Statistics" in `Fuel/Views/ContentView.swift`
- [x] T002 [P] [US1] Rename navigationTitle "History"→"Fuel" in `Fuel/Views/FillUpListView.swift`
- [x] T003 [P] [US1] Rename navigationTitle "Vehicles"→"Costs" in `Fuel/Views/VehicleListView.swift`
- [x] T004 [P] [US1] Rename navigationTitle "Summary"→"Statistics" in `Fuel/Views/SummaryView.swift`

**Checkpoint**: After T001–T004 — build and run on simulator. Verify:
1. Bottom tab bar shows: "Fuel" | "Costs" | "Statistics"
2. Tab icons unchanged (fuelpump, car.2, chart.bar)
3. Tapping "Fuel" → screen title reads "Fuel"
4. Tapping "Costs" → screen title reads "Costs"
5. Tapping "Statistics" → screen title reads "Statistics"

---

## Phase 4: Polish & Cross-Cutting Concerns

- [ ] T005 [P] Verify tab labels are not truncated on iPhone SE (small screen)
- [ ] T006 [P] Verify tab labels render correctly in Dark Mode
- [ ] T007 [P] Verify VoiceOver reads updated tab names ("Fuel", "Costs", "Statistics")

---

## Dependencies & Execution Order

### Phase Dependencies

- **User Story 1 (Phase 3)**: No dependencies — all 4 tasks can start immediately and run in parallel
- **Polish (Phase 4)**: Depends on all of T001–T004 complete

### Within User Story 1

- T001, T002, T003, T004 are all [P] — different files, no shared state, run simultaneously

### Parallel Opportunities

- T001, T002, T003, T004 run in parallel (4 independent files)
- T005, T006, T007 run in parallel after all implementation tasks complete

---

## Parallel Example: User Story 1

```
Launch all 4 implementation tasks simultaneously:
  Task T001: ContentView.swift — 4 string changes
  Task T002: FillUpListView.swift — 1 string change
  Task T003: VehicleListView.swift — 1 string change
  Task T004: SummaryView.swift — 1 string change
```

---

## Implementation Strategy

### MVP (This feature IS the MVP)

1. Complete T001–T004 in parallel — ~7 string literal replacements total
2. Validate at checkpoint
3. Run T005–T007 in parallel
4. Done

### T001 Detail (ContentView.swift)

Change all 4 strings in `Fuel/Views/ContentView.swift`:
- `Label("History", systemImage: "fuelpump")` → `Label("Fuel", systemImage: "fuelpump")`
- `Label("Vehicles", systemImage: "car.2")` → `Label("Costs", systemImage: "car.2")`
- `Label("Summary", systemImage: "chart.bar")` → `Label("Statistics", systemImage: "chart.bar")`
- `.navigationTitle("Summary")` (inside SummaryTabView) → `.navigationTitle("Statistics")`

---

## Notes

- Total tasks: 7 (4 implementation + 3 polish/verification)
- All [P] implementation tasks touch different files — zero conflicts
- Internal Swift type names (`VehicleListView`, `SummaryViewModel`, etc.) are NOT renamed
- Empty state message in FillUpListView ("Add a vehicle in the Vehicles tab…") is left unchanged — it refers to tab content, not the label
