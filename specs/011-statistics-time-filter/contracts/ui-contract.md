# UI Contract: Statistics Time Filter

**Feature**: 011-statistics-time-filter
**Date**: 2026-04-21

## Statistics Tab Layout

```
┌─────────────────────────────────┐
│ Statistics              (...)   │  ← TabHeaderView (existing)
├─────────────────────────────────┤
│ [Vehicle Picker Card]           │  ← VehiclePickerCard (existing)
├─────────────────────────────────┤
│ Week │ Month │ Year │ All │ Custom │  ← NEW: Segmented filter control
├─────────────────────────────────┤
│ Start: [Apr 1, 2026]           │  ← NEW: Only visible when "Custom" selected
│ End:   [Apr 21, 2026]          │
├─────────────────────────────────┤
│ ┌─ Summary ───────────────────┐ │
│ │ Total Spent       1,234.56  │ │
│ │ Total Fuel         456.7 L  │ │
│ │ Fill-Ups               12   │ │
│ │ Avg Efficiency  7.2 L/100km │ │
│ └─────────────────────────────┘ │
│ ┌─ Monthly Costs (Chart) ─────┐ │
│ │ [Bar chart]                 │ │
│ └─────────────────────────────┘ │
│ ┌─ Monthly Breakdown ─────────┐ │
│ │ April 2026        345.67    │ │
│ │ March 2026        289.01    │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

## Filter Control Behavior

| Action | Result |
|--------|--------|
| Tap "Week" | Statistics show last 7 days; custom date pickers hidden |
| Tap "Month" | Statistics show last month; custom date pickers hidden |
| Tap "Year" | Statistics show last year; custom date pickers hidden |
| Tap "All" | Statistics show all data (default); custom date pickers hidden |
| Tap "Custom" | Custom date pickers animate in below filter; statistics update on date change |
| Change start/end date | Statistics recalculate for new custom range |
| Switch vehicle | Statistics recalculate with current filter applied to new vehicle |
| Switch tab and return | Filter selection preserved |
| App relaunch | Filter resets to "All" |

## Empty State

When no fill-ups exist within the selected time range:
- Show existing `EmptyStateView` with message: "No fill-ups in the selected period."
- Keep the filter control visible so the user can change their selection.

## Accessibility

- Segmented control labels: "Last Week", "Last Month", "Last Year", "All Time", "Custom Range"
- Date pickers: standard iOS accessibility (VoiceOver reads date values)
- Filter change announces updated summary via accessibility notification
