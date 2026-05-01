# Quickstart: Enhanced Fill-Up Form

**Date**: 2026-04-20
**Branch**: `004-enhanced-fillup-form`

## Prerequisites

- Xcode 15.0+, macOS Sonoma 14.0+, iOS 17.0+ simulator/device

## Setup

```bash
cd fuel
git checkout 004-enhanced-fillup-form
open Fuel.xcodeproj
```

Build and run (⌘R).

## What This Feature Changes

### Modified Files
- `Fuel/Models/FillUp.swift` — Add `note: String?` and `fuelType: FuelType?`
- `Fuel/ViewModels/AddFillUpViewModel.swift` — Prefill fuel type from vehicle, note handling
- `Fuel/Views/AddFillUpView.swift` — Reorder form, add fuel type picker + note field
- `Fuel/Views/FillUpListView.swift` — Show note in fill-up row

## Testing Notes

- Create a vehicle with fuel type "Diesel" → Open add fill-up → Verify "Diesel" is prefilled
- Switch vehicle in dropdown → Verify fuel type updates
- Enter a note → Save → Verify note appears in history list
- Leave note empty → Save → Verify no note indicator in history
