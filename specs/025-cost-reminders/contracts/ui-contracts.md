# UI Contracts: Cost Reminders

**Feature**: 025-cost-reminders
**Date**: 2026-04-30

---

## Contract 1: ReminderFormSection

Embedded section shown at the bottom of `AddCostView` and `EditCostView`.

### Inputs
| Prop | Type | Description |
|------|------|-------------|
| `reminder` | `Binding<CostReminder?>` | Current reminder (nil = no reminder set) |
| `costEntryDate` | `Date` | Date of the cost entry (used as origin for time-based) |
| `costEntryOdometer` | `Double?` | Odometer at entry time (used as origin for distance-based) |

### States
| State | Display |
|-------|---------|
| No reminder | Toggle "Set Reminder" off; section collapsed |
| Toggle on (new) | Toggle on; inline form appears: type picker, interval stepper, lead stepper |
| Editing existing | Same inline form pre-populated with existing values |

### User Actions
| Action | Outcome |
|--------|---------|
| Toggle on | Creates a draft `CostReminder` with defaults (type: timeBased, interval: 1 year, lead: 14 days) |
| Toggle off | Clears the draft; if editing existing, marks for deletion on save |
| Change type | Switches between time/distance fields; resets interval and lead to sensible defaults |
| Adjust interval | Updates `intervalValue` and `intervalUnit` |
| Adjust lead | Updates `leadValue` and `leadUnit` |

### Validation
- Save button remains enabled regardless of reminder section state (reminder is optional)
- Interval stepper minimum = 1; lead stepper minimum = 0
- Distance type only available if `costEntryOdometer != nil`; otherwise type picker disables distance option with explanatory caption

---

## Contract 2: VehicleRemindersView

Standalone list view, navigated to from `VehicleDetailView`.

### Inputs
| Prop | Type | Description |
|------|------|-------------|
| `vehicle` | `Vehicle` | The vehicle whose reminders are shown |

### States
| State | Display |
|-------|---------|
| No reminders | Empty state: "No reminders set. Add one from a cost entry." |
| Has reminders | Grouped list by status: Due/Overdue first, then Pending, then Silenced |

### Row Display (per reminder)
| Field | Display |
|-------|---------|
| Category icon + name | Leading label |
| Status badge | Colour-coded pill: orange (Due Soon), red (Overdue), blue (Pending), grey (Silenced) |
| Due date or due odometer | Secondary line |
| Interval summary | Caption: e.g. "Every 1 year, 14 days notice" |

### User Actions
| Action | Outcome |
|--------|---------|
| Tap row | Navigate to `ReminderDetailView` for edit/delete |
| Swipe left on row | Delete action (with confirmation) |
| Tap "Re-enable" on silenced row | Sets `isSilenced = false`; status recomputed |

---

## Contract 3: VehicleCardBadge

Modifier/overlay applied to the vehicle photo view in `VehicleListView`.

### Inputs
| Prop | Type | Description |
|------|------|-------------|
| `hasDueReminders` | `Bool` | True when vehicle has ≥ 1 reminder with status `dueSoon` or `overdue` |

### Behaviour
| State | Display |
|-------|---------|
| `hasDueReminders == false` | No badge shown |
| `hasDueReminders == true` | Small filled circle (`.fill` system image or `Circle()`) in accent or orange, overlaid at top-trailing corner of vehicle photo |

---

## Contract 4: ReminderResetConfirmationDialog

Shown after saving a new `CostEntry` when a matching active reminder exists.

### Trigger
`AddCostViewModel.save()` detects: vehicle has a `CostReminder` whose category name matches the new entry's category, and `isSilenced == false`.

### Display
```
Title:   "Reset Reminder?"
Message: "You recorded a new [Category Name]. Reset the reminder from this entry's date?"
Actions:
  - "Reset Reminder"  → primary, resets originDate/originOdometer to new entry values, isSilenced = false
  - "Keep Existing"   → cancel, leaves reminder unchanged
```

---

## Contract 5: ReminderEvaluationService

Pure service (no SwiftData dependency) that computes `ReminderStatus` from a reminder and current context.

### Interface
```swift
// Input
struct ReminderContext {
    let currentDate: Date
    let currentOdometer: Double?
}

// Output
enum ReminderStatus { case pending, dueSoon, overdue, silenced }

// Method
func status(for reminder: CostReminder, context: ReminderContext) -> ReminderStatus
```

### Rules
1. If `reminder.isSilenced` → `.silenced`
2. If `timeBased`: compare `context.currentDate` vs `triggerDate` and `nextDueDate`
3. If `distanceBased` and `context.currentOdometer == nil` → `.pending` (no data yet)
4. If `distanceBased`: compare `context.currentOdometer` vs `triggerOdometer` and `nextDueOdometer`
