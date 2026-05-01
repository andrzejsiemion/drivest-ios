# Implementation Plan: Launch Screen Animation

**Branch**: `026-launch-animation` | **Date**: 2026-04-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/026-launch-animation/spec.md`

## Summary

Replace the plain black launch screen with a branded two-phase experience: (1) an iOS-native `UILaunchScreen` Info.plist configuration that shows the app logo on the accent-color background instantly before the Swift runtime starts, and (2) a SwiftUI `SplashView` that plays a logo fade+scale animation and transitions smoothly into `ContentView`, running concurrently with app initialisation to add zero latency.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI (Apple — no new dependencies)
**Storage**: N/A (no data layer changes)
**Testing**: XCTest (unit), manual visual verification on device/simulator
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (SwiftUI, MVVM)
**Performance Goals**: Animation completes within 1.2 s; no added latency before interactive main screen
**Constraints**: Must respect `accessibilityReduceMotion`; no third-party libraries; no UIKit
**Scale/Scope**: Single new view (`SplashView`), one asset set, one Info.plist change, one `DrivestApp.swift` edit

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | `SplashView` does one thing; no dead code |
| II. Simple UX | ✅ Pass | Simple logo animation ≤1.2 s; no user action required |
| III. Responsive Design | ✅ Pass | SwiftUI adaptive layout; tested at all sizes; Dark Mode via AccentColor asset |
| IV. Minimal Dependencies | ✅ Pass | SwiftUI only; no new packages |
| iOS Platform (iOS 17+, SwiftUI) | ✅ Pass | `UILaunchScreen` supported since iOS 14; `SplashView` is pure SwiftUI |
| No server dependency | ✅ Pass | Entirely local/offline |

**Post-design re-check**: No violations. No Complexity Tracking entry required.

## Project Structure

### Documentation (this feature)

```text
specs/026-launch-animation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── spec.md              # Feature specification
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
Drivest/
├── DrivestApp.swift                          # Modified — add SplashView overlay
├── Views/
│   └── SplashView.swift                      # New — animated splash screen view
└── Resources/
    └── Assets.xcassets/
        └── LaunchLogo.imageset/              # New — logo image for UILaunchScreen
            ├── Contents.json
            └── drivest.png                   # Copy/symlink of existing app icon PNG

Drivest/Supporting Files/
└── Info.plist                                # Modified — UILaunchScreen dict populated
```

**Structure Decision**: Single-project iOS app. All changes are within the existing `Drivest/` module. No new targets, packages, or architectural layers are introduced.

## Phase 0: Research

Research complete. See [research.md](research.md).

Key decisions:
- **Two-phase approach**: OS launch screen (Info.plist) + SwiftUI `SplashView`
- **No new dependencies**: Pure SwiftUI
- **Reduced motion**: `@Environment(\.accessibilityReduceMotion)` guards all motion
- **Asset**: New `LaunchLogo` image set referencing existing `drivest.png`
- **UILaunchScreen keys**: `UIColorName = "AccentColor"`, `UIImageName = "LaunchLogo"`

## Phase 1: Design

### Component Design: `SplashView`

`SplashView` is a full-screen SwiftUI view displayed on top of `ContentView` using a `ZStack` in `DrivestApp.body`. It is responsible for the animated transition from launch to the main app.

**Behaviour**:
1. On appear: logo is invisible (`opacity 0`) and slightly scaled down (`scale 0.8`)
2. With `.easeOut(duration: 0.6)` animation: logo fades in and scales to 1.0
3. After 1.0 s total (animation + brief hold): `onDismiss` closure is called
4. `DrivestApp` sets `showSplash = false`; `SplashView` fades out via `.transition(.opacity)` on the ZStack

**Reduced motion path**:
- If `accessibilityReduceMotion == true`: animation duration = 0, scale animation skipped, dismissal at 0.4 s

**SwiftUI structure (pseudocode)**:

```swift
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .opacity(opacity)
                .scaleEffect(reduceMotion ? 1.0 : scale)
        }
        .onAppear {
            let duration = reduceMotion ? 0.0 : 0.6
            withAnimation(.easeOut(duration: duration)) {
                opacity = 1.0
                scale = 1.0
            }
            let delay = reduceMotion ? 0.4 : 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                onDismiss()
            }
        }
    }
}
```

**`DrivestApp.body` change**:

```swift
var body: some Scene {
    WindowGroup {
        ZStack {
            ContentView()
                .environment(selectionStore)
                // ... other environments ...
            if showSplash {
                SplashView(onDismiss: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
    .modelContainer(container)
}
```

This ensures `ContentView` initialises immediately in the background — no latency added (SC-002, FR-004).

### Asset: `LaunchLogo` Image Set

Create `Drivest/Resources/Assets.xcassets/LaunchLogo.imageset/` with:
- `Contents.json`: declares a universal scale (1x) entry pointing to `drivest.png`
- `drivest.png`: the existing 1024×1024 app icon PNG, referenced (or copied) from `AppIcon.appiconset/drivest.png`

The `UIImageName = "LaunchLogo"` key in Info.plist references this asset set.

**Contents.json structure**:
```json
{
  "images": [
    { "filename": "drivest.png", "idiom": "universal", "scale": "1x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

### Info.plist: `UILaunchScreen`

Replace the current empty dict with:
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>AccentColor</string>
    <key>UIImageName</key>
    <string>LaunchLogo</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <false/>
</dict>
```

This immediately eliminates the black screen at the OS level.

### No Data Model Changes

This feature has no new persisted entities. `data-model.md` is not required.

### No External Contracts

This feature has no public APIs, exported schemas, or external interfaces. The `contracts/` directory is not required.

## Verification Checklist

Before marking the feature complete, verify:

- [ ] Cold launch from Xcode shows branded OS launch screen (no black flash)
- [ ] SwiftUI animation plays smoothly after OS hands control to the app
- [ ] Transition from splash to main screen has no hard cut
- [ ] Time from launch to interactive screen is ≤ baseline (measured with Instruments if needed)
- [ ] Reduced motion: with "Reduce Motion" enabled in Accessibility settings, animation is suppressed
- [ ] Dark Mode: splash background and logo render correctly
- [ ] iPhone SE (small) and iPhone 15 Pro Max (large): no layout clipping
- [ ] VoiceOver: splash screen does not block navigation (dismiss fires within 1.2 s regardless)
