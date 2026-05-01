# Feature Specification: Odometer Chart on Statistics Page

**Feature Branch**: `024-odometer-chart`
**Created**: 2026-04-27
**Status**: Draft
**Input**: User description: "On stats page user should be able to see linear chart of odometer where x axis (time) can be adjusted - Y axis (km) should scale automatically to adjust to chart area"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Odometer Progress Over Time (Priority: P1)

As a vehicle owner, I want to see a line chart of my odometer readings over time on the Statistics page so that I can visualise how much I have driven over any selected period.

**Why this priority**: This is the core deliverable — without the chart, the feature does not exist.

**Independent Test**: Can be fully tested by navigating to the Statistics page and confirming a line chart appears with odometer data points plotted against time. The chart delivers standalone value even without time-range filtering.

**Acceptance Scenarios**:

1. **Given** I am on the Statistics page and have at least two fill-ups recorded, **When** I view the page, **Then** a line chart is visible showing odometer readings (Y-axis) plotted against dates (X-axis).
2. **Given** the chart is visible, **When** I read the Y-axis, **Then** it displays kilometre values that are automatically scaled to fit the data within the visible chart area with no clipping.
3. **Given** the chart is visible, **When** I read the X-axis, **Then** date labels are shown at regular, readable intervals matching the current time range selection.
4. **Given** I have only one fill-up recorded, **When** I view the chart, **Then** an empty-state message is shown explaining that more data is needed.

---

### User Story 2 - Adjust the Time Range of the Chart (Priority: P2)

As a vehicle owner, I want to change the time range displayed on the odometer chart so that I can zoom in on a specific period (e.g., last month) or view the full history.

**Why this priority**: The time-range control is the primary interactive feature described in the request. Without it the chart is static and less useful for trend analysis.

**Independent Test**: Can be fully tested by switching between time-range options and verifying the chart data and X-axis labels update accordingly.

**Acceptance Scenarios**:

1. **Given** the chart is visible, **When** I change the time range to "Last Month", **Then** only fill-up odometer readings from the past 30 days are plotted and the X-axis rescales to that period.
2. **Given** the chart is visible, **When** I change the time range to "Last Year", **Then** data from the past 12 months is plotted and axis labels reflect a yearly span.
3. **Given** the chart is visible, **When** I change the time range to "All Time", **Then** all recorded fill-up odometer readings are plotted from the earliest to the most recent.
4. **Given** a time range is selected that contains no data, **When** the chart renders, **Then** an appropriate empty-state message is shown for that period.

---

### Edge Cases

- What happens when the selected vehicle has no fill-ups at all? → Display an empty-state message prompting the user to add fill-ups.
- What happens when all fill-ups fall on the same date? → Chart shows a single point; Y-axis still scales correctly.
- What happens when odometer values are non-monotonically increasing (data entry error)? → All points are plotted as-is; no data is filtered out.
- What happens when the vehicle uses miles instead of kilometres? → Y-axis label and values reflect the vehicle's configured distance unit.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Statistics page MUST display a line chart of odometer readings for the selected vehicle.
- **FR-002**: The chart X-axis MUST represent time (dates of fill-up records).
- **FR-003**: The chart Y-axis MUST represent the odometer value in the vehicle's configured distance unit (km or miles) and MUST scale automatically to fit all visible data points without clipping.
- **FR-004**: Users MUST be able to select a time range for the chart from at least three options: Last Month, Last Year, and All Time.
- **FR-005**: When the time range changes, the chart MUST update immediately to show only data within the selected period.
- **FR-006**: The Y-axis scale MUST recalculate whenever the visible data set changes (time range switch or vehicle switch).
- **FR-007**: When fewer than two data points exist for the current selection, the chart MUST show a clear empty-state message rather than an empty or broken chart.
- **FR-008**: The chart MUST respect the vehicle's distance unit setting (kilometres vs. miles) for all axis labels and values.
- **FR-009**: The time-range selector MUST be visually accessible without scrolling when the chart is in view.
- **FR-010**: The chart MUST be available for each vehicle independently (switching vehicle updates the chart data).

### Key Entities

- **Fill-Up**: Existing record containing an odometer reading and a date; provides the raw data points for the chart.
- **Chart Data Point**: A pair of (date, odometer value) derived from a fill-up, used to draw the line.
- **Time Range**: A user-selectable filter (Last Month / Last Year / All Time) that limits which data points are rendered.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The chart renders and is interactive within 1 second of navigating to the Statistics page on a device with up to 500 fill-up records.
- **SC-002**: All available time-range options are reachable in a single tap from the chart view.
- **SC-003**: The Y-axis always shows the minimum and maximum odometer values of the visible data set within a 5% margin, with no data points clipped outside the chart area.
- **SC-004**: Switching the time range updates the chart within 300 milliseconds on the target device.
- **SC-005**: 100% of existing fill-up records for the selected vehicle and time range are reflected in the chart without omission.

## Assumptions

- The chart data source is the existing fill-up records (odometer readings); no new data collection is needed.
- The Statistics page already exists and hosts summary statistics; the chart is added as a new section within that page.
- The selected time-range options (Last Month, Last Year, All Time) align with existing filter options already used elsewhere in the app.
- The feature applies to whichever vehicle is currently selected in the Statistics tab; no multi-vehicle overlay is required.
- The chart is read-only — users cannot edit data points directly on the chart.
- Smooth animated transitions between time ranges are desirable but not a hard requirement for acceptance.
