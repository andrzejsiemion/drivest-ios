# Tasks: Cost Category Settings

**Input**: Design documents from `specs/009-cost-category-settings/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ui-contract.md ✅

**Organization**: 2 user stories — foundational store + injection first, then US1 (toggle categories), US2 (data integrity verification).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[US1]**: Enable/Disable Cost Categories
- **[US2]**: Protect Existing Cost Entries

---

## Phase 1: Setup

No project setup required — existing iOS project.

*No tasks needed.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared preferences store + Xcode registration + environment injection. ALL user stories depend on this phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Create `CategorySettingsStore` (`@Observable` final class, `disabledCategories: Set<String>` backed by UserDefaults key `"disabledCostCategories"`, `enabledCategories: [CostCategory]` computed, `isEnabled(_:) -> Bool`, `toggle(_:)`) in `Fuel/Models/CategorySettingsStore.swift`
- [x] T002 [P] Register `CategorySettingsStore.swift` (IDs A10000076/A20000076, Models group) and `SettingsView.swift` (IDs A10000077/A20000077, Views group) in `Fuel.xcodeproj/project.pbxproj` — add PBXBuildFile, PBXFileReference, group children, and AA0000001 sources entries
- [x] T003 Inject `CategorySettingsStore()` into SwiftUI environment (`.environment(CategorySettingsStore())`) in `Fuel/FuelApp.swift` (depends on T001)

**Checkpoint**: Build succeeds — `CategorySettingsStore` compiles, environment injection in place.

---

## Phase 3: User Story 1 - Enable/Disable Cost Categories (Priority: P1) 🎯 MVP

**Goal**: Users open Settings via ··· on any tab, toggle categories on/off; disabled categories disappear from the Add Cost picker immediately and persist across launches.

**Independent Test**: Any tab → tap ··· → tap "Settings" → toggle "Tolls" off → Done → Costs tab → tap + → confirm "Tolls" absent from category picker → force-quit and relaunch → confirm "Tolls" still absent.

### Implementation for User Story 1

- [x] T004 [US1] Create `SettingsView` (sheet with `NavigationStack`, title "Settings", "Done" `ToolbarItem(.confirmationAction)`, `Form` with Section "Cost Categories" containing `ForEach(CostCategory.allCases)` rows of `Toggle` + `Label(displayName, systemImage)` bound to `@Environment(CategorySettingsStore.self)`) in `Fuel/Views/SettingsView.swift` (depends on T001)
- [x] T005 [P] [US1] Add `@State private var showSettings = false`, "Settings" `Label("Settings", systemImage: "gearshape")` button as first item in the existing `Menu`, and `.sheet(isPresented: $showSettings) { SettingsView() }` in `Fuel/Views/FillUpListView.swift` (depends on T004)
- [x] T006 [P] [US1] Add `@State private var showSettings = false`, "Settings" `Label("Settings", systemImage: "gearshape")` button as first item in the existing `Menu`, and `.sheet(isPresented: $showSettings) { SettingsView() }` in `Fuel/Views/CostListView.swift` (depends on T004)
- [x] T007 [P] [US1] Add `@State private var showSettings = false`, "Settings" `Label("Settings", systemImage: "gearshape")` button as first item in the existing `Menu`, and `.sheet(isPresented: $showSettings) { SettingsView() }` in `Fuel/Views/ContentView.swift` `SummaryTabView` (depends on T004)
- [x] T008 [US1] Add `@Environment(CategorySettingsStore.self) private var settings` to `AddCostView`; replace `ForEach(CostCategory.allCases)` in the Category `Picker` with `ForEach(settings.enabledCategories)`; when `settings.enabledCategories.isEmpty`, replace the Picker with a `Text("No categories available.")` + `Text("Enable categories in Settings (···).")` and ensure `isValid` stays false in `Fuel/Views/AddCostView.swift` (depends on T001, T004)

**Checkpoint**: Build and run. ··· menu on all tabs shows "Settings" above "Manage Vehicles". Toggle off a category → Add Cost picker excludes it. Relaunch → preference persisted.

---

## Phase 4: User Story 2 - Protect Existing Cost Entries (Priority: P2)

**Goal**: Disabling a category never removes or hides existing `CostEntry` records in the Costs list.

**Independent Test**: Log a cost entry with "Wash" → Settings → disable "Wash" → return to Costs tab → confirm the "Wash" entry is still fully visible.

### Implementation for User Story 2

- [x] T009 [US2] Verify `CostListViewModel.fetchCosts(for:)` fetches all `CostEntry` records without filtering by category — confirm no category filter exists and add none; if any accidental filter is found, remove it in `Fuel/ViewModels/CostListViewModel.swift` (read-only verification unless a bug is found)

**Checkpoint**: Existing cost entries with disabled categories remain fully visible in the Costs list.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [ ] T010 [P] Verify Settings preference persists after force-quit and relaunch on iPhone simulator
- [ ] T011 [P] Verify SettingsView renders correctly in Dark Mode on iPhone SE and iPhone 15 Pro Max simulators

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 2 (Foundational)
    └─▶ Phase 3 (US1) — BLOCKS all story phases
            └─▶ Phase 4 (US2) — verification only, no code dep on US1
                    └─▶ Phase 5 (Polish)
```

### Within Phase 2 (Foundational)

- T001, T002 → parallel (different files)
- T003 → after T001 (needs CategorySettingsStore type)

### Within Phase 3 (US1)

- T004 → after T001 (needs CategorySettingsStore in environment)
- T005, T006, T007 → parallel after T004 (different files, same change pattern)
- T008 → after T001 + T004 (needs store type and SettingsView to exist)

### Parallel Opportunities

```
Phase 2: T001 ‖ T002 → then T003
Phase 3: T004 → then T005 ‖ T006 ‖ T007 (simultaneously) → T008
Phase 5: T010 ‖ T011
```

---

## Implementation Strategy

### MVP (User Story 1 Only — P1)

1. Complete Phase 2: T001 ‖ T002 → T003
2. Complete Phase 3: T004 → T005 ‖ T006 ‖ T007 → T008
3. **Validate checkpoint**: Settings accessible from all tabs, category filtering works, persists across launches

### Full Delivery

1. MVP (above) → validate US1
2. Phase 4 (T009): Verify data integrity — validate US2
3. Phase 5 (T010–T011): Polish

---

## Notes

- Total tasks: 11 (3 foundational + 5 US1 + 1 US2 + 2 polish)
- New Xcode project IDs: CategorySettingsStore.swift = A10000076/A20000076 (Models group A80000003); SettingsView.swift = A10000077/A20000077 (Views group A80000005)
- `SettingsView` reads/writes `CategorySettingsStore` via `@Environment(CategorySettingsStore.self)` — no ViewModel needed (simple toggle list)
- Menu item order per ui-contract.md: "Settings" first, "Manage Vehicles" second
- UserDefaults key `"disabledCostCategories"` stores `[String]` of disabled raw values; empty array = all enabled (correct first-launch default)
- `AddCostView` must handle the edge case where `enabledCategories` is empty — show inline prompt, keep Save disabled
