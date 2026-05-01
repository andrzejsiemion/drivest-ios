# Data Model: Multilanguage Support

**Feature**: 022-multilanguage-support
**Date**: 2026-04-24

---

## Entities

### LocalisationKey
A string identifier that maps to a user-visible text in each supported language.

- **identifier**: `String` — the key used in source code (e.g., `"settings.title"` or the English text itself when using SwiftUI's implicit key approach)
- **defaultValue (en)**: `String` — English fallback text
- **translations**: `[locale: String]` — one entry per supported language (e.g., `"pl"` → Polish translation)

*Note: This entity lives entirely within `Localizable.xcstrings`. It has no Swift model class.*

---

### SupportedLocale
A language the app has a translation bundle for.

- **code**: `String` — BCP 47 language tag (e.g., `"en"`, `"pl"`)
- **displayName**: `String` — Human-readable name shown in iOS Settings (managed by the OS)

*This is not a persisted model; it is derived from the project's declared localisations.*

---

### LanguagePreference
The user's explicit language override, if any.

- **Stored by**: iOS operating system (per-app language in Settings.app)
- **Access in code**: `Locale.current` / `Bundle.main.preferredLocalizations.first`
- **Override mechanism**: User sets via iOS Settings → Fuel → Language & Region → Language
- **Persistence**: OS-managed, survives app restarts and updates

*No custom AppStorage key or Swift model is required. The OS owns this preference.*

---

## State Transitions

```
[OS locale active] ──user opens iOS Settings──> [Language & Region screen]
                                                         │
                                               [selects a language]
                                                         │
                                               [returns to Fuel app]
                                                         │
                                               [app relaunches locale]
                                                         │
                                               [new language active]
```

---

## String Catalog Structure

File: `Fuel/Resources/Localizable.xcstrings`

Format (JSON inside .xcstrings):
```json
{
  "sourceLanguage": "en",
  "strings": {
    "settings.title": {
      "localizations": {
        "en": { "stringUnit": { "state": "translated", "value": "Settings" } },
        "pl": { "stringUnit": { "state": "translated", "value": "Ustawienia" } }
      }
    },
    ...
  },
  "version": "1.0"
}
```

*SwiftUI implicit key approach*: When using `Text("Settings")`, Xcode uses the English string itself as the key. The catalog entry for key `"Settings"` maps to the Polish translation `"Ustawienia"`. This requires no code changes at existing Text() call sites.

---

## Info.plist Changes

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>pl</string>
</array>
```

This declares supported languages so iOS per-app language settings shows the correct options.
