# Implementation Plan: Dual Currency Support

**Branch**: `012-dual-currency` | **Date**: 2026-04-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/012-dual-currency/spec.md`

## Summary

Add dual currency support allowing users to configure a default and secondary currency with a manual exchange rate. Fill-up and cost forms get a currency toggle for quick switching. Entries store their original currency and rate. Statistics convert everything to the default currency.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (all Apple frameworks)
**Storage**: SwiftData (entries), UserDefaults (currency settings)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iOS)
**Performance Goals**: Currency conversion inline, no perceptible delay
**Constraints**: Offline-capable, no external API dependencies
**Scale/Scope**: 1 new file, ~10 modified files across Models, ViewModels, Views

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Single-responsibility CurrencyDefinition type, minimal per-file changes |
| II. Simple UX | ✅ Pass | Single-tap currency toggle, inline conversion display |
| III. Responsive Design | ✅ Pass | Pill button and conversion line adapt to all device sizes |
| IV. Minimal Dependencies | ✅ Pass | Hardcoded currency list, no external APIs |
| iOS Platform Constraints | ✅ Pass | iOS 17+, Swift 5.9+, SwiftUI, SwiftData, MVVM |
| Development Workflow | ✅ Pass | Feature branch, incremental changes |

**Post-Phase 1 Re-check**: All gates pass. No new dependencies. Navigation depth unchanged.

## Project Structure

### Documentation (this feature)

```text
specs/012-dual-currency/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── ui-contract.md   # Phase 1 output
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (repository root)

```text
Fuel/
├── Models/
│   ├── CurrencyDefinition.swift     # NEW: Currency enum with code/symbol/name
│   ├── FillUp.swift                 # MODIFIED: Add currencyCode, exchangeRate
│   └── CostEntry.swift              # MODIFIED: Add currencyCode, exchangeRate
├── ViewModels/
│   ├── AddFillUpViewModel.swift     # MODIFIED: Currency state + conversion
│   ├── AddCostViewModel.swift       # MODIFIED: Currency state + conversion
│   ├── EditFillUpViewModel.swift    # MODIFIED: Currency display
│   └── SummaryViewModel.swift       # MODIFIED: Convert to default currency
├── Views/
│   ├── SettingsView.swift           # MODIFIED: Currency section
│   ├── AddFillUpView.swift          # MODIFIED: Currency toggle
│   ├── AddCostView.swift            # MODIFIED: Currency toggle
│   ├── FillUpListView.swift         # MODIFIED: Dual currency display
│   ├── CostListView.swift           # MODIFIED: Dual currency display
│   ├── EditFillUpView.swift         # MODIFIED: Currency display
│   └── FillUpDetailView.swift       # MODIFIED: Currency display
└── Services/
    (no new services needed)
```

**Structure Decision**: Follows existing MVVM pattern. New CurrencyDefinition goes in Models/ alongside other value types. Currency settings use @AppStorage in views that need them.

## Complexity Tracking

No constitution violations. No complexity justification needed.

## Implementation Tasks

### Task 1: Create CurrencyDefinition
**File**: `Fuel/Models/CurrencyDefinition.swift` (NEW)
- Define struct with `code`, `symbol`, `name` properties
- Static `allCurrencies` array with ~17 common currencies
- Static `currency(for code:)` lookup method
- Register file in pbxproj

### Task 2: Add currency fields to models
**Files**: `Fuel/Models/FillUp.swift`, `Fuel/Models/CostEntry.swift` (MODIFY)
- Add `currencyCode: String?` and `exchangeRate: Double?` optional fields
- No migration needed — SwiftData handles optional field additions

### Task 3: Add Currency section to Settings
**File**: `Fuel/Views/SettingsView.swift` (MODIFY)
- Add Currency section with Picker for default currency, Picker for secondary currency, TextField for exchange rate
- Use `@AppStorage` for persistence
- Validate exchange rate > 0, prevent same currency for both

### Task 4: Update AddFillUpView with currency toggle
**Files**: `Fuel/Views/AddFillUpView.swift`, `Fuel/ViewModels/AddFillUpViewModel.swift` (MODIFY)
- Add currency pill button next to cost fields
- Show conversion reference line when secondary currency active
- Pass currencyCode and exchangeRate to FillUp on save

### Task 5: Update AddCostView with currency toggle
**Files**: `Fuel/Views/AddCostView.swift`, `Fuel/ViewModels/AddCostViewModel.swift` (MODIFY)
- Same currency toggle pattern as fill-up form
- Pass currencyCode and exchangeRate to CostEntry on save

### Task 6: Update list views with dual currency display
**Files**: `Fuel/Views/FillUpListView.swift`, `Fuel/Views/CostListView.swift` (MODIFY)
- Show original currency amount
- Show converted default-currency equivalent when entry is in secondary currency

### Task 7: Update statistics for currency conversion
**File**: `Fuel/ViewModels/SummaryViewModel.swift` (MODIFY)
- Convert all entry amounts to default currency using per-entry exchangeRate
- Treat nil currencyCode entries as default currency at rate 1.0

### Task 8: Update edit and detail views
**Files**: `Fuel/Views/EditFillUpView.swift`, `Fuel/Views/FillUpDetailView.swift` (MODIFY)
- Display currency info on existing entries
- Support currency toggle when editing
