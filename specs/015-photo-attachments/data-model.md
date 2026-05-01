# Data Model: Photo Attachments

**Feature**: 015-photo-attachments
**Date**: 2026-04-21

---

## Changes to Existing Models

### FillUp (modified)

**New field**:

| Field       | Type    | Default | Constraint          |
|-------------|---------|---------|---------------------|
| `photoData` | `Data?` | `nil`   | Optional; ≤800 KB after compression |

**Notes**:
- Added as `var photoData: Data?` to the existing `@Model final class FillUp`.
- SwiftData migration is automatic (new optional field with nil default requires no migration step for existing records).
- No change to init signature — `photoData` defaults to `nil`.

---

### CostEntry (modified)

**New field**:

| Field       | Type    | Default | Constraint          |
|-------------|---------|---------|---------------------|
| `photoData` | `Data?` | `nil`   | Optional; ≤800 KB after compression |

**Notes**:
- Same pattern as `FillUp.photoData`.
- Existing cost entries unaffected (field is nil by default).

---

## New Model: None

No new SwiftData model is introduced. Photo data lives directly on the two existing record models, matching the established `Vehicle.photoData: Data?` pattern.

---

## Deletion Behaviour

| Record deleted | Photo fate |
|----------------|-----------|
| `FillUp` deleted | `photoData` field is part of the record — automatically freed when record is deleted |
| `CostEntry` deleted | Same — no orphaned data |

---

## Image Processing (not a data model entity, but defined here for clarity)

Before any `Data?` is written to a model, the raw image goes through:

1. `UIImage` → `UIImage.jpegData(compressionQuality: 0.7)` → target ≤800 KB
2. If result > 800 KB, retry at quality 0.5, then 0.3

This logic lives in a small utility function shared by both `AddFillUpViewModel` and `AddCostViewModel`.

---

## View Layer Additions

| New File | Purpose |
|----------|---------|
| `Fuel/Views/CostDetailView.swift` | New detail view for cost entries (needed to display attached photo and cost fields in a dedicated read-only screen, mirroring `FillUpDetailView`) |
| `Fuel/Views/EditCostView.swift` | New edit form for cost entries (category, amount, date, note, photo — mirroring `EditFillUpView`) |
| `Fuel/Views/CameraPickerView.swift` | `UIViewControllerRepresentable` wrapper around `UIImagePickerController` for camera capture |

| Modified File | Change |
|---------------|--------|
| `Fuel/Models/FillUp.swift` | Add `var photoData: Data?` |
| `Fuel/Models/CostEntry.swift` | Add `var photoData: Data?` |
| `Fuel/ViewModels/AddFillUpViewModel.swift` | Add `var photoData: Data?` state + `compressedPhotoData(from:)` utility; pass to `save()` |
| `Fuel/ViewModels/EditFillUpViewModel.swift` | Same additions |
| `Fuel/ViewModels/AddCostViewModel.swift` | Add `var photoData: Data?` state + same utility; pass to `save()` |
| `Fuel/Views/AddFillUpView.swift` | Add photo attachment section (source picker + thumbnail preview) |
| `Fuel/Views/EditFillUpView.swift` | Same additions |
| `Fuel/Views/FillUpDetailView.swift` | Add photo display section at top |
| `Fuel/Views/AddCostView.swift` | Add photo attachment section |
| `Fuel/Views/CostListView.swift` | Add `NavigationLink` to `CostDetailView` for each cost row |
