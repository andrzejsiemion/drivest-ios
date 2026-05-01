# Implementation Plan: Vehicle Photo

**Branch**: `003-vehicle-photo` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/003-vehicle-photo/spec.md`

## Summary

Add the ability for users to attach a single photo to each vehicle. Photos are displayed as circular thumbnails on the left side of vehicle list rows. Images are captured via camera or selected from the photo library, compressed to ≤500KB, and stored locally on-device alongside the Vehicle entity.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, PhotosUI (Apple frameworks only)
**Storage**: SwiftData (photo stored as Data on Vehicle entity)
**Testing**: XCTest for unit tests; XCUITest for UI tests
**Target Platform**: iOS 17.0+
**Project Type**: mobile-app
**Performance Goals**: Thumbnails render within 0.5s for 20+ vehicles; photo add flow under 15s
**Constraints**: Fully offline, ≤500KB per photo stored, zero third-party packages
**Scale/Scope**: Adds 1 optional field to Vehicle, 1 new view component, updates to 2 existing views

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | PASS | Image handling isolated in utility; single responsibility maintained |
| II. Simple UX | PASS | Single tap to add photo; system photo picker (minimal friction) |
| III. Responsive Design | PASS | Circular thumbnail scales with Dynamic Type; no hardcoded dimensions |
| IV. Minimal Dependencies | PASS | Uses PhotosUI (Apple framework); zero new third-party deps |
| iOS Platform Constraints | PASS | iOS 17+, PhotosUI available since iOS 16, SwiftData |
| Development Workflow | PASS | Feature branch active |

No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-vehicle-photo/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (changes to existing structure)

```text
Fuel/
├── Models/
│   └── Vehicle.swift                  # UPDATE: Add photoData: Data? field
├── ViewModels/
│   └── VehicleViewModel.swift         # UPDATE: Add photo save/delete methods
├── Views/
│   ├── VehicleListView.swift          # UPDATE: Add circular thumbnail to row
│   ├── VehicleDetailView.swift        # UPDATE: Display photo + tap to change
│   ├── VehicleFormView.swift          # UPDATE: Add photo picker section
│   └── Components/
│       └── VehiclePhotoView.swift     # NEW: Reusable circular photo/placeholder component
├── Services/
│   └── ImageCompressor.swift          # NEW: Resize/compress to ≤500KB
└── Resources/

FuelTests/
└── ImageCompressorTests.swift         # NEW: Compression logic tests
```

**Structure Decision**: Minimal addition — one new component, one new service, updates to existing views. No structural changes.
