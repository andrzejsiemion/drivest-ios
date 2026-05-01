# Tasks: Multilanguage Support

**Input**: Design documents from `/specs/022-multilanguage-support/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Localisation Infrastructure)

**Purpose**: Create the String Catalog and declare supported localisations. Must complete before any string extraction begins.

- [X] T001 Add `Fuel/Resources/Localizable.xcstrings` file — create the String Catalog with `sourceLanguage = "en"` and empty `strings` dictionary, then register it in `Fuel.xcodeproj/project.pbxproj` under the Fuel target (PBXBuildFile + PBXFileReference + PBXGroup Resources + PBXResourcesBuildPhase)
- [X] T002 Declare Polish localisation in `Fuel.xcodeproj/project.pbxproj` — add `pl` to the `knownRegions` array and to the project's localizations list so Xcode recognises Polish as a supported locale
- [X] T003 Add `CFBundleLocalizations` to `Fuel/Info.plist` — insert `<key>CFBundleLocalizations</key><array><string>en</string><string>pl</string></array>` so iOS per-app language settings shows both options

**Checkpoint**: Build succeeds; `Localizable.xcstrings` appears in the Xcode project navigator under Resources; iOS Settings → Fuel shows a Language option with English and Polish.

---

## Phase 2: Foundational (Pipeline Verification)

**Purpose**: Verify end-to-end localisation pipeline with a small smoke-test batch before extracting all strings.

**⚠️ CRITICAL**: Confirm the pipeline works before extracting all 154+ strings.

- [X] T004 Add 5 smoke-test keys to `Fuel/Resources/Localizable.xcstrings` — add English keys and Polish translations for: `"Settings"` → `"Ustawienia"`, `"Save"` → `"Zapisz"`, `"Cancel"` → `"Anuluj"`, `"Add Fill-Up"` → `"Dodaj tankowanie"`, `"Vehicles"` → `"Pojazdy"`. Verify SwiftUI `Text("Settings")` resolves to `"Ustawienia"` on a Polish-locale simulator.
- [ ] T005 Run on Polish-locale simulator and confirm the 5 smoke-test strings display in Polish — launch on iPhone simulator with language set to Polish, navigate to Settings tab and main nav, verify strings match translations. Fix any catalog format issues before proceeding.

**Checkpoint**: Pipeline confirmed working — all remaining extraction tasks can proceed.

---

## Phase 3: User Story 1 — OS Language Auto-Detection (Priority: P1) 🎯 MVP

**Goal**: Every user-visible string in the app appears in Polish when the device locale is Polish, with English as the fallback for any missing translation.

**Independent Test**: Run the app on a Polish-locale simulator. Navigate through every screen. Zero English strings should appear. All count-dependent strings should use correct Polish plural forms.

### Implementation: Static String Extraction

- [X] T006 [P] [US1] Extract all strings from `Fuel/Views/SettingsView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all `Text()`, `Section()`, `Button()`, `Label()`, `navigationTitle()`, `Toggle()`, `Picker()` call sites (≈18 strings including "Settings", "Manage Vehicles", "Vehicle Order", "Default Currency", "Additional Currencies", "Integrations", "Done", "Edit", "Delete", "Add Category", "Categories", "Language", etc.) and add en+pl entries for each
- [X] T007 [P] [US1] Extract all strings from `Fuel/Views/AddFillUpView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈12 strings including "Add Fill-Up", "Odometer", "Vehicle", "Fuel Type", "Not set", "Price per Unit", "Volume", "Total Cost", "Discount", "Full Tank", "Date", "Note (Optional)", "Add a note...", "Save", "Cancel") and add en+pl entries
- [X] T008 [P] [US1] Extract all strings from `Fuel/Views/EditFillUpView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈10 strings including "Edit Fill-Up", "Vehicle", "Odometer", "Fuel", "Fuel Type", "Price per Unit", "Volume", "Total Cost", "Discount", "Full Tank", "Exchange Rate", "Rate", "Note", "Add a note (optional)", "Save", "Cancel") and add en+pl entries
- [X] T009 [P] [US1] Extract all strings from `Fuel/Views/VolvoSettingsView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈12 strings including connection status messages, button titles "Disconnect", "Save Token", "Paste from Clipboard", field labels, error messages) and add en+pl entries
- [X] T010 [P] [US1] Extract all strings from `Fuel/Views/ToyotaSettingsView.swift` and `Fuel/Views/IntegrationsView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈10 strings including "Sign In", "Email", "Password", "Disconnect", "Signed in as", "Volvo", "Toyota", "Integrations") and add en+pl entries
- [X] T011 [P] [US1] Extract all strings from `Fuel/Views/ImportConfirmationSheet.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈9 strings including import confirmation prompts, strategy labels, button titles) and add en+pl entries
- [X] T012 [P] [US1] Extract all strings from `Fuel/Views/AddCostView.swift`, `Fuel/Views/EditCostView.swift`, and `Fuel/Views/CostDetailView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈14 strings including "Add Cost", "Edit Cost", "Category", "Amount", "Date", "Note", "No categories available.", "Save", "Cancel", "Delete") and add en+pl entries
- [X] T013 [P] [US1] Extract all strings from `Fuel/Views/CostListView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (section headers, empty-state messages, button titles, navigation titles) and add en+pl entries
- [X] T014 [P] [US1] Extract all strings from `Fuel/Views/VehicleListView.swift`, `Fuel/Views/VehicleDetailView.swift`, and `Fuel/Views/VehicleFormView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (≈15 strings including "Vehicles", "No Vehicles", "Add your first vehicle to start tracking fuel costs.", "Name", "Brand", "Model", "Year", "Distance Unit", "Fuel Unit", "Efficiency Format", "Save", "Cancel", "Delete") and add en+pl entries
- [X] T015 [P] [US1] Extract all strings from `Fuel/Views/FillUpListView.swift`, `Fuel/Views/FillUpDetailView.swift`, and `Fuel/Views/SummaryView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (fill-up history labels, statistics labels, empty states, date section headers) and add en+pl entries
- [X] T016 [P] [US1] Extract all strings from `Fuel/Views/ContentView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit tab bar labels and any other static string literals (e.g., "Vehicles", "Fill-Ups", "Costs", "Statistics", "Settings") and add en+pl entries
- [X] T017 [P] [US1] Extract all strings from all files in `Fuel/Views/Components/` into `Fuel/Resources/Localizable.xcstrings` — audit `EmptyStateView.swift`, `EfficiencyBadge.swift`, `FuelUnitPicker.swift`, `VehiclePickerCard.swift`, `TabHeaderView.swift`, `ReceiptScannerView.swift`, `FillUpScanButton.swift` for all static string literals and add en+pl entries
- [X] T018 [P] [US1] Extract all strings from `Fuel/Views/CameraPickerView.swift`, `Fuel/Views/PhotoAttachmentSection.swift`, `Fuel/Views/FileAttachmentSection.swift`, and `Fuel/Views/DocumentPickerView.swift` into `Fuel/Resources/Localizable.xcstrings` — audit all static string literals (camera permission prompts, attachment labels, picker titles) and add en+pl entries

### Implementation: Interpolated & Computed Strings

- [X] T019 [US1] Audit and convert all interpolated string literals across all view files to use localised format strings in `Fuel/Resources/Localizable.xcstrings` — identify every `Text(String(format: "...", value))` and `Text("≈ \(value) \(symbol)")` pattern; replace with `Text(String(localized: "key \(value)"))` and add the format key with Polish translation to the catalog. Key cases: efficiency format strings in `SummaryView.swift` and `FillUpDetailView.swift`, approximate cost string in `AddFillUpView.swift`, odometer-with-unit strings in `AddFillUpView.swift` and `EditFillUpView.swift`

### Implementation: Plural Rules

- [X] T020 [US1] Identify all count-dependent string call sites across the codebase — search all view and viewModel files for string patterns containing a numeric count variable (e.g., "X vehicles", "X fill-ups", "X photos", character count indicators). Document each found instance with file path and line number.
- [X] T021 [US1] Add plural rule entries to `Fuel/Resources/Localizable.xcstrings` for each count-dependent string found in T020 — use the String Catalog's `variations.plural` structure to define `one`, `few`, and `other` forms for Polish (e.g., "1 pojazd", "2 pojazdy", "5 pojazdów"). Update the call sites in view files to use `String(localized:)` with the count argument so the plural form is selected automatically.

### Implementation: Accessibility Labels

- [X] T022 [US1] Audit all `.accessibilityLabel()`, `.accessibilityValue()`, and `.accessibilityHint()` call sites across all view files — for each that uses a hardcoded string literal, add the key+Polish translation to `Fuel/Resources/Localizable.xcstrings`. SwiftUI's `LocalizedStringKey` overload handles these automatically; verify each call site passes a string literal (not a computed string).

**Checkpoint**: Run app on Polish-locale simulator. Navigate through all screens. Zero English strings visible. Plural forms display correctly for counts 1, 2, 5, 11, 21, 22.

---

## Phase 4: User Story 2 — Manual Language Override in Settings (Priority: P2)

**Goal**: User taps "Change Language" in Fuel's Settings, is taken to iOS Settings, and upon returning sees a prompt offering to restart the app in the new language.

**Independent Test**: Set device to English. Open Fuel → Settings → Change Language → iOS Settings opens. Change to Polish. Return to Fuel. Prompt appears. Tap Restart. App relaunches in Polish.

### Implementation: Settings UI

- [X] T023 [US2] Add a "Language" section to `Fuel/Views/SettingsView.swift` — insert a new `Section` (localised key: `"Language"`) containing a `Button` labelled `"Change Language"` (localised). The button action opens `UIApplication.openSettingsURLString` via `UIApplication.shared.open(url)`. Display the current active language name (e.g., "English", "Polski") as secondary text using `Locale.current.localizedString(forLanguageCode:)`. Add the section's string keys to `Fuel/Resources/Localizable.xcstrings`.

### Implementation: Language-Change Detection & Restart Prompt

- [X] T024 [US2] Add locale-change detection to `Fuel/FuelApp.swift` — store the active language code at app launch using `@State` or `@AppStorage("lastActiveLanguageCode")`. Subscribe to `UIApplication.didBecomeActiveNotification` using `.onReceive`. On each foreground event, compare `Locale.current.language.languageCode?.identifier` to the stored value; if different, set a `@State var showLanguageChangedAlert = true` flag.
- [X] T025 [US2] Add the language-changed alert to the root view in `Fuel/FuelApp.swift` — when `showLanguageChangedAlert` is true, present an `.alert("Language Changed", ...)` with message "Restart the app to apply the new language." and two buttons: "Restart" (calls `exit(0)`) and "Later" (dismisses). Add all alert string keys to `Fuel/Resources/Localizable.xcstrings` with Polish translations.
- [X] T026 [US2] Add `"lastActiveLanguageCode"` update logic to `Fuel/FuelApp.swift` — after displaying or dismissing the alert, update the stored language code to the current value so the alert does not reappear on subsequent foreground events unless the language changes again.

**Checkpoint**: Full manual override flow works end-to-end. Restart prompt appears exactly once per language change. Stored preference survives app relaunch.

---

## Phase 5: User Story 3 — Future Language Extensibility (Priority: P3)

**Goal**: Verify and document that adding a third language requires only translation file changes — no Swift source changes.

**Independent Test**: Add a stub German (`de`) translation for 5 keys to `Localizable.xcstrings`, register `de` in the project, run on a German-locale simulator, and confirm the 5 German strings appear with zero Swift code changes.

### Implementation: Extensibility Verification

- [ ] T027 [US3] Add German (`de`) as a temporary stub locale to verify extensibility — add `de` to `CFBundleLocalizations` in `Fuel/Info.plist` and to `knownRegions` in `Fuel.xcodeproj/project.pbxproj`, add 5 German translation entries to `Fuel/Resources/Localizable.xcstrings` (e.g., "Settings" → "Einstellungen"), run on a German-locale simulator and confirm the strings appear, then remove the `de` locale registration (keep the German entries in the catalog as a demonstration — they simply won't activate without a registered locale).
- [ ] T028 [US3] Update `specs/022-multilanguage-support/quickstart.md` — replace placeholder steps with the verified exact procedure: (1) add locale to `CFBundleLocalizations` in Info.plist, (2) add locale to `knownRegions` in project.pbxproj, (3) add translations to `Localizable.xcstrings`. Confirm the guide matches the T027 experience exactly.

**Checkpoint**: Extensibility verified. Any future language can be added by following the quickstart guide with zero Swift source changes.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gate, layout verification, and key-coverage enforcement across all stories.

- [X] T029 [P] Create `FuelTests/LocalisationTests.swift` — write three unit tests: (1) key-coverage test asserting every key in the English catalog has a non-empty Polish entry; (2) no-orphan-key test asserting catalog keys appear as string literals in the source (via a grep of the source directory); (3) plural-coverage test asserting that count-dependent keys define `one`, `few`, and `other` plural variants for Polish.
- [ ] T030 [P] Verify all localised screens on iPhone SE (small) simulator in Polish — check for text truncation, layout overflow, or clipped labels caused by longer Polish strings. Fix any layout issues found (use `.minimumScaleFactor`, multi-line `Text`, or adjusted padding) across affected view files.
- [ ] T031 Verify VoiceOver navigation in Polish — enable VoiceOver on a Polish-locale simulator and navigate through the primary flows (Add Fill-Up, Vehicle List, Settings). Confirm all VoiceOver announcements are in Polish and grammatically correct.
- [X] T032 Remove the T004 smoke-test entries from `Fuel/Resources/Localizable.xcstrings` if they were added as standalone placeholders — confirm the production string entries (added in T006 onwards) already cover "Settings", "Save", "Cancel", "Add Fill-Up", "Vehicles" so there are no duplicate keys in the catalog.

**Checkpoint**: All unit tests pass. No layout regressions on SE. VoiceOver speaks Polish. Catalog has no duplicates.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion
- **Phase 3 (US1)**: Depends on Phase 2 — T006–T018 can all run in parallel after T005; T019–T022 depend on T006–T018 being done
- **Phase 4 (US2)**: Depends on Phase 2 only — can overlap with Phase 3 since it touches different files
- **Phase 5 (US3)**: Depends on Phase 1 only — can run after Phase 2 in parallel with Phase 3/4
- **Phase 6 (Polish)**: Depends on Phases 3, 4, and 5 being complete

### Within Phase 3

- T006–T018: All parallel (each targets different files)
- T019: Depends on T006–T018 (needs to know which interpolated strings exist after static extraction)
- T020–T021: Can run parallel to T019 (different concern — plural rules)
- T022: Can run parallel to T019 and T020 (accessibility labels)

### Parallel Opportunities

- T006 through T018: All 13 extraction tasks are fully independent — each edits a different set of source files
- T023 (Settings UI) and T024–T026 (detection logic) are independent and can run in parallel
- T029 and T030 are independent and can run in parallel in Phase 6

---

## Parallel Example: Phase 3 String Extraction

```
Parallel batch (all independent — different files):
  T006: SettingsView.swift strings
  T007: AddFillUpView.swift strings
  T008: EditFillUpView.swift strings
  T009: VolvoSettingsView.swift strings
  T010: ToyotaSettingsView + IntegrationsView strings
  T011: ImportConfirmationSheet.swift strings
  T012: Cost views strings
  T013: CostListView.swift strings
  T014: Vehicle views strings
  T015: FillUp list/detail + SummaryView strings
  T016: ContentView.swift strings
  T017: Components/ strings
  T018: Camera/photo views strings

Then sequentially (depends on extraction being complete):
  T019: Interpolated strings audit + conversion
  T020 + T021: Plural rules (parallel with T019)
  T022: Accessibility labels audit (parallel with T019)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Pipeline verification (T004–T005)
3. Complete Phase 3: All string extraction (T006–T022)
4. **STOP and VALIDATE**: Polish-locale simulator shows zero English strings
5. Ship US1 — OS language detection now works for all Polish speakers

### Incremental Delivery

1. Phase 1 + 2 → Localisation infrastructure ready
2. Phase 3 (US1) → Polish-locale users get full native experience (MVP)
3. Phase 4 (US2) → Bilingual users can override language via Settings
4. Phase 5 (US3) → Extensibility confirmed and documented
5. Phase 6 → Quality gate passed; feature complete

---

## Notes

- [P] tasks = different files, no conflicting edits — safe to run concurrently
- All catalog edits go to the single file `Fuel/Resources/Localizable.xcstrings`; when running extraction tasks in parallel, merge catalog additions carefully to avoid key collisions
- SwiftUI `Text("literal")` call sites require **no Swift code change** — only add the key to the catalog
- Only `String(format:...)` and interpolated strings (T019) and plural strings (T021) require Swift code changes at call sites
- `exit(0)` for the restart mechanism is acceptable for iOS apps — it is the standard approach used by Apple's own Settings app language switch
- Commit after each phase checkpoint
