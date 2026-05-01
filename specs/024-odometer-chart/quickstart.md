# Quickstart: Odometer Chart

## Scenario 1 — Chart renders with existing data

**Precondition**: Vehicle "Teton" has 5 fill-ups spread over the last 6 months.

1. Open the app → tap **Statistics** tab.
2. Observe: `OdometerChartView` appears at the top of the page showing a rising line from the earliest to the most recent fill-up.
3. The Y-axis label reads "km" (or "mi" for a miles vehicle).
4. The segmented control shows **Last Month | Last Year | All Time**; "All Time" is pre-selected.
5. Tap **Last Month** → only fill-ups within the past 30 days are plotted; axes rescale.
6. Tap **Last Year** → fill-ups within the past 12 months appear.

**Pass condition**: Chart updates immediately on each tap; no crash; Y-axis never clips data.

---

## Scenario 2 — Empty state (no fill-ups)

**Precondition**: A freshly added vehicle "NewCar" with zero fill-ups is selected.

1. Navigate to **Statistics** tab.
2. Observe: Chart area shows "Add fill-ups to see odometer progress." — no broken chart.

**Pass condition**: Graceful empty state with guidance text.

---

## Scenario 3 — Empty state (fill-ups exist but none in selected period)

**Precondition**: Vehicle "OldCar" has 3 fill-ups all dated over 2 years ago.

1. Navigate to **Statistics** tab with "OldCar" selected.
2. Select **Last Month** in the time-range picker.
3. Observe: Chart area shows "No data for this period." — Y-axis does not collapse or crash.
4. Select **All Time** → all three historical fill-ups appear correctly.

**Pass condition**: Period-specific empty state; All Time restores the chart.

---

## Scenario 4 — Vehicle switch

**Precondition**: Two vehicles: "V90" (many fill-ups) and "CHR" (few fill-ups).

1. On Statistics tab, "V90" is selected — chart shows V90's odometer data.
2. Tap the vehicle picker card → select "CHR".
3. Observe: Chart immediately updates to show CHR's fill-up data; Y-axis rescales to CHR's odometer range.

**Pass condition**: No stale data from V90 remains visible after switching.

---

## Scenario 5 — Miles vehicle

**Precondition**: Vehicle "Ranger" is configured with Distance Unit = Miles and has fill-ups.

1. Navigate to **Statistics** tab with "Ranger" selected.
2. Observe: Y-axis label shows "mi"; values are odometer readings divided by 1.60934.

**Pass condition**: Unit label and values reflect miles, not kilometres.
