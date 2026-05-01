# Quickstart: Edit Exchange Rate

Manual test scenarios to verify the feature end-to-end.

---

## Setup

Before running scenarios, ensure:
- At least one fill-up exists that was saved with a secondary currency (currencyCode set, exchangeRate set)
- At least one cost entry exists saved with a secondary currency
- At least one fill-up and one cost exist saved with the default currency only

---

## Scenario 1: Edit exchange rate on fill-up (primary flow)

1. Open the Fill-Ups list
2. Tap a fill-up that was saved with a secondary currency (e.g. EUR → PLN)
3. Tap "Edit"
4. Verify: the edit form shows an "Exchange Rate" section with the current rate (e.g. "4.2500")
5. Tap the rate field and change it to "4.3000"
6. Tap "Save"
7. **Expected**: Fill-up is saved; the detail view shows the converted total recalculated at the new rate

---

## Scenario 2: Edit exchange rate on cost entry (primary flow)

1. Open the Costs list
2. Tap a cost entry saved with a secondary currency
3. In the detail view, tap "Edit"
4. Verify: the edit form shows an "Exchange Rate" section
5. Change the rate
6. Tap "Save"
7. **Expected**: Cost entry saved with the new rate; converted amount updates in list and detail

---

## Scenario 3: No exchange rate field for single-currency records

1. Open the edit form for a fill-up saved in the default currency only
2. **Expected**: No "Exchange Rate" section visible — the form is unchanged from before this feature

3. Repeat for a cost entry saved in the default currency
4. **Expected**: Same — no exchange rate field shown

---

## Scenario 4: Validation — zero rate blocked

1. Open edit for a secondary-currency fill-up
2. Clear the exchange rate field and type "0"
3. Verify: "Save" button is disabled (or a validation message appears)
4. Change to "4.2500"
5. Verify: "Save" button becomes enabled

---

## Scenario 5: Validation — negative rate blocked

1. On a secondary-currency fill-up edit form, enter "-1" as exchange rate
2. **Expected**: Save is disabled

---

## Scenario 6: Locale — comma decimal separator

1. If device locale uses comma as decimal separator (e.g. Polish)
2. Enter "4,3000" in the exchange rate field
3. Tap "Save"
4. **Expected**: Save succeeds; rate stored as 4.3; converted amount reflects the rate correctly

---

## Scenario 7: Regression — existing edit functionality unchanged

1. Open any fill-up, edit the odometer and note fields
2. **Expected**: Save works; exchange rate field absent for default-currency records; no regressions in auto-calculation of price/volume/totalCost
