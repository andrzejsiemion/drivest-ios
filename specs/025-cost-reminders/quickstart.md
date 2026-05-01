# Quickstart: Cost Reminders — Integration Scenarios

**Feature**: 025-cost-reminders
**Date**: 2026-04-30

---

## Scenario 1: Create a time-based reminder (insurance, annual)

1. Open the app and select a vehicle.
2. Navigate to **Costs** → tap **+** to add a new cost entry.
3. Select category **Insurance**, enter amount and date.
4. In the **Reminder** section at the bottom, toggle "Set Reminder" on.
5. Leave type as **Time** (default).
6. Set interval to **1 year**.
7. Set lead time to **14 days**.
8. Tap **Save**.

**Expected**: The cost entry is saved. A `CostReminder` with `reminderType = .timeBased`, `intervalValue = 1`, `intervalUnit = .years`, `leadValue = 14`, `leadUnit = .days` is created and linked to the entry and the vehicle.

**Verify reminder is pending**: Open the vehicle detail screen → tap **Reminders**. The Insurance reminder appears with status **Pending**, showing the next due date (entry date + 1 year).

---

## Scenario 2: Create a distance-based reminder (oil change)

1. Add a new cost entry. Select category **Service** (or a maintenance category).
2. Toggle "Set Reminder" on. Switch type to **Distance**.
3. Set interval to **10 000 km** and lead distance to **500 km**.
4. Tap **Save**.

**Expected**: `CostReminder` created with `reminderType = .distanceBased`, `intervalValue = 10000`, `intervalUnit = .kilometers`, `leadValue = 500`, `leadUnit = .kilometers`, `originOdometer` set from the vehicle's current odometer at entry time.

**Verify trigger**: Add a fill-up that brings the vehicle odometer within 500 km of the next-due odometer. Open the app. The vehicle card shows a **badge**. The Reminders list shows the Service reminder as **Due Soon**.

---

## Scenario 3: Silencing a triggered reminder

1. With a triggered reminder (status Due Soon or Overdue), open **Reminders** from the vehicle detail.
2. Tap the due reminder row.
3. Tap **Dismiss** (or swipe and dismiss via action).

**Expected**: Reminder status changes to **Silenced**. The vehicle card badge disappears. The reminder appears at the bottom of the Reminders list under "Silenced."

---

## Scenario 4: Re-enabling a silenced reminder

1. Open the vehicle detail → **Reminders**.
2. Tap a silenced reminder.
3. Tap **Re-enable**.

**Expected**: `isSilenced` is set to `false`. Status is recomputed immediately. If the due date/odometer has already passed, status shows as **Overdue**; otherwise **Pending** or **Due Soon**.

---

## Scenario 5: Auto-reset prompt when recording same-category cost

1. An active (non-silenced) Insurance reminder exists for the vehicle.
2. Record a new cost entry with category **Insurance** on the same vehicle.
3. Tap **Save**.

**Expected**: A `confirmationDialog` appears: "Reset Reminder? You recorded a new Insurance. Reset the reminder from this entry's date?" with actions **Reset Reminder** and **Keep Existing**.

- Tapping **Reset Reminder**: `originDate` on the reminder is updated to the new entry's date; `isSilenced` is set to `false`; next-due date recalculates.
- Tapping **Keep Existing**: Reminder unchanged.

---

## Scenario 6: Vehicle deletion cascades

1. A vehicle with two cost entries (each having a reminder) is deleted.
2. In the vehicle list, swipe to delete the vehicle and confirm.

**Expected**: Vehicle, its cost entries, and all two reminders are removed. No orphan `CostReminder` records remain in the store.

---

## Scenario 7: Edit reminder after creation

1. Open the vehicle detail → **Reminders**.
2. Tap an existing reminder.
3. Change the interval from 1 year to 6 months.
4. Tap **Save**.

**Expected**: The reminder's `intervalValue` and `intervalUnit` are updated. The next-due date recalculates based on `originDate + 6 months`.

---

## Scenario 8: Delete a reminder independently

1. Open the vehicle detail → **Reminders**.
2. Swipe left on a reminder row.
3. Tap **Delete** and confirm.

**Expected**: The `CostReminder` is deleted. The linked `CostEntry` is unchanged. The vehicle card badge (if applicable) is removed.
