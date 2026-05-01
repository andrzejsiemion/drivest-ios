# Feature Specification: Statistics in Default Currency with Historical Exchange Rates

**Feature Branch**: `013-stats-default-currency`
**Created**: 2026-04-21
**Status**: Draft
**Input**: User description: "All statistics should be calculated and shown by default currency - the exchange rate should be remembered by note because it may vary at time."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — View Statistics Always in Default Currency (Priority: P1)

A user who has added fill-ups and costs in a mix of default and secondary currencies opens the Statistics tab. All totals (total cost, monthly summaries, averages) are displayed in the default currency regardless of which currency each entry was originally recorded in. There is no ambiguity about what currency the figures represent.

**Why this priority**: This is the core of the feature — without it, statistics are meaningless when multiple currencies are involved. It is the minimum viable outcome.

**Independent Test**: Configure a default currency (e.g., PLN) and a secondary currency (e.g., EUR). Add one fill-up in PLN and one in EUR. Open Statistics. Verify all cost totals are shown in PLN only, with no EUR amounts visible in aggregated figures.

**Acceptance Scenarios**:

1. **Given** the user has fill-ups recorded in two different currencies, **When** they open the Statistics tab, **Then** all aggregated cost totals are shown in the default currency only.
2. **Given** the user has no secondary currency configured, **When** they open Statistics, **Then** all amounts show in the default currency (no change in behavior).
3. **Given** all entries were recorded in the default currency, **When** the user views Statistics, **Then** totals match the raw amounts exactly (no conversion applied).

---

### User Story 2 — Historical Exchange Rate Accuracy (Priority: P2)

A user recorded a fill-up six months ago when the EUR/PLN rate was 4.20. Today the rate in Settings is 4.30. When viewing statistics, the six-month-old fill-up is converted using the 4.20 rate that was in effect at the time of recording — not today's 4.30 rate. This ensures historical statistics reflect the actual money spent at the time.

**Why this priority**: Without per-entry rate storage, changing the exchange rate in Settings would silently alter all historical statistics, making the data unreliable. This story protects data integrity.

**Independent Test**: Record a fill-up in secondary currency with rate 4.20. Change the exchange rate in Settings to 4.50. Open Statistics and verify the old fill-up's contribution to totals still uses 4.20 (not 4.50).

**Acceptance Scenarios**:

1. **Given** a fill-up was recorded with exchange rate 4.20, **When** the user later changes the exchange rate in Settings to 4.50, **Then** Statistics still convert that fill-up at 4.20.
2. **Given** a new fill-up is added after the rate change, **When** Statistics are displayed, **Then** the new entry is converted at 4.50 and the old entry at 4.20.
3. **Given** a fill-up in the default currency (rate 1.0), **When** the user views Statistics, **Then** no conversion is applied and the amount is used as-is.

---

### User Story 3 — Default Currency Label Shown on Statistics (Priority: P3)

When statistics are displayed, the default currency symbol or code is shown alongside all aggregated cost figures so the user always knows which currency the totals are in. This provides unambiguous context especially for users who regularly switch between currencies.

**Why this priority**: Context is important but the feature still delivers value without it. Labelling is a polish concern.

**Independent Test**: Configure PLN as the default currency. Open Statistics. Verify the total cost and monthly summary amounts all have "zł" or "PLN" displayed next to them.

**Acceptance Scenarios**:

1. **Given** a default currency is configured, **When** the user views Statistics, **Then** all cost totals display the default currency symbol or code.
2. **Given** no default currency is configured, **When** the user views Statistics, **Then** no currency symbol is displayed (backward compatible with legacy data).

---

### Edge Cases

- What happens when an entry has no stored exchange rate (legacy data recorded before this feature)? — It should be treated as if the rate is 1.0 (i.e., the amount is assumed to already be in the default currency).
- What happens when the user has no default currency configured but has entries with stored exchange rates? — Amounts are displayed as-is with no conversion or currency label.
- What happens when the exchange rate stored on an entry is zero or negative? — It should fall back to 1.0 to avoid nonsensical totals.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Statistics totals (overall and per-period) MUST be expressed in the default currency at all times.
- **FR-002**: When converting an entry from a secondary currency to the default currency, the system MUST use the exchange rate stored with that specific entry at the time it was recorded.
- **FR-003**: The system MUST NOT use the current exchange rate from Settings when computing historical statistics — only the per-entry stored rate is used.
- **FR-004**: Entries recorded in the default currency (or with no currency metadata) MUST be included in totals at their original value without any conversion.
- **FR-005**: The default currency symbol or code MUST be displayed alongside all aggregated cost figures in the Statistics view.
- **FR-006**: Legacy entries with no stored exchange rate MUST be treated as rate 1.0 (no conversion) to preserve backward compatibility.
- **FR-007**: The Statistics view MUST remain unchanged (no currency label, no conversion) when no default currency has been configured by the user.

### Key Entities *(include if feature involves data)*

- **Fill-Up Entry**: A recorded refuelling event; has an optional currency code and an optional exchange rate capturing the conversion rate at time of recording.
- **Cost Entry**: A recorded vehicle expense; same optional currency and exchange rate fields as fill-up.
- **Default Currency**: The user's chosen display currency stored in app settings; all statistics are expressed in this currency.
- **Exchange Rate (per-entry)**: The rate stored with each individual entry at save time; represents "1 secondary = X default" at the moment of recording. This is the authoritative rate for historical conversions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of cost aggregates in the Statistics view are expressed in the default currency when a default currency is configured.
- **SC-002**: Changing the exchange rate in Settings does not alter the converted value of any previously recorded entry when viewed in Statistics.
- **SC-003**: Statistics for legacy entries (no stored currency/rate) remain numerically identical before and after the feature is active.
- **SC-004**: The default currency symbol or code is visible on all cost figures in Statistics when a default currency is configured.
- **SC-005**: Users can view Statistics immediately after changing the exchange rate and confirm historical figures have not changed.

## Assumptions

- The app already stores a currency code and exchange rate on each fill-up and cost entry at the time of saving (implemented in feature 012-dual-currency).
- Entries with a `nil` exchange rate are treated as rate 1.0 — they are in the default currency and require no conversion.
- The exchange rate direction is "1 secondary = X default" (e.g., 1 EUR = 4.30 PLN), consistent with the existing convention from feature 012.
- Statistics in this context means the aggregated totals and monthly summaries shown on the Statistics tab — not individual entry rows in the fill-up or cost lists.
- Individual entry rows in fill-up/cost lists already show original amounts with their recorded currency symbol; this feature does not change that behaviour.
- Volume statistics (litres) are not affected — only cost amounts are converted.
