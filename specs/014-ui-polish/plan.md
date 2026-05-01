# Implementation Plan: UI Polish Improvements

**Branch**: `014-ui-polish` | **Date**: 2026-04-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/014-ui-polish/spec.md`

## Summary

Three targeted, independent view-layer improvements with no model changes:
1. Price per litre in fill-up list rows uses 2 decimal places for all currencies except EUR (3dp).
2. The `+` toolbar button in Settings is replaced by an inline "Add Category" row at the bottom of the Categories list section.
3. Fill-Up Details merges the Date, Vehicle, and Odometer single-row sections into one compact section, eliminating repeated labels.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (Apple frameworks only)
**Storage**: No storage changes
**Testing**: XCTest (no new tests required — no logic changes)
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iPhone/iPad)
**Performance Goals**: No impact — purely display changes
**Constraints**: No server dependency; fully offline
**Scale/Scope**: 3 view files; purely additive/subtractive display changes

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Conditional formatting inline; no new abstractions needed |
| II. Simple UX | ✅ Pass | All three changes reduce friction/noise |
| III. Responsive Design | ✅ Pass | All changes use existing adaptive containers |
| IV. Minimal Dependencies | ✅ Pass | No new dependencies |
| iOS Platform Constraints | ✅ Pass | SwiftUI, SwiftData, iOS 17+, MVVM — no violations |
| Development Workflow | ✅ Pass | UI changes verified on iPhone SE + iPhone 17 Pro Max |

No violations. No Complexity Tracking needed.

## Project Structure

### Documentation (this feature)

```text
specs/014-ui-polish/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (affected files only)

```text
Fuel/Views/
├── FillUpListView.swift       # US1: price precision
├── SettingsView.swift         # US2: inline add category
└── FillUpDetailView.swift     # US3: compact detail layout
```

No new files. No model files touched.

## Implementation Plan

### US1 — Price Precision (FillUpListView.swift)

`FillUpRow` currently uses `"%.3f/L"` unconditionally. Change to a conditional format:
- `fillUp.currencyCode == "EUR"` → `"%.3f/L"`
- all other cases (including nil) → `"%.2f/L"`

### US2 — Settings Inline Add Category (SettingsView.swift)

1. Remove the `ToolbarItem(.primaryAction)` block (the `+` button).
2. In the Categories section, after the `ForEach`/`.onDelete`, add a `Button` row:
   - Label: `Label("Add Category", systemImage: "plus.circle.fill")`
   - Action: `showAddCategory = true`
3. The existing `showAddCategory` state and `AddCategoryView` sheet are unchanged.

### US3 — Fill-Up Details Compact Layout (FillUpDetailView.swift)

Replace three single-row sections with one combined headerless section:

- Remove `Section("Date")` wrapper; keep `LabeledContent("Date")`
- Remove `Section("Vehicle")` wrapper; keep `LabeledContent("Vehicle")`
- Remove `Section("Odometer")` wrapper; rename `LabeledContent("Reading")` to `LabeledContent("Odometer")`
- Group all three into a single `Section { }` (no header)

All data is preserved; only the redundant section header wrapping is removed.

## Design Decisions

1. **EUR-only 3dp**: EUR is the only currency in the supported list where 3dp is conventional for fuel pricing. Hard-coded comparison to "EUR" is sufficient — no configuration needed.
2. **Inline `Button` row for Add Category**: Uses `Label` with `plus.circle.fill` — standard iOS "add item" idiom. No edit mode, no extra state, reuses the existing sheet.
3. **Headerless combined section**: Date/Vehicle/Odometer labels are self-evident. A section header that just says the same word as the row label adds no value. The "Fuel" and "Details" sections keep their headers as they group multiple heterogeneous fields.
