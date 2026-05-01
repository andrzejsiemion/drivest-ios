# Feature Specification: Statistics Time Filter

**Feature Branch**: `011-statistics-time-filter`
**Created**: 2026-04-21
**Status**: Draft
**Input**: User description: "In statistics user should be able to choose statistics for last week, month, year, all time and custom value provided by date start and stop"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Time Period Selection (Priority: P1)

A user opens the Statistics tab and wants to see fuel spending for the last month. They tap a segmented control or filter bar and select "Month." The statistics immediately update to show only data from the past 30 days.

**Why this priority**: This is the core interaction — preset time filters cover the majority of use cases and deliver immediate value without any additional input.

**Independent Test**: Can be fully tested by selecting each preset option (Week, Month, Year, All Time) and verifying the displayed statistics match the expected date range.

**Acceptance Scenarios**:

1. **Given** the user is on the Statistics tab with fill-up data spanning multiple months, **When** they select "Week", **Then** only data from the last 7 days is displayed in all summary metrics and monthly breakdowns.
2. **Given** the user is on the Statistics tab, **When** they select "Month", **Then** only data from the last 30 days is displayed.
3. **Given** the user is on the Statistics tab, **When** they select "Year", **Then** only data from the last 365 days is displayed.
4. **Given** the user is on the Statistics tab, **When** they select "All Time", **Then** all available data is displayed (default behavior).
5. **Given** the user has no fill-up data within the selected time range, **When** they select any preset, **Then** an appropriate empty state is shown.

---

### User Story 2 - Custom Date Range Selection (Priority: P2)

A user wants to see statistics for a specific period, such as a vacation trip or a quarter. They select "Custom" from the filter options, pick a start date and end date using date pickers, and the statistics update to reflect only that range.

**Why this priority**: Custom ranges provide flexibility for power users who need precise date control, but most users will rely on presets.

**Independent Test**: Can be tested by selecting "Custom", choosing a start and end date, and verifying statistics reflect only fill-ups within that range.

**Acceptance Scenarios**:

1. **Given** the user selects "Custom" from the time filter, **When** they pick a start date and end date, **Then** statistics display only data within that inclusive date range.
2. **Given** the user has selected a custom range, **When** the start date is after the end date, **Then** the system prevents this selection or swaps the dates automatically.
3. **Given** the user selects a custom range with no data, **When** the range is confirmed, **Then** an empty state is displayed with a message indicating no data exists for the selected period.

---

### User Story 3 - Persistent Filter Selection (Priority: P3)

A user selects "Month" as their preferred time filter. When they switch to another tab and return to Statistics, the filter remains set to "Month" for continuity.

**Why this priority**: Persistence avoids frustration of re-selecting filters but is not essential for core functionality.

**Independent Test**: Can be tested by selecting a filter, navigating away and back, and verifying the filter persists within the session.

**Acceptance Scenarios**:

1. **Given** the user has selected "Year" as the time filter, **When** they navigate to another tab and return to Statistics, **Then** the "Year" filter is still active.
2. **Given** the user force-quits and reopens the app, **When** they navigate to Statistics, **Then** the default filter ("All Time") is shown.

---

### Edge Cases

- What happens when the user has exactly one fill-up at the boundary of a time period?
- How does the filter behave when the device time zone changes?
- What happens when the user switches vehicles while a custom date range is active?
- How are fill-ups recorded at midnight handled for daily boundary calculations?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST display a time filter control on the Statistics tab with options: Week, Month, Year, All Time, and Custom.
- **FR-002**: Selecting a preset filter (Week, Month, Year, All Time) MUST immediately update all displayed statistics to reflect only fill-ups within that time range.
- **FR-003**: "Week" MUST filter to the last 7 days from today (inclusive).
- **FR-004**: "Month" MUST filter to the last 30 days from today (inclusive).
- **FR-005**: "Year" MUST filter to the last 365 days from today (inclusive).
- **FR-006**: "All Time" MUST show all fill-up data with no date restriction (default).
- **FR-007**: "Custom" MUST present start and end date pickers allowing the user to define an arbitrary date range.
- **FR-008**: Custom date range MUST prevent the start date from being after the end date.
- **FR-009**: All summary metrics (total cost, total volume, total fill-ups, average efficiency) MUST recalculate based on the active filter.
- **FR-010**: Monthly breakdowns MUST only include months that fall within the active filter range.
- **FR-011**: The selected filter MUST persist during the current app session (across tab switches).
- **FR-012**: The filter MUST reset to "All Time" on a fresh app launch.
- **FR-013**: Changing the selected vehicle MUST reapply the current time filter to the new vehicle's data.
- **FR-014**: When no data exists within the selected time range, the system MUST display an empty state message.

### Key Entities

- **Time Filter**: Represents the active time range selection — either a preset period (week, month, year, all time) or a custom date range with start and end dates.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can switch between any preset time filter in a single tap.
- **SC-002**: Statistics update within 1 second of selecting a new time filter.
- **SC-003**: Custom date range selection requires no more than 3 taps (select Custom, pick start, pick end).
- **SC-004**: 100% of displayed metrics correctly reflect only the data within the selected time range.
- **SC-005**: Filter selection persists across tab switches within the same session.

## Assumptions

- The Statistics tab already exists with summary metrics and monthly breakdowns.
- Fill-up dates are stored with sufficient precision (at least day-level) for filtering.
- "Last 7/30/365 days" is calculated relative to the current device date at the time of viewing.
- The time filter applies only to the Statistics tab and does not affect the Fill-ups or Costs tabs.
- Session persistence means in-memory state; no need for on-disk persistence of the filter selection.
