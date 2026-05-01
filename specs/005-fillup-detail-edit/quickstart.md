# Quickstart: Fill-Up Detail & Edit

**Date**: 2026-04-20
**Branch**: `005-fillup-detail-edit`

## Setup

```bash
cd fuel && git checkout 005-fillup-detail-edit && open Fuel.xcodeproj
```

Build and run (⌘R).

## What This Feature Changes

### New Files
- `Fuel/Views/FillUpDetailView.swift` — Read-only detail screen
- `Fuel/Views/EditFillUpView.swift` — Edit form (pre-populated)
- `Fuel/ViewModels/EditFillUpViewModel.swift` — Edit logic, validation, save

### Modified Files
- `Fuel/Views/FillUpListView.swift` — NavigationLink on rows
- `Fuel.xcodeproj/project.pbxproj` — New files added

## Testing Notes

- Add 3+ fill-ups → Tap one → Detail screen with all fields
- Tap Edit → Change price → Total auto-recalculates → Save → Updated in detail + list
- Edit odometer to break ordering → Save → Validation error shown
- Edit a full-tank fill-up's volume → Save → Efficiency recalculated for it and subsequent entries
