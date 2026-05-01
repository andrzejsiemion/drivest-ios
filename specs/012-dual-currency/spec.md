# Feature Specification: Dual Currency Support

**Feature Branch**: `012-dual-currency`
**Created**: 2026-04-21
**Status**: Draft
**Input**: User description: "User can pay with different currency - in settings should be able to specify default currency as well as second one with exchange rate. When adding info about fill-up or cost default currency should be used but user should be able to easily change it to second one when needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Default and Secondary Currency (Priority: P1)

A user who frequently travels between countries (e.g., Poland and Germany) opens Settings and configures their default currency as PLN and their secondary currency as EUR. They enter the current exchange rate (e.g., 1 EUR = 4.30 PLN). The settings are saved and apply to all future entries.

**Why this priority**: Without currency configuration, no other currency feature can function. This is the foundational setup.

**Independent Test**: Can be fully tested by opening Settings, selecting two currencies, entering an exchange rate, saving, and verifying the values persist.

**Acceptance Scenarios**:

1. **Given** the user opens Settings, **When** they select a default currency from a list of common currencies, **Then** the selection is saved and displayed as the active default.
2. **Given** the user has set a default currency, **When** they select a secondary currency and enter an exchange rate, **Then** both the secondary currency and rate are saved.
3. **Given** the user has configured currencies, **When** they close and reopen Settings, **Then** the previously saved currencies and exchange rate are displayed.
4. **Given** the user changes the exchange rate, **When** they save, **Then** the new rate applies to all future entries (existing entries retain their original recorded values).

---

### User Story 2 - Add Fill-Up with Default Currency (Priority: P2)

A user adds a fill-up. The form pre-fills with the default currency. The total cost and price per unit fields display the default currency symbol. The user completes the form and saves — the entry is stored in the default currency.

**Why this priority**: This is the primary flow — most fill-ups use the default currency. Must work seamlessly before the currency-switching feature.

**Independent Test**: Configure a default currency, add a fill-up, verify the currency symbol appears and the entry is saved with the correct currency.

**Acceptance Scenarios**:

1. **Given** the user has set PLN as the default currency, **When** they open the Add Fill-Up form, **Then** cost fields show the PLN currency symbol.
2. **Given** the user fills in a fill-up with total cost 250 PLN, **When** they save, **Then** the entry is stored with amount 250 and currency PLN.
3. **Given** no currencies are configured, **When** the user adds a fill-up, **Then** no currency symbol is shown (backward-compatible with existing behavior).

---

### User Story 3 - Switch to Secondary Currency When Adding Entry (Priority: P3)

A user is adding a fill-up while abroad. The form defaults to PLN but they tap a currency toggle/selector to switch to EUR. The price fields update to show EUR symbol. They enter the cost in EUR and save. The entry stores both the original EUR amount and the converted PLN equivalent for statistics.

**Why this priority**: This is the key differentiating feature — quick currency switching — but depends on US1 and US2 being complete.

**Independent Test**: Configure dual currencies, add a fill-up, switch to secondary currency, enter amount, save, verify both currencies are stored.

**Acceptance Scenarios**:

1. **Given** the user has configured PLN (default) and EUR (secondary), **When** they open the Add Fill-Up form, **Then** a currency toggle is visible showing "PLN" with an option to switch to "EUR".
2. **Given** the user switches to EUR in the fill-up form, **When** they enter a total cost of 50 EUR, **Then** the form shows the equivalent in PLN (215 PLN at rate 4.30) as a reference.
3. **Given** the user saves a fill-up in EUR, **When** the entry appears in the fill-up list, **Then** it displays the original EUR amount with a converted PLN amount shown alongside.
4. **Given** the user is adding a cost entry, **When** they switch to the secondary currency, **Then** the same currency toggle and conversion behavior applies as for fill-ups.

---

### Edge Cases

- Exchange rate set to 0 or negative: Validation rejects it (FR-014); save button disabled until valid.
- Secondary currency removed after entries recorded in it: Existing entries retain their stored currency code and rate; they continue to display correctly. The toggle is hidden in forms but list/detail views still show historical currency.
- Statistics with mixed currencies: All amounts converted to default currency using each entry's stored exchange rate (FR-013).
- Exchange rate changed: Existing entries retain their original rate (FR-016); only future entries use the new rate.
- Default and secondary set to same currency: Prevented by validation (FR-017); picker excludes the already-selected currency.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow the user to select a default currency from a predefined list of common currencies in Settings.
- **FR-002**: System MUST allow the user to select a secondary currency from the same list in Settings.
- **FR-003**: System MUST allow the user to enter an exchange rate expressed as "1 [secondary] = X [default]" (e.g., "1 EUR = 4.30 PLN"). The rate is how much default currency per 1 unit of secondary currency.
- **FR-004**: System MUST persist currency settings across app launches.
- **FR-005**: The Add Fill-Up form MUST display the default currency symbol next to cost-related fields.
- **FR-006**: The Add Fill-Up form MUST provide a single-tap toggle to switch between default and secondary currency.
- **FR-007**: When the secondary currency is selected in the form, the system MUST display the converted equivalent in the default currency as a reference.
- **FR-008**: Each fill-up entry MUST store the currency code and original amount as entered by the user.
- **FR-009**: Each fill-up entry MUST store the exchange rate used at the time of entry for historical accuracy.
- **FR-010**: The Add Cost form MUST support the same currency toggle and conversion as the fill-up form.
- **FR-011**: Each cost entry MUST store the currency code, original amount, and exchange rate used.
- **FR-012**: The fill-up list and cost list MUST display amounts in their original currency with the default-currency equivalent shown when different.
- **FR-013**: Statistics and summaries MUST calculate totals by converting all amounts to the default currency using each entry's stored exchange rate.
- **FR-014**: The exchange rate MUST be validated to be a positive number greater than zero.
- **FR-015**: If no currencies are configured, the system MUST behave identically to the current version (no currency symbols, no toggle).
- **FR-016**: Changing the exchange rate in Settings MUST NOT retroactively modify existing entries.
- **FR-017**: The default and secondary currencies MUST NOT be allowed to be the same.

### Key Entities

- **Currency Setting**: The user's configured default currency, secondary currency, and exchange rate — stored as app-level settings.
- **Entry Currency Info**: Per-entry metadata storing the currency code used and the exchange rate at the time of recording.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can configure currencies and exchange rate in under 30 seconds.
- **SC-002**: Switching currency when adding an entry requires exactly 1 tap.
- **SC-003**: 100% of entries display their original currency and converted equivalent correctly.
- **SC-004**: Statistics totals are accurate within rounding tolerance (±0.01) when mixing currencies.
- **SC-005**: Existing users with no currency configuration experience zero behavior changes.

## Clarifications

### Session 2026-04-21

- Q: Exchange rate direction? → A: "1 secondary = X default" (e.g., 1 EUR = 4.30 PLN). The rate expresses how much of the home/default currency equals 1 unit of the foreign/secondary currency.

## Assumptions

- The app supports exactly two currencies (one default, one secondary) — not an arbitrary number.
- Exchange rates are manually entered by the user, not fetched from an external service.
- The predefined currency list includes at least: USD, EUR, GBP, PLN, CZK, CHF, SEK, NOK, DKK, HUF, RON, BGN, HRK, TRY, UAH, RUB, JPY, CAD, AUD.
- Currency settings are global (not per-vehicle).
- Existing entries created before this feature have no currency metadata and are treated as default-currency entries.
- Conversion reference shown in the form is informational — the stored value is always what the user entered.
