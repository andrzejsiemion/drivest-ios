# Implementation Plan: Multilanguage Support

**Branch**: `022-multilanguage-support` | **Date**: 2026-04-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/022-multilanguage-support/spec.md`

---

## Summary

Introduce full localisation infrastructure to the Fuel iOS app, beginning with English (existing) and Polish (new), architected so future languages require only translation file additions. Users get automatic locale detection from the OS and an in-app shortcut to the iOS per-app language setting for manual override.

---

## Technical Context

**Language/Version**: Swift 5.9+, iOS 17.0 minimum deployment target
**Primary Dependencies**: SwiftUI (existing), Xcode String Catalogs (Xcode 15 native feature — no new packages)
**Storage**: OS-managed per-app language preference (iOS Settings); `Localizable.xcstrings` for string bundles
**Testing**: XCTest (unit tests for locale-sensitive logic), XCUITest (UI tests verifying Polish strings appear)
**Target Platform**: iOS 17.0+ (iPhone & iPad)
**Project Type**: Mobile app (SwiftUI/SwiftData, MVVM)
**Performance Goals**: Language switch latency ≤ 1 second (OS-managed, effectively instant)
**Constraints**: Zero third-party dependencies; no custom Bundle swizzling; must work fully offline
**Scale/Scope**: ~154 hardcoded string literals across ~30 view files; 2 languages at launch; extensible to N

---

## Constitution Check

*GATE: Must pass before implementation.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ PASS | Strings extracted to catalog; no logic changes in view files for static strings |
| II. Simple UX | ✅ PASS | In-app shortcut button (one tap) → iOS language setting; no custom modal picker needed |
| III. Responsive Design | ✅ PASS | Localised strings respect Dynamic Type; layout adapts to longer Polish text via SwiftUI flex |
| IV. Minimal Dependencies | ✅ PASS | Uses Apple-native String Catalog and iOS per-app language — zero new packages |
| iOS Platform Constraints | ✅ PASS | iOS 13+ per-app language is available; deployment target is iOS 17 |
| Dev Workflow | ✅ PASS | Feature branch; tests required; accessibility audit applicable |

**No violations.**

---

## Project Structure

### Documentation (this feature)

```text
specs/022-multilanguage-support/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 decisions
├── data-model.md        # String catalog structure and entities
├── quickstart.md        # Translator and developer guide
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
Fuel/
├── Resources/
│   └── Localizable.xcstrings        # NEW — String Catalog (en + pl)
├── Info.plist                        # ADD CFBundleLocalizations (en, pl)
└── Views/
    └── SettingsView.swift            # ADD Language section with iOS Settings deep link

FuelTests/
└── LocalisationTests.swift          # NEW — verifies key coverage and fallback behaviour
```

---

## Implementation Phases

### Phase 1: Infrastructure Setup

**Goal**: Create the String Catalog, declare supported localisations, verify the pipeline end-to-end with a small set of strings.

**Steps**:

1. **Add `Localizable.xcstrings` to the Xcode project**
   - Location: `Fuel/Resources/Localizable.xcstrings`
   - Add to the Fuel target in `project.pbxproj`
   - Set source language to `en`

2. **Declare Polish localisation in project settings**
   - In Xcode: Project → Fuel target → Localizations → add `pl (Polish)`
   - Add `CFBundleLocalizations` to `Info.plist`:
     ```xml
     <key>CFBundleLocalizations</key>
     <array>
         <string>en</string>
         <string>pl</string>
     </array>
     ```

3. **Smoke test**: Add 3–5 representative keys (e.g., "Settings", "Save", "Cancel") to the catalog with Polish translations. Run on a Polish-locale simulator and verify strings appear in Polish.

---

### Phase 2: Full String Extraction — Static Strings

**Goal**: Extract all static string literals from all view files into the String Catalog.

**Approach**: SwiftUI `Text("literal")`, `Button("title")`, `navigationTitle("title")`, `Section("header")`, `Label("title", systemImage:)` accept `LocalizedStringKey` natively — **no Swift code changes required** at these call sites. Only the catalog entries need to be added.

**Files to process** (in order of string count):

| File | Approx. strings | Notes |
|------|----------------|-------|
| SettingsView.swift | 18 | Highest priority — main hub |
| AddFillUpView.swift | 12 | Core user flow |
| VolvoSettingsView.swift | 12 | Integration |
| EditFillUpView.swift | ~10 | Core user flow |
| ImportConfirmationSheet.swift | 9 | Import/export flow |
| AddCostView.swift | ~8 | Cost tracking |
| ToyotaSettingsView.swift | 7 | Integration |
| EditCostView.swift | 6 | Cost tracking |
| VehicleListView.swift | 5 | Vehicle management |
| ContentView.swift | ~4 | Tab bar labels |
| All remaining views | ~63 | Remainder |

**For each file**: identify all string literals in `Text()`, `Button()`, `Label()`, `Section()`, `navigationTitle()`, `TextField` placeholder, `EmptyStateView` messages, toolbar button titles → add key + Polish translation to catalog.

---

### Phase 3: Interpolated & Computed Strings

**Goal**: Handle string literals that contain runtime values (cannot be expressed as a static `LocalizedStringKey`).

**Known examples** (from codebase exploration):

```swift
// Efficiency formatting
Text(String(format: "%.1f L/100km", value))
// → String(localized: "efficiency.format \(value, format: .number.precision(.fractionLength(1)))")

// Currency approximate conversion
Text("≈ \(String(format: "%.2f", converted)) \(defaultSymbol)")
// → Text("cost.converted.approximate \(converted, format: .number) \(defaultSymbol)")

// Odometer with unit
Text(String(format: "%.0f km", currentOdometer))
// → localised format with unit

// Character count
Text("\(vm.noteText.count)/200")
// → static pattern, no translation needed (numerals are universal)
```

**Approach**: Use `String(localized:)` with format specifiers where substitution is needed, or keep numeric-only format strings as-is (numerals are language-neutral).

---

### Phase 4: Language Setting UI in Settings Screen

**Goal**: Add a visible "Language" entry in `SettingsView` that deep-links to the iOS per-app language settings page.

**Implementation**:

```swift
// In SettingsView — new section
Section("Language") {
    Button {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    } label: {
        HStack {
            Text("App Language")
            Spacer()
            Text(Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "en") ?? "")
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
    .foregroundStyle(.primary)
}
```

This shows the current active language name and opens the app's iOS Settings page. iOS 13+ automatically shows "Language & Region → Language" for apps that declare multiple localizations.

---

### Phase 5: Tests

**Goal**: Verify coverage and fallback behaviour.

**Unit tests** (`FuelTests/LocalisationTests.swift`):

1. **Key coverage test**: For every key in the English catalog, assert a Polish entry exists and is non-empty.
2. **Fallback test**: For any key where the Polish value is empty or missing, assert the English value is returned (not a key token).
3. **No orphan keys**: Assert all keys in the catalog correspond to a string literal actually used in the app (prevents stale entries).

**UI tests**:
- Run on a Polish-locale simulator and assert that primary screen titles appear in Polish on: vehicle list, fill-up list, settings, statistics.

---

## Complexity Tracking

No constitution violations. No complexity justification required.

---

## Key Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| SwiftUI Text with interpolation silently not localising | Medium | Phase 3 audit of all non-static string call sites |
| Polish strings too long for fixed-width layouts | Medium | Verify on iPhone SE simulator; use `.minimumScaleFactor` or multi-line where needed |
| Missing strings in catalog not caught before release | Low | Phase 5 key-coverage unit test catches gaps at test time |
| iOS per-app language setting not visible (language not declared) | Low | Covered by Phase 1 step 2 — `CFBundleLocalizations` declaration |
