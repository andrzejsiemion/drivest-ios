# Tasks: Launch Screen Animation

**Input**: Design documents from `specs/026-launch-animation/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Exact file paths included in all task descriptions

---

## Phase 1: Foundational (Blocking Prerequisite)

**Purpose**: Create the `LaunchLogo` image asset that both the Info.plist launch screen config and the SwiftUI `SplashView` depend on. Must complete before any user story work.

**⚠️ CRITICAL**: US1 implementation cannot begin until this phase is complete.

- [x] T001 Create `Drivest/Resources/Assets.xcassets/LaunchLogo.imageset/Contents.json` declaring a universal 1x image entry pointing to `drivest.png`
- [x] T002 Copy `Drivest/Resources/Assets.xcassets/AppIcon.appiconset/drivest.png` into `Drivest/Resources/Assets.xcassets/LaunchLogo.imageset/drivest.png`

**Checkpoint**: `LaunchLogo` image set exists in the asset catalog and is referenceable by name — both Info.plist and SwiftUI code can now use it.

---

## Phase 2: User Story 1 — Animated App Launch (Priority: P1) 🎯 MVP

**Goal**: Replace the plain black launch screen with a branded animated experience — an instant OS-managed logo screen followed by a SwiftUI fade+scale animation transitioning into the main app.

**Independent Test**: Cold-launch the app from the home screen. Verify: (1) no black screen is visible at any point, (2) the app icon appears on the accent-color background immediately, (3) a logo animation plays, (4) the app transitions smoothly to the vehicle list.

### Implementation for User Story 1

- [x] T003 [US1] Update the `UILaunchScreen` dict in `Drivest/Supporting Files/Info.plist` (or `Drivest/Info.plist`) to set `UIColorName = "AccentColor"`, `UIImageName = "LaunchLogo"`, and `UIImageRespectsSafeAreaInsets = false`
- [x] T004 [US1] Create `Drivest/Views/SplashView.swift` — full-screen SwiftUI view with accent-color background, `LaunchLogo` image centred at 120×120 pt, opacity fade-in (0→1) and scale animation (0.8→1.0) using `.easeOut(duration: 0.6)` on `.onAppear`, with a `DispatchQueue.main.asyncAfter` of 1.0 s before calling the `onDismiss: () -> Void` closure; reads `@Environment(\.accessibilityReduceMotion)` to skip scale and use 0.4 s instant-appear when enabled
- [x] T005 [US1] Modify `DrivestApp.swift` — add `@State private var showSplash = true`, wrap the `WindowGroup` body in a `ZStack` with `ContentView` (and all its `.environment` modifiers) as the base layer and `SplashView(onDismiss: { withAnimation(.easeOut(duration: 0.3)) { showSplash = false } })` as the overlay with `.transition(.opacity).zIndex(1)` shown only when `showSplash == true`

**Checkpoint**: User Story 1 is fully functional. Cold launch shows branded screen + animation + smooth transition. No black flash.

---

## Phase 3: User Story 2 — Fast Launch Perception (Priority: P2)

**Goal**: Confirm that the animation adds no perceptible delay before the user can interact with the main screen. The ZStack architecture from US1 ensures `ContentView` initialises concurrently with the splash — this phase validates that guarantee holds and requires no additional code changes.

**Independent Test**: Time the interval from launch gesture to interactive vehicle list on a reference device (e.g. iPhone 14 simulator). Compare with the pre-feature baseline. The delta must be ≤ 0 (animation runs concurrently, not sequentially).

### Implementation for User Story 2

- [x] T006 [US2] Review `DrivestApp.swift` — confirm `ContentView` sits at `zIndex(0)` in the `ZStack` (below `SplashView`) and is NOT conditionally rendered; it must be present and initialising from app start, not deferred until after the splash. Adjust if needed.
- [x] T007 [US2] Verify in `SplashView.swift` that the `onDismiss` closure fires unconditionally after the fixed delay — there must be no `await`/`Task` or blocking call that could hold the splash open longer than the designed duration, regardless of `ContentView` load time.

**Checkpoint**: Architecture confirmed — `ContentView` initialises in the background behind the splash. No latency added.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, device size, and Dark Mode verification.

- [ ] T008 [P] Manual check on iPhone SE (4.7″) simulator — verify `LaunchLogo` image is centred, not clipped, and the accent-color background fills the screen edge-to-edge on the OS launch screen
- [ ] T009 [P] Manual check on iPhone 15 Pro Max (6.7″) simulator — same verification as T008
- [ ] T010 [P] Dark Mode check — toggle Appearance to Dark in simulator, cold-launch, verify accent-color background and logo render correctly in both OS launch screen and `SplashView`
- [ ] T011 Accessibility check — enable Settings → Accessibility → Motion → Reduce Motion in simulator, cold-launch, verify no scale animation plays and splash dismisses within 0.4 s

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **User Story 1 (Phase 2)**: Depends on Phase 1 (T001, T002 must be done first)
- **User Story 2 (Phase 3)**: Depends on Phase 2 (US1 implementation must be in place to verify)
- **Polish (Phase 4)**: Depends on Phase 2 + Phase 3

### Task-Level Dependencies

```
T001 → T002 → T003 (Info.plist)
              T004 (SplashView.swift)
              T005 (DrivestApp.swift)
         ↓
        T006 → T007
         ↓
    T008, T009, T010 (parallel) → T011
```

### Parallel Opportunities

- T001 and research of Info.plist key names can run in parallel
- T003, T004, T005 can all run in parallel once Phase 1 is complete (different files)
- T006 and T007 can run in parallel (different concerns, same file T006 but read-only review)
- T008, T009, T010 can run in parallel (different simulators/settings)

---

## Parallel Example: User Story 1

```
# After T001 + T002 are done, launch all three in parallel:
T003 — Update Info.plist UILaunchScreen
T004 — Create SplashView.swift
T005 — Modify DrivestApp.swift
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1 (T001–T002) — create asset
2. Complete Phase 2 (T003–T005) in parallel — Info.plist + SplashView + DrivestApp
3. **STOP and VALIDATE**: Cold-launch on simulator, confirm no black screen, animation plays, transition is smooth
4. Feature delivers full user value at this point

### Incremental Delivery

1. Phase 1 → asset ready
2. T003 alone → OS launch screen branded (eliminates black flash even without SwiftUI animation)
3. T004 + T005 → adds SwiftUI animation layer
4. Phase 3 → architecture review confirms no latency regression
5. Phase 4 → polish and accessibility sign-off

---

## Notes

- [P] tasks = different files or independent concerns, safe to parallelise
- No new Swift Package dependencies; all tasks use SwiftUI and existing assets only
- Commit after Phase 1 (asset), after Phase 2 (core feature), after Phase 4 (polish)
- The Info.plist file location may be `Drivest/Info.plist` or inside the Xcode project — confirm actual path before T003
