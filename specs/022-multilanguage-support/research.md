# Research: Multilanguage Support

**Feature**: 022-multilanguage-support
**Date**: 2026-04-24

---

## Decision 1: Localisation File Format — String Catalog (.xcstrings)

**Decision**: Use Xcode String Catalogs (`.xcstrings`) introduced in Xcode 15.

**Rationale**:
- A single JSON file holds all languages; no per-language `.lproj` directories to maintain.
- Xcode automatically detects untranslated strings, shows translation progress, and marks stale keys.
- SwiftUI's `Text("literal")` automatically resolves to a `LocalizedStringKey`, so the majority of existing string literals become localizable without code changes — only the catalog entry is required.
- String Catalogs are the Apple-recommended format going forward and receive first-class tooling support.

**Alternatives considered**:
- `.strings` files per language (classic approach) — requires one file per language, more fragile, no built-in staleness tracking.
- Gettext / third-party i18n library — violates Constitution Principle IV (Minimal Dependencies); Apple's native stack is sufficient.

---

## Decision 2: In-App Language Override Mechanism — iOS Per-App Language Setting

**Decision**: Rely on iOS 13+ per-app language settings (iOS Settings → Fuel → Language & Region → Language). Expose a "Change Language" button in the Fuel Settings screen that deep-links to the system settings page for the app.

**Rationale**:
- iOS 13+ natively supports per-app language selection entirely within the OS settings. No custom logic required.
- When the user returns to the app after changing the language, iOS relaunches or re-initialises the app's locale automatically.
- Zero additional code for the actual language-switching mechanism; only a `UIApplication.openSettingsURLString` deep link is needed.
- Satisfies spec FR-003 ("provide a Language setting in the app's Settings screen") and FR-005 ("takes effect without requiring a device restart" — returning to the app from iOS Settings reloads the locale).
- Satisfies spec FR-004 ("persists across launches") — the OS persists the choice.
- Perfectly aligned with Constitution Principle IV: no third-party dependency, no custom bundle swizzling.

**Alternatives considered**:
- Custom in-app language switcher with `Bundle` swizzling — requires restarting the SwiftUI hierarchy or using complex workarounds; fragile and introduces technical debt.
- `UserDefaults.standard.set(["pl"], forKey: "AppleLanguages")` + app restart — deprecated pattern, unreliable on modern iOS, requires forcing a termination which is not acceptable UX.
- Manual `Environment(\.locale)` injection — doesn't affect `NSLocalizedString` paths; only affects date/number formatters, not text strings.

---

## Decision 3: String Extraction Strategy — SwiftUI Auto-Localisation First

**Decision**: Leverage SwiftUI's built-in `LocalizedStringKey` behaviour for the vast majority of strings, and use explicit `String(localized:)` only for computed/interpolated strings that cannot be expressed as a static key.

**Rationale**:
- `Text("Add Fill-Up")`, `Button("Save") {}`, `navigationTitle("Settings")`, `Section("Fuel") {}`, `Label("Delete", systemImage: "trash")` all accept `LocalizedStringKey` natively. Adding these keys to the String Catalog is sufficient — no code changes required for these call sites.
- Only dynamic interpolated strings (e.g., `Text("≈ \(value) \(symbol)")`) need special handling using stringsdict-style format specifiers or explicit `String(localized:, substitutions:)`.
- Approximately 154 hardcoded string literals exist; the majority are static and will be covered by catalog entries alone.

**Alternatives considered**:
- Wrapping every string in `NSLocalizedString()` — redundant for SwiftUI views where `LocalizedStringKey` already does the work.
- A custom localisation wrapper function — unnecessary complexity.

---

## Decision 4: Supported Languages at Launch

**Decision**: English (en) — primary/fallback; Polish (pl) — initial additional language.

**Rationale**: As specified. English is the development language and the fallback for any missing translations. The architecture (String Catalog) allows any future language to be added purely by adding entries to the catalog — no Swift code changes.

**Adding a future language requires**:
1. Add the locale to the project's localisation list in Xcode project settings.
2. Provide translations in `Localizable.xcstrings`.
3. That's all — no logic changes.

---

## Decision 5: Accessibility Labels

**Decision**: All `accessibilityLabel(_:)` and `accessibilityValue(_:)` call sites that use string literals must be covered by the same String Catalog.

**Rationale**: Spec FR-007 explicitly includes accessibility labels. SwiftUI accessibility modifiers accept `LocalizedStringKey` directly for string overloads, so they're covered by the same mechanism.

---

## Codebase State Summary

| Dimension | Current State |
|-----------|---------------|
| Localisation files | None — starting from scratch |
| `NSLocalizedString` / `String(localized:)` calls | 0 |
| Hardcoded string literals in Views | ~154 |
| AppStorage language preference key | Does not exist |
| Info.plist `CFBundleLocalizations` | Not set |
| String Catalog (.xcstrings) | Does not exist |
| Settings language UI | Does not exist |
