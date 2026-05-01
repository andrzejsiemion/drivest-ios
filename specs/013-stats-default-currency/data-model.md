# Data Model: Statistics in Default Currency with Historical Exchange Rates

**Feature**: 013-stats-default-currency
**Date**: 2026-04-21

---

## Existing Models (No Changes Required)

All data model changes for this feature were already implemented in feature 012-dual-currency.

### FillUp (existing)

| Field | Type | Notes |
|-------|------|-------|
| `totalCost` | `Double` | Amount in the currency recorded at the time |
| `currencyCode` | `String?` | ISO currency code (e.g., "PLN", "EUR"). `nil` = legacy entry |
| `exchangeRate` | `Double?` | Rate at time of save: "1 secondary = X default". `nil` = 1.0 |

**Conversion rule**: `convertedCostInDefault = totalCost * (exchangeRate ?? 1.0)`

### CostEntry (existing, out of scope for statistics aggregation)

| Field | Type | Notes |
|-------|------|-------|
| `amount` | `Double` | Amount in recorded currency |
| `currencyCode` | `String?` | ISO currency code. `nil` = legacy entry |
| `exchangeRate` | `Double?` | Rate at time of save. `nil` = 1.0 |

### App Settings (UserDefaults / @AppStorage, existing)

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `"defaultCurrency"` | `String` | `""` | ISO code of default currency; empty = not configured |
| `"secondaryCurrency"` | `String` | `""` | ISO code of secondary currency |
| `"exchangeRate"` | `Double` | `1.0` | Current rate for new entries; NOT used for historical conversion |

---

## View State Model (new additions)

### SummaryTabView additions

`SummaryTabView` (in `ContentView.swift`) reads default currency from `@AppStorage` to pass down to `SummaryContentSection`:

```
@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
```

### SummaryContentSection additions

Accepts a `currencySymbol: String?` parameter (resolved from `defaultCurrencyCode`). Renders the symbol as a trailing text suffix on the "Total Spent" row.

### SummaryView additions (legacy modal)

`SummaryView` reads `@AppStorage("defaultCurrency")` directly and resolves symbol for display in "Total Spent" and monthly breakdown rows.

---

## Conversion Logic (already implemented, documented here for reference)

```
// SummaryViewModel.convertedCost(for:)
convertedCost = fillUp.totalCost × (fillUp.exchangeRate ?? 1.0)
```

- `exchangeRate` is stored per-entry at save time from `@AppStorage("exchangeRate")` at that moment
- Changing Settings exchange rate never mutates stored `FillUp.exchangeRate` values
- Legacy entries (nil exchangeRate) contribute their raw `totalCost` unchanged

---

## No Migration Required

All model fields are optional and were added in feature 012. SwiftData handles optional field additions without a migration step.
