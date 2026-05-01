# Feature Specification: Vehicle Photo

**Feature Branch**: `003-vehicle-photo`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "Add photo of vehicle - on list of vehicles photo should be on left side"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a Photo to a Vehicle (Priority: P1)

As a vehicle owner, I want to add a photo of my vehicle so that I can visually identify it quickly in my vehicle list.

**Why this priority**: The photo cannot be displayed until it can be added. This is the foundational action.

**Independent Test**: Can be tested by navigating to a vehicle's edit/detail screen, tapping to add a photo, selecting or capturing an image, and confirming the photo persists after saving.

**Acceptance Scenarios**:

1. **Given** I am viewing or editing a vehicle, **When** I tap the photo area (or an "Add Photo" button), **Then** I am presented with options to take a photo or choose from my photo library.
2. **Given** I have selected a photo, **When** I confirm the selection, **Then** the photo is saved with the vehicle and displayed immediately.
3. **Given** I already have a photo on a vehicle, **When** I tap the photo area, **Then** I can replace it with a new image or remove it entirely.

---

### User Story 2 - View Vehicle Photo in List (Priority: P2)

As a vehicle owner, I want to see a thumbnail photo of each vehicle on the left side of the vehicle list so that I can quickly identify my vehicles at a glance.

**Why this priority**: Displaying the photo in the list is the user's explicit requirement and depends on the photo being stored first.

**Independent Test**: Can be tested by adding photos to multiple vehicles and verifying thumbnails appear on the left side of each row in the vehicle list.

**Acceptance Scenarios**:

1. **Given** a vehicle has a photo, **When** I view the vehicle list, **Then** I see a circular thumbnail of the photo on the left side of that vehicle's row.
2. **Given** a vehicle has no photo, **When** I view the vehicle list, **Then** I see a placeholder icon (e.g., a car silhouette) on the left side of the row.
3. **Given** I have multiple vehicles with different photos, **When** I scroll the vehicle list, **Then** the correct photo appears next to each vehicle without noticeable lag.

---

### Edge Cases

- What happens when the user denies camera/photo library access? → The app shows a message explaining that access is needed and directs the user to Settings.
- What happens when the user selects a very large photo? → The app automatically resizes/compresses the image to a reasonable size for storage and display.
- What happens when a vehicle's photo is deleted? → The placeholder icon is shown in the list and on the detail screen.
- What happens on a device without a camera (e.g., iPod touch, simulator)? → Only the "Choose from Library" option is shown; the camera option is hidden.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to add a photo to any vehicle from the vehicle detail or edit screen.
- **FR-002**: System MUST support selecting a photo from the device photo library.
- **FR-003**: System MUST support capturing a new photo using the device camera (when available).
- **FR-004**: System MUST display the vehicle photo as a circular thumbnail on the left side of each row in the vehicle list.
- **FR-005**: System MUST display a placeholder image when a vehicle has no photo.
- **FR-006**: System MUST allow users to replace or remove an existing vehicle photo.
- **FR-007**: System MUST resize/compress photos to limit storage impact (maximum stored size not exceeding 500KB per photo).
- **FR-008**: System MUST persist vehicle photos locally on-device alongside other vehicle data.

### Key Entities

- **Vehicle** (extended): Adds an optional photo attribute (stored image data) to the existing Vehicle entity.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a photo to a vehicle in under 15 seconds (from tapping "add photo" to seeing it saved).
- **SC-002**: Vehicle list displays all thumbnails within 0.5 seconds of appearing on screen, even with 20+ vehicles.
- **SC-003**: 100% of vehicles without a photo show the placeholder — no blank or broken image states.
- **SC-004**: Photo storage adds no more than 500KB per vehicle to on-device data.

## Assumptions

- Photos are stored locally on-device only (no cloud sync for photos in this version).
- A single photo per vehicle is sufficient (no gallery or multiple photos).
- The photo is displayed as a circular thumbnail in the vehicle list (standard iOS avatar pattern).
- Image compression/resizing is handled automatically — the user does not configure quality settings.
- The photo picker uses the system-provided interface (no custom camera UI needed).
