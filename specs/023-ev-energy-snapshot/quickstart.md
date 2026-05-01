# Quickstart: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Branch**: `023-ev-energy-snapshot` | **Date**: 2026-04-25

Integration scenarios for manual testing during development.

---

## Scenario 1: First Snapshot Collected

**Pre-conditions**:
- Vehicle exists with `fuelType == .ev` and `make == "volvo"` (or `"toyota"`)
- Volvo/Toyota credentials stored in Keychain

**Steps**:
1. Open app → navigate to Settings → EV Snapshot section
2. Confirm "Background Sync" toggle is ON (default)
3. Tap "Fetch Now"
4. Observe loading spinner
5. Confirm success: last-fetched timestamp updates to current time

**Expected result**: One `EnergySnapshot` record exists for the vehicle with today's date, non-zero odometer, and optionally SoC value.

---

## Scenario 2: Manual Fetch with API Failure

**Pre-conditions**: Same vehicle as above, but temporarily disable network

**Steps**:
1. Tap "Fetch Now" with network off
2. Observe error displayed inline ("Unable to connect")
3. Re-enable network, tap again
4. Observe success

**Expected result**: First tap produces no new snapshot. Second tap produces one new snapshot. Failure counter is NOT incremented for a single manual-triggered failure (only background scheduled failures count toward the alert threshold).

---

## Scenario 3: 3 Consecutive Failures → In-App Alert

**Pre-conditions**: Valid vehicle, break API credentials (delete Keychain token)

**Steps**:
1. Wait for or simulate 3 background fetch failures (or tap "Fetch Now" 3 times with invalid credentials)
2. Navigate to any screen in the app

**Expected result**: Persistent banner appears: "Unable to sync your [Make] — please reconnect your account in Integrations." Banner disappears as soon as a successful fetch occurs.

---

## Scenario 4: First Electricity Bill (Baseline)

**Pre-conditions**: At least one `EnergySnapshot` exists for the vehicle

**Steps**:
1. Navigate to EV tab → Bills → tap "+"
2. Enter: End date = today, Total kWh = 150, Total cost = 45.00
3. Tap Save

**Expected result**: Bill saved. Detail view shows "This is your first bill — efficiency will be calculated from your next bill." No kWh/100km or cost/km is shown.

---

## Scenario 5: Second Bill — Reconciliation Success

**Pre-conditions**: First bill exists (Scenario 4); at least 2 snapshots bracketing the billing period

**Steps**:
1. Tap "+" for new bill
2. Enter: End date = today + 30 days (simulate), Total kWh = 180, Total cost = 54.00
3. Tap Save

**Expected result**:
- App finds start snapshot (closest to first bill's end date) and end snapshot (closest to today + 30 days)
- Distance = `endOdometer − startOdometer` km
- Efficiency = `(180 / distance) × 100` kWh/100km
- Cost/km = `54.00 / distance`
- All values displayed in bill detail

---

## Scenario 6: Non-EV Vehicle — Feature Hidden

**Pre-conditions**: Vehicle with `fuelType == .diesel` selected

**Steps**:
1. Navigate to ContentView
2. Confirm: no EV tab, no Snapshots tab, no background task scheduled

**Expected result**: Entire feature invisible. No snapshot-related UI elements anywhere.

---

## Scenario 7: 6-Month Purge

**Steps** (development only — set fetch date to 7 months ago in debug):
1. Insert a snapshot with `fetchedAt = Date.now - 7 months`
2. Foreground the app
3. Observe snapshot no longer appears in history

**Expected result**: `SnapshotPurgeService.purgeExpired(context:)` deletes the old record. Bills that previously used this snapshot retain their calculated values (stored at save time).

---

## Schedule Configuration

| Setting | Default | Range |
|---|---|---|
| Frequency | Daily | daily / twiceDaily / every6Hours / every12Hours |
| Hour | 5 | 0–23 |
| Minute | 0 | 0–59 |
| Enabled | true | — |
