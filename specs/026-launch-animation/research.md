# Research: Launch Screen Animation

**Feature**: 026-launch-animation
**Date**: 2026-04-30

---

## Finding 1: Current State of the Launch Screen

**Decision**: The current `UILaunchScreen` entry in Info.plist is an empty dictionary `{}`, which causes iOS to display a plain black screen while the app binary loads.

**Rationale**: iOS uses `UILaunchScreen` (introduced iOS 14 as the modern replacement for `LaunchScreen.storyboard`) to render a native OS-managed screen before the Swift runtime even starts. An empty dict → no background color, no image → black.

**Fix**: Populate `UILaunchScreen` with `UIColorName` (app background) and `UIImageName` (app icon) so the OS launch screen is visually branded with zero Swift code.

**Alternatives considered**:
- `LaunchScreen.storyboard`: deprecated path, adds UIKit dependency, constitution prefers SwiftUI/modern approach.
- Third-party splash libraries: violates Principle IV (Minimal Dependencies).

---

## Finding 2: Two-Phase Approach (OS Launch Screen + SwiftUI Animation)

**Decision**: Use a two-phase approach:
1. **Phase A — OS Launch Screen** (Info.plist): Branded, instant, zero-latency. Shows app icon centred on background color. Managed entirely by iOS — no Swift code needed.
2. **Phase B — SwiftUI Splash View**: A thin SwiftUI view displayed as the first scene after the OS hands control to the app. Plays a logo fade+scale animation while `ModelContainer` and other services are already initialized (they run in `DrivestApp.init()` which happens before the scene appears). Once the animation completes, the view transitions to `ContentView`.

**Rationale**: Phase A eliminates the black flash before the Swift runtime starts. Phase B provides the branded animated transition the user asked for and aligns the visual hand-off between OS launch screen and the live app. Without Phase B, there would be a jarring hard cut from the static OS screen to the full vehicle list.

**Alternatives considered**:
- Phase A only (no SwiftUI animation): Eliminates the black screen but gives no smooth transition. Acceptable minimum but misses the UX goal.
- Phase B only (without Info.plist fix): The black flash before the OS hands control persists — partly solves the problem.
- A full-screen video or Lottie animation: Disproportionate complexity for a utility app; violates Principle II (Simple UX) and Principle IV (Minimal Dependencies).

---

## Finding 3: SwiftUI Implementation Pattern

**Decision**: Implement `SplashView` as a pure SwiftUI view that:
- Shows the app logo (from Assets.xcassets `AppIcon` or a dedicated logo image set)
- Applies `.opacity` + `.scaleEffect` with `.easeOut` animation (~0.6 s) on `.onAppear`
- After a total display time of ~1.0–1.2 s, calls a completion closure that sets `showSplash = false` in `DrivestApp`
- Reads `@Environment(\.accessibilityReduceMotion)` — if `true`, skips the scale animation and uses only a fast fade

In `DrivestApp.body`, the scene uses a `ZStack` with `ContentView` underneath and `SplashView` on top, with `SplashView` fading out (`.opacity` transition) when dismissed. This avoids navigation stack pollution and keeps `ContentView` already loading in the background.

**Rationale**:
- ZStack approach means `ContentView` initializes immediately — no added latency (SC-002 preserved).
- `@Environment(\.accessibilityReduceMotion)` is the Apple-idiomatic way to respect the system accessibility setting (FR-005).
- No new dependencies; uses only SwiftUI — compliant with Principle IV.

**Alternatives considered**:
- Conditional `if showSplash { SplashView() } else { ContentView() }`: Simpler but delays `ContentView` initialization until splash completes.
- UIKit `UILaunchScreen` programmatic customization: Unnecessary complexity given SwiftUI can handle Phase B entirely.

---

## Finding 4: Reduced Motion Handling

**Decision**: When `accessibilityReduceMotion` is `true`:
- Skip `.scaleEffect` animation entirely (logo appears at full size)
- Replace opacity fade-in with an instant appear (or very short 0.15 s fade)
- Timer-based dismissal still fires at ~0.8 s so the splash doesn't linger

**Rationale**: Apple's HIG and WCAG 2.1 SC 2.3.3 (AAA) require that motion animations can be disabled. SwiftUI's `accessibilityReduceMotion` environment value is the canonical check.

---

## Finding 5: Info.plist UILaunchScreen Keys

**Decision**: Set the following keys in the `UILaunchScreen` dict:

| Key | Value | Effect |
|-----|-------|--------|
| `UIColorName` | `"AccentColor"` | Uses the existing accent color asset as the background — matches app branding with no new asset needed |
| `UIImageName` | `"AppIcon"` (or dedicated `LaunchLogo` asset) | Displays the app icon centred on screen |
| `UIImageRespectsSafeAreaInsets` | `false` | Allows the image to be centred in the full screen bounds |

**Note**: The `AppIcon` appiconset cannot be directly referenced by `UIImageName` (it is a special asset type). A dedicated `LaunchLogo` image set containing the same `drivest.png` at 1x/2x/3x must be created in Assets.xcassets and referenced by `UIImageName`.

**Alternatives considered**:
- White/system background: Does not match the dark-green accent branding.
- Custom colour not in assets: Requires hardcoded hex — less maintainable.
