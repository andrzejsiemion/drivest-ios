# Research: Photo Attachments

**Feature**: 015-photo-attachments
**Date**: 2026-04-21

---

## Decision 1: Photo Storage Strategy

**Decision**: Store photo as `Data?` directly on the `FillUp` and `CostEntry` SwiftData models.

**Rationale**: `Vehicle.photoData: Data?` in the existing codebase uses exactly this pattern. It is the established convention for this project, avoids adding a new entity/relationship, and keeps SwiftData cascade deletes automatic. SwiftData handles binary blobs well for the typical receipt photo sizes (≤500 KB after compression).

**Alternatives considered**:
- Separate `PhotoAttachment` entity with a `@Relationship` to each record — adds unnecessary complexity and a new join for a one-to-one optional attachment.
- File system storage (writing JPEG to Documents folder and storing a file path) — more complex lifecycle management, no automatic cleanup on record deletion, no free cascade delete.

---

## Decision 2: Photo Picker & Camera Access

**Decision**: Use `PhotosPicker` (SwiftUI native, iOS 16+) for gallery access, and `UIImagePickerController` wrapped in a `UIViewControllerRepresentable` for camera capture. Both are presented via a `confirmationDialog` that lets the user choose the source.

**Rationale**: SwiftUI's `PhotosPicker` does not support `.camera` as a source on iOS 17. For camera capture, UIKit's `UIImagePickerController` is required — this is explicitly justified by the constitution ("UIKit permitted only for capabilities not yet available in SwiftUI"). `confirmationDialog` is the standard iOS idiom for presenting a choice of source.

**Alternatives considered**:
- `UIImagePickerController` for both gallery and camera — works but bypasses the modern SwiftUI `PhotosPicker`, which has better privacy (on-demand photo access).
- Third-party image picker library — violates constitution Principle IV (Minimal Dependencies); no justification when Apple frameworks cover the need.

---

## Decision 3: Image Compression

**Decision**: Before saving, convert the selected/captured image to JPEG with quality 0.7 using `UIImage.jpegData(compressionQuality: 0.7)`. Cap output at 800 KB; if still over limit, reduce quality iteratively.

**Rationale**: Receipt photos need to be legible but not full-resolution. A 12 MP iPhone photo at JPEG 0.7 typically compresses to 300–700 KB, well within the spec's ≤500 KB target on average. Iterative fallback protects against oversized inputs (e.g., very large gallery photos).

**Alternatives considered**:
- Store at full resolution — risks multi-MB blobs per record, degrading SwiftData performance and storage.
- Fixed 300×400 px thumbnail — too small for reading receipt text in detail view.
- PNG — lossless but significantly larger than JPEG for photographic content.

---

## Decision 4: Cost Detail View

**Decision**: Create a new `CostDetailView` that presents the cost entry details (date, category, amount, note, photo). Navigate to it from `CostListView` list rows.

**Rationale**: There is currently no detail view for cost entries. Without a detail view, there is no natural place to display an attached photo. Adding a detail view also improves the overall UX by making costs consistent with fill-ups (which already have `FillUpDetailView`).

**Alternatives considered**:
- Show photo thumbnail in the list row — cramped, small; not suitable for viewing receipt details.
- Show photo inside the edit sheet — conflates view and edit modes; non-standard iOS pattern.

---

## Decision 5: Permissions Handling

**Decision**: Use `Info.plist` keys `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` (already required by iOS). On permission denial, show an alert with a "Open Settings" button using `UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)`.

**Rationale**: Standard iOS pattern. `PhotosPicker` on iOS 17 requests photo library access automatically with the system UI. Camera permission must be declared in `Info.plist` and will be requested on first camera use by the system.

**Alternatives considered**:
- Pre-flight permission check before showing picker — adds code complexity; iOS system handles the prompt automatically for both photo library and camera.

---

## Decision 6: Photo Display in Detail Views

**Decision**: Display the photo as a full-width `Image` view at the top of the `Section` in `FillUpDetailView` and `CostDetailView`, with aspect ratio `.fit` and a maximum height of 280 pt.

**Rationale**: Receipts are typically portrait-oriented and need to be large enough to read. 280 pt height gives legible text on all screen sizes while not dominating the entire screen. A dedicated section with no header keeps the layout clean.

**Alternatives considered**:
- Thumbnail with tap-to-expand full screen view — desirable but out of scope per spec assumption ("No full-screen zoom required in initial implementation").
- Fixed square thumbnail — too small for receipt legibility.
