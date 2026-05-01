# Research: Vehicle Settings Menu

**Feature**: Move "Add Vehicle" button into a top-right contextual menu
**Date**: 2026-04-20

## Decision 1: Menu Icon

- **Decision**: Use `ellipsis.circle` SF Symbol
- **Rationale**: iOS HIG uses ellipsis ("…") for "more actions" menus — i.e., contextual actions that are available but not the primary flow. A gear (`gearshape`) implies configuration/settings rather than an action list. Since the menu currently only contains "Add Vehicle" (an action, not a setting), `ellipsis.circle` is the correct convention. It is also the standard used by Apple's own apps (Mail, Files, Contacts) for secondary actions menus.
- **Alternatives considered**:
  - `gearshape` / `gearshape.fill` — rejected; implies a settings screen, not an action list
  - `plus.circle` — rejected; same as the current button, defeats the purpose of hiding the action
  - Custom icon — rejected; violates IV. Minimal Dependencies / Apple-native preference

## Decision 2: SwiftUI Component

- **Decision**: Use SwiftUI `Menu` view as a `ToolbarItem`
- **Rationale**: `Menu` renders natively as a contextual popup on iOS 14+ and requires zero custom presentation code. It is SwiftUI-idiomatic and already used for this pattern throughout iOS system apps.
- **Alternatives considered**:
  - `.confirmationDialog` — rejected; semantically wrong (used for destructive confirmations), renders from bottom
  - Custom `ActionSheet` — rejected; UIKit, violates constitution
  - `sheet` with a list of options — rejected; overcomplicated for a single action

## Decision 3: Scope of Empty State

- **Decision**: Keep existing `EmptyStateView` with its "Add Vehicle" button unchanged
- **Rationale**: FR-003 in spec is explicit. First-time users have no vehicles and the menu pattern may not be immediately discoverable. The empty state's call-to-action is the primary onboarding path and must not be removed.
- **Alternatives considered**:
  - Remove empty state button, rely on menu only — rejected; violates spec FR-003 and Constitution II (empty states MUST guide user toward next action)

## Summary of Changes Required

- **1 file modified**: `Fuel/Views/VehicleListView.swift`
- Replace `ToolbarItem` containing a plain `Button { showAddVehicle = true } label: { Image(systemName: "plus") }` with a `Menu` containing one `Button` labeled "Add Vehicle"
- No ViewModel changes, no model changes, no new files
