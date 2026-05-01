# Quickstart: Dual Currency Support

**Feature**: 012-dual-currency
**Date**: 2026-04-21

## What This Feature Does

Adds dual currency support so users can configure a default and secondary currency with an exchange rate, toggle between currencies when adding fill-ups or costs, and see converted equivalents in lists and statistics.

## Files to Create

| File | Purpose |
|------|---------|
| `Fuel/Models/CurrencyDefinition.swift` | Enum/struct with supported currencies (code, symbol, name) |

## Files to Modify

| File | Change |
|------|--------|
| `Fuel/Models/FillUp.swift` | Add `currencyCode: String?` and `exchangeRate: Double?` fields |
| `Fuel/Models/CostEntry.swift` | Add `currencyCode: String?` and `exchangeRate: Double?` fields |
| `Fuel/Views/SettingsView.swift` | Add Currency section with pickers and exchange rate field |
| `Fuel/Views/AddFillUpView.swift` | Add currency toggle pill and conversion reference |
| `Fuel/ViewModels/AddFillUpViewModel.swift` | Add currency state and conversion logic |
| `Fuel/Views/AddCostView.swift` | Add currency toggle pill and conversion reference |
| `Fuel/ViewModels/AddCostViewModel.swift` | Add currency state and conversion logic |
| `Fuel/Views/FillUpListView.swift` | Display original currency + converted equivalent |
| `Fuel/Views/CostListView.swift` | Display original currency + converted equivalent |
| `Fuel/ViewModels/SummaryViewModel.swift` | Convert entries to default currency for totals |
| `Fuel/Views/EditFillUpView.swift` | Support currency display for editing |

## Implementation Steps

1. **Create `CurrencyDefinition`** with supported currencies and a static lookup method.
2. **Add currency fields** to `FillUp` and `CostEntry` models (optional, backward-compatible).
3. **Add Currency section** to `SettingsView` with pickers for default/secondary currency and exchange rate input.
4. **Add currency toggle** to `AddFillUpView` and `AddCostView` — pill button next to cost fields, conversion line below.
5. **Update ViewModels** to pass currency code and exchange rate when saving entries.
6. **Update list views** to show original currency and converted equivalent when applicable.
7. **Update SummaryViewModel** to convert all entries to default currency for statistics.
8. **Register new file** in `Fuel.xcodeproj/project.pbxproj`.

## Key Decisions

- Currency settings stored in UserDefaults (app-level, not per-vehicle)
- Per-entry exchange rate storage for historical accuracy
- Optional fields on models for backward compatibility (nil = legacy/default)
- Hardcoded currency list (~17 currencies) — no external API
- Single-tap toggle between default and secondary currency
