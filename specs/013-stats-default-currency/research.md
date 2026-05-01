# Research: Statistics in Default Currency with Historical Exchange Rates

**Feature**: 013-stats-default-currency
**Date**: 2026-04-21

---

## Current State Analysis

### What already exists (from feature 012-dual-currency)

**Conversion logic in `SummaryViewModel`** — already correct:
```swift
private static func convertedCost(for fillUp: FillUp) -> Double {
    fillUp.totalCost * (fillUp.exchangeRate ?? 1.0)
}
```
This uses the per-entry rate stored at save time. Changing the Settings exchange rate does **not** affect historical entries. FR-002, FR-003, FR-006 are already satisfied.

**Per-entry exchange rate storage** — already in place:
- `FillUp.currencyCode: String?` and `FillUp.exchangeRate: Double?`
- `CostEntry.currencyCode: String?` and `CostEntry.exchangeRate: Double?`
- At save time, `AddFillUpViewModel.save(currencyCode:exchangeRate:)` stores the rate from Settings
- At save time, `AddCostViewModel.save(currencyCode:exchangeRate:)` does the same

**Statistics views:**
- `SummaryTabView` (main Statistics tab, `ContentView.swift`) displays `viewModel.totalCost` as `"%.2f"` — **no currency symbol**
- `SummaryView` (legacy modal stats sheet) also shows `"%.2f"` — **no currency symbol**
- `SummaryContentSection` renders the cost row without any currency label

### What is missing

1. **Currency symbol/code next to cost totals in Statistics** (FR-005, US3):
   - `SummaryTabView` → `SummaryContentSection` → "Total Spent" row
   - `SummaryView` → "All Time" / totals section → "Total Spent" and monthly rows
   - Both need `@AppStorage("defaultCurrency")` to read the configured currency and display its symbol

2. **CostEntry amounts not aggregated in SummaryViewModel** — this is by design (Statistics tab only shows fuel statistics). CostEntry display is handled separately in CostListView. Out of scope for this feature.

---

## Decision Log

### Decision 1: Scope of "statistics"
- **Decision**: Statistics = aggregated fuel fill-up data in the Statistics tab (SummaryTabView + SummaryView)
- **Rationale**: CostListView already shows per-entry cost amounts. The Statistics tab is exclusively about fuel consumption and fuel cost summaries. The spec says "statistics" without defining it more broadly, and the existing app architecture treats them as fuel statistics.
- **Alternatives considered**: Including CostEntry totals in the summary — rejected because it would require significant scope expansion and the CostListView already handles cost display.

### Decision 2: Currency label placement
- **Decision**: Show default currency symbol (e.g., "zł") as suffix text after cost amounts in the statistics views. Match the style used in list rows (Text with `.foregroundStyle(.secondary)`).
- **Rationale**: Consistent with the currency display pattern already established in FillUpListView and CostListView (feature 012).
- **Alternatives considered**: Showing currency code (e.g., "PLN") instead of symbol — symbol is more compact and already the convention in the app.

### Decision 3: Where to read default currency
- **Decision**: Read `@AppStorage("defaultCurrency")` directly in the view layer (`SummaryTabView`, `SummaryContentSection`, `SummaryView`). No ViewModel changes needed.
- **Rationale**: Currency code is a settings value in UserDefaults. Reading it in the view is consistent with how all other views in the app handle it. The ViewModel concern is aggregation; display formatting is a view concern.
- **Alternatives considered**: Passing currency code through ViewModel — unnecessary coupling.

### Decision 4: SummaryViewModel already handles FR-002/FR-003 correctly
- **Decision**: No changes needed to `SummaryViewModel.convertedCost(for:)`.
- **Rationale**: The method uses `fillUp.exchangeRate ?? 1.0` — the per-entry stored rate. The current exchange rate in Settings is never read by this method.
- **Verification**: Confirmed by code inspection. Changing Settings rate post-save does not affect any FillUp.exchangeRate values already persisted.

---

## Implementation Gap Summary

| Requirement | Status | Gap |
|-------------|--------|-----|
| FR-001: Totals in default currency | ✅ Already done (convertedCost) | None |
| FR-002: Use per-entry rate | ✅ Already done | None |
| FR-003: Do not use current Settings rate | ✅ Already done | None |
| FR-004: Default currency entries unchanged | ✅ Already done (rate 1.0) | None |
| FR-005: Show currency symbol in Statistics | ❌ Missing | Add symbol display to SummaryTabView and SummaryView |
| FR-006: Legacy entries use rate 1.0 | ✅ Already done (`?? 1.0`) | None |
| FR-007: No label when no currency configured | Partial | Guard with empty string check |

**Conclusion**: This feature is ~80% already implemented. The only remaining work is adding currency symbol labels to the two statistics views.
