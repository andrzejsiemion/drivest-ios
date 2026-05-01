# Feature Specification: Fill-Up Detail & Edit

**Feature Branch**: `005-fillup-detail-edit`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "On history tab I want to see more details and make possible to edit values when I click history position"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Fill-Up Details (Priority: P1)

As a vehicle owner, I want to tap on a fill-up entry in the history list to see all its details on a dedicated screen so that I can review the full information about a specific refueling event.

**Why this priority**: Viewing details is the prerequisite for editing — users need to see all data before they can decide what to change.

**Independent Test**: Can be tested by logging a fill-up and tapping on it in the history list. A detail screen appears showing all fields: date, vehicle, odometer, fuel type, price per unit, volume, total cost, full tank status, efficiency, and note.

**Acceptance Scenarios**:

1. **Given** I have fill-ups in my history, **When** I tap on a fill-up row, **Then** I navigate to a detail screen showing all fields for that entry.
2. **Given** I am on the fill-up detail screen, **When** I view the details, **Then** I see: date and time, vehicle name, odometer reading, fuel type (if set), price per unit, volume, total cost, full tank indicator, efficiency (if calculated), and note (if present).
3. **Given** the fill-up has no note or fuel type, **When** I view the details, **Then** those fields are either hidden or shown as "Not set" — no blank or broken display.

---

### User Story 2 - Edit a Fill-Up (Priority: P2)

As a vehicle owner, I want to edit an existing fill-up entry so that I can correct mistakes (e.g., wrong odometer reading, wrong price) after the fact.

**Why this priority**: Editing depends on having the detail screen (US1) and is the user's explicit request.

**Independent Test**: Can be tested by tapping a fill-up, tapping Edit, changing a field (e.g., price), saving, and verifying the updated value appears in both the detail view and the history list.

**Acceptance Scenarios**:

1. **Given** I am on the fill-up detail screen, **When** I tap an "Edit" button, **Then** the fields become editable in a form (same layout as the add fill-up form, pre-populated with current values).
2. **Given** I am editing a fill-up, **When** I change the price per unit, **Then** the total cost auto-recalculates (maintaining the existing auto-calc behavior).
3. **Given** I have made changes, **When** I tap "Save", **Then** the fill-up is updated, efficiency is recalculated if needed, and I return to the detail screen showing the new values.
4. **Given** I am editing, **When** I tap "Cancel", **Then** no changes are saved and I return to the detail screen with original values.
5. **Given** I edit the odometer reading, **When** I save, **Then** the system validates the odometer is still monotonically increasing relative to adjacent entries.

---

### Edge Cases

- What happens when the user edits a fill-up that affects efficiency calculations? → Efficiency is recalculated for the edited entry and all subsequent entries of the same vehicle.
- What happens when the user changes the odometer to a value that breaks ordering? → The save is rejected with a validation error explaining the constraint.
- What happens when the user edits the only fill-up? → Edit works normally; efficiency remains nil (still only one entry).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to tap a fill-up entry in the history list to navigate to a detail screen.
- **FR-002**: The detail screen MUST display all fill-up fields: date, vehicle name, odometer reading, fuel type, price per unit, volume, total cost, full tank status, efficiency, and note.
- **FR-003**: The detail screen MUST include an "Edit" action (button or toolbar item).
- **FR-004**: The edit screen MUST pre-populate all fields with the fill-up's current values.
- **FR-005**: The edit screen MUST support the same auto-calculation behavior as the add form (two-of-three: price, volume, total).
- **FR-006**: On save after edit, the system MUST validate odometer ordering against adjacent entries.
- **FR-007**: On save after edit, the system MUST recalculate efficiency for the edited entry and all subsequent entries of the same vehicle.
- **FR-008**: The edit screen MUST allow changing: date, odometer, fuel type, price, volume, total cost, full tank toggle, and note. Vehicle assignment is NOT editable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can navigate from history list to fill-up detail in under 1 second (single tap).
- **SC-002**: All fill-up fields are visible on the detail screen with zero missing data for any entry.
- **SC-003**: Users can complete an edit (open → change → save) in under 15 seconds.
- **SC-004**: After editing, efficiency values are recalculated within 1 second and displayed correctly.

## Assumptions

- The detail screen is a navigation push (not a modal/sheet) from the history list.
- Vehicle assignment cannot be changed when editing — if the user logged a fill-up to the wrong vehicle, they should delete and re-create it.
- The edit form reuses the same layout and auto-calculation logic as the add fill-up form.
- Deleting a fill-up from the detail screen is out of scope for this feature (already available via swipe in the list).
