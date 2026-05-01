# Feature Specification: Multilanguage Support

**Feature Branch**: `022-multilanguage-support`
**Created**: 2026-04-24
**Status**: Draft
**Input**: User description: "Application should be multilanguage - firstly we are going to add polish next to english but solution should keep space for another languages in future. By default it should use language set by operating system but give user also possibility to choose different option if needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - OS Language Auto-Detection (Priority: P1)

A user who has their device set to Polish opens the app for the first time. All UI text — labels, buttons, navigation titles, messages, and placeholders — appears in Polish without any manual configuration.

**Why this priority**: This is the baseline behaviour expected by native speakers. A correct default eliminates friction for the majority of users in a supported locale.

**Independent Test**: Launch the app on a device/simulator with system language set to Polish and verify all visible strings are in Polish.

**Acceptance Scenarios**:

1. **Given** the device language is set to Polish, **When** the app is launched, **Then** all UI strings are displayed in Polish.
2. **Given** the device language is set to English (or any unsupported language), **When** the app is launched, **Then** all UI strings are displayed in English (the fallback language).
3. **Given** the device language is set to a language that is partially supported, **When** the app is launched, **Then** missing strings fall back to English rather than showing keys or blank text.

---

### User Story 2 - Manual Language Override in Settings (Priority: P2)

A bilingual user whose device is set to English wants to use the app in Polish. They open Settings, find a Language option, select Polish, and the app immediately switches all UI text to Polish.

**Why this priority**: Supports users whose device language differs from their preferred app language — a common scenario for bilingual users or shared devices.

**Independent Test**: Change the language setting inside the app and confirm all screens update to the chosen language without relaunching the device.

**Acceptance Scenarios**:

1. **Given** the user is in Settings, **When** they tap "Change Language", **Then** they are taken to iOS Settings for the app; upon returning to Fuel, a prompt appears: "Language changed — tap Restart to apply" with a Restart button that relaunches the app.
2. **Given** the user previously selected Polish manually, **When** they relaunch the app, **Then** Polish is still the active language.
3. **Given** the user selected a manual language override, **When** they choose "Use Device Language", **Then** the app reverts to following the OS locale.

---

### User Story 3 - Adding a New Language in the Future (Priority: P3)

A developer or translator wants to add a third language (e.g., German) to the app. The architecture should allow adding new translations without changing application logic — only new string resource files are needed.

**Why this priority**: Ensuring extensibility now prevents technical debt. New languages should be addable purely through content, not code changes.

**Independent Test**: Add a stub German translation file; verify the app correctly displays German strings for a German device without any logic changes.

**Acceptance Scenarios**:

1. **Given** a new language translation file is added to the project, **When** the app runs on a device with that language set, **Then** the new language is displayed correctly.
2. **Given** a translation file is incomplete (some strings missing), **When** those strings are needed, **Then** the app falls back gracefully to English.

---

### Edge Cases

- What happens when a new OS language update introduces a locale variant (e.g., `pl-PL` vs `pl`)? The app should match the base language code.
- What if all strings in a particular screen are not yet translated? Each untranslated string should individually fall back to English, not cause a crash or display a key.
- How should count-dependent strings behave with edge-case quantities (0, negative, very large numbers)? The app should use the "many" plural form for 0 and any quantity not matching the one/few rules.
- What happens when the user changes the language setting and immediately navigates to another screen? The transition should be seamless.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display all user-facing strings in the language matching the device's OS locale when a supported translation exists.
- **FR-002**: The app MUST fall back to English for any string not available in the active language.
- **FR-003**: The app MUST provide a Language setting in the app's Settings screen, allowing users to choose from: Device Default, English, Polish.
- **FR-004**: The chosen language preference MUST persist across app launches.
- **FR-005**: When the user returns to the app after changing the language in iOS Settings, the app MUST display a prompt: "Language changed — tap Restart to apply" with a Restart button. Tapping Restart terminates and relaunches the app in the new language.
- **FR-006**: The translation system MUST be structured so that adding a new language requires only adding a new string resource file, with no changes to application logic.
- **FR-007**: All user-visible strings — including labels, button titles, navigation titles, error messages, placeholders, and accessibility labels — MUST be covered by the localisation system.
- **FR-008**: The Settings screen MUST clearly indicate the currently active language.
- **FR-009**: The localisation system MUST support plural rules for count-dependent strings. Polish plural forms (one / few / many) MUST be correctly applied — for example "1 pojazd", "2 pojazdy", "5 pojazdów". The platform's built-in plural rules mechanism (stringsdict or String Catalog plural variants) MUST be used; hardcoded workarounds are not permitted.

### Key Entities

- **Language Preference**: The user-selected language override (Device Default, or a specific locale). Persists in app storage.
- **Translation Bundle**: A per-language set of string mappings covering all user-visible text in the app. One bundle per supported language.
- **Supported Locale**: A locale code (e.g., `en`, `pl`) for which a complete or partial translation bundle exists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of user-visible strings in the app are covered by the localisation system — no hardcoded text remains in any supported screen.
- **SC-002**: After tapping Restart in the language-change prompt, the app relaunches in the new language within 3 seconds.
- **SC-003**: On a Polish-locale device, a new user encounters zero English strings on **any screen** — all screens including integration settings (Volvo, Toyota) must be fully translated before the feature ships.
- **SC-004**: Adding a new language requires changes to translation files only — zero changes to Swift source files outside of registering the new locale.
- **SC-006**: All count-dependent strings display grammatically correct Polish plural forms for quantities 1, 2, 5, 11, 21, and 22 (covers all Polish plural rule cases).
- **SC-005**: All previously English-only strings fall back correctly to English when a partial translation is active — no missing-key placeholders visible to users.

## Clarifications

### Session 2026-04-24

- Q: Which screens must be fully translated for the initial Polish release — all screens or only core flows? → A: All screens fully translated — no English visible on any screen when Polish is active (including integration settings screens such as Volvo and Toyota).
- Q: What should the app do when the user returns from iOS Settings after changing the language? → A: Show a prompt "Language changed — tap Restart to apply" with a Restart button that relaunches the app.
- Q: Does the app display count-dependent strings requiring plural forms (e.g., "3 vehicles", "2 fill-ups")? → A: Yes — plural forms must be handled correctly for Polish using the platform's plural rules system.

## Assumptions

- The initial release supports exactly two languages: English (existing, primary) and Polish (new).
- Device Default means following the iOS system locale; no custom locale-detection logic is needed beyond what the platform already provides.
- Right-to-left (RTL) language support is out of scope for this feature.
- Date, number, and currency formatting already respects the device locale via the existing formatting utilities and does not require changes as part of this feature.
- The app currently has no localisation infrastructure — this feature introduces it from scratch.
- Accessibility strings (VoiceOver labels) must be localised alongside regular UI strings.
