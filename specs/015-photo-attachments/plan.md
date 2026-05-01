# Implementation Plan: Photo Attachments

**Branch**: `015-photo-attachments` | **Date**: 2026-04-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/015-photo-attachments/spec.md`

## Summary

Allow users to attach one optional photo (from camera or gallery) to each fill-up and cost entry. Photos are compressed JPEG blobs stored directly on the existing SwiftData models (`FillUp.photoData`, `CostEntry.photoData`), matching the `Vehicle.photoData` precedent. A new `CostDetailView` is added so cost photos have a place to be displayed. A UIKit camera wrapper (`CameraPickerView`) bridges the gap between SwiftUI and `UIImagePickerController` for camera capture.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, PhotosUI (gallery picker), UIKit (camera only — not available in SwiftUI)
**Storage**: SwiftData — `Data?` fields on `FillUp` and `CostEntry`; JPEG compression before write
**Testing**: XCTest (no new unit tests required — no business logic changes; UI verified on simulators)
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iPhone/iPad)
**Performance Goals**: Photo compress + save in <2 s; detail screen renders photo in <1 s
**Constraints**: ≤800 KB stored per photo (JPEG 0.7 quality, iterative fallback); fully offline
**Scale/Scope**: 2 model files, 3 view files modified, 2 new view files, 3 ViewModel files modified

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | `compressImage(_:)` utility keeps compression logic in one place; single responsibility per view/VM |
| II. Simple UX | ✅ Pass | One tap to open source picker; thumbnail preview before save; optional — no friction added |
| III. Responsive Design | ✅ Pass | `Image.scaledToFit()` with max height is adaptive; works in portrait and landscape |
| IV. Minimal Dependencies | ✅ Pass | `PhotosUI` is Apple-provided; UIKit camera use is justified (camera not in SwiftUI PhotosPicker) |
| iOS Platform Constraints | ✅ Pass | SwiftUI + SwiftData + UIKit bridge; iOS 17+; MVVM maintained |
| Development Workflow | ✅ Pass | UI verified on iPhone SE + iPhone 17 Pro Max simulators |

No Complexity Tracking needed — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/015-photo-attachments/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (affected files)

```text
Fuel/Models/
├── FillUp.swift              # +photoData: Data?
└── CostEntry.swift           # +photoData: Data?

Fuel/ViewModels/
├── AddFillUpViewModel.swift  # +photoData state + compressImage helper + save update
├── EditFillUpViewModel.swift # +photoData state (pre-populated) + save update
└── AddCostViewModel.swift    # +photoData state + compressImage helper + save update

Fuel/Views/
├── CameraPickerView.swift    # NEW: UIImagePickerController wrapper (camera only)
├── CostDetailView.swift      # NEW: read-only cost detail (mirrors FillUpDetailView)
├── EditCostView.swift        # NEW: cost edit form (category, amount, date, note, photo)
├── AddFillUpView.swift       # +photo section (source picker, thumbnail, remove)
├── EditFillUpView.swift      # +photo section (shows existing, allows replace/remove)
├── FillUpDetailView.swift    # +photo display section at top
├── AddCostView.swift         # +photo section
└── CostListView.swift        # +NavigationLink to CostDetailView per row

Fuel/
└── Info.plist                # +NSCameraUsageDescription, NSPhotoLibraryUsageDescription
```

## Implementation Plan

### Foundational: Model Changes

Add `var photoData: Data?` to `FillUp` and `CostEntry`. SwiftData handles the migration automatically (new optional field, nil default).

### Foundational: Image Compression Utility

A free function `compressImage(_ image: UIImage, maxBytes: Int = 800_000) -> Data?` in a new file `Fuel/Utilities/ImageCompressor.swift`:
- Try JPEG quality 0.7 → if ≤ maxBytes, return
- Try quality 0.5 → if ≤ maxBytes, return
- Try quality 0.3 → return (or nil if still over limit)

Used by all three ViewModels — single implementation, no duplication.

### Foundational: Camera Picker View

`CameraPickerView` — a `UIViewControllerRepresentable` wrapping `UIImagePickerController` with `.sourceType = .camera`. Dismisses on image pick or cancel. Calls a completion `(UIImage?) -> Void`.

On camera permission denied, the system's standard permission alert fires automatically. The app also shows a custom alert linking to Settings if the picker returns without an image due to denial.

### US1: Fill-Up Photo Attachment

**AddFillUpView + AddFillUpViewModel**:
- `photoData: Data?` state in ViewModel
- In the view, after the Note section: a `Section("Photo")` containing:
  - If no photo: `Button("Add Photo")` that sets `showPhotoSourcePicker = true` and triggers `confirmationDialog`
  - If photo set: `Image(uiImage:)` thumbnail (80×80 pt) + `Button("Remove")` + `Button("Change")`
- `confirmationDialog` with "Take Photo" (→ `showCameraPicker`) and "Choose from Library" (→ `showPhotoPicker`)
- `PhotosPicker` (selection binding) for gallery; `CameraPickerView` sheet for camera
- On selection: call `compressImage(_:)` → set `vm.photoData`
- In `save(currencyCode:exchangeRate:)`: pass `photoData` to the `FillUp` initializer (or set after init)

**EditFillUpView + EditFillUpViewModel**:
- Same photo section — pre-populate `photoData` from `fillUp.photoData` on init
- Replace/Remove/Change works the same way
- `save()` writes updated `photoData` back to the `FillUp` model

**FillUpDetailView**:
- If `fillUp.photoData != nil`: add a headerless `Section` at the top of the `List` containing `Image(uiImage: UIImage(data: photoData)!).resizable().scaledToFit().frame(maxHeight: 280)`

### US2: Cost Photo Attachment

**AddCostView + AddCostViewModel**:
- Same photo section and `confirmationDialog` pattern as fill-up
- `save(...)` sets `entry.photoData = photoData`

**CostDetailView** (new file):
- Mirrors `FillUpDetailView` structure:
  - If `costEntry.photoData != nil`: photo at top
  - Sections for: date, category + amount, note
  - Toolbar "Edit" button → presents `EditCostView` sheet

**EditCostView** (new file):
- Mirrors `EditFillUpView` structure
- Fields: category (Picker), amount (TextField), date (DatePicker), note (TextField), photo section (same replace/remove/add pattern)
- Toolbar: Cancel + Save

**CostListView**:
- Wrap each cost row in a `NavigationLink(value: costEntry.id)` + `.navigationDestination(for: UUID.self)` → `CostDetailView(costEntry:)`

### Info.plist

Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` keys with descriptive strings.

## Design Decisions

1. **`Data?` directly on model**: Follows `Vehicle.photoData` precedent. Simple, zero-ceremony cascade delete.
2. **`confirmationDialog` for source selection**: Standard iOS pattern for camera-vs-library choice. One tap to reach either source.
3. **`PhotosPicker` + `UIImagePickerController` hybrid**: Keeps SwiftUI-native gallery access while satisfying camera need with minimal UIKit surface area.
4. **`CostDetailView` required**: No existing detail view for costs; photo display requires a destination screen. This also improves cost UX generally.
5. **Compression before storage**: Prevents multi-MB blobs degrading SwiftData performance; targets ≤800 KB per photo.
6. **No full-screen photo zoom**: Out of scope per spec; reduces implementation scope without user impact for this release.
