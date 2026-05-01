# Feature Specification: UI Polish Improvements

**Feature Branch**: `014-ui-polish`
**Created**: 2026-04-21
**Status**: Draft
**Input**: User description: "small improvements - price of fuel in PLN should be with two digits after period but in euro with 3. In settings tab + sign on top of pane is for adding cost category - now is misleading - modification of cost categories should be resolved another way - propose something smooth. On fill panel there a lot of redundant information like date and line below again date, vehicle and vehicle, odometer and reading - make it simpler and more compact without repetitions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Fuel Price Formatting per Currency (Priority: P1)

When a user views a fill-up list row, the price-per-litre is displayed with a number of decimal places appropriate for the currency: 2 decimal places for currencies where fuel prices are typically expressed to the cent (e.g., PLN: "6.45/L"), and 3 decimal places for currencies where fuel prices are traditionally quoted to the third decimal (e.g., EUR: "1.699/L"). This matches how drivers think about and quote fuel prices in each currency.

**Why this priority**: It is a data accuracy issue — showing 3 decimals for PLN is noisy, and showing 2 decimals for EUR loses meaningful precision at the pump.

**Independent Test**: Add a fill-up in PLN at price 6.459/L and another in EUR at 1.699/L. In the fill-up list, verify the PLN fill-up shows "6.46/L" (2dp) and the EUR fill-up shows "1.699/L" (3dp).

**Acceptance Scenarios**:

1. **Given** a fill-up recorded in PLN, **When** viewing the fill-up list row, **Then** the price per litre is displayed with exactly 2 decimal places.
2. **Given** a fill-up recorded in EUR, **When** viewing the fill-up list row, **Then** the price per litre is displayed with exactly 3 decimal places.
3. **Given** a fill-up with no currency configured (legacy entry), **When** viewing the fill-up list row, **Then** the price per litre is displayed with 2 decimal places (default behaviour, unchanged).
4. **Given** a fill-up recorded in any non-EUR currency, **When** viewing the fill-up list row, **Then** the price per litre is displayed with 2 decimal places.

---

### User Story 2 — Settings: Inline Category Management (Priority: P2)

Currently a `+` button appears in the top toolbar of Settings, which is used exclusively to add cost categories. This placement is confusing — users expect toolbar buttons to act on the whole screen, not a specific section. Instead, category management actions (add, delete, reorder) should be available inline within the Categories section itself, following standard iOS list editing patterns. The top toolbar `+` button is removed entirely.

**Why this priority**: A misleading affordance actively confuses users every time they open Settings. Fixing it reduces friction.

**Independent Test**: Open Settings. Verify no `+` button exists in the top toolbar. Verify the user can add a new cost category directly within the Categories section without needing a toolbar button.

**Acceptance Scenarios**:

1. **Given** the user opens Settings, **When** the screen loads, **Then** no `+` button is visible in the top navigation bar.
2. **Given** the user views the Categories section in Settings, **When** they want to add a category, **Then** an "Add Category" affordance is visible inline within the section (e.g., a row with a `+` icon at the bottom of the list).
3. **Given** the user taps the inline "Add Category" row, **When** the action triggers, **Then** the same category creation flow as before is presented (name + icon picker).
4. **Given** the user wants to delete a category, **When** they swipe left on a category row, **Then** a Delete action is revealed (existing behaviour preserved).
5. **Given** the user wants to reorder categories, **When** they long-press or use the drag handle on a category row, **Then** they can drag to reorder (existing behaviour preserved).

---

### User Story 3 — Fill-Up Detail: Compact Layout Without Redundancy (Priority: P3)

The Fill-Up Details screen currently displays section headers and row labels that repeat the same word — "Date" → "Date", "Vehicle" → "Vehicle", "Odometer" → "Reading". This wastes vertical space and looks cluttered. The layout should be reorganised so each piece of information is shown once, clearly, without repeating the label in both the section header and the row label.

**Why this priority**: Visual polish — the screen still works without this fix, but it looks unpolished and wastes space.

**Independent Test**: Open any fill-up detail. Verify that no label or section header word appears redundantly twice for the same data point.

**Acceptance Scenarios**:

1. **Given** the user opens Fill-Up Details, **When** viewing the date information, **Then** the word "Date" appears once only (not as both section header and row label).
2. **Given** the user opens Fill-Up Details, **When** viewing the vehicle information, **Then** the vehicle name is displayed without the section header "Vehicle" and row label "Vehicle" both appearing.
3. **Given** the user opens Fill-Up Details, **When** viewing the odometer, **Then** "Odometer" and "Reading" are consolidated — the value is shown under a single clear label.
4. **Given** the fill-up has all fields populated, **When** viewing the detail screen, **Then** all information is still present — nothing is removed, only the redundant labels are eliminated.

---

### Edge Cases

- What happens if no currency is stored on a fill-up (legacy entry with nil currencyCode)? — Use 2 decimal places for price (default, unchanged behaviour).
- What if the user has EUR as their default currency and PLN as secondary? — The decimal precision follows the currency of the specific entry (the entry's stored currencyCode), not the default currency setting.
- What if all cost categories are deleted? — The Settings Categories section shows only the "Add Category" inline row.
- What if a fill-up has no note, no fuel type, and minimal fields? — The detail screen still shows all available information; empty optional sections are hidden.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The fill-up list row MUST display price per litre with 2 decimal places when the entry's currency is any currency other than EUR (or when no currency is set).
- **FR-002**: The fill-up list row MUST display price per litre with 3 decimal places when the entry's currency is EUR.
- **FR-003**: The Settings screen MUST NOT have a `+` button in the top navigation bar.
- **FR-004**: The Settings Categories section MUST provide an inline "Add Category" affordance visible directly within the section without requiring navigation or a toolbar button.
- **FR-005**: All existing category management capabilities (add, delete, reorder) MUST remain fully functional after the toolbar button is removed.
- **FR-006**: The Fill-Up Details screen MUST NOT display the same word as both a section header and a row label for the same data field.
- **FR-007**: The Fill-Up Details screen MUST display all existing information — no data fields may be removed, only redundant labels eliminated.
- **FR-008**: The Fill-Up Details layout MUST be more compact than the current layout (fewer lines of vertical space used for the same data).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of EUR fill-up list rows display price per litre with exactly 3 decimal places.
- **SC-002**: 100% of non-EUR fill-up list rows display price per litre with exactly 2 decimal places.
- **SC-003**: The Settings top navigation bar contains 0 action buttons (the `+` is removed).
- **SC-004**: A user can add a cost category from within the Categories section in 2 taps or fewer.
- **SC-005**: The Fill-Up Details screen has 0 instances of the same word appearing as both section header and immediate row label.
- **SC-006**: All three improvements are visible without any app configuration changes — they apply to all users immediately.

## Assumptions

- EUR is the only currency that uses 3 decimal places for fuel pricing. All other currencies (PLN, GBP, USD, CHF, etc.) use 2 decimal places.
- The decimal precision rule applies to the fill-up list row price display ("X.XX/L" or "X.XXX/L"). It does not apply to other views such as the fill-up detail or edit screens at this time.
- The inline "Add Category" affordance is a tappable row at the bottom of the categories list, styled with a `+` icon and "Add Category" label — consistent with standard iOS list patterns.
- The Fill-Up Details restructuring removes section headers for Date, Vehicle, and Odometer and instead uses concise `LabeledContent` rows with clear standalone labels (e.g., "Date", "Vehicle", "Odometer") directly, without a wrapping section that duplicates the label.
- No data is lost or hidden — the goal is label deduplication and layout compaction only.
