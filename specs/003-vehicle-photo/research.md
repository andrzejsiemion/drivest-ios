# Research: Vehicle Photo

**Date**: 2026-04-20
**Status**: Complete — no NEEDS CLARIFICATION items

## Decisions

### 1. Image Storage Strategy

- **Decision**: Store compressed image as `Data?` directly on the Vehicle SwiftData model.
- **Rationale**: For a local-only app with ≤500KB per image and a small number of vehicles (typically <10), inline binary storage in SwiftData is simpler than file-system management. SwiftData handles persistence and cascade deletion automatically.
- **Alternatives considered**: File system storage with path reference (adds file management complexity, orphan risk), separate ImageStore entity (over-engineered for single image per vehicle).

### 2. Photo Picker Framework

- **Decision**: Use `PhotosUI` with `PhotosPicker` (SwiftUI native, iOS 16+).
- **Rationale**: PhotosPicker integrates seamlessly with SwiftUI, handles permissions transparently, and doesn't require explicit PHPhotoLibrary authorization for read-only access. Supports both library selection and limited photo access.
- **Alternatives considered**: UIImagePickerController (UIKit, requires bridging), custom camera UI (overkill, violates Principle II).

### 3. Camera Capture

- **Decision**: Use UIImagePickerController with `.camera` source type, presented via SwiftUI sheet wrapper.
- **Rationale**: PhotosPicker doesn't support camera capture. UIImagePickerController is the standard approach for camera access in iOS. Camera availability is checked via `UIImagePickerController.isSourceTypeAvailable(.camera)`.
- **Alternatives considered**: AVFoundation custom camera (massively over-engineered for a single photo capture).

### 4. Image Compression Strategy

- **Decision**: Resize to max 300×300 pixels, then JPEG compress at quality 0.7. This typically yields images well under 500KB while remaining visually sharp for thumbnail display.
- **Rationale**: Vehicle photos are only displayed as small circular thumbnails (~50-80pt diameter). High resolution is unnecessary. JPEG at 0.7 quality balances file size and visual quality.
- **Alternatives considered**: HEIF compression (better ratio but less compatible for debugging), PNG (too large for photos), no resize (risks multi-MB storage per vehicle).

### 5. Thumbnail Display in List

- **Decision**: Display as 44×44pt circular clipped image on the leading edge of each vehicle row. Use a car.fill SF Symbol as placeholder for vehicles without photos.
- **Rationale**: 44pt matches standard iOS touch target and list row height. Circular crop is a widely recognized avatar/thumbnail pattern. SF Symbols provide consistent placeholder styling.
- **Alternatives considered**: Square thumbnail (less visually distinct), larger image (takes too much row space), no placeholder (creates visual misalignment between rows).
