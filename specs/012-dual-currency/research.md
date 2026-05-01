# Research: Dual Currency Support

**Feature**: 012-dual-currency
**Date**: 2026-04-21

## R1: Currency Storage Pattern

**Decision**: Store currency settings using `@AppStorage` with string keys for currency codes and a Double for the exchange rate. This is app-level configuration, not per-entity data — no SwiftData model needed for settings.

**Rationale**: Currency settings are simple key-value pairs (two strings + one double). `@AppStorage`/`UserDefaults` is the standard iOS pattern for app-level preferences. Using SwiftData would add unnecessary complexity for 3 scalar values.

**Alternatives considered**:
- SwiftData model for currency settings: Overkill for 3 values; requires fetch queries
- Plist file: More code than @AppStorage for the same result
- Environment object: Doesn't persist across launches

## R2: Per-Entry Currency Metadata

**Decision**: Add `currencyCode: String?` and `exchangeRate: Double?` fields to both `FillUp` and `CostEntry` models. Optional fields ensure backward compatibility — existing entries with `nil` values are treated as default-currency entries.

**Rationale**: Each entry must record its own currency and rate for historical accuracy (FR-009, FR-016). Optional fields avoid migration issues with existing data. String currency codes (ISO 4217) are compact and universally understood.

**Alternatives considered**:
- Separate CurrencyInfo model with relationship: Over-engineered for 2 fields
- Non-optional with default values: Requires data migration for existing entries
- Store only converted amount: Loses original entry data

## R3: Currency Toggle UI Pattern

**Decision**: Use a tappable `Button` styled as a pill/chip next to cost fields showing the active currency code (e.g., "PLN"). Tapping it toggles to the secondary currency. Show the converted equivalent as a secondary line below the amount field.

**Rationale**: A single-tap toggle is the fastest interaction (FR-006, SC-002). A pill button is compact and non-intrusive. Showing the conversion inline keeps the user informed without extra navigation.

**Alternatives considered**:
- Picker/dropdown: Overkill for 2 options, requires more taps
- Segmented control: Takes too much horizontal space in a form row
- Separate currency field: Adds unnecessary form complexity

## R4: Statistics Conversion Strategy

**Decision**: When calculating totals and averages, convert each entry to the default currency using that entry's stored `exchangeRate`. Entries with no currency metadata (legacy) are treated as default-currency at rate 1.0.

**Rationale**: Using per-entry rates (FR-013, FR-016) ensures historical accuracy. Legacy entries with nil values naturally fall through as 1.0 multiplier.

**Alternatives considered**:
- Use current exchange rate for all: Inaccurate, violates FR-016
- Dual totals (one per currency): Confusing UX, doesn't match spec

## R5: Currency List

**Decision**: Use a hardcoded list of common currencies with ISO 4217 codes and symbols. Include ~20 currencies covering Europe, major global currencies, and neighboring regions. Stored as a simple enum or struct with `code`, `symbol`, and `name`.

**Rationale**: A hardcoded list avoids external API dependencies (Constitution IV: Minimal Dependencies). The user manually enters exchange rates, so no live rate feeds are needed.

**Alternatives considered**:
- Fetch from API: Adds network dependency, violates offline-capable constraint
- Use Foundation's `Locale.Currency`: Available on iOS 16+ but doesn't provide symbols reliably across all currencies
- Full ISO 4217 list (170+ currencies): Overwhelming for the user; 20 covers the use case
