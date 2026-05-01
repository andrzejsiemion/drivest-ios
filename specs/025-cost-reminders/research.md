# Research: Cost Reminders

**Feature**: 025-cost-reminders
**Date**: 2026-04-30

---

## Decision 1: Reminder Storage Strategy

**Decision**: Standalone `CostReminder` SwiftData `@Model`, related to `CostEntry` via an optional one-to-one relationship and to `Vehicle` via a one-to-many cascade relationship.

**Rationale**: SwiftData's `@Relationship(deleteRule: .cascade)` handles orphan cleanup automatically when a vehicle or cost entry is deleted. A standalone model keeps reminder logic isolated from the existing `CostEntry` model, which already has significant complexity (photos, attachments, currency). This avoids making `CostEntry` a God object.

**Alternatives considered**:
- Embedding reminder fields directly on `CostEntry` (rejected: pollutes the model with optional nullable fields that are irrelevant for most entries; SwiftData migrations become messier)
- Using `@Attribute` with encoded JSON on `CostEntry` (rejected: loses query-ability and type safety)

---

## Decision 2: Reminder Status Computation

**Decision**: Status (`pending`, `dueSoon`, `overdue`, `silenced`) is computed at read time by a `ReminderEvaluationService`, not stored as a persisted field.

**Rationale**: Stored status becomes stale between app launches and requires background update logic. Since the app is offline-first and status depends only on current date and current odometer (both cheap to compute), deriving status at read time is simpler, always accurate, and eliminates a sync problem.

**Alternatives considered**:
- Persisting status and updating via `scenePhase` observer (rejected: adds complexity, risk of staleness if background fetch is missed)
- Using `NSPredicate` to filter due reminders directly (rejected: computed domain logic doesn't map cleanly to SwiftData predicates)

---

## Decision 3: Odometer Source for Distance-Based Reminders

**Decision**: Use `Vehicle.currentOdometer`, which already computes `fillUps.map(\.odometerReading).max() ?? initialOdometer`. No new odometer field is needed.

**Rationale**: The `Vehicle` model already exposes the highest recorded odometer from fill-ups. Cost entries do not carry odometer readings, so the most recent fill-up odometer is the best available proxy.

**Alternatives considered**:
- Adding an odometer field to `CostEntry` (rejected: out of scope; most cost entries are not odometer-tied events)
- Storing "snapshot odometer" on the reminder at creation time only (accepted partially: the reminder stores the odometer at the time the originating cost entry was recorded, from which the next-due odometer is calculated)

---

## Decision 4: Reminder Reset on New Same-Category Entry

**Decision**: When saving a new `CostEntry` whose `categoryName` matches an active reminder's category on the same vehicle, the save flow presents a SwiftUI `confirmationDialog` offering to reset the reminder.

**Rationale**: The spec (FR-007) and clarification require a user confirmation prompt. SwiftUI's `confirmationDialog` is the idiomatic pattern for this (used by iOS Photos, Files, etc.) and requires no additional dependencies.

**Alternatives considered**:
- Alert (rejected: less idiomatic for multi-action choices on iOS 15+)
- Inline toggle in the save form (rejected: premature — user hasn't confirmed the new entry belongs to the same cycle yet)

---

## Decision 5: Vehicle Card Badge

**Decision**: Add a computed property on `Vehicle` (or evaluated externally) that returns `hasDueReminders: Bool`. The vehicle card in `VehicleListView` reads this and overlays a small accent-coloured dot badge on the vehicle photo/icon.

**Rationale**: A minimal dot badge is the lightest possible signal, consistent with iOS notification badges. It requires no new navigation and is scannable at a glance. The `VehicleListView` already shows `VehiclePhotoView`; the badge overlays it.

**Alternatives considered**:
- Full row highlight with background tint (deferred: noisier, may conflict with multiple vehicles due)
- System notification badge (out of scope for v1 per Assumptions)

---

## Decision 6: No New Third-Party Dependencies

**Decision**: All reminder logic uses only Swift standard library, Foundation (`DateComponents`, `Calendar`), and SwiftData. No new packages required.

**Rationale**: The constitution mandates minimal dependencies (max 5 third-party packages, Apple frameworks preferred). Interval arithmetic is fully covered by `Calendar.date(byAdding:to:)` for time-based reminders and simple subtraction for distance-based reminders.
