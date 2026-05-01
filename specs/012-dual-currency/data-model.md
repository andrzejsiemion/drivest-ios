# Data Model: Dual Currency Support

**Feature**: 012-dual-currency
**Date**: 2026-04-21

## New Entities

### CurrencyDefinition (Value type, not persisted)

Represents a supported currency for selection in the UI.

| Field | Type | Description |
|-------|------|-------------|
| `code` | String | ISO 4217 code (e.g., "PLN", "EUR") |
| `symbol` | String | Display symbol (e.g., "zł", "€") |
| `name` | String | Full name (e.g., "Polish Złoty", "Euro") |

**Supported currencies**: USD ($), EUR (€), GBP (£), PLN (zł), CZK (Kč), CHF (Fr), SEK (kr), NOK (kr), DKK (kr), HUF (Ft), RON (lei), BGN (лв), TRY (₺), UAH (₴), JPY (¥), CAD (C$), AUD (A$)

### CurrencySettings (App-level, UserDefaults)

| Field | Storage Key | Type | Default |
|-------|------------|------|---------|
| `defaultCurrencyCode` | `defaultCurrency` | String? | nil (no currency) |
| `secondaryCurrencyCode` | `secondaryCurrency` | String? | nil (disabled) |
| `exchangeRate` | `exchangeRate` | Double | 1.0 |

**Validation**:
- `exchangeRate` must be > 0
- `defaultCurrencyCode` ≠ `secondaryCurrencyCode`
- If `defaultCurrencyCode` is nil, currency features are hidden (backward compatible)

## Modified Entities

### FillUp (SwiftData model)

**New optional fields**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `currencyCode` | String? | nil | ISO 4217 code of the currency used for this entry |
| `exchangeRate` | Double? | nil | Exchange rate to default currency at time of entry |

- `nil` values = legacy entry, treated as default currency at rate 1.0
- `totalCost` always stores the amount in the entered currency
- To get default-currency equivalent: `totalCost * (exchangeRate ?? 1.0)` when entry is in secondary currency, or `totalCost` when in default currency

### CostEntry (SwiftData model)

**New optional fields** (identical to FillUp):

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `currencyCode` | String? | nil | ISO 4217 code of the currency used |
| `exchangeRate` | Double? | nil | Exchange rate to default currency at time of entry |

## State Flow

```
Settings (UserDefaults)
    ├── defaultCurrencyCode → used as form default
    ├── secondaryCurrencyCode → available via toggle
    └── exchangeRate → applied when secondary currency selected

AddFillUpView / AddCostView
    ├── @State selectedCurrency (defaults to defaultCurrencyCode)
    ├── Currency toggle button → switches between default/secondary
    ├── Conversion reference line → amount × exchangeRate
    └── On save → stores currencyCode + exchangeRate on entry

FillUpListView / CostListView
    └── Display: original amount + currency, converted equivalent if different

SummaryViewModel
    └── Convert all entries to default currency using per-entry exchangeRate
```
