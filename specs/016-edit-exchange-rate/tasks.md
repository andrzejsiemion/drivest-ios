# Tasks: Edit Exchange Rate

**Input**: Design documents from `specs/016-edit-exchange-rate/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

No new project structure required — feature modifies existing files only.

---

## Phase 2: Foundational

**Purpose**: Restore the optional model fields that were reverted. These fields are required by both user stories and by `EditCostViewModel` (which already references `costEntry.photoData`).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Restore `var currencyCode: String?`, `var exchangeRate: Double?`, and `var photoData: Data?` as nil-default stored properties to `@Model final class FillUp` in `Fuel/Models/FillUp.swift` — add after the `note` property; do NOT add to the `init` (SwiftData handles nil-default optional migration automatically)
- [X] T002 [P] Restore `var currencyCode: String?`, `var exchangeRate: Double?`, and `var photoData: Data?` as nil-default stored properties to `@Model final class CostEntry` in `Fuel/Models/CostEntry.swift` — same pattern as T001; do NOT add to the `init`

**Checkpoint**: Models restored. Both `EditCostViewModel` (which references `costEntry.photoData`) and the new exchange rate editing tasks can now proceed.

---

## Phase 3: User Story 1 — Edit Exchange Rate on Fill-Up (Priority: P1) 🎯 MVP

**Goal**: Users can view and edit the exchange rate on the fill-up edit form when the fill-up was saved in a secondary currency.

**Independent Test**: Find a fill-up saved with a non-default currency. Open its edit form — the current exchange rate is shown. Change it to a new value, save, and verify the converted amount in the detail view reflects the updated rate. A fill-up saved in the default currency shows no exchange rate field.

### Implementation for User Story 1

- [X] T003 [US1] Update `EditFillUpViewModel` in `Fuel/ViewModels/EditFillUpViewModel.swift`:
  - Add `var exchangeRateText: String` — in `init`, set to `String(format: "%.4f", fillUp.exchangeRate ?? 1.0)` if `fillUp.exchangeRate != nil`, otherwise `""`
  - Add computed `var hasSecondaryCurrency: Bool { fillUp.currencyCode != nil }`
  - Add computed `var exchangeRate: Double? { Self.parseDouble(exchangeRateText) }` using locale-aware parsing: `Double(text) ?? Double(text.replacingOccurrences(of: Locale.current.decimalSeparator ?? ",", with: "."))`
  - Add private static `func parseDouble(_ text: String) -> Double?` implementing the above
  - Extend `isValid` to add `&& (!hasSecondaryCurrency || (exchangeRate ?? 0) > 0)`
  - In `save()`, add `if hasSecondaryCurrency { fillUp.exchangeRate = exchangeRate }` before calling `Persistence.save`

- [X] T004 [US1] Update `EditFillUpView` in `Fuel/Views/EditFillUpView.swift`:
  - Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` at the top of the struct
  - After the Fuel Section (closing brace of the Section containing Price/Volume/Total), add a conditional block:
    ```swift
    if vm.hasSecondaryCurrency {
        Section {
            HStack {
                Text(fillUp.currencyCode.map { "\($0) → \(defaultCurrencyCode)" } ?? "Exchange Rate")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("1.0000", text: Binding(
                    get: { vm.exchangeRateText },
                    set: { vm.exchangeRateText = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Exchange Rate")
        }
    }
    ```

**Checkpoint**: Fill-up exchange rate editing fully functional. US2 can now begin.

---

## Phase 4: User Story 2 — Edit Exchange Rate on Cost Entry (Priority: P2)

**Goal**: Users can view and edit the exchange rate on the cost entry edit form when the cost was saved in a secondary currency.

**Independent Test**: Find a cost entry saved with a non-default currency. Open it, tap Edit — exchange rate field is visible. Change it, save, and verify the converted amount updates in the cost detail view. A cost saved in the default currency shows no field.

### Implementation for User Story 2

- [X] T005 [US2] Update `EditCostViewModel` in `Fuel/ViewModels/EditCostViewModel.swift`:
  - Add `var exchangeRateText: String` — in `init`, set to `String(format: "%.4f", costEntry.exchangeRate ?? 1.0)` if `costEntry.exchangeRate != nil`, otherwise `""`
  - Add computed `var hasSecondaryCurrency: Bool { costEntry.currencyCode != nil }`
  - Add computed `var exchangeRate: Double?` with locale-aware parsing (same `parseDouble` pattern as T003)
  - Add private static `func parseDouble(_ text: String) -> Double?`
  - Extend `isValid` to include exchange rate guard: `&& (!hasSecondaryCurrency || (exchangeRate ?? 0) > 0)`
  - In `save()`, add `if hasSecondaryCurrency { costEntry.exchangeRate = exchangeRate }` before `Persistence.save`

- [X] T006 [US2] Update `EditCostView` in `Fuel/Views/EditCostView.swift`:
  - Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""` at the top of the struct
  - After the Amount Section (the Section containing the HStack with TextField and currency symbol), add:
    ```swift
    if vm.hasSecondaryCurrency {
        Section {
            HStack {
                Text(costEntry.currencyCode.map { "\($0) → \(defaultCurrencyCode)" } ?? "Exchange Rate")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("1.0000", text: Binding(
                    get: { vm.exchangeRateText },
                    set: { vm.exchangeRateText = $0 }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Exchange Rate")
        }
    }
    ```

**Checkpoint**: Both US1 and US2 fully functional.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T007 [P] Apply locale-aware `parseDouble` to `AddFillUpViewModel` in `Fuel/ViewModels/AddFillUpViewModel.swift` — replace `var pricePerLiter: Double? { Double(pricePerLiterText) }`, `var volume`, `var totalCost`, `var odometer` with calls to a private static `parseDouble(_:)` identical to T003; this fixes auto-calculation on non-English locale devices
- [X] T008 [P] Apply the same locale-aware `parseDouble` to `EditFillUpViewModel` in `Fuel/ViewModels/EditFillUpViewModel.swift` — replace the four `Double(textField)` computed property bodies with `Self.parseDouble(textField)` (note: T003 already adds `parseDouble` to this file, so T008 just updates the four existing computed properties to use it)
- [X] T009 Build the project with `xcodebuild -project Fuel.xcodeproj -scheme Fuel -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' build` from the repo root and confirm zero errors
- [X] T010 [P] Run quickstart.md Scenarios 1–4 on iPhone SE simulator — verify exchange rate edit on fill-up and cost, no field for single-currency records, and zero/negative rate blocked
- [X] T011 [P] Run quickstart.md Scenario 7 (regression) on iPhone SE simulator — verify auto-calculation of price/volume/totalCost still works and existing fill-up/cost editing is unaffected

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
  - T001 and T002 are parallel (different model files)
- **US1 (Phase 3)**: Depends on Phase 2 complete
  - T003 and T004 are sequential (T004 uses `vm.hasSecondaryCurrency` added in T003)
- **US2 (Phase 4)**: Depends on Phase 2 complete; can run in parallel with US1
  - T005 and T006 are sequential (same reason)
- **Polish (Phase 5)**: Depends on US1 and US2 complete
  - T007, T008 are parallel (different VMs); T010, T011 are parallel

### Parallel Opportunities

- T001, T002: parallel (Phase 2)
- US1 (T003–T004) and US2 (T005–T006): parallel phases after T001+T002 done
- T007, T008, T010, T011: parallel (Phase 5)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001, T002 in parallel → models restored
2. T003 → T004 → fill-up exchange rate editable
3. **STOP and VALIDATE** using quickstart.md Scenario 1, 3, 4

### Incremental Delivery

1. T001, T002 → Foundation ✓
2. T003, T004 → Fill-up exchange rate ✓ (MVP!)
3. T005, T006 → Cost exchange rate ✓
4. T007–T011 → Polish + locale fix ✓

---

## Notes

- T001/T002: SwiftData handles nil-default optional field migration automatically — no schema version bump, no `ModelConfiguration(schema:)` change needed
- T003/T005: The `parseDouble` helper should be `private static func` so it doesn't pollute the `@Observable` tracked properties
- T004/T006: `fillUp.currencyCode` is accessed directly on the model (not via the VM) because it is read-only in the edit form; the VM exposes only `hasSecondaryCurrency` (Bool)
- T007/T008: These locale-aware fixes address the auto-calculation bug reported by the user (comma decimal separator on non-English devices); they belong in Polish phase since they are cross-cutting improvements
- T008 note: `parseDouble` is added in T003 for `EditFillUpViewModel` — T008 just updates the four existing computed properties (`pricePerLiter`, `volume`, `totalCost`, `odometer`) to use it instead of bare `Double()`
