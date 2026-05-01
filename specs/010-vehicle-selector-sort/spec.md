# Feature Specification: Vehicle Selector & Sort Order

**Feature Branch**: `010-vehicle-selector-sort`
**Created**: 2026-04-20
**Status**: Draft

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rich Vehicle Selector Widget (Priority: P1)

As a user with one or more vehicles, I want to see a visually prominent vehicle selector at the top of each main tab that shows my vehicle's photo (or placeholder), name, and current odometer reading, so I can quickly see which vehicle's data I'm viewing and switch between vehicles easily.

The selector should look like a card/row: circular vehicle photo on the left, vehicle name in bold, odometer reading below it in secondary text, and a chevron on the right indicating it's tappable to switch vehicles.

**Why this priority**: This is the primary UX improvement — the current plain text name in the toolbar is insufficient for multi-vehicle users. The rich card creates immediate visual context.

**Independent Test**: Can be tested with a single vehicle — card appears at the top of the Fuel tab showing photo placeholder, vehicle name, and odometer.

**Acceptance Scenarios**:

1. **Given** a user has one vehicle, **When** they open any main tab, **Then** a vehicle selector card appears at the top showing the vehicle's photo (or placeholder icon), name in bold, and odometer reading.
2. **Given** a user has multiple vehicles, **When** they tap the vehicle selector card, **Then** a picker or sheet appears listing all vehicles, and selecting one updates the card and the tab content.
3. **Given** a vehicle has a photo, **When** the selector card is shown, **Then** the vehicle's photo is displayed in a circular crop.
4. **Given** a vehicle has no photo, **When** the selector card is shown, **Then** a car icon placeholder is shown in the circular area.

---

### User Story 2 - Shared Vehicle Selection Across Tabs (Priority: P2)

As a user who switches between the Fuel, Costs, and Statistics tabs, I want the selected vehicle to remain the same when I switch tabs, so I don't have to re-select my vehicle every time I move between tabs.

**Why this priority**: Critical for multi-vehicle users — without shared state, switching tabs resets context and creates confusion.

**Independent Test**: Select vehicle B on the Fuel tab, switch to the Costs tab — vehicle B is pre-selected without any additional action.

**Acceptance Scenarios**:

1. **Given** a user has selected "Tesla Model 3" on the Fuel tab, **When** they tap the Costs tab, **Then** "Tesla Model 3" is already selected on the Costs tab.
2. **Given** a user changes the selected vehicle on any tab, **When** they switch to another tab, **Then** the newly selected vehicle is shown on that tab too.
3. **Given** a user has only one vehicle, **When** they switch tabs, **Then** that vehicle is shown on all tabs (no visible change in selection).

---

### User Story 3 - Vehicle Sort Order Preference (Priority: P3)

As a user with multiple vehicles, I want to choose the order in which vehicles appear in the selector list (alphabetically, by date added, by last used, or custom drag-to-reorder), so the vehicle I use most often appears first.

**Why this priority**: Convenience feature for multi-vehicle users. Does not affect single-vehicle users.

**Independent Test**: With 3+ vehicles, change sort order to "Alphabetical" in Settings — the selector list reorders accordingly.

**Acceptance Scenarios**:

1. **Given** a user opens Settings, **When** they find the "Vehicle Order" preference, **Then** they see four options: Alphabetical, Date Added, Last Used, Custom.
2. **Given** a user selects "Alphabetical", **When** they open the vehicle picker, **Then** vehicles are listed A–Z by name.
3. **Given** a user selects "Date Added", **When** they open the vehicle picker, **Then** vehicles are listed oldest-first (order they were added to the app).
4. **Given** a user selects "Last Used", **When** they open the vehicle picker, **Then** vehicles are listed with the most recently viewed vehicle first.
5. **Given** a user selects "Custom", **When** they open the vehicle picker or a dedicated reorder screen, **Then** they can drag vehicles to set a manual order, which persists.
6. **Given** a user has set a custom order and adds a new vehicle, **When** they open the vehicle picker, **Then** the new vehicle appears at the bottom of the custom list.

---

### Edge Cases

- What happens when the user has zero vehicles? The selector area shows an empty/onboarding state prompting to add a vehicle.
- What happens when the selected vehicle is deleted? The app automatically selects the next available vehicle, or shows the empty state if none remain.
- What happens if a vehicle's odometer has no recorded fill-ups (odometer = 0 or nil)? The odometer row is hidden or shows "—".
- What happens when "Last Used" order is selected but no vehicle has ever been used? Falls back to Date Added order.
- What happens when the user has only one vehicle and tries to access the sort order setting? The setting is visible but its effect is only apparent with multiple vehicles (no need to hide it).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The vehicle selector MUST appear at the top of the Fuel, Costs, and Statistics tabs as a prominent card/row element.
- **FR-002**: The selector card MUST display the vehicle's circular photo (or a car icon placeholder if no photo), vehicle name in bold, and most recent odometer reading in secondary text.
- **FR-003**: The selector card MUST show a chevron or visual cue indicating it is interactive when multiple vehicles exist.
- **FR-004**: Tapping the selector card (when multiple vehicles exist) MUST present a list of all vehicles for selection.
- **FR-005**: The selected vehicle MUST be shared across all tabs — changing it on one tab changes it on all tabs simultaneously.
- **FR-006**: The app MUST remember the last selected vehicle across app restarts.
- **FR-007**: Settings MUST include a "Vehicle Order" preference with four options: Alphabetical, Date Added, Last Used, Custom.
- **FR-008**: The chosen sort order MUST determine the order vehicles appear in the selector picker list.
- **FR-009**: "Custom" order MUST allow users to drag-and-drop vehicles into their preferred sequence.
- **FR-010**: The selected sort order MUST persist across app restarts.
- **FR-011**: When the currently selected vehicle is deleted, the app MUST automatically select another available vehicle.
- **FR-012**: The odometer display MUST reflect the most recent recorded value (from fill-ups); if none exists, it MUST show a dash or be hidden.

### Key Entities

- **Selected Vehicle**: The currently active vehicle shown across all tabs — a shared piece of app state, not per-tab.
- **Vehicle Order Preference**: User setting (one of: Alphabetical, Date Added, Last Used, Custom) stored persistently.
- **Custom Vehicle Order**: An ordered list of vehicle identifiers representing the user's manually specified sequence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with multiple vehicles can identify the active vehicle at a glance without reading tab titles — the selector card is visible within 1 second of opening any main tab.
- **SC-002**: Switching tabs never resets the selected vehicle — 0 unintended vehicle resets observed during tab switching.
- **SC-003**: Users can change vehicle sort order in under 30 seconds from opening Settings.
- **SC-004**: Custom vehicle ordering persists correctly after app restart — 100% of reorder actions survive a cold launch.

## Assumptions

- The vehicle selector replaces the current plain-text vehicle name shown in the toolbar/principal area.
- Odometer reading shown is derived from the most recent fill-up entry; no separate odometer field is maintained on the vehicle itself.
- The selector widget is shown on Fuel, Costs, and Statistics tabs; it is not shown on a dedicated Vehicles/Settings screen.
- Single-vehicle users see the selector card as non-interactive (no chevron, no picker) — it is informational only.
- The "Last Used" sort order is updated whenever the user selects a different vehicle (selection event, not fill-up event).
- Custom drag ordering is done within the Settings screen or a dedicated reorder view, not inline within the tab selector.
