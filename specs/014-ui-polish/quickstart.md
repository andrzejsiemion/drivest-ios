# Quickstart: UI Polish Improvements

**Feature**: 014-ui-polish
**Date**: 2026-04-21

---

## What This Feature Does

Three targeted UI improvements:

1. **Price precision per currency**: Fill-up list rows show price/L with 2dp for PLN (and all non-EUR currencies), 3dp for EUR.
2. **Settings inline category add**: The `+` toolbar button is removed; an "Add Category" row appears inline at the bottom of the Categories section.
3. **Fill-Up Details compaction**: Date/Vehicle/Odometer are merged into a single section, eliminating three redundant label pairs.

---

## Files to Modify

| File | Change |
|------|--------|
| `Fuel/Views/FillUpListView.swift` | Price format: `%.3f` → `%.2f` or `%.3f` based on `fillUp.currencyCode` |
| `Fuel/Views/SettingsView.swift` | Remove toolbar `+` button; add inline "Add Category" row |
| `Fuel/Views/FillUpDetailView.swift` | Merge Date/Vehicle/Odometer into single compact section |

---

## Test Scenarios

### Price formatting
1. Add fill-up in PLN at 6.459/L → list shows "6.46/L"
2. Add fill-up in EUR at 1.699/L → list shows "1.699/L"
3. Add fill-up with no currency → list shows "6.46/L" (2dp)

### Settings
1. Open Settings → no `+` in nav bar
2. Scroll to Categories → "Add Category" row visible at bottom
3. Tap it → category creation sheet opens

### Fill-Up Details
1. Open any fill-up → "Date" appears once, not as both section header and row label
2. "Vehicle" appears once
3. "Odometer" / "Reading" duplication gone
4. All data still present
