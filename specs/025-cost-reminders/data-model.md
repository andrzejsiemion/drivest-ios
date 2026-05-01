# Data Model: Cost Reminders

**Feature**: 025-cost-reminders
**Date**: 2026-04-30

---

## New Entity: CostReminder

**SwiftData `@Model` class**

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UUID` | Primary key, generated on creation |
| `reminderType` | `ReminderType` (enum) | `.timeBased` or `.distanceBased` |
| `intervalValue` | `Int` | Numeric recurrence interval (e.g. 1, 10000) |
| `intervalUnit` | `ReminderIntervalUnit` (enum) | `.days`, `.months`, `.years` (time) or `.kilometers` (distance) |
| `leadValue` | `Int` | Advance warning quantity (e.g. 14, 500) |
| `leadUnit` | `ReminderLeadUnit` (enum) | `.days` (time) or `.kilometers` (distance) |
| `originDate` | `Date?` | Date of the originating cost entry (time-based) |
| `originOdometer` | `Double?` | Odometer of the originating cost entry (distance-based) |
| `isSilenced` | `Bool` | `true` when user has dismissed/silenced; reset to `false` on re-enable or manual reset |
| `createdAt` | `Date` | Creation timestamp |

**Relationships**:

| Relationship | Type | Delete Rule | Notes |
|-------------|------|-------------|-------|
| `costEntry` | `CostEntry?` | `.nullify` | Optional back-reference; reminder survives if entry deleted (user may re-attach) |
| `vehicle` | `Vehicle` | Owner side — `Vehicle` cascades | Vehicle deletion deletes all its reminders |

---

## Computed Properties (not persisted)

These are calculated by `ReminderEvaluationService` at read time:

| Property | Logic |
|----------|-------|
| `nextDueDate` | `originDate + intervalValue * intervalUnit` (time-based only) |
| `triggerDate` | `nextDueDate - leadValue days` (time-based only) |
| `nextDueOdometer` | `originOdometer + intervalValue` (distance-based only) |
| `triggerOdometer` | `nextDueOdometer - leadValue` (distance-based only) |
| `status` | See Status Machine below |

---

## Status Machine

```
pending   → dueSoon   : current date ≥ triggerDate (time) OR current odometer ≥ triggerOdometer (distance)
dueSoon   → overdue   : current date ≥ nextDueDate (time) OR current odometer ≥ nextDueOdometer (distance)
any       → silenced  : user taps "Dismiss" on a triggered reminder (sets isSilenced = true)
silenced  → pending   : user taps "Re-enable" in reminders list (sets isSilenced = false, status recomputed)
any       → pending   : user confirms reset after recording a new same-category cost entry
```

**Status display labels**:

| Status | Condition |
|--------|-----------|
| `pending` | Trigger threshold not yet reached; `isSilenced == false` |
| `dueSoon` | Past trigger threshold but before due date/odometer; `isSilenced == false` |
| `overdue` | Past due date/odometer; `isSilenced == false` |
| `silenced` | `isSilenced == true` (regardless of computed threshold) |

---

## Supporting Enums

### ReminderType
```
case timeBased
case distanceBased
```

### ReminderIntervalUnit
```
case days
case months
case years
case kilometers   // only valid when reminderType == .distanceBased
```

### ReminderLeadUnit
```
case days         // only valid when reminderType == .timeBased
case kilometers   // only valid when reminderType == .distanceBased
```

### ReminderStatus (computed, not persisted)
```
case pending
case dueSoon
case overdue
case silenced
```

---

## Modified Entities

### CostEntry (extended)

New optional relationship added:

| Field | Type | Notes |
|-------|------|-------|
| `reminder` | `CostReminder?` | Optional one-to-one; `deleteRule: .cascade` — deleting a cost entry deletes its reminder |

### Vehicle (extended)

New cascade relationship added:

| Field | Type | Notes |
|-------|------|-------|
| `reminders` | `[CostReminder]` | `@Relationship(deleteRule: .cascade)` — deleting a vehicle deletes all its reminders |

---

## Validation Rules

- `intervalValue` MUST be > 0
- `leadValue` MUST be ≥ 0 (0 is valid — triggers exactly on due date)
- `intervalUnit` MUST be `.kilometers` when `reminderType == .distanceBased`; MUST be `.days`, `.months`, or `.years` when `.timeBased`
- `originDate` MUST be non-nil when `reminderType == .timeBased`
- `originOdometer` MUST be non-nil when `reminderType == .distanceBased`
- Each `CostEntry` MUST NOT have more than one `CostReminder` (enforced at ViewModel level; UI shows reminder section as edit-only if one already exists)
