# Tasks: Photo Attachments

**Input**: Design documents from `specs/015-photo-attachments/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup

- [X] T001 Add `NSCameraUsageDescription` ("Used to capture receipt or pump photos for your fill-up and cost records.") and `NSPhotoLibraryUsageDescription` ("Used to attach photos from your library to fill-up and cost records.") keys to `Fuel/Info.plist`

---

## Phase 2: Foundational

**Purpose**: Core infrastructure required by both US1 and US2 — must complete before user story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Add `var photoData: Data?` (default `nil`) to `@Model final class FillUp` in `Fuel/Models/FillUp.swift` — no init change required (SwiftData handles optional nil-default migration automatically)
- [X] T003 [P] Add `var photoData: Data?` (default `nil`) to `@Model final class CostEntry` in `Fuel/Models/CostEntry.swift` — same migration-safe pattern as T002
- [X] T004 [P] Create `Fuel/Utilities/ImageCompressor.swift` — define `func compressImage(_ image: UIImage, maxBytes: Int = 800_000) -> Data?` that tries `jpegData(compressionQuality: 0.7)` first, then `0.5`, then `0.3`; returns nil if all exceed `maxBytes`
- [X] T005 [P] Create `Fuel/Views/CameraPickerView.swift` — `UIViewControllerRepresentable` wrapping `UIImagePickerController` with `sourceType = .camera`; `Coordinator` handles `imagePickerController(_:didFinishPickingMediaWithInfo:)` and `imagePickerControllerDidCancel(_:)`, calling completion `(UIImage?) -> Void`
- [X] T006 Create `Fuel/Views/PhotoAttachmentSection.swift` — a reusable SwiftUI `View` accepting `@Binding var photoData: Data?`; renders: (a) if nil — `Button("Add Photo")` with `photo.on.rectangle` icon that triggers `confirmationDialog("Photo Source", presenting: ...)` with "Take Photo" (shows `CameraPickerView` sheet) and "Choose from Library" (shows `PhotosPicker`); (b) if not nil — `Image(uiImage:).resizable().scaledToFit().frame(maxHeight: 120)` thumbnail + `Button("Remove")` + `Button("Change")`; on image selection calls `compressImage(_:)` and writes result to `photoData`; on camera permission denial shows alert with "Open Settings" button using `UIApplication.openSettingsURLString`

**Checkpoint**: Models updated, compressor utility and shared photo attachment UI component ready. User stories can now begin in parallel.

---

## Phase 3: User Story 1 — Fill-Up Photo Attachment (Priority: P1) 🎯 MVP

**Goal**: Users can attach, view, replace, and remove a photo on fill-up records via Add and Edit forms; photo is displayed in Fill-Up Detail.

**Independent Test**: Add a fill-up, attach a gallery photo → save → open detail → photo displayed. Edit the fill-up → existing photo shown, can be removed → save → detail shows no photo. Delete the fill-up → no orphaned data.

### Implementation for User Story 1

- [X] T007 [P] [US1] Update `AddFillUpViewModel` in `Fuel/ViewModels/AddFillUpViewModel.swift` — add `var selectedPhotoData: Data?` property; update `save(currencyCode:exchangeRate:)` to set `fillUp.photoData = selectedPhotoData` on the newly created `FillUp` instance
- [X] T008 [P] [US1] Update `EditFillUpViewModel` in `Fuel/ViewModels/EditFillUpViewModel.swift` — add `var selectedPhotoData: Data?` property initialised from `fillUp.photoData` in `init`; update `save()` to write `fillUp.photoData = selectedPhotoData`
- [X] T009 [US1] Update `AddFillUpView` in `Fuel/Views/AddFillUpView.swift` — inside the `else if let vm = viewModel` branch, add `PhotoAttachmentSection(photoData: Binding(get: { vm.selectedPhotoData }, set: { vm.selectedPhotoData = $0 }))` as a new `Section` after the existing Note section
- [X] T010 [P] [US1] Update `EditFillUpView` in `Fuel/Views/EditFillUpView.swift` — same pattern: add `PhotoAttachmentSection(photoData: Binding(get: { vm.selectedPhotoData }, set: { vm.selectedPhotoData = $0 }))` after the Note section
- [X] T011 [P] [US1] Update `FillUpDetailView` in `Fuel/Views/FillUpDetailView.swift` — at the top of the `List { ... }`, before the existing first `Section`, add: `if let data = fillUp.photoData, let img = UIImage(data: data) { Section { Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 280).clipShape(RoundedRectangle(cornerRadius: 8)) } }`

**Checkpoint**: Fill-up photos fully functional end-to-end. US2 can now begin.

---

## Phase 4: User Story 2 — Cost Entry Photo Attachment (Priority: P2)

**Goal**: Users can attach, view, replace, and remove a photo on cost entries via Add and new Edit forms; photo is displayed in new Cost Detail view; cost list navigates to detail.

**Independent Test**: Add a cost with a camera photo → save → tap cost row in list → Cost Detail opens → photo displayed. Edit cost → replace photo → save → detail shows new photo. Restart app → photo persists.

### Implementation for User Story 2

- [X] T012 [P] [US2] Update `AddCostViewModel` in `Fuel/ViewModels/AddCostViewModel.swift` — add `var selectedPhotoData: Data?` property; update `save(currencyCode:exchangeRate:)` to set `entry.photoData = selectedPhotoData` on the newly created `CostEntry`
- [X] T013 [P] [US2] Create `EditCostViewModel` in `Fuel/ViewModels/EditCostViewModel.swift` — `@Observable final class EditCostViewModel` with `modelContext: ModelContext`, `costEntry: CostEntry`; properties: `var date: Date`, `var selectedCategory: CostCategory?`, `var amountText: String`, `var noteText: String`, `var selectedPhotoData: Data?`; `init` pre-populates all from `costEntry`; `var isValid: Bool` checks `amountText` is a positive number; `func save()` writes all fields back to `costEntry` and calls `Persistence.save(modelContext)`
- [X] T014 [US2] Update `AddCostForm` in `Fuel/Views/AddCostView.swift` — add `PhotoAttachmentSection(photoData: $viewModel.selectedPhotoData)` as a new section after the Note section in the Form
- [X] T015 [P] [US2] Create `CostDetailView` in `Fuel/Views/CostDetailView.swift` — `struct CostDetailView: View` with `let costEntry: CostEntry`; List with: (1) if photo present — headerless Section with full-width image display same as T011; (2) Section with `LabeledContent("Date")` + formatted date, `LabeledContent("Category")` with icon + name, `LabeledContent("Amount")` with formatted amount + currency symbol; (3) if note present — `Section("Note") { Text(costEntry.note!) }`; toolbar `ToolbarItem(.topBarTrailing)` with "Edit" button presenting `EditCostView(costEntry: costEntry)` sheet; `.navigationTitle("Cost Details")`
- [X] T016 [US2] Create `EditCostView` in `Fuel/Views/EditCostView.swift` — `struct EditCostView: View` with `@State private var viewModel: EditCostViewModel?` and `let costEntry: CostEntry`; Form with sections: Section (no header) for category Picker bound to `vm.selectedCategory` (using `@Query(sort: \CostCategory.sortOrder) private var categories`), Section for Amount `HStack { TextField(...) + currency symbol }`, Section("Date") with DatePicker, Section("Note") with TextField, PhotoAttachmentSection; toolbar Cancel + Save; `onAppear` creates `EditCostViewModel(modelContext:costEntry:)`
- [X] T017 [US2] Update `CostListView` in `Fuel/Views/CostListView.swift` — inside the cost rows `ForEach`, wrap each row in `NavigationLink(value: costEntry.id)` and add `.navigationDestination(for: UUID.self) { id in if let entry = vm.costEntries.first(where: { $0.id == id }) { CostDetailView(costEntry: entry) } }` on the inner `List`

**Checkpoint**: Cost photos fully functional. Both US1 and US2 complete.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T018 Build the project with `xcodebuild` and confirm zero errors across all modified and new files
- [X] T019 [P] Run all 7 quickstart.md scenarios manually on iPhone SE simulator — verify gallery attach, camera attach, replace, remove, cost photo, permission denied alert, and regression (no-photo fill-up)
- [X] T020 [P] Run quickstart.md scenarios on iPhone 17 Pro Max simulator — verify photo display fits correctly on large screen (no clipping, correct max height)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 completion — blocks all user story work
  - T002, T003, T004, T005 are all parallel (different new files)
  - T006 depends on T005 (uses `CameraPickerView`)
- **US1 (Phase 3)**: Depends on Phase 2 complete
  - T007 and T008 are parallel (different VM files)
  - T009 depends on T006 + T007; T010 depends on T006 + T008 (both parallel with each other)
  - T011 depends on T002 only — can run in parallel with T009/T010
- **US2 (Phase 4)**: Depends on Phase 2 complete; can run in parallel with US1 if needed
  - T012 and T013 are parallel (different VM files)
  - T014 depends on T006 + T012
  - T015 and T016 are parallel (different new view files); T016 depends on T013
  - T017 depends on T015
- **Polish (Phase 5)**: Depends on both US1 and US2 complete

### Parallel Opportunities

- T002, T003, T004, T005: all parallel (Phase 2)
- T007, T008: parallel (Phase 3)
- T009, T010, T011: all parallel within Phase 3 (after their dependencies)
- T012, T013: parallel (Phase 4)
- T015, T016: parallel (Phase 4)
- T019, T020: parallel (Phase 5)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001: Info.plist privacy strings
2. T002, T003, T004, T005 in parallel → T006
3. T007, T008 in parallel → T009, T010, T011
4. **STOP and VALIDATE**: Add fill-up with photo (gallery + camera), view detail, edit, delete
5. Demo if ready

### Incremental Delivery

1. T001 → Setup ✓
2. T002–T006 → Foundational ✓
3. T007–T011 → Fill-Up photo ✓ (MVP!)
4. T012–T017 → Cost photo ✓
5. T018–T020 → Polish ✓

---

## Notes

- T002 and T003: SwiftData handles nil-default optional field migrations automatically — no schema version bump required
- T006 (`PhotoAttachmentSection`): Used by 4 forms (AddFillUp, EditFillUp, AddCost, EditCost) — single implementation eliminates duplication
- T013 (`EditCostViewModel`): Mirror of `EditFillUpViewModel`; must support `CostCategory` picker (using `@Query` in the view)
- T015 (`CostDetailView`): Check `CostListViewModel` for how `costEntries` are fetched to match the same data access pattern
- T016 (`EditCostView`): The currency symbol comes from `costEntry.currencyCode` (same as `FillUpDetailView` pattern)
- T017: Check existing `FillUpListView` `NavigationLink(value:)` + `.navigationDestination` pattern to match exactly
