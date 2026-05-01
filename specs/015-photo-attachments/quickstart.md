# Quickstart: Photo Attachments

**Feature**: 015-photo-attachments
**Date**: 2026-04-21

---

## Integration Scenarios

### Scenario 1: Add a fill-up with a photo from the gallery

1. Open the app → Fill-Ups tab → tap `+`.
2. Fill in the fuel fields (price, volume, total, odometer).
3. Scroll to the "Photo" section at the bottom of the form.
4. Tap "Add Photo" — a `confirmationDialog` appears with "Take Photo" and "Choose from Library".
5. Tap "Choose from Library" → `PhotosPicker` opens.
6. Select a photo → thumbnail appears in the "Photo" section.
7. Tap "Save" — fill-up is saved with photo attached.
8. **Verify**: Open fill-up detail → photo displayed at the top in full width.

### Scenario 2: Add a fill-up with a photo from the camera

1. Open the Add Fill-Up form → fill in fields.
2. Tap "Add Photo" → choose "Take Photo".
3. Camera opens (system permission prompt on first use).
4. Capture a photo → thumbnail shown in form.
5. Save → detail view shows the photo.

### Scenario 3: Replace photo on an existing fill-up

1. Open Fill-Up Detail → tap "Edit".
2. In the "Photo" section, the existing thumbnail is shown.
3. Tap the thumbnail or "Change Photo" → source picker appears.
4. Choose a new photo → thumbnail updates.
5. Save → detail view now shows the new photo.

### Scenario 4: Remove photo from an existing fill-up

1. Open Fill-Up Detail → tap "Edit".
2. In the "Photo" section, tap "Remove Photo" (shown below thumbnail).
3. Thumbnail disappears; section shows "Add Photo" again.
4. Save → detail view shows no photo.

### Scenario 5: Add a cost entry with a photo

1. Open the Costs tab → tap `+`.
2. Fill in category, amount, date.
3. Scroll to the "Photo" section → tap "Add Photo".
4. Choose source → select photo → thumbnail shown.
5. Save.
6. **Verify**: In cost list, tap the cost row → `CostDetailView` opens with photo displayed.

### Scenario 6: Permission denied for camera

1. On a device where camera permission is denied for this app, open Add Fill-Up form.
2. Tap "Add Photo" → "Take Photo".
3. System returns immediately (permission denied) → app shows an alert: "Camera Access Required — Please allow camera access in Settings." with a "Open Settings" button.
4. Tapping "Open Settings" opens the iOS Settings app at the app's permission page.

### Scenario 7: Fill-up without photo (regression test)

1. Add a fill-up with no photo attached.
2. Save and view detail — no photo section shown (or empty state shown without error).
3. All existing fill-ups (pre-feature) display correctly without errors.

---

## Key Files After Implementation

| File | Role |
|------|------|
| `Fuel/Models/FillUp.swift` | +`photoData: Data?` |
| `Fuel/Models/CostEntry.swift` | +`photoData: Data?` |
| `Fuel/Views/CameraPickerView.swift` | UIKit camera wrapper |
| `Fuel/Views/CostDetailView.swift` | New cost detail view |
| `Fuel/Views/EditCostView.swift` | New cost edit form |
| `Fuel/Views/AddFillUpView.swift` | +photo attachment section |
| `Fuel/Views/EditFillUpView.swift` | +photo attachment section |
| `Fuel/Views/FillUpDetailView.swift` | +photo display section |
| `Fuel/Views/AddCostView.swift` | +photo attachment section |
| `Fuel/Views/CostListView.swift` | +navigation to CostDetailView |
| `Fuel/ViewModels/AddFillUpViewModel.swift` | +photoData state + compress helper |
| `Fuel/ViewModels/EditFillUpViewModel.swift` | +photoData state + compress helper |
| `Fuel/ViewModels/AddCostViewModel.swift` | +photoData state + compress helper |

---

## Privacy Requirements

Add to `Info.plist` (if not already present):

- `NSCameraUsageDescription`: "Used to capture receipt or pump photos for your fill-up and cost records."
- `NSPhotoLibraryUsageDescription`: "Used to attach photos from your library to fill-up and cost records."
