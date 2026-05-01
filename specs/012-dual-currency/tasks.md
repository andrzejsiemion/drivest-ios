# Tasks: Dual Currency Support

**Input**: Design documents from `specs/012-dual-currency/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: Create the new currency model and add currency fields to existing models

- [X] T001 Create `CurrencyDefinition` struct with `code: String`, `symbol: String`, `name: String` properties and a static `allCurrencies` array containing ~17 common currencies (USD, EUR, GBP, PLN, CZK, CHF, SEK, NOK, DKK, HUF, RON, BGN, TRY, UAH, JPY, CAD, AUD) plus a static `currency(for code: String) -> CurrencyDefinition?` lookup method in Fuel/Models/CurrencyDefinition.swift
- [X] T002 Register CurrencyDefinition.swift in Fuel.xcodeproj/project.pbxproj (PBXBuildFile, PBXFileReference, Models group, Sources build phase)

**Checkpoint**: New CurrencyDefinition type compiles and is available for use

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add currency fields to data models — MUST complete before any UI work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 [P] Add `currencyCode: String?` and `exchangeRate: Double?` optional properties to `FillUp` model — add to class body (no init change needed, SwiftData handles optional fields) in Fuel/Models/FillUp.swift
- [X] T004 [P] Add `currencyCode: String?` and `exchangeRate: Double?` optional properties to `CostEntry` model — add to class body (no init change needed) in Fuel/Models/CostEntry.swift

**Checkpoint**: Models compile with new optional fields, existing data loads without migration

---

## Phase 3: User Story 1 — Configure Default and Secondary Currency (Priority: P1) 🎯 MVP

**Goal**: Users can set default currency, secondary currency, and exchange rate in Settings

**Independent Test**: Open Settings, select two currencies, enter exchange rate, close and reopen Settings, verify values persist

### Implementation for User Story 1

- [X] T005 [US1] Add a "Currency" `Section` to `SettingsView` above the existing "Categories" section with: a `Picker` for default currency (from `CurrencyDefinition.allCurrencies`), a `Picker` for secondary currency (excluding the selected default), and a `TextField` for exchange rate. Use `@AppStorage("defaultCurrency")` for default currency code, `@AppStorage("secondaryCurrency")` for secondary code, and `@AppStorage("exchangeRate")` for rate (Double, default 1.0). Show helper text "1 [secondary] = [rate] [default]" below the rate field in Fuel/Views/SettingsView.swift
- [X] T006 [US1] Add validation: disable saving if exchange rate ≤ 0; filter secondary currency picker to exclude the currently selected default currency; if user selects same currency for both, clear the secondary selection in Fuel/Views/SettingsView.swift
- [X] T007 [US1] Add a "None" option as the first item in both currency pickers so the user can clear their selection (backward compatibility — no currency configured = no symbols shown) in Fuel/Views/SettingsView.swift

**Checkpoint**: User can configure currencies in Settings. Values persist across launches. MVP complete.

---

## Phase 4: User Story 2 — Add Fill-Up/Cost with Default Currency (Priority: P2)

**Goal**: Forms display the default currency symbol next to cost fields; entries are saved with currency metadata

**Independent Test**: Configure a default currency, add a fill-up, verify currency symbol appears in form and entry is saved with correct currency code

### Implementation for User Story 2

- [X] T008 [US2] Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` to `AddFillUpView` and display the currency symbol (from `CurrencyDefinition.currency(for:)`) next to "Price per Unit" and "Total Cost" field labels — if no currency configured, show no symbol (backward compatible) in Fuel/Views/AddFillUpView.swift
- [X] T009 [US2] Update `AddFillUpViewModel.save()` to set `fillUp.currencyCode` to the active currency code and `fillUp.exchangeRate` to 1.0 (default currency = rate 1.0) when saving. Only set these if a default currency is configured in Fuel/ViewModels/AddFillUpViewModel.swift
- [X] T010 [P] [US2] Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` to `AddCostView` and display the currency symbol next to the "Amount" field label in Fuel/Views/AddCostView.swift
- [X] T011 [P] [US2] Update `AddCostViewModel.save()` to set `costEntry.currencyCode` and `costEntry.exchangeRate` (1.0 for default currency) when saving in Fuel/ViewModels/AddCostViewModel.swift
- [X] T012 [US2] Update fill-up list rows in `FillUpListView` to append the currency symbol to cost display (e.g., "250.00 zł" instead of "250.00") — only when currency is configured. Read symbol from the entry's `currencyCode` via `CurrencyDefinition.currency(for:)` in Fuel/Views/FillUpListView.swift
- [X] T013 [P] [US2] Update cost list rows in `CostListView` to append the currency symbol to amount display — same pattern as fill-up list in Fuel/Views/CostListView.swift

**Checkpoint**: Currency symbols appear in forms and lists. Entries store currency metadata. Backward compatible when unconfigured.

---

## Phase 5: User Story 3 — Switch to Secondary Currency When Adding Entry (Priority: P3)

**Goal**: Users can toggle between default and secondary currency in forms; conversion reference shown; entries store original currency and rate

**Independent Test**: Configure dual currencies, add a fill-up, tap currency toggle to switch to secondary, enter amount, verify conversion shown and entry saved with secondary currency code and exchange rate

### Implementation for User Story 3

- [X] T014 [US3] Add `@AppStorage("secondaryCurrency") private var secondaryCurrencyCode: String = ""` and `@AppStorage("exchangeRate") private var exchangeRate: Double = 1.0` to `AddFillUpView`. Add `@State private var useSecondaryCurrency = false` toggle state in Fuel/Views/AddFillUpView.swift
- [X] T015 [US3] Add a tappable currency pill `Button` next to "Total Cost" label — shows active currency code (e.g., "PLN"), tapping toggles `useSecondaryCurrency`. Only visible when both currencies are configured. Style as a rounded pill with `.font(.caption).fontWeight(.semibold)` and tinted background in Fuel/Views/AddFillUpView.swift
- [X] T016 [US3] Add a conversion reference line below the Total Cost field — when secondary currency is active, show "≈ [amount × exchangeRate] [defaultSymbol]" in `.font(.caption).foregroundStyle(.secondary)`. Update dynamically as totalCost text changes in Fuel/Views/AddFillUpView.swift
- [X] T017 [US3] Update `AddFillUpViewModel.save()` to pass the active currency code and exchange rate — when secondary currency is active, set `currencyCode` to secondary code and `exchangeRate` to the configured rate; when default is active, set `currencyCode` to default code and `exchangeRate` to 1.0 in Fuel/ViewModels/AddFillUpViewModel.swift
- [X] T018 [P] [US3] Add the same currency toggle pill, conversion reference, and state management to `AddCostView` and `AddCostViewModel` — identical pattern to fill-up form in Fuel/Views/AddCostView.swift and Fuel/ViewModels/AddCostViewModel.swift
- [X] T019 [US3] Update fill-up list rows: when an entry's `currencyCode` differs from the default currency, show the converted equivalent below the original amount (e.g., "57.75 €" primary, "≈ 248.33 zł" secondary dimmed). Compute as `totalCost * (exchangeRate ?? 1.0)` in Fuel/Views/FillUpListView.swift
- [X] T020 [P] [US3] Update cost list rows with the same dual-currency display pattern as fill-up list in Fuel/Views/CostListView.swift
- [X] T021 [US3] Update `SummaryViewModel.loadSummary(for:period:)` to convert all entry amounts to the default currency when computing totals: for each fill-up, use `totalCost * (exchangeRate ?? 1.0)` when `currencyCode` differs from default, otherwise use `totalCost` directly. Apply same logic to volume-related costs in Fuel/ViewModels/SummaryViewModel.swift

**Checkpoint**: Currency toggle works in both forms. Conversion reference shown. Lists display dual currencies. Statistics aggregate correctly.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edit views, detail views, accessibility

- [X] T022 Update `EditFillUpView` to display the entry's currency symbol next to cost fields (read-only currency display — editing currency of existing entries is out of scope) in Fuel/Views/EditFillUpView.swift
- [X] T023 Update `FillUpDetailView` to show currency info (original amount with symbol, converted equivalent if different from default) in Fuel/Views/FillUpDetailView.swift
- [X] T024 Add accessibility labels to currency toggle pill ("Switch to [currency name]") and conversion reference line in Fuel/Views/AddFillUpView.swift and Fuel/Views/AddCostView.swift
- [X] T025 Verify Settings currency pickers, forms, and lists render correctly on iPhone SE (small) and iPhone 17 Pro Max (large) in all modified view files

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001-T002) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (T003-T004)
- **User Story 2 (Phase 4)**: Depends on Phase 3 (needs currency settings to exist)
- **User Story 3 (Phase 5)**: Depends on Phase 4 (extends form with toggle)
- **Polish (Phase 6)**: Depends on Phase 5

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — independent
- **US2 (P2)**: Depends on US1 (needs configured currencies to display symbols)
- **US3 (P3)**: Depends on US2 (extends forms that US2 modified)

### Parallel Opportunities

- T003, T004 can run in parallel (different model files)
- T010, T011 can run in parallel with T008, T009 (different files: cost vs fill-up)
- T012, T013 can run in parallel (different list view files)
- T018, T020 can run in parallel with fill-up equivalents
- T019, T020 can run in parallel (different list view files)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (create CurrencyDefinition)
2. Complete Phase 2: Foundational (add fields to models)
3. Complete Phase 3: User Story 1 (currency settings in Settings)
4. **STOP and VALIDATE**: Verify currencies persist in Settings
5. Demo if ready

### Incremental Delivery

1. Setup + Foundational → CurrencyDefinition + model fields ready
2. Add User Story 1 → Settings currency config → MVP!
3. Add User Story 2 → Currency symbols in forms + lists
4. Add User Story 3 → Currency toggle + conversion + statistics
5. Polish → Edit/detail views, accessibility

---

## Notes

- SwiftData handles optional field additions without migration — no schema versioning needed
- `@AppStorage` reads UserDefaults directly — no ViewModel wrapper needed for settings
- Currency pill button pattern: `Button` with `.background(.tint.opacity(0.15)).clipShape(Capsule())`
- Conversion formula: `amount * exchangeRate` when secondary → default; entries in default currency have rate 1.0
- Legacy entries (nil currencyCode) are treated as default currency at rate 1.0
