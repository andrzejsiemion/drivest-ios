# Feature Specification: Fuel Cost Tracker

**Feature Branch**: `001-fuel-cost-tracker`
**Created**: 2026-04-19
**Status**: Clarified
**Input**: User description: "Mobile app for iOS to track cost of fuel for a given vehicle, accepting price per liter, amount fueled, total price, and odometer reading to calculate efficiency per km"

## Clarifications

### Session 2026-04-19

- Q: Should v1 support multiple vehicles or single vehicle only? → A: Multi-vehicle in v1 with "suggest last used" default selection.
- Q: How should partial fill-ups affect efficiency calculation? → A: "Full tank" is the default. User can mark a fill-up as partial. Efficiency is calculated at the next full-tank entry by accumulating fuel and distance across partial fills.
- Q: What is the main navigation structure? → A: Single list (history) as home screen with floating "+" button; summary accessible from navigation bar.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Log a Fuel Fill-Up (Priority: P1)

As a vehicle owner, I want to quickly log a fuel fill-up so that I can
keep a history of my fuel expenses and track consumption over time.

**Why this priority**: This is the core action of the app. Without
logging fill-ups, no other feature (cost tracking, efficiency
calculation) can function.

**Independent Test**: Can be fully tested by opening the app, entering
fuel data for a single fill-up, saving it, and seeing it appear in a
list. Delivers immediate value as a personal fuel expense log.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** I tap the floating "+" button,
   **Then** I see a form with fields for price per liter, liters filled,
   total price, odometer reading, vehicle selector (defaulting to last
   used), and a "full tank" toggle (on by default).
2. **Given** I am on the fill-up form, **When** I enter price per liter
   and liters filled, **Then** the total price is auto-calculated (and
   vice versa: entering total price and liters calculates price per
   liter).
3. **Given** I have filled all required fields, **When** I tap "Save",
   **Then** the fill-up is persisted locally and appears in my fill-up
   history sorted by date (most recent first).
4. **Given** I am on the fill-up form, **When** I leave a required
   field empty, **Then** the Save button is disabled and the empty field
   is highlighted.

---

### User Story 2 - View Fuel Efficiency (Priority: P2)

As a vehicle owner, I want to see my fuel efficiency (liters per 100 km)
calculated automatically so that I can monitor how economically my
vehicle is running.

**Why this priority**: Efficiency calculation is the primary analytical
value of the app and directly requested by the user. It depends on
having at least two fill-up entries.

**Independent Test**: Can be tested by logging two consecutive fill-ups
with odometer readings. The app displays L/100km for the most recent
fill-up and an average over all entries.

**Acceptance Scenarios**:

1. **Given** I have logged at least two fill-ups with odometer readings,
   **When** I view my fill-up history, **Then** each entry (from the
   second onward) displays the calculated fuel efficiency in L/100km.
2. **Given** I have multiple fill-ups, **When** I view the summary
   screen, **Then** I see average efficiency across all recorded
   fill-ups.
3. **Given** I have only one fill-up logged, **When** I view the
   history, **Then** efficiency is shown as "—" (not yet calculable)
   with a hint that a second fill-up is needed.

---

### User Story 3 - View Expense Summary (Priority: P3)

As a vehicle owner, I want to see a summary of my total fuel spending
so that I can understand my monthly and overall vehicle fuel costs.

**Why this priority**: Cost visibility is valuable but secondary to
the core logging and efficiency features.

**Independent Test**: Can be tested by logging several fill-ups across
different dates and verifying that monthly totals and an overall total
are displayed correctly.

**Acceptance Scenarios**:

1. **Given** I have logged fill-ups across multiple months, **When** I
   view the expense summary, **Then** I see total spending broken down
   by month.
2. **Given** I have fill-ups recorded, **When** I view the summary,
   **Then** I see the total amount spent on fuel across all time.
3. **Given** I have no fill-ups logged, **When** I view the summary,
   **Then** I see an empty state prompting me to add my first fill-up.

---

### Edge Cases

- What happens when the user enters an odometer reading lower than the
  previous entry? → The app warns "Odometer reading must be greater than
  the previous entry" and prevents saving.
- What happens when total price and price-per-liter × liters don't
  match? → The app auto-calculates the third field from the other two;
  only two of the three fields are manually editable at a time.
- What happens when the user has only one vehicle? → The vehicle
  selector auto-selects the only vehicle. With multiple vehicles, the
  app pre-selects the one used most recently.
- What happens when a partial fill-up is logged? → The fill-up is saved
  for cost tracking but efficiency is not calculated until the next
  full-tank entry. At that point, accumulated fuel volume and total
  distance since the last full-tank fill-up are used for the L/100km
  calculation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to log a fuel fill-up with: date,
  price per liter, liters filled, total price, odometer reading, vehicle
  selection, and full-tank indicator (defaulting to full).
- **FR-002**: System MUST auto-calculate the third value when any two of
  price per liter, liters, or total price are entered.
- **FR-003**: System MUST calculate fuel efficiency (L/100km) between
  consecutive full-tank fill-ups, accumulating fuel volume and distance
  across any intervening partial fills.
- **FR-004**: System MUST persist all fill-up data locally on-device.
- **FR-005**: System MUST display fill-up history sorted by date
  (most recent first).
- **FR-006**: System MUST display monthly and total fuel expense
  summaries.
- **FR-007**: System MUST validate that odometer readings are
  monotonically increasing.
- **FR-008**: System MUST support multiple vehicles. When adding a
  fill-up, the vehicle selector MUST default to the most recently used
  vehicle.
- **FR-011**: System MUST allow users to add, edit, and delete vehicles
  (name and initial odometer reading).
- **FR-012**: System MUST include a "full tank" toggle (on by default)
  on the fill-up form. Partial fills are tracked for cost but excluded
  from per-entry efficiency calculation until the next full-tank entry.
- **FR-009**: System MUST pre-fill the date field with the current date
  and time.
- **FR-010**: System MUST allow editing and deleting existing fill-up
  entries.

### Key Entities

- **Fill-Up**: Represents a single refueling event. Attributes: date,
  price per liter, volume (liters), total cost, odometer reading,
  is-full-tank (boolean, default true), calculated efficiency (L/100km,
  null for partial fills and first entry). Belongs to one Vehicle.
- **Vehicle**: Represents a user's vehicle. Attributes: name, initial
  odometer reading, last-used timestamp. A user may have multiple
  vehicles.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can log a complete fill-up in under 30 seconds
  (from app launch to saved entry).
- **SC-002**: Fuel efficiency is displayed accurately (within 0.1
  L/100km of manual calculation) after two or more fill-ups are
  recorded.
- **SC-003**: Monthly expense totals are accurate to the cent when
  compared to manual addition of individual entries.
- **SC-004**: The app is fully usable without network connectivity.
- **SC-005**: All primary actions (add, view history, view summary)
  are reachable within 2 taps from the home screen.
- **SC-006**: Efficiency calculation correctly accumulates partial
  fills — the L/100km shown at a full-tank entry accounts for all
  fuel added since the previous full-tank entry.

## Assumptions

- The app supports multiple vehicles in v1 with "suggest last used"
  selection behavior.
- Currency is assumed to be the user's locale default (no manual
  currency selection needed for v1).
- Fuel type is assumed to be uniform (no diesel vs. petrol
  differentiation for v1).
- Units are metric (liters, kilometers) for v1; imperial unit support
  is a future enhancement.
- No cloud sync or backup — data lives only on-device for v1.
- No user accounts or authentication required — the app is purely
  local and personal.
