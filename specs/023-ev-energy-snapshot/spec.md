# Feature Specification: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Feature Branch**: `023-ev-energy-snapshot`
**Created**: 2026-04-24
**Status**: Draft
**Input**: User description: "Daily EV energy snapshot and electricity bill reconciliation. App fetches odometer and energy state (SoC%) from manufacturer API on a configurable schedule. Snapshots are stored locally for 6 months then auto-purged. When user receives electricity bill they enter: end date, total kWh from meter, total cost - the app remembers the previous bill as the start point and calculates real efficiency (kWh/100km) and cost per km using actual meter data over that period. Feature applies only to vehicles with fuelType == .ev. Manufacturer API (Toyota/Volvo) is the data source for odometer and energy readings."

## Clarifications

### Session 2026-04-24

- Q: What is the source of truth for odometer and SoC data? → A: Manufacturer API (Toyota/Volvo)
- Q: Which bill fields does the user enter? → A: All fields — end date, total kWh from meter, total cost. App remembers previous bill as start point.
- Q: Which vehicles does this feature apply to? → A: Vehicles with fuelType == .ev only
- Q: Where does odometer data come from for snapshot? → A: From the manufacturer API

### Session 2026-04-25

- Q: When multiple fetches occur in one day (e.g., every 6 hours), how should snapshots be stored? → A: Store every fetch as a separate timestamped record; use the snapshots closest to billing period boundaries for efficiency calculations.
- Q: Should the user be able to trigger a fetch manually, or is fetching schedule-only? → A: Include a "Fetch Now" button in settings that shows last-fetched timestamp and result.
- Q: When manufacturer API credentials expire causing repeated fetch failures, should the app notify the user? → A: After 3 or more consecutive failed fetches, show a persistent in-app alert prompting the user to reconnect their vehicle account.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automated Daily Snapshots (Priority: P1)

As an EV owner, I want the app to automatically fetch and store daily odometer and battery state readings from my car's API, so I have a historical record of my vehicle's usage without manual input.

**Why this priority**: This is the foundation of the feature — without stored snapshots, electricity bill reconciliation is impossible. It delivers standalone value as a usage history log.

**Independent Test**: Can be tested by enabling auto-fetch for an EV vehicle, waiting for or triggering a scheduled fetch, and verifying a snapshot appears in history with odometer and SoC values.

**Acceptance Scenarios**:

1. **Given** a vehicle with fuelType == .ev and a manufacturer API connection configured, **When** the scheduled fetch time arrives, **Then** the app records a snapshot containing odometer reading and SoC percentage with the current timestamp.
2. **Given** an EV vehicle snapshot has been stored, **When** the user views snapshot history, **Then** they see a list of daily readings sorted by date with odometer and SoC values.
3. **Given** a snapshot is older than 6 months, **When** the auto-purge runs, **Then** the snapshot is permanently deleted and is no longer visible.
4. **Given** the manufacturer API is unreachable at fetch time, **When** the scheduled fetch attempts, **Then** the app records the failure silently and retries at the next scheduled interval without alerting the user.

---

### User Story 2 - Configurable Fetch Schedule (Priority: P2)

As an EV owner, I want to configure how often and at what time of day the app fetches data from my car's API, so I can balance battery drain and data freshness to my preference.

**Why this priority**: Configurability is important for user control but the default (5 AM daily) already provides correct behaviour. Snapshot collection works without customisation.

**Independent Test**: Can be tested by changing the fetch frequency and time in settings and verifying the next scheduled fetch occurs at the newly configured time.

**Acceptance Scenarios**:

1. **Given** the user has not changed any settings, **When** the app fetches data, **Then** it does so once per day at 5:00 AM by default.
2. **Given** the user opens fetch schedule settings, **When** they select a frequency (daily / twice daily / every 6 hours / every 12 hours) and a time of day, **Then** subsequent fetches occur at the configured interval starting from the specified time.
3. **Given** the user changes the schedule, **When** the next fetch is due, **Then** it runs at the new schedule, not the old one.

---

### User Story 3 - Electricity Bill Reconciliation (Priority: P3)

As an EV owner who receives periodic electricity bills, I want to enter my bill's end date, total kWh consumed, and total cost, so the app can calculate my real-world charging efficiency (kWh/100km) and cost per km for that billing period.

**Why this priority**: This is the primary analytical output of the feature. It requires snapshots (US1) to already exist but delivers the core business value — understanding true electricity cost of driving.

**Independent Test**: Can be tested by entering two bills with different end dates (the first establishes a baseline) and verifying the second bill shows calculated efficiency and cost/km.

**Acceptance Scenarios**:

1. **Given** there are no previous bills recorded, **When** the user enters their first bill (end date, total kWh, total cost), **Then** the app stores it as a baseline for future reconciliation and displays a message that the next bill will show efficiency metrics.
2. **Given** a previous bill is already stored, **When** the user enters a new bill with end date, total kWh from meter, and total cost, **Then** the app calculates kWh/100km using the odometer snapshots between the two bill dates and cost per km from the total cost divided by distance driven.
3. **Given** a bill is reconciled, **When** the user views the bill detail, **Then** they see: billing period (start–end date), distance driven, kWh from meter, total cost, calculated kWh/100km, and cost per km.
4. **Given** no odometer snapshots exist within the billing period, **When** the user tries to reconcile a bill, **Then** the app shows a warning that efficiency cannot be calculated due to missing snapshot data.
5. **Given** a bill has been saved, **When** the user views bill history, **Then** they see all bills sorted by date with their reconciliation status (pending first bill / calculated / no snapshot data).

---

### Edge Cases

- What happens when the manufacturer API returns no data (vehicle offline, connectivity issue)? → Fetch silently fails; no snapshot is stored for that interval; next scheduled fetch is attempted normally.
- What happens when the user has multiple EV vehicles? → Each vehicle maintains its own independent snapshot history and bill history.
- What happens if the user adds their first bill but there are no snapshots in the period? → Efficiency cannot be calculated; bill is stored as baseline only with a "no data" indicator.
- What happens if snapshot data has gaps within a billing period? → Calculation uses available boundary snapshots (closest to bill start and end dates); a warning is shown if gaps exceed 7 days.
- What happens when snapshots approach the 6-month limit? → Auto-purge removes entries older than 6 months. Bills referencing purged snapshot data retain their calculated efficiency values (already computed at save time).
- What happens for non-EV vehicles? → The entire feature (snapshot history, schedule settings, bill entry) is hidden; no fetches are scheduled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST automatically fetch odometer and battery state of charge (SoC%) from the vehicle's manufacturer API (Toyota or Volvo) on a configurable recurring schedule.
- **FR-002**: The default fetch schedule MUST be once per day at 5:00 AM local time.
- **FR-003**: Users MUST be able to configure the fetch frequency: daily, twice daily, every 6 hours, or every 12 hours.
- **FR-004**: Users MUST be able to configure the time of day for the first daily fetch.
- **FR-005**: Each successful fetch MUST store a snapshot record containing: timestamp, odometer reading, and SoC percentage for the associated vehicle.
- **FR-006**: Snapshot records MUST be automatically purged after 6 months from their recorded date.
- **FR-007**: The feature MUST only be active for vehicles whose primary fuel type is Electric (fuelType == .ev).
- **FR-008**: Users MUST be able to enter an electricity bill with: end date, total kWh consumed (from electricity meter), and total cost.
- **FR-009**: The app MUST remember the previously entered bill as the start point for the next reconciliation period.
- **FR-010**: When a second or later bill is entered, the app MUST calculate and display: distance driven in the period, kWh/100km efficiency, and cost per km.
- **FR-011**: Efficiency calculations MUST use the snapshots whose timestamps are closest to the previous bill date (period start) and the current bill date (period end), regardless of how many snapshots exist in between. Each fetch creates a distinct snapshot record; multiple snapshots in a single day are all retained.
- **FR-012**: Users MUST be able to view a history of all entered bills with their reconciliation status and calculated metrics.
- **FR-013**: If no snapshot data covers the billing period, the app MUST store the bill but display a "no data available" indicator instead of calculated metrics.
- **FR-014**: The app MUST continue scheduling and collecting snapshots even when closed (background operation), subject to OS scheduling constraints.
- **FR-015**: The snapshot fetch schedule settings MUST be accessible from the existing Settings screen.
- **FR-016**: The settings screen MUST include a "Fetch Now" button that immediately triggers a snapshot fetch for all configured EV vehicles and displays the result (success with timestamp, or error reason) inline.
- **FR-017**: If 3 or more consecutive scheduled fetches fail for the same vehicle, the app MUST display a persistent in-app alert prompting the user to reconnect their vehicle account. The alert MUST be dismissed automatically once a subsequent fetch succeeds.

### Key Entities

- **EnergySnapshot**: A point-in-time reading for an EV vehicle, containing timestamp, odometer value (km or mi), SoC percentage (0–100), vehicle reference, and data source (manufacturer API name). Every fetch creates a new record regardless of how many occur in a day; uniqueness is determined by vehicle + timestamp combination.
- **ElectricityBill**: A user-entered electricity bill record, containing end date, total kWh from meter, total cost, currency, calculated distance driven (km/mi), calculated kWh/100km, calculated cost per km, and vehicle reference. Implicitly references the previous bill as period start.
- **SnapshotFetchSchedule**: Per-app configuration for how often and at what time snapshots are fetched: frequency (daily/twice daily/every 6h/every 12h), hour of first fetch, minute of first fetch, enabled flag, last successful fetch timestamp.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After enabling the feature for an EV vehicle, at least one snapshot is collected within 24 hours without any user action beyond initial setup.
- **SC-002**: Snapshot history remains accurate for 6 months; entries older than 6 months are no longer visible within 24 hours of expiry.
- **SC-003**: When a user enters their second electricity bill, efficiency (kWh/100km) and cost per km are displayed within 2 seconds of saving the bill.
- **SC-004**: Schedule changes take effect for the next fetch without requiring an app restart.
- **SC-005**: The feature is completely invisible (no UI elements, no background activity) for vehicles that are not configured as Electric.

## Assumptions

- The app already has working manufacturer API integrations for Toyota and Volvo that return odometer and SoC data (existing VolvoAPIClient and ToyotaAPIClient services).
- Background fetch capability is available on the device; if the OS throttles or prevents background execution, the app fetches opportunistically when foregrounded instead.
- Electricity bill reconciliation uses the nearest available snapshots to the billing period boundaries (not interpolation).
- The app stores data locally on-device; no cloud sync is in scope.
- A single "default" currency is used for bill cost display, consistent with the app's existing currency settings.
- The first bill entered for a vehicle always serves as a baseline — no efficiency is calculated for it.
- Odometer values from manufacturer API are in kilometres; conversion to user's preferred distance unit is applied at display time.
- Transient fetch failures (network down, server error) are silent; the last successful fetch timestamp is shown in settings. Persistent failures (3+ consecutive) trigger an in-app alert.
