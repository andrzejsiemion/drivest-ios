# Quickstart: Vehicle Photo Feature

**Date**: 2026-04-20
**Branch**: `003-vehicle-photo`

## Prerequisites

- Xcode 15.0+ (for Swift 5.9 and iOS 17 SDK)
- macOS Sonoma 14.0+
- iPhone Simulator or physical device running iOS 17.0+
- For camera testing: physical device required (simulator has no camera)

## Setup

```bash
cd fuel
git checkout 003-vehicle-photo
open Fuel.xcodeproj
```

Build and run (⌘R). No package resolution needed.

## What This Feature Changes

### New Files
- `Fuel/Views/Components/VehiclePhotoView.swift` — Circular photo/placeholder component
- `Fuel/Services/ImageCompressor.swift` — Resize + JPEG compression utility

### Modified Files
- `Fuel/Models/Vehicle.swift` — Add `photoData: Data?` field
- `Fuel/Views/VehicleListView.swift` — Add thumbnail to vehicle rows
- `Fuel/Views/VehicleDetailView.swift` — Show photo + change action
- `Fuel/Views/VehicleFormView.swift` — Photo picker section
- `Fuel/ViewModels/VehicleViewModel.swift` — Photo save/remove methods
- `Fuel.xcodeproj/project.pbxproj` — New files added to project

## Testing Notes

- **Photo Library**: Works in simulator (add photos via Photos app or drag images in)
- **Camera**: Requires physical device. Hide camera option when unavailable.
- **Compression**: Verify output is ≤500KB by checking `photoData?.count`
- **Placeholder**: Remove photo and verify SF Symbol placeholder displays correctly
