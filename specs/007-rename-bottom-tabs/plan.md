# Implementation Plan: Rename Bottom Tab Labels

**Branch**: `008-rename-bottom-tabs` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/007-rename-bottom-tabs/spec.md`

## Summary

Rename the three bottom tab bar labels and their matching navigation titles: "History"→"Fuel", "Vehicles"→"Costs", "Summary"→"Statistics". Pure string-literal change across 4 source files with no logic, data model, or architecture impact.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI (existing)
**Storage**: N/A — no data changes
**Testing**: XCTest / XCUITest
**Target Platform**: iOS 17+
**Project Type**: Mobile app (SwiftUI, MVVM)
**Performance Goals**: N/A
**Constraints**: Display strings only — no type renames, no localisation changes
**Scale/Scope**: 4 files modified, 7 string literals changed

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | String literal changes only; no logic touched |
| II. Simple UX | ✅ Pass | Clearer tab labels improve navigation clarity |
| III. Responsive Design | ✅ Pass | No layout changes; SwiftUI renders labels adaptively |
| IV. Minimal Dependencies | ✅ Pass | No new dependencies |
| iOS Platform Constraints | ✅ Pass | Standard SwiftUI tab/navigation title API |

**Gate**: No violations — implementation approved.

## Project Structure

### Documentation (this feature)

```text
specs/007-rename-bottom-tabs/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Scope decision: tab labels + navigation titles
├── data-model.md        # No data model changes
├── contracts/
│   └── ui-contract.md   # Full string change map
└── tasks.md             # Phase 2 output (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
Fuel/Views/
├── ContentView.swift       ← MODIFIED (tab labels, Costs icon, inline navigationTitle)
├── FillUpListView.swift    ← MODIFIED (navigationTitle only)
├── VehicleListView.swift   ← MODIFIED (navigationTitle only)
└── SummaryView.swift       ← MODIFIED (navigationTitle only)
```

**Structure Decision**: Single project, SwiftUI mobile app. All changes are string literal replacements in existing view files.

## Implementation Approach

### String Change Map

| File | Old | New |
|------|-----|-----|
| `ContentView.swift` tabItem 1 | `"History"` | `"Fuel"` |
| `ContentView.swift` tabItem 2 label | `"Vehicles"` | `"Costs"` |
| `ContentView.swift` tabItem 2 icon | `car.2` | `wrench.and.screwdriver` |
| `ContentView.swift` tabItem 3 | `"Summary"` | `"Statistics"` |
| `ContentView.swift` navigationTitle (SummaryTabView) | `"Summary"` | `"Statistics"` |
| `FillUpListView.swift` navigationTitle | `"History"` | `"Fuel"` |
| `VehicleListView.swift` navigationTitle | `"Vehicles"` | `"Costs"` |
| `SummaryView.swift` navigationTitle | `"Summary"` | `"Statistics"` |

## Complexity Tracking

No constitution violations — table not required.
