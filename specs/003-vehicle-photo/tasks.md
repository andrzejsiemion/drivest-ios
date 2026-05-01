# Tasks: Vehicle Photo

**Input**: Design documents from `specs/003-vehicle-photo/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, quickstart.md

**Tests**: Not explicitly requested in the feature specification. Test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Image compression service and reusable photo component needed by both user stories

- [x] T001 [P] Create ImageCompressor service with a static method that accepts image Data, resizes to max 300×300 pixels, and JPEG-compresses at quality 0.7, returning Data ≤500KB in Fuel/Services/ImageCompressor.swift
- [x] T002 [P] Create VehiclePhotoView component that displays a circular image from optional Data, or a car.fill SF Symbol placeholder when nil. Accept a size parameter (default 44pt) in Fuel/Views/Components/VehiclePhotoView.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Vehicle model extension that MUST be complete before user story work

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Add optional photoData: Data? field to Vehicle model in Fuel/Models/Vehicle.swift
- [x] T004 Add new source files (ImageCompressor.swift, VehiclePhotoView.swift) to the Xcode project build phase in Fuel.xcodeproj/project.pbxproj

**Checkpoint**: Foundation ready — Vehicle can store photo data, compression and display components exist

---

## Phase 3: User Story 1 - Add a Photo to a Vehicle (Priority: P1) 🎯 MVP

**Goal**: Users can add, replace, or remove a photo on any vehicle

**Independent Test**: Open vehicle detail → Tap photo area → Select/capture image → Photo appears and persists after leaving and returning to the screen

### Implementation for User Story 1

- [x] T005 [US1] Add photo save and remove methods to VehicleViewModel: `savePhoto(_ data: Data, for vehicle: Vehicle)` using ImageCompressor, and `removePhoto(for vehicle: Vehicle)` in Fuel/ViewModels/VehicleViewModel.swift
- [x] T006 [US1] Add a photo section to VehicleFormView: show VehiclePhotoView (large, ~100pt), a PhotosPicker button for library selection, and a camera button (shown only when camera is available). On selection, compress via ImageCompressor and store on the vehicle in Fuel/Views/VehicleFormView.swift
- [x] T007 [US1] Add photo display to VehicleDetailView: show VehiclePhotoView (large, ~100pt) at the top with a tap action to present photo change options (replace from library, take photo, remove) in Fuel/Views/VehicleDetailView.swift
- [x] T008 [US1] Handle permission denial: when PhotosPicker returns no selection due to access restrictions, show an informational message directing user to Settings in Fuel/Views/VehicleFormView.swift

**Checkpoint**: User Story 1 fully functional — users can add, replace, and remove vehicle photos

---

## Phase 4: User Story 2 - View Vehicle Photo in List (Priority: P2)

**Goal**: Vehicle list shows circular thumbnail photo on left side of each row

**Independent Test**: Add photos to multiple vehicles → Navigate to Vehicles tab → Each row shows the correct photo thumbnail on the left, or a placeholder if no photo

### Implementation for User Story 2

- [x] T009 [US2] Update VehicleRow in VehicleListView to display VehiclePhotoView (44pt) as the leading element of each row, before the vehicle name/details in Fuel/Views/VehicleListView.swift

**Checkpoint**: Both user stories functional — photos can be added and are visible as thumbnails in the vehicle list

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Performance and accessibility

- [x] T010 Verify thumbnail rendering performance with 20+ vehicles in the list — ensure no visible lag when scrolling. If needed, add lazy image decoding in Fuel/Views/Components/VehiclePhotoView.swift
- [x] T011 Add accessibility labels to VehiclePhotoView: "Vehicle photo" when image present, "No vehicle photo" for placeholder in Fuel/Views/Components/VehiclePhotoView.swift

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — ImageCompressor and VehiclePhotoView can be created in parallel
- **Foundational (Phase 2)**: Depends on Phase 1 (components must exist before model references them)
- **User Story 1 (Phase 3)**: Depends on Foundational phase
- **User Story 2 (Phase 4)**: Depends on Foundational phase (VehiclePhotoView) — can run in parallel with US1 but benefits from US1 being done
- **Polish (Phase 5)**: Depends on both user stories

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational — creates the photo data
- **User Story 2 (P2)**: Can start after Foundational — only reads photoData. Technically independent of US1 (placeholder works without US1) but testing is more meaningful with US1 complete.

### Parallel Opportunities

- T001 + T002: Both new files, no dependencies
- US2 (T009) only touches VehicleListView, while US1 touches VehicleFormView/DetailView — could run in parallel

---

## Parallel Example: Phase 1 Setup

```bash
# Both components are independent new files:
Task: "Create ImageCompressor in Fuel/Services/ImageCompressor.swift"
Task: "Create VehiclePhotoView in Fuel/Views/Components/VehiclePhotoView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (compressor + photo view component)
2. Complete Phase 2: Foundational (model field + pbxproj)
3. Complete Phase 3: User Story 1 (add/replace/remove photo)
4. **STOP and VALIDATE**: Can add photo, see it on detail screen, persists
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → MVP (photo management)
3. Add User Story 2 → Test independently → Full feature (thumbnails in list)
4. Polish → Accessibility + performance verification

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- PhotosUI import needed in VehicleFormView for PhotosPicker
- UIImagePickerController bridging needed for camera capture (SwiftUI doesn't have native camera picker)
- Commit after each task or logical group
