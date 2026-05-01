# Feature Specification: Launch Screen Animation

**Feature Branch**: `026-launch-animation`
**Created**: 2026-04-30
**Status**: Draft
**Input**: User description: "when application is launched black screen appears - can we make some animation here to improve user experience?"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Animated App Launch (Priority: P1)

When a user opens the app, instead of a plain black screen they see a smooth branded animation that transitions into the main screen. This replaces the jarring blank-screen flash with a polished first impression.

**Why this priority**: Every app launch goes through this screen, making it the highest-frequency UX touchpoint. Eliminating the black screen flash is the core goal of this feature.

**Independent Test**: Can be fully tested by cold-launching the app and observing that a branded animation plays before the main screen appears, with no black flash visible.

**Acceptance Scenarios**:

1. **Given** the app is launched from a cold start, **When** the OS loads the app, **Then** an animated launch screen with the app logo/branding is displayed immediately — no plain black screen is visible.
2. **Given** the launch animation is playing, **When** the animation completes, **Then** the app transitions smoothly into the main screen (vehicle list) without a hard cut or flash.
3. **Given** a device with reduced-motion accessibility settings enabled, **When** the app is launched, **Then** the animation is skipped or replaced by a simple fade — the branded screen still appears but without motion.

---

### User Story 2 - Fast Launch Perception (Priority: P2)

The launch animation does not make the app feel slower. It fills the time the app needs to initialise, so users perceive a snappy experience rather than waiting on a blank screen.

**Why this priority**: A launch animation that adds perceptible delay would be worse than the black screen. The animation must be a polish improvement, not a performance regression.

**Independent Test**: Can be tested by timing the interval between app open and interactive main screen on a reference device, comparing with and without the animation, and verifying the animation adds no user-perceivable delay.

**Acceptance Scenarios**:

1. **Given** the app launches normally, **When** the animation plays, **Then** the total time from launch gesture to interactive main screen is no greater than without the animation (animation runs concurrently with app initialisation, not before it).
2. **Given** the app initialises faster than the minimum animation duration, **When** the animation ends, **Then** the app transitions to the main screen without holding the user on the launch screen any longer than necessary.

---

### Edge Cases

- What happens on very slow devices where initialisation takes longer than the animation? → The launch screen remains visible until initialisation completes; the animation may loop or hold its final frame rather than transitioning prematurely.
- What happens if the user has reduced motion enabled in accessibility settings? → The animation is suppressed or replaced by a simple crossfade; the branded screen still appears.
- What happens on the very first launch after install (no cached state)? → Behaviour is identical — animation plays as normal.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a branded launch screen immediately on cold start, replacing the plain black screen.
- **FR-002**: The launch screen MUST include an animated transition (e.g. logo reveal, fade, or scale) that plays during app initialisation.
- **FR-003**: The animation MUST transition into the main app screen (vehicle list) upon completion without a hard visual cut.
- **FR-004**: The launch animation MUST run concurrently with app initialisation — it MUST NOT add wall-clock time before the user can interact with the app.
- **FR-005**: The system MUST respect the device's reduced-motion accessibility preference; when enabled, motion is suppressed or minimised.
- **FR-006**: The launch screen MUST display app branding (logo and/or app name) consistent with the app's visual identity.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: No plain black screen is visible during any cold-start launch of the app.
- **SC-002**: The time from launch gesture to interactive main screen is equal to or less than the current baseline (no perceptible delay added).
- **SC-003**: The animation completes and transitions to the main screen within 2 seconds on a reference mid-range device.
- **SC-004**: The feature passes visual inspection on all supported device screen sizes with no layout clipping or distortion.
- **SC-005**: Reduced-motion mode is respected — no motion animation plays when the accessibility setting is active.

## Assumptions

- The app is an iOS SwiftUI application; the launch screen solution uses iOS-native mechanisms.
- The existing app icon/logo asset is used for branding on the launch screen — no new graphic design assets are required beyond what already exists.
- The animation is simple (logo fade-in or scale) rather than a complex multi-step sequence; elaborate cinematic intros are out of scope.
- The feature targets cold starts only; resume-from-background behaviour is unchanged.
- No server-side data is required to display the launch screen.
