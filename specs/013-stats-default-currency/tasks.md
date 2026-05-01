# Tasks: Statistics in Default Currency with Historical Exchange Rates

**Input**: Design documents from `specs/013-stats-default-currency/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: No new files or infrastructure needed — this feature is purely additive display changes to two existing views.

*(No setup tasks required — all models, settings, and ViewModel logic are already in place from feature 012-dual-currency.)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify all prerequisites from feature 012 are in place before adding display labels.

**⚠️ CRITICAL**: Confirm these before proceeding

- [X] T001 Verify `FillUp.currencyCode: String?` and `FillUp.exchangeRate: Double?` exist and compile in Fuel/Models/FillUp.swift
- [X] T002 Verify `SummaryViewModel.convertedCost(for:)` uses `fillUp.exchangeRate ?? 1.0` (not the Settings rate) in Fuel/ViewModels/SummaryViewModel.swift
- [X] T003 Verify `CurrencyDefinition.currency(for:)` static lookup method exists in Fuel/Models/CurrencyDefinition.swift

**Checkpoint**: Foundation confirmed — user story display work can begin

---

## Phase 3: User Story 1 — Statistics Always in Default Currency (Priority: P1) 🎯 MVP

**Goal**: Cost totals in the Statistics tab show the default currency symbol so users know which currency the figures represent

**Independent Test**: Configure PLN as default currency. Add fill-ups in PLN and EUR. Open the Statistics tab. Verify "Total Spent" row shows "zł" suffix. Remove default currency in Settings. Verify no symbol appears.

### Implementation for User Story 1

- [X] T004 [US1] Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` to `SummaryTabView` and compute a `private var defaultCurrencySymbol: String?` that resolves the symbol via `CurrencyDefinition.currency(for: defaultCurrencyCode)?.symbol` in Fuel/Views/ContentView.swift
- [X] T005 [US1] Update `SummaryContentSection` to accept `currencySymbol: String? = nil` parameter and display the symbol as a trailing suffix after the cost value on the "Total Spent" `LabeledContent` row — format: `"\(String(format: "%.2f", viewModel.totalCost)) \(symbol)"` when symbol is non-nil, otherwise plain `"%.2f"` in Fuel/Views/ContentView.swift
- [X] T006 [US1] Update the `SummaryContentSection` call site in `SummaryTabView.body` to pass `currencySymbol: defaultCurrencySymbol` in Fuel/Views/ContentView.swift

**Checkpoint**: Statistics tab "Total Spent" displays default currency symbol. No symbol shown when no default currency configured.

---

## Phase 4: User Story 2 — Historical Exchange Rate Accuracy (Priority: P2)

**Goal**: Confirm that changing the exchange rate in Settings does not retroactively alter Statistics totals

**Independent Test**: Record a fill-up in EUR at rate 4.20. Change Settings exchange rate to 5.00. Verify Statistics "Total Spent" has not changed (still uses 4.20 for that entry).

### Implementation for User Story 2

*(No code changes required — the historical accuracy is already implemented in `SummaryViewModel.convertedCost(for:)` which reads `fillUp.exchangeRate` and never reads the Settings rate. This phase exists to formally confirm and document the verification.)*

- [X] T007 [US2] Verify by code inspection that `SummaryViewModel.convertedCost(for:)` reads `fillUp.exchangeRate ?? 1.0` and does NOT read `@AppStorage("exchangeRate")` or any UserDefaults key — document confirmation in a code comment if not already clear in Fuel/ViewModels/SummaryViewModel.swift

**Checkpoint**: Historical rate accuracy is confirmed by inspection. Changing Settings rate has no effect on past entries.

---

## Phase 5: User Story 3 — Default Currency Label on Statistics (Priority: P3)

**Goal**: All cost figures in Statistics — including monthly breakdown rows — display the default currency symbol

**Independent Test**: Configure EUR as default currency. Open Statistics with multiple months of data. Verify every monthly row cost figure shows "€" suffix. Verify the legacy SummaryView modal (if accessible) also shows "€".

### Implementation for User Story 3

- [X] T008 [P] [US3] Update monthly breakdown rows in `SummaryContentSection` — add the currency symbol suffix to the `Text(String(format: "%.2f", summary.totalCost))` in the `ForEach(vm.monthlySummaries)` block — pass symbol down or read it from the enclosing view in Fuel/Views/ContentView.swift
- [X] T009 [P] [US3] Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` and `private var currencySymbol: String? { CurrencyDefinition.currency(for: defaultCurrencyCode)?.symbol }` to `SummaryView` (legacy modal sheet) in Fuel/Views/SummaryView.swift
- [X] T010 [US3] Update "Total Spent" `LabeledContent` in `SummaryView` to append currency symbol when non-nil — format: `"\(String(format: "%.2f", vm.totalCost)) \(symbol)"` in Fuel/Views/SummaryView.swift
- [X] T011 [US3] Update monthly breakdown cost `Text` in `SummaryView` to append currency symbol when non-nil in Fuel/Views/SummaryView.swift

**Checkpoint**: All cost figures in both Statistics views (tab + modal) display the default currency symbol. No symbol when unconfigured.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T012 Build the project and confirm zero warnings and zero errors (`xcodebuild`) in all modified files
- [X] T013 Verify Statistics renders correctly on iPhone SE simulator (small screen — cost label + symbol must not truncate)
- [X] T014 Verify Statistics renders correctly on iPhone 17 Pro Max simulator (large screen — consistent layout)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No code changes — verify prerequisites only
- **User Story 1 (Phase 3)**: Depends on Phase 2 confirmation — BLOCKS US3 (T008 needs updated `SummaryContentSection`)
- **User Story 2 (Phase 4)**: Independent — can run any time after Phase 2
- **User Story 3 (Phase 5)**: T008 depends on updated `SummaryContentSection` from T005; T009–T011 can run in parallel with Phase 3
- **Polish (Phase 6)**: Depends on all user story phases complete

### User Story Dependencies

- **US1 (P1)**: No dependencies — start immediately after Phase 2
- **US2 (P2)**: No code changes — independent verification, run any time
- **US3 (P3)**: T008 depends on `SummaryContentSection` changes from T005/T006; T009–T011 are independent of US1

### Parallel Opportunities

- T001, T002, T003 can run in parallel (different files, read-only verification)
- T008 and T009–T011 can run in parallel once T005 is complete (different files)
- T013 and T014 can run in parallel (different simulators)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Confirm Phase 2 prerequisites (T001–T003)
2. Complete Phase 3: US1 (T004–T006)
3. **STOP and VALIDATE**: Open Statistics tab, confirm currency symbol appears next to "Total Spent"
4. Demo if ready

### Incremental Delivery

1. Phase 2: Confirm prerequisites
2. Phase 3 (T004–T006): "Total Spent" label in Statistics tab → MVP!
3. Phase 4 (T007): Verify historical accuracy (documentation only)
4. Phase 5 (T008–T011): Monthly rows + legacy SummaryView modal
5. Phase 6: Build check + device size verification

---

## Notes

- No new files required — all changes are additive to existing views
- No model changes — `FillUp.exchangeRate` already stores per-entry rates
- No ViewModel changes — `SummaryViewModel.convertedCost(for:)` already uses per-entry rates
- Legacy entries (nil exchangeRate) automatically treated as rate 1.0 via `?? 1.0`
- Empty `defaultCurrencyCode` → `CurrencyDefinition.currency(for:)` returns nil → no symbol shown (backward compatible)
