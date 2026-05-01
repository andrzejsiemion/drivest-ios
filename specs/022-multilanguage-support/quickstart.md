# Quickstart: Multilanguage Support

**Feature**: 022-multilanguage-support
**Date**: 2026-04-24

---

## For Translators: Adding a New String

1. Open `Fuel/Resources/Localizable.xcstrings` in Xcode.
2. Find the English key (or search by text).
3. Click the Polish (or target language) row and enter the translation.
4. Save. Done — no code changes needed.

## For Developers: Adding a New User-Visible String

### SwiftUI static strings (the common case)
Use string literals as-is — SwiftUI resolves them via `LocalizedStringKey` automatically:
```swift
Text("Add Fill-Up")          // ✅ automatically localised
Button("Save") { ... }       // ✅ automatically localised
.navigationTitle("Settings") // ✅ automatically localised
Section("Fuel") { ... }      // ✅ automatically localised
```
Then add the English key + Polish translation to `Localizable.xcstrings`.

### Interpolated/computed strings
```swift
// Use String(localized:) with a format specifier in the catalog
Text(String(localized: "total.cost.approximate \(formattedValue) \(symbol)"))
```
Or use a SwiftUI string interpolation format:
```swift
Text("≈ \(formattedValue) \(symbol)")  // Add format key to catalog
```

### Accessibility labels
```swift
.accessibilityLabel("Vehicle photo")   // ✅ localised automatically via LocalizedStringKey overload
```

## For Developers: Adding a New Language

1. In Xcode project settings → Fuel target → Localizations, click `+` and add the new locale.
2. Xcode will prompt to create entries in `Localizable.xcstrings` for the new locale.
3. Provide translations. No Swift code changes required.
4. Update `CFBundleLocalizations` in `Info.plist` to include the new locale code.

## For Users: Changing the App Language

1. Open iOS Settings.
2. Scroll to Fuel (or use the search).
3. Tap Language & Region → Language.
4. Select the desired language.
5. Confirm — the app relaunches in the new language.

*A shortcut button in Fuel's Settings screen opens this page directly.*
