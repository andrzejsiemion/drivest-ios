# Feature Specification: Edit Exchange Rate

**Feature Branch**: `016-edit-exchange-rate`
**Created**: 2026-04-22
**Status**: Draft
**Input**: User description: "When user edit fillup or cost should be able to edit also exchange rate"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Edit Exchange Rate on Fill-Up (Priority: P1)

When a user opens a previously saved fill-up for editing, they can view and change the exchange rate that was recorded with that fill-up. This is needed when the exchange rate was captured incorrectly at the time of recording or when the user wants to correct a historical entry.

**Why this priority**: Fill-up records are the core data in the app. Incorrect exchange rates distort the displayed cost in the default currency across summaries and statistics.

**Independent Test**: Open an existing fill-up that was saved with a secondary currency, edit the exchange rate to a new value, save, then verify that the displayed converted amount in the fill-up list and detail view reflects the updated rate.

**Acceptance Scenarios**:

1. **Given** a fill-up was saved with a secondary currency and exchange rate, **When** the user opens the edit form, **Then** the current exchange rate is displayed in an editable field.
2. **Given** the user changes the exchange rate value, **When** the user saves, **Then** the fill-up is updated with the new exchange rate and all converted amounts are recalculated.
3. **Given** a fill-up was saved with no exchange rate (primary currency only), **When** the user opens the edit form, **Then** no exchange rate field is shown.
4. **Given** the user clears the exchange rate field, **When** the user tries to save, **Then** the form prevents saving and shows a validation message requiring a positive value.

---

### User Story 2 - Edit Exchange Rate on Cost Entry (Priority: P2)

When a user opens a previously saved cost entry for editing, they can view and change the exchange rate recorded with that cost. This ensures cost entries in foreign currencies can be corrected the same way fill-ups can.

**Why this priority**: Cost entries follow the same currency model as fill-ups. Parity between the two record types is important for consistent user experience, but costs are secondary to fill-ups.

**Independent Test**: Open an existing cost entry saved with a secondary currency, change the exchange rate, save, and verify the converted amount shown in the cost list and detail view updates correctly.

**Acceptance Scenarios**:

1. **Given** a cost entry was saved with a secondary currency and exchange rate, **When** the user opens the edit form, **Then** the current exchange rate is shown in an editable field.
2. **Given** the user enters a new exchange rate, **When** the user saves, **Then** the cost entry reflects the new rate and the converted amount updates everywhere it is displayed.
3. **Given** a cost entry saved with no exchange rate (primary currency only), **When** the user opens the edit form, **Then** no exchange rate field is shown.

---

### Edge Cases

- What happens when the user enters 0 or a negative number as exchange rate? → Field is invalid; save is blocked with an explanatory message.
- What happens when the stored currency code is the same as the default currency? → Exchange rate field is not shown (rate would always be 1.0 and editing it has no meaning).
- What if the exchange rate field is left blank? → Save is blocked; field must contain a valid positive number when shown.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The fill-up edit form MUST display the stored exchange rate in an editable numeric field when the fill-up was originally saved with a currency different from the default currency.
- **FR-002**: The cost edit form MUST display the stored exchange rate in an editable numeric field when the cost was originally saved with a currency different from the default currency.
- **FR-003**: The exchange rate field MUST be hidden when the record was saved using the default currency (no conversion needed).
- **FR-004**: The system MUST validate that the exchange rate is a positive number greater than zero before allowing the record to be saved.
- **FR-005**: Upon saving, the system MUST persist the updated exchange rate and all displayed converted amounts MUST reflect the new value immediately.
- **FR-006**: The edit form MUST show a label identifying the exchange rate field, including which currency pair it represents (e.g., "Rate: EUR → PLN").
- **FR-007**: The exchange rate field MUST use a numeric decimal input method.

### Key Entities

- **FillUp**: An existing fill-up record with optional `currencyCode` and `exchangeRate` fields. The `exchangeRate` converts the recorded amount from the fill-up currency to the default currency.
- **CostEntry**: An existing cost entry record with optional `currencyCode` and `exchangeRate` fields. Same conversion semantics as FillUp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can update the exchange rate on any fill-up or cost entry that was saved in a secondary currency within 3 taps from the record list.
- **SC-002**: 100% of converted amounts displayed in list views, detail views, and summaries reflect the updated exchange rate immediately after saving.
- **SC-003**: The exchange rate field is absent for records saved in the default currency — users are never presented with irrelevant fields.
- **SC-004**: Invalid exchange rate values (zero, negative, non-numeric) are rejected before save with a clear message in 100% of cases.

## Assumptions

- The app already supports dual-currency recording for both fill-ups and cost entries; this feature adds editing capability for the exchange rate field that exists in those records.
- The currency code of a record is not editable in this feature — only the exchange rate. Changing the currency itself is considered out of scope.
- The default currency is stored in app settings and is used only to determine whether to show the exchange rate field; it is not changed by this feature.
- Only one exchange rate per record is supported (the rate at the time of recording); multi-rate or historical-rate lookups are out of scope.
