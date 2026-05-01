# Feature Specification: Vehicle Settings Menu

**Feature Branch**: `006-vehicle-settings-menu`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "Move vehicle add button from bottom to top right corner and hide it in settings menu (there is no need to add vehicles frequently)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Access Vehicle Management via Settings Menu (Priority: P1)

As a vehicle owner, I want the "Add Vehicle" action tucked into a settings/more menu in the top-right corner of the Vehicles tab so that the main vehicle list is cleaner and the rarely-used add action doesn't take up prominent space.

**Why this priority**: This is the only change requested — relocating the add button from a prominent toolbar position to a contextual menu.

**Independent Test**: Can be tested by navigating to the Vehicles tab, tapping the menu icon in the top-right corner, seeing "Add Vehicle" as a menu option, tapping it, and successfully adding a vehicle.

**Acceptance Scenarios**:

1. **Given** I am on the Vehicles tab, **When** I look at the toolbar, **Then** I see a menu icon (e.g., ellipsis/gear) in the top-right corner instead of a standalone "+" button.
2. **Given** I tap the menu icon, **When** the menu opens, **Then** I see an "Add Vehicle" option.
3. **Given** I tap "Add Vehicle" in the menu, **Then** the add vehicle form is presented (same as before).
4. **Given** I have no vehicles (empty state), **When** I view the Vehicles tab, **Then** the empty state guidance and a direct "Add Vehicle" button remain visible (the menu is supplementary, not the only path).

---

### Edge Cases

- What happens on the empty state? → The empty state still shows a direct "Add Vehicle" button for first-time users. The menu is also available in the toolbar.
- What happens if additional settings are added later? → The menu pattern supports adding more items (e.g., "Sort by", "Export data") without UI changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Vehicles tab toolbar MUST display a menu icon (ellipsis "..." or gear) in the top-right corner instead of a standalone "+" button.
- **FR-002**: The menu MUST contain an "Add Vehicle" option that presents the vehicle creation form.
- **FR-003**: The empty state on the Vehicles tab MUST retain a direct "Add Vehicle" button for discoverability.
- **FR-004**: All existing vehicle management functionality (list, detail, edit, delete, photo) MUST remain unchanged.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a vehicle via the menu in under 3 taps from the Vehicles tab (tap menu → tap Add Vehicle → form appears).
- **SC-002**: The Vehicles tab toolbar has no standalone "+" button — the add action is exclusively in the menu (except empty state).
- **SC-003**: 100% of existing vehicle functionality remains accessible and unbroken.

## Assumptions

- The menu uses a standard iOS contextual menu pattern (ellipsis icon with dropdown).
- The menu currently only contains "Add Vehicle" but is designed to accommodate future items.
- The empty state's direct "Add Vehicle" button remains for first-time user experience.
- No new data model changes — this is purely a UI relocation.
