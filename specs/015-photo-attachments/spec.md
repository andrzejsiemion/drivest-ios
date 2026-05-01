# Feature Specification: Photo Attachments

**Feature Branch**: `015-photo-attachments`
**Created**: 2026-04-21
**Status**: Draft
**Input**: User description: "User should be able to add to fill-ups and costs photos (make them by camera or add them from gallery)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Attach Photo to Fill-Up (Priority: P1)

A user logging a fuel fill-up wants to attach a photo of the receipt or pump display as evidence or for future reference. When adding a new fill-up, they can tap a camera/gallery button to capture a new photo or choose one from their device's photo library. The photo is saved alongside the fill-up record and can be viewed later in the fill-up detail screen.

**Why this priority**: Fill-ups are the core record type in the app. Photo evidence of receipts is the most common user need for this kind of tracking app (tax records, expense reports, dispute resolution). This delivers standalone value immediately.

**Independent Test**: Create a new fill-up, attach a photo from the gallery, save. Open the fill-up detail — photo is displayed. Delete the fill-up — photo is also removed.

**Acceptance Scenarios**:

1. **Given** the Add Fill-Up form is open, **When** the user taps the photo attachment area, **Then** a picker appears offering "Take Photo" (camera) and "Choose from Library" (photo gallery) options.
2. **Given** the user selects a photo source, **When** they choose or capture a photo, **Then** the photo is shown as a thumbnail preview in the form before saving.
3. **Given** a fill-up with a photo is saved, **When** the user opens the Fill-Up Detail screen, **Then** the photo is displayed in full view.
4. **Given** a fill-up with a photo, **When** the user edits the fill-up, **Then** the existing photo is shown and they can replace or remove it.
5. **Given** a fill-up with a photo, **When** the user deletes the fill-up, **Then** the stored photo data is also removed.
6. **Given** the user is adding a fill-up, **When** they do not attach a photo, **Then** the fill-up saves normally with no photo — photo is optional.

---

### User Story 2 - Attach Photo to Cost Entry (Priority: P2)

A user logging a vehicle cost (service, repair, insurance) wants to attach a photo of the invoice or document. When adding or editing a cost entry, they can attach a photo the same way as for fill-ups. The photo appears in the cost detail view.

**Why this priority**: Cost entries are secondary records. The photo attachment capability should mirror fill-ups for consistency, but the core value is established by US1 first.

**Independent Test**: Create a new cost entry, attach a photo via camera, save. Open the cost entry — photo is displayed. Verify photo persists after app restart.

**Acceptance Scenarios**:

1. **Given** the Add Cost form is open, **When** the user taps the photo attachment area, **Then** a source picker appears with camera and gallery options.
2. **Given** a cost entry with a photo is saved, **When** the user views the cost entry, **Then** the attached photo is displayed.
3. **Given** a cost entry with a photo, **When** the user edits the cost entry, **Then** they can replace or remove the existing photo.
4. **Given** the user adds a cost without a photo, **Then** the cost saves normally — photo is optional.

---

### Edge Cases

- What happens when the user denies camera or photo library permission? → A clear, user-friendly message is shown explaining why the permission is needed, with an option to open system Settings.
- What happens if the selected photo is very large? → The photo is resized/compressed before storage to prevent excessive storage use, without visible quality loss for receipt-level detail.
- What happens if the user taps the photo attachment button but cancels without selecting a photo? → The form remains unchanged; no photo is attached and no error is shown.
- What happens if storage space is insufficient to save the photo? → A clear error message is shown; the fill-up/cost can still be saved without the photo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to attach one photo to a fill-up record when adding or editing it.
- **FR-002**: Users MUST be able to attach one photo to a cost entry record when adding or editing it. A dedicated cost entry edit screen (covering category, amount, date, note, and photo) MUST be provided.
- **FR-003**: The photo source picker MUST offer two options: take a new photo with the camera, or choose an existing photo from the device's photo library.
- **FR-004**: A thumbnail preview of the selected photo MUST be displayed in the form before the record is saved.
- **FR-005**: The attached photo MUST be displayed in the Fill-Up Detail screen and Cost Detail screen.
- **FR-006**: Users MUST be able to remove an attached photo from an existing record without deleting the record itself.
- **FR-007**: Users MUST be able to replace an attached photo on an existing record.
- **FR-008**: Photos MUST be stored locally on the device alongside the record data.
- **FR-009**: When a record (fill-up or cost) is deleted, its associated photo MUST also be deleted.
- **FR-010**: Photo attachment MUST be optional — records without photos must save and display normally.
- **FR-011**: The system MUST request camera and photo library permissions before first use, with a clear explanation of why access is needed.
- **FR-012**: If permissions are denied, the system MUST inform the user and provide a path to system Settings to grant access.
- **FR-013**: Photos MUST be compressed/resized before storage to keep storage usage reasonable while preserving legibility of receipt text.

### Key Entities

- **Photo Attachment**: Binary image data stored per record. Attributes: image data (compressed), source (camera or library). One fill-up or cost entry can have at most one photo.
- **Fill-Up** (existing): Gains an optional photo attachment.
- **Cost Entry** (existing): Gains an optional photo attachment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can attach a photo to a fill-up or cost in under 30 seconds from tapping the attachment control.
- **SC-002**: 100% of fill-ups and cost entries with attached photos display the photo correctly in their detail screens.
- **SC-003**: Attached photos remain visible after closing and reopening the app (persistent storage verified).
- **SC-004**: Deleting a record with a photo leaves no orphaned photo data in storage.
- **SC-005**: Photo attachment is optional — 0% of existing records or new records without photos are affected by this feature (no regressions).
- **SC-006**: Photos stored per record occupy no more than 500 KB on average after compression, ensuring the app remains storage-efficient.

## Clarifications

### Session 2026-04-21

- Q: Does implementing cost photo attachment require building a full EditCostView, or should photo editing on costs be limited to add-only? → A: Build a minimal EditCostView (category, amount, date, note, photo) as part of this feature.

## Assumptions

- Each fill-up and cost entry supports at most one photo (not a gallery of multiple photos).
- Photos are stored locally on the device — no cloud upload or sync is in scope.
- The photo is displayed as a single inline image in the detail view; no full-screen zoom is required in the initial implementation (nice-to-have but not required).
- Existing fill-up and cost records without photos are unaffected and display normally.
- The app targets iOS, so the camera and photo library are accessed via standard iOS system pickers — no third-party image library is required.
- Photo compression targets legibility of printed receipt text at a reasonable storage cost — exact compression ratio is an implementation decision.
