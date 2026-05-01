# Quickstart: Statistics in Default Currency

**Feature**: 013-stats-default-currency
**Date**: 2026-04-21

---

## What This Feature Does

Adds default currency labels to all cost figures in the Statistics tab and the Statistics modal sheet, so users always know which currency aggregated totals are expressed in.

The historical exchange rate accuracy (per-entry rate storage) was already implemented in feature 012-dual-currency.

---

## Files to Modify

| File | Change |
|------|--------|
| `Fuel/Views/ContentView.swift` | Add `@AppStorage("defaultCurrency")` to `SummaryTabView`; pass currency symbol to `SummaryContentSection` |
| `Fuel/Views/ContentView.swift` | Update `SummaryContentSection` to accept and display `currencySymbol: String?` |
| `Fuel/Views/SummaryView.swift` | Add `@AppStorage("defaultCurrency")` and display currency symbol next to cost figures |

---

## Minimal Test Scenario

1. Open Settings → set Default Currency to "PLN (zł)"
2. Add a fill-up in PLN → Total Cost = 200.00
3. Add a fill-up in EUR with rate 4.30 → Total Cost = 50.00 EUR
4. Open Statistics tab
5. **Expected**: "Total Spent" shows "≈ 415.00 zł" (200 + 50 × 4.30)
6. Change exchange rate in Settings to 5.00
7. Return to Statistics — **Expected**: total still shows "415.00 zł" (rate not retroactively changed)
8. Remove default currency from Settings
9. **Expected**: Statistics shows amounts with no currency symbol

---

## Key Constraint

The per-entry `exchangeRate` field is the **only** rate used for historical statistics. The current exchange rate in Settings is **never** used for conversion of existing entries.
