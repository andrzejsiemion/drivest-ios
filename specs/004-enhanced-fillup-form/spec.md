# Feature Specification: Enhanced Fill-Up Form

**Feature Branch**: `004-enhanced-fillup-form`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "Add Fill-up functionality - on top of this tab should be dropbox with vehicle name then odo counter next fuel type (that should be prefilled from vehicle settings) then fuel price then total cost and optional note field"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log a Fill-Up with Prefilled Vehicle Data (Priority: P1)

As a vehicle owner, I want to log a fuel fill-up where the fuel type is automatically prefilled from my vehicle's settings so that I don't have to re-enter information the system already knows.

**Why this priority**: The enhanced form is the core interaction — logging fill-ups quickly with less manual data entry.

**Independent Test**: Can be tested by selecting a vehicle (with fuel type configured), verifying fuel type is prefilled, entering remaining fields, saving, and seeing the entry in history.

**Acceptance Scenarios**:

1. **Given** I am on the fill-up form, **When** the form loads, **Then** I see fields in this order from top to bottom: vehicle selector, odometer reading, fuel type (prefilled from vehicle settings), fuel price per unit, total cost, and an optional note field.
2. **Given** I have selected a vehicle with fuel type set to "Diesel", **When** I view the fuel type field, **Then** it is prefilled with "Diesel" but remains editable.
3. **Given** I have entered fuel price and volume, **When** I view the total cost field, **Then** it is auto-calculated (and vice versa).
4. **Given** I have filled all required fields, **When** I tap "Save", **Then** the fill-up is persisted with the note (if provided) and appears in my history.
5. **Given** I switch the vehicle in the dropdown, **When** the new vehicle has a different fuel type, **Then** the fuel type field updates to match the new vehicle's setting.

---

### User Story 2 - Add Optional Notes to Fill-Ups (Priority: P2)

As a vehicle owner, I want to add an optional note to a fill-up (e.g., "highway trip", "city driving", "premium fuel station") so that I can remember context about specific entries later.

**Why this priority**: Notes add context value but are optional — the form works fully without them.

**Independent Test**: Can be tested by adding a fill-up with a note, viewing the fill-up in history, and confirming the note text is displayed.

**Acceptance Scenarios**:

1. **Given** I am on the fill-up form, **When** I see the note field, **Then** it is clearly marked as optional with placeholder text.
2. **Given** I have entered a note, **When** I save the fill-up, **Then** the note is persisted with the entry.
3. **Given** I view a fill-up with a note in history, **When** I look at the entry details, **Then** the note text is visible.
4. **Given** I leave the note field empty, **When** I save, **Then** the fill-up saves successfully without a note.

---

### Edge Cases

- What happens when a vehicle has no fuel type configured (nil)? → The fuel type field is empty/not prefilled; the user must select one manually or leave it unset.
- What happens when the user changes the vehicle after editing the fuel type? → The fuel type resets to the newly selected vehicle's configured type.
- What happens when the user enters a note longer than a reasonable limit? → Notes are capped at 200 characters with a visible character counter.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The fill-up form MUST display fields in this order: vehicle selector (dropdown), odometer reading, fuel type, fuel price per unit, volume, total cost, full tank toggle, and note (optional).
- **FR-002**: The fuel type field MUST be prefilled from the selected vehicle's configured fuel type when available.
- **FR-003**: When the user changes the selected vehicle, the fuel type field MUST update to reflect the new vehicle's fuel type setting.
- **FR-004**: The fuel type field MUST remain editable (user can override the prefilled value for a one-off fill-up with different fuel).
- **FR-005**: The note field MUST be optional, with a maximum of 200 characters and a visible character count.
- **FR-006**: The note MUST be persisted with the fill-up entry and displayed in the fill-up history.
- **FR-007**: The auto-calculation behavior (two of three: price, volume, total) MUST continue to work as previously specified.
- **FR-008**: The vehicle selector MUST default to the most recently used vehicle.

### Key Entities

- **FillUp** (enhanced): Adds a note attribute (optional text, max 200 characters) and a fuel type attribute (to record the type used for this specific fill-up, which may differ from the vehicle's default).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can log a complete fill-up (with prefilled fuel type) in under 20 seconds from form open to save.
- **SC-002**: Fuel type is correctly prefilled in 100% of cases where the selected vehicle has a fuel type configured.
- **SC-003**: Notes are preserved and displayed without data loss for all fill-ups that include them.
- **SC-004**: Changing the vehicle selection updates the fuel type within 0.5 seconds with no manual intervention needed.

## Assumptions

- The existing fill-up form is being enhanced (not replaced) with the new field order and additions.
- The fuel type field on a fill-up records what fuel was actually used for that specific fill-up (may differ from vehicle default for one-off situations like using E10 instead of E5).
- The existing auto-calculation logic (price × volume = total) is preserved.
- The full tank toggle remains part of the form (for efficiency calculation purposes).
- The note is purely informational — it does not affect calculations or filtering in v1.
