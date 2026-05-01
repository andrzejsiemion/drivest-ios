# Quickstart: Statistics Time Filter

**Feature**: 011-statistics-time-filter
**Date**: 2026-04-21

## What This Feature Does

Adds a time filter to the Statistics tab so users can view fuel spending statistics for a specific time period: last week, last month, last year, all time (default), or a custom date range.

## Files to Create

| File | Purpose |
|------|---------|
| `Fuel/Models/StatisticsTimePeriod.swift` | Enum defining the 5 filter options with date range computation |

## Files to Modify

| File | Change |
|------|--------|
| `Fuel/ViewModels/SummaryViewModel.swift` | Add `period` parameter to `loadSummary()`, filter fetch by date range |
| `Fuel/Views/ContentView.swift` | Add `@State selectedPeriod`, segmented picker, custom date pickers, pass period to ViewModel |

## Implementation Steps

1. **Create `StatisticsTimePeriod` enum** with cases `.week`, `.month`, `.year`, `.allTime`, `.custom(start: Date, end: Date)` and a `dateRange` computed property returning optional start/end dates.

2. **Update `SummaryViewModel.loadSummary(for:period:)`** to accept a `StatisticsTimePeriod` parameter and add date bounds to the `#Predicate` in the fetch descriptor.

3. **Update `SummaryTabView`** in `ContentView.swift`:
   - Add `@State private var selectedPeriod: StatisticsTimePeriod = .allTime`
   - Add segmented `Picker` between VehiclePickerCard and the statistics list
   - Add conditional `DatePicker` controls for custom range
   - Wire `onChange(of: selectedPeriod)` to reload summary

4. **Register new file** in `Fuel.xcodeproj/project.pbxproj`.

## Key Decisions

- Filter state is `@State` in the view (session-persistent, resets on launch)
- Date filtering happens at SwiftData query level (`#Predicate`) for efficiency
- Segmented control is the standard iOS pattern for this kind of filter
- Custom date pickers appear inline (no modal) to minimize navigation depth
