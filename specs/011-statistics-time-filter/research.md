# Research: Statistics Time Filter

**Feature**: 011-statistics-time-filter
**Date**: 2026-04-21

## R1: Time Filter UI Pattern for iOS

**Decision**: Use a horizontally scrollable `Picker` with `.segmented` style for the 5 preset options (Week, Month, Year, All Time, Custom). When "Custom" is selected, reveal inline start/end `DatePicker` controls below the segmented control.

**Rationale**: Segmented controls are the standard iOS pattern for mutually exclusive filter options. SwiftUI's `Picker(.segmented)` integrates naturally with the existing design. Inline date pickers avoid modal sheets (fewer taps, per Constitution II: Simple UX).

**Alternatives considered**:
- Menu-based picker: Hides options behind a tap — violates "single obvious primary action" principle
- Separate filter sheet: Adds navigation depth — violates "≤3 levels" constraint
- Horizontal scroll of chips: Non-standard iOS pattern, accessibility concerns

## R2: Date Filtering Strategy in SwiftData

**Decision**: Filter fill-ups at the SwiftData `#Predicate` level by adding date bounds to the existing vehicle-scoped fetch descriptor in `SummaryViewModel.loadSummary()`.

**Rationale**: Filtering at the query level is more efficient than fetching all records and filtering in memory. SwiftData `#Predicate` supports `>=` and `<=` date comparisons natively.

**Alternatives considered**:
- In-memory filtering after fetch: Simpler code but wasteful for large datasets
- Separate fetch descriptors per filter: Code duplication; a single parameterized descriptor is cleaner

## R3: Time Range Calculation

**Decision**: Use `Calendar.current.date(byAdding:value:to:)` to compute the start date for preset filters. "Week" = -7 days, "Month" = -1 month (calendar-aware), "Year" = -1 year. Start of day for the computed date to include the full boundary day.

**Rationale**: Calendar-based arithmetic handles edge cases (leap years, month boundaries) correctly. Using `startOfDay` ensures fill-ups on the boundary day are included.

**Alternatives considered**:
- Fixed day counts (7, 30, 365): Doesn't account for varying month lengths
- `DateInterval` from `Calendar`: More API surface for the same result

**Update**: Based on the spec's explicit wording ("last 7 days", "last 30 days", "last 365 days"), we'll use fixed day counts for Week and Year (7 and 365), but calendar-aware `-1 month` for Month to match user expectations for "last month."

**Final Decision**: Use `-7 days` for Week, `Calendar.date(byAdding: .month, value: -1)` for Month, `Calendar.date(byAdding: .year, value: -1)` for Year. This respects spec language while handling month boundaries correctly.

## R4: Filter State Persistence Strategy

**Decision**: Store the selected filter as `@State` in `SummaryTabView`. This provides session persistence (survives tab switches) but resets on app relaunch, matching FR-011 and FR-012.

**Rationale**: `@State` in the parent view naturally persists across child view updates and tab switches without requiring any external storage. No need for `@AppStorage` or SwiftData persistence since the spec explicitly requires reset on fresh launch.

**Alternatives considered**:
- `@AppStorage`: Would persist across launches (violates FR-012)
- ViewModel property: Equivalent to `@State` but adds unnecessary indirection since the filter is purely a view concern
- `VehicleSelectionStore`: Mixing concerns; the filter is not vehicle-related state

## R5: Custom Date Range UX

**Decision**: When user selects "Custom", animate-reveal two `DatePicker` controls (start date, end date) between the segmented control and the statistics list. Use `.datePickerStyle(.compact)` for minimal space. Auto-swap dates if start > end.

**Rationale**: Inline reveal avoids navigation depth. Compact style shows the date as a tappable label that expands into a calendar — standard iOS pattern, minimal permanent screen space.

**Alternatives considered**:
- Full calendar view: Takes too much space for a filter control
- Text field with date parsing: Error-prone, poor UX
- Bottom sheet with date range: Extra navigation depth
