# Feature Specification: Vehicle Cost Categories

**Feature Branch**: `008-cost-categories`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "On Cost tab there should be no information for fuel - instead of that user should be able to add there cost categories like Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log a Non-Fuel Vehicle Cost (Priority: P1)

As a vehicle owner, I want to record non-fuel expenses (such as insurance payments, service appointments, tolls, car washes, parking fees, maintenance work, and traffic tickets) so that I can track the full cost of owning and operating my vehicle beyond just fuel.

**Why this priority**: This is the core deliverable — without the ability to add a cost entry, the Costs tab has no value.

**Independent Test**: Can be tested by tapping the Costs tab, adding a new cost entry with a category, amount, and date, and confirming it appears in the costs list.

**Acceptance Scenarios**:

1. **Given** I am on the Costs tab, **When** I tap the add button, **Then** a form appears for entering a new cost entry.
2. **Given** the add cost form is open, **When** I select a category (e.g., "Insurance"), enter an amount, and confirm, **Then** the entry is saved and appears in the Costs list.
3. **Given** cost entries exist, **When** I view the Costs tab, **Then** I see a list of entries showing category, amount, and date.
4. **Given** no cost entries exist, **When** I view the Costs tab, **Then** an empty state guides me to add my first cost.
5. **Given** a cost entry exists, **When** I swipe to delete it, **Then** it is removed from the list.

---

### User Story 2 - View Costs Per Vehicle (Priority: P2)

As a vehicle owner with multiple vehicles, I want cost entries to be associated with a specific vehicle so that I can see the true total cost of each vehicle separately.

**Why this priority**: Without per-vehicle association, the Costs tab would be unusable for users with more than one vehicle. However, single-vehicle users can still benefit from User Story 1 alone.

**Independent Test**: Add cost entries for two different vehicles; switch between vehicles using the vehicle selector; confirm only costs for the selected vehicle are displayed.

**Acceptance Scenarios**:

1. **Given** I have multiple vehicles, **When** I view the Costs tab, **Then** I can select which vehicle's costs to display (using the same vehicle picker as the Fuel tab).
2. **Given** I select a vehicle, **When** the Costs list loads, **Then** only cost entries for that vehicle are shown.

---

### User Story 3 - View Cost Summary by Category (Priority: P3)

As a vehicle owner, I want to see a breakdown of my costs by category so that I understand where my money is going beyond fuel.

**Why this priority**: Useful analytics, but the app still delivers core value (logging costs) without it. Can be added after US1 and US2 are stable.

**Independent Test**: With cost entries across multiple categories, view the Costs tab summary section and confirm totals per category are displayed correctly.

**Acceptance Scenarios**:

1. **Given** I have cost entries in multiple categories, **When** I view the Costs tab, **Then** I see a summary showing the total spent per category.
2. **Given** I have no cost entries, **When** I view the Costs tab summary, **Then** no summary is shown (or an empty state is displayed).

---

### Edge Cases

- The Costs tab must NOT display any fuel fill-up data — it is exclusively for non-fuel costs.
- If a vehicle has no cost entries, the empty state must guide the user to add their first cost.
- A cost entry without an optional note is still valid.
- The predefined categories are: Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets. Custom categories are out of scope for this version.
- Deleting a vehicle removes all associated cost entries.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Costs tab MUST display a list of non-fuel cost entries for the selected vehicle.
- **FR-002**: Users MUST be able to add a new cost entry by specifying: category (from predefined list), amount, date, and an optional note.
- **FR-003**: Predefined cost categories MUST include: Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets.
- **FR-004**: The Costs tab MUST NOT display any fuel fill-up history or fuel-related data.
- **FR-005**: Users MUST be able to delete a cost entry.
- **FR-006**: Cost entries MUST be associated with a specific vehicle.
- **FR-007**: The Costs tab MUST show an empty state with a call-to-action when no cost entries exist for the selected vehicle.
- **FR-008**: The Costs tab MUST display the total spent across all cost categories for the selected vehicle.

### Key Entities

- **CostEntry**: Represents a single non-fuel expense. Attributes: vehicle (reference), category, amount, date, optional note.
- **CostCategory**: An enumeration of predefined categories — Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a cost entry in under 4 taps from the Costs tab.
- **SC-002**: The Costs tab displays zero fuel-related data — 100% of content is non-fuel costs.
- **SC-003**: All 7 predefined cost categories are selectable when adding a new entry.
- **SC-004**: Cost entries are correctly filtered per vehicle — switching vehicles shows only that vehicle's costs.
- **SC-005**: Total spent is correctly calculated and displayed for all entries of the selected vehicle.

## Assumptions

- Custom (user-defined) cost categories are out of scope for this version — only the 7 predefined categories are supported.
- Each cost entry has exactly one category.
- The add cost form requires: category, amount, and date. Note is optional.
- Costs are stored locally on-device (same storage mechanism as fill-ups).
- The vehicle selector on the Costs tab mirrors the one on the Fuel tab — users select a vehicle to filter costs.
- Editing an existing cost entry is out of scope for this version (delete and re-add workflow is acceptable).
- Currency display follows the same formatting already used in the app.
