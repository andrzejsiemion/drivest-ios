# Feature Specification: Cost Reminders

**Feature Branch**: `025-cost-reminders`
**Created**: 2026-04-28
**Status**: Draft
**Input**: User description: "User should be able to set in cost reminder about next expense of the same type - for example insurance or technical inspection in 1 year or maintenance after amount of km. It should be also possible to set how many time or km before the reminder will be triggered."

## Clarifications

### Session 2026-04-30

- Q: When a user dismisses a triggered reminder, what happens next? → A: Dismissal permanently silences the reminder until the user manually re-enables it.
- Q: Can a reminder be attached to an existing cost entry after it was already saved, or only during creation? → A: Reminder can be attached or edited on both new and existing cost entries.
- Q: Where in the app's navigation does the reminders list live? → A: Per-vehicle section inside the vehicle detail / cost history screen.
- Q: When a new cost entry of the same category is recorded, how is the reminder reset triggered? → A: A confirmation prompt is shown asking the user to confirm the reset.
- Q: Where are due/overdue reminders surfaced on app open? → A: Badge or highlight on the vehicle card in the main vehicle list screen.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set Time-Based Cost Reminder (Priority: P1)

A vehicle owner adds a cost entry (e.g. insurance, annual technical inspection) and wants to be reminded when the same expense is due again in the future. They specify a recurrence interval in days/months/years and how far in advance (lead time in days) the app should alert them.

**Why this priority**: Time-based reminders (insurance, MOT/inspection) are the most common recurring vehicle costs and deliver the highest immediate value.

**Independent Test**: Can be fully tested by adding an insurance cost entry, attaching a time-based reminder (e.g. "remind in 1 year, 14 days before"), advancing the simulated date past the trigger threshold, and verifying a reminder appears.

**Acceptance Scenarios**:

1. **Given** a user records a cost entry for category "Insurance", **When** they enable a reminder and set interval = 1 year and lead time = 14 days, **Then** the reminder is saved and associated with that vehicle.
2. **Given** a saved time-based reminder whose trigger date (due date minus lead time) has passed, **When** the user opens the app, **Then** an in-app reminder badge or banner is visible for that vehicle.
3. **Given** a triggered reminder, **When** the user records a new cost entry of the same category, **Then** the reminder is automatically reset/rescheduled to the next due date.
4. **Given** a triggered reminder, **When** the user dismisses it manually, **Then** it is permanently silenced and no longer shown; the user must manually re-enable it from the reminders list.

---

### User Story 2 - Set Distance-Based Cost Reminder (Priority: P2)

A vehicle owner adds a cost entry (e.g. engine oil change, tire rotation) and wants to be reminded when the same service is due again after a certain number of kilometres. They specify the service interval in km and how many km before the threshold the app should start alerting them.

**Why this priority**: Distance-based reminders (oil change, filter replacement) are the second most common vehicle maintenance pattern, complementing time-based reminders.

**Independent Test**: Can be fully tested by adding an oil change cost entry, attaching a distance-based reminder (interval = 10 000 km, lead distance = 500 km), updating the vehicle odometer past the trigger point, and verifying the reminder appears.

**Acceptance Scenarios**:

1. **Given** a user records an oil change cost entry at 50 000 km, **When** they enable a reminder and set interval = 10 000 km and lead distance = 500 km, **Then** the reminder is saved with next-due odometer = 60 000 km, trigger odometer = 59 500 km.
2. **Given** a saved distance-based reminder and the vehicle odometer reaches or exceeds the trigger odometer, **When** the user opens the app, **Then** an in-app reminder is shown for that vehicle.
3. **Given** a triggered distance-based reminder, **When** the user records a new cost entry of the same category, **Then** the reminder is rescheduled from the new entry's odometer reading.

---

### User Story 3 - View and Manage Reminders (Priority: P3)

A user can see all reminders for a specific vehicle from within that vehicle's detail screen, edit reminder settings, or delete reminders they no longer need.

**Why this priority**: Management of existing reminders is secondary to creating them, but necessary for long-term usability.

**Independent Test**: Can be fully tested by creating at least one reminder then navigating to the reminders list, editing the lead time, and deleting a reminder.

**Acceptance Scenarios**:

1. **Given** at least one reminder exists, **When** the user opens the reminders section, **Then** all reminders are listed showing category name, vehicle name, due date or due odometer, and current status (pending / due soon / overdue / silenced).
2. **Given** the reminders list, **When** the user taps a reminder, **Then** they can edit the interval and lead time/distance, or re-enable a silenced reminder.
3. **Given** the reminders list, **When** the user deletes a reminder, **Then** it is permanently removed and no longer triggers alerts.

---

### Edge Cases

- What happens when a vehicle has no odometer data and a distance-based reminder is added? → Reminder should still be saveable; trigger detection is skipped until the first odometer reading is available.
- What happens if a user changes the cost category of an entry that has an attached reminder? → The reminder remains attached to the entry; its category label updates accordingly.
- What if the user sets lead time = 0 or lead distance = 0? → Reminder triggers exactly on the due date/odometer with no advance warning; system should accept this as valid.
- What if a reminder interval is set to a very short period (e.g. 1 day)? → Treated as valid; no minimum enforced beyond > 0.
- What happens when a vehicle is deleted? → All reminders associated with that vehicle are deleted.
- What happens when a silenced reminder is re-enabled? → Its status is recalculated against the current date/odometer immediately; if already past due, it shows as overdue.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to attach a time-based reminder to any cost entry (at creation or by editing an existing entry), specifying a recurrence interval (in days, months, or years) and a lead time (in days) before the due date.
- **FR-002**: Users MUST be able to attach a distance-based reminder to any cost entry (at creation or by editing an existing entry), specifying a recurrence interval (in km) and a lead distance (in km) before the due odometer reading.
- **FR-003**: Each cost entry MAY have at most one reminder (either time-based or distance-based, not both simultaneously).
- **FR-004**: The system MUST calculate the next due date or due odometer for each reminder based on the originating cost entry's date or odometer value plus the interval.
- **FR-005**: The system MUST show a badge or visual highlight on the vehicle card in the main vehicle list for any reminder whose trigger threshold has been reached and which has not been silenced.
- **FR-006**: Users MUST be able to dismiss (permanently silence) a triggered reminder; a silenced reminder is hidden from alerts until the user manually re-enables it from the reminders list.
- **FR-007**: When a new cost entry of the same category is recorded for the same vehicle and an active reminder exists, the system MUST show a confirmation prompt offering to reset the reminder from the new entry's date or odometer; the reset only occurs if the user confirms.
- **FR-008**: Users MUST be able to view a list of all reminders for a vehicle from within that vehicle's detail screen, showing category, due date or due odometer, and status (Pending / Due Soon / Overdue / Silenced).
- **FR-009**: Users MUST be able to edit reminder interval and lead settings after creation.
- **FR-010**: Users MUST be able to delete a reminder independently of the source cost entry.
- **FR-011**: When a vehicle is deleted, all associated reminders MUST be deleted.
- **FR-012**: Users MUST be able to re-enable a silenced reminder from the reminders list; upon re-enabling, status is recalculated immediately.

### Key Entities

- **CostReminder**: Represents a recurring reminder. Key attributes: reminder type (time / distance), interval value and unit, lead value and unit, computed next-due date or next-due odometer, status (pending / due soon / overdue / silenced), linked cost entry, linked vehicle.
- **CostEntry** (existing, extended): Gains an optional relationship to one CostReminder.
- **Vehicle** (existing): Has a one-to-many relationship to CostReminder for cascade deletion.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a time-based or distance-based reminder in under 30 seconds from either the cost entry creation screen or the cost entry detail/edit screen.
- **SC-002**: Due or overdue reminders are surfaced as a badge or highlight on the vehicle card in the main vehicle list, visible immediately on app open with no additional navigation required.
- **SC-003**: 100% of reminders associated with a deleted vehicle are also removed — no orphan records.
- **SC-004**: Reminder status (Pending / Due Soon / Overdue / Silenced) reflects the current date and vehicle odometer accurately every time the app is opened.
- **SC-005**: Users can locate, edit, or delete any existing reminder within 3 taps from the vehicle detail screen.

## Assumptions

- Reminders are scoped per vehicle — a reminder set on one vehicle does not affect others.
- The app does not require iOS push notifications for reminders; in-app display on next open is sufficient for v1.
- Distance is always in km (consistent with the rest of the app); no imperial unit conversion is required for this feature.
- Odometer readings come from existing fill-up or cost entry records; the reminder system reads the most recent recorded odometer for distance-based trigger detection.
- A single cost entry can have at most one reminder at a time; supporting both time and distance on the same entry is deferred to a future enhancement.
- The feature reuses existing CostCategory data; no new categories are introduced by this feature.
