# Research: Edit Exchange Rate

## Decision 1: Model fields prerequisite

**Decision**: Both `FillUp` and `CostEntry` require `var currencyCode: String?` and `var exchangeRate: Double?` optional fields before exchange rate editing can be implemented. These fields are currently absent from the SwiftData models.

**Rationale**: SwiftData handles optional fields with nil defaults transparently during schema migration — no version bump or migration block is required. Adding `var currencyCode: String?` and `var exchangeRate: Double?` as bare stored properties (not in the init) is the migration-safe pattern used throughout the project.

**Alternatives considered**: Adding non-optional fields with defaults would require a schema version migration. Optional nil-default fields avoid this entirely.

---

## Decision 2: When to show the exchange rate field

**Decision**: Show the exchange rate input field only when the record's `currencyCode` is set and differs from the device's `@AppStorage("defaultCurrency")`. When `currencyCode` is nil or matches the default currency, the field is hidden.

**Rationale**: The exchange rate is only meaningful when a conversion exists. Showing a "Rate: 1.0" field for single-currency records would confuse users and violate the Simple UX principle.

**Alternatives considered**: Always showing the field with 1.0 when not applicable — rejected because it adds visual noise for the majority of users who use only one currency.

---

## Decision 3: Exchange rate field label

**Decision**: Show the label as `"Rate (\(currencyCode) → \(defaultCurrency))"` when both codes are available, e.g. "Rate (EUR → PLN)". Fall back to just "Exchange Rate" if only one code is known.

**Rationale**: Users need context to know what the rate represents. Showing both currency codes eliminates ambiguity (e.g., is it EUR/PLN or PLN/EUR?).

**Alternatives considered**: Plain "Exchange Rate" label — rejected because it doesn't clarify direction when multiple currencies may be in use.

---

## Decision 4: Exchange rate number parsing

**Decision**: Parse the exchange rate text using the same locale-aware `parseDouble` approach used elsewhere: try `Double(text)` first, then replace `Locale.current.decimalSeparator` with `"."` and retry.

**Rationale**: Decimal separator varies by locale (period vs comma). Hard-coding `Double(text)` fails silently on Polish and other European locales, making the field appear broken.

**Alternatives considered**: `NumberFormatter` with `.decimal` style — technically more correct but adds complexity. The two-step fallback is sufficient for the numeric input in this context.

---

## Decision 5: Validation

**Decision**: `exchangeRate` must be > 0 when shown. `isValid` in the ViewModel must include `exchangeRate > 0` as an additional guard when a secondary currency is present.

**Rationale**: A zero or negative exchange rate produces nonsensical converted amounts and would silently corrupt data.

**Alternatives considered**: Allowing any non-nil value including negative — rejected; financial data must be positive.
