# Refactoring Plan — Fuel iOS App

## Scope

This plan addresses code quality, security, architecture, and performance issues discovered across 56 Swift files. Changes are grouped by impact and risk. Each item has a specific file target and a concrete change.

---

## P0 — Security (fix before any release)

### S1 · Clear credential State after save
**File**: `Fuel/Views/VolvoSettingsView.swift`
**Issue**: `clientIDInput`, `clientSecretInput`, `vccAPIKeyInput` remain in memory after save.
**Fix**: Zero-out `@State` strings immediately after `KeychainService.save()`. Also clear on `onDisappear`.

### S2 · Never pre-populate credential fields
**File**: `Fuel/Views/VolvoSettingsView.swift`
**Issue**: `loadCredentials()` called in `onAppear` puts Keychain secrets into `@State` strings — visible in memory dumps, state restoration, and iOS accessibility tools.
**Fix**: Remove `loadCredentials()`. Pre-populate only field-by-field when user taps an edit button, clear immediately on save/dismiss. Show masked indicators (`••••••••`) to confirm credentials are saved without loading the actual value.

### S3 · KeychainService return errors
**File**: `Fuel/Services/KeychainService.swift`
**Issue**: `SecItemAdd`/`SecItemDelete` results ignored. Silent Keychain failures leave app in inconsistent state.
**Fix**: Return `@discardableResult Bool` (or `Result<Void, KeychainError>`) from `save()` and `delete()`. Log failures with `os.log`.

### S4 · Token input validation
**File**: `Fuel/Views/VolvoSettingsView.swift`
**Issue**: Arbitrary string accepted as OAuth refresh_token and stored in Keychain without validation.
**Fix**: Validate minimum length (e.g. ≥ 20 chars), character set (alphanumeric + `-_`). Show inline error if invalid before allowing save.

---

## P1 — Architecture (high impact, no behavior change)

### A1 · Extract shared FillUpFormLogic
**Files**: `Fuel/ViewModels/AddFillUpViewModel.swift`, `Fuel/ViewModels/EditFillUpViewModel.swift`
**Issue**: Three methods duplicated verbatim — `onFieldEdited()`, `applyAutoCalculation()`, `fetchVolvoOdometer()`. Any bug fix must be applied twice.
**Fix**: Create `Fuel/ViewModels/FillUpFormLogic.swift` as a struct/class holding shared state (`lastEditedFields`, `isFetchingOdometer`, `odometerFetchError`) and the three methods. Both ViewModels hold an instance and delegate to it.

### A2 · ViewModel initialization — remove onAppear pattern
**Files**: `Fuel/Views/AddFillUpView.swift`, `Fuel/Views/AddCostView.swift`, `Fuel/Views/EditFillUpView.swift`, `Fuel/Views/FillUpListView.swift`, `Fuel/Views/ContentView.swift`
**Issue**: `@State private var viewModel: SomeViewModel?` + nil-check in body + assignment in `onAppear`. Views show `ProgressView()` for one frame, then swap content — causes visual flash and is an anti-pattern.
**Fix**: Use `@State private var viewModel = SomeViewModel(...)` with a custom `init` that accepts `modelContext` via a wrapper, OR use SwiftUI `@StateObject`-equivalent initialization with `State(wrappedValue:)` in the view's `init`. Remove all Optional unwrap paths.

### A3 · Split VehicleSelectionStore
**File**: `Fuel/Services/VehicleSelectionStore.swift`
**Issue**: Business logic (selected vehicle, sort order) mixed with UserDefaults persistence via `didSet` side effects.
**Fix**: Extract persistence into `AppPreferences` (thin UserDefaults wrapper with typed keys). `VehicleSelectionStore` reads initial values from `AppPreferences` once and writes back explicitly. Removes `didSet` side effects.

### A4 · Predicate builders
**Files**: `Fuel/ViewModels/FillUpListViewModel.swift`, `Fuel/ViewModels/AddFillUpViewModel.swift`, `Fuel/ViewModels/EditFillUpViewModel.swift`, `Fuel/ViewModels/SummaryViewModel.swift`
**Issue**: `#Predicate<FillUp> { $0.vehicle?.id == vehicleId }` repeated 10+ times. Any schema change (soft delete, etc.) requires hunting all call sites.
**Fix**: Add `extension FillUp` with static predicate factories: `FillUp.predicate(for vehicle: Vehicle) -> Predicate<FillUp>`. Same for `CostEntry`.

### A5 · Unify UserDefaults access
**Files**: Mix of `@AppStorage` in Views, `UserDefaults.standard` in ViewModels/Services
**Issue**: Two access patterns for same keys — easy to mistype key strings, impossible to mock in tests.
**Fix**: Create `Fuel/Services/AppPreferences.swift` with typed `@AppStorage`-backed properties. ViewModels receive `AppPreferences` via init (dependency injection). Eliminates raw string keys outside this one file.

---

## P2 — Data & Performance

### D1 · Complete photoData → photos migration
**File**: `Fuel/Models/FillUp.swift`
**Issue**: `photoData: Data?` (legacy single-photo) coexists with `photos: [Data]`. `allPhotos` merges both on every access. All photo-related code needs to handle both paths.
**Fix**: Write a lightweight SwiftData migration step (or on-read migration in `allPhotos` getter) that moves `photoData` into `photos[0]` and nils out the old field. After migration, remove `allPhotos` computed var — use `photos` directly everywhere.

### D2 · Cache grouped list data in ViewModel
**File**: `Fuel/Views/FillUpListView.swift`, `Fuel/Views/CostListView.swift`, `Fuel/Services/TabHeaderView.swift`
**Issue**: `groupedByMonth()` called inside `body` — recomputes on every view update.
**Fix**: Move grouping to ViewModel. Compute once per `fillUps` change using `onChange`. Store `var groupedFillUps: [(key: String, values: [FillUp])]` in ViewModel.

### D3 · Batch SwiftData writes during efficiency recalculation
**File**: `Fuel/Services/EfficiencyCalculator.swift`, `Fuel/ViewModels/FillUpListViewModel.swift`
**Issue**: `recalculateAll()` updates each FillUp individually then calls `Persistence.save()` — O(n) separate object mutations.
**Fix**: Accumulate all mutations, then call `Persistence.save()` once. For delete: recalculate only the subset of fill-ups that come after the deleted entry (not the entire history).

### D4 · Cache decoded images
**Files**: `Fuel/Views/FillUpDetailView.swift`, `Fuel/Views/Components/PhotoAttachmentSection.swift`
**Issue**: `UIImage(data:)` called on every render pass for each photo.
**Fix**: Add `@State private var cachedImages: [Data: UIImage] = [:]` in the containing view. Decode once on `onAppear` or when `photos` changes. Use cached value in `body`.

### D5 · Reduce fetch count on delete
**File**: `Fuel/ViewModels/FillUpListViewModel.swift` `deleteFillUp()`
**Issue**: Triggers 3 database reads (delete → fetch-for-recalc → fetch-for-display).
**Fix**: After delete, update in-memory `fillUps` array directly (remove the item). Pass updated in-memory array to `recalculateAll()`. Skip final `fetchFillUps()` call.

---

## P3 — Code Quality

### Q1 · Extract currency conversion to protocol
**Files**: `Fuel/Models/FillUp.swift`, `Fuel/Models/CostEntry.swift`
**Issue**: Identical `costInDefaultCurrency()` and `convertedCost()` in both models.
**Fix**: Define `protocol CurrencyConvertible` with default implementations. Both models conform. Delete duplicated code.

### Q2 · Consolidate odometer validation
**Files**: `Fuel/ViewModels/AddFillUpViewModel.swift`, `Fuel/ViewModels/EditFillUpViewModel.swift`
**Issue**: Similar `validateOdometer()` methods — differ only in whether they check against `vehicle.initialOdometer` (Add) or the next fill-up entry (Edit).
**Fix**: Extract to `OdometerValidator` struct with `validate(reading: Double, context: ValidationContext)` where context carries min/max bounds. Both ViewModels call it with appropriate context.

### Q3 · Move global helpers out of TabHeaderView
**File**: `Fuel/Views/Components/TabHeaderView.swift`
**Issue**: `computedOdometer()`, `guardVehicleSelection()`, `groupedByMonth()` are free functions in a View component file.
**Fix**: `groupedByMonth()` → `Fuel/Extensions/Collection+Grouping.swift`. `computedOdometer()` → `Vehicle` extension. `guardVehicleSelection()` → remove (inline at call sites, it's trivial).

### Q4 · Reduce @State count in VehicleFormView
**File**: `Fuel/Views/VehicleFormView.swift`
**Issue**: 12 `@State` vars, no validation grouping.
**Fix**: `VehicleFormData` already exists as a struct — use `@State private var form = VehicleFormData(from: vehicle)`. Bind fields to `$form.name`, `$form.make`, etc. Remove 11 individual `@State` vars.

### Q5 · Remove Binding side effects
**Files**: `Fuel/Views/AddFillUpView.swift`, `Fuel/Views/EditFillUpView.swift`
**Issue**: `Binding(get:set:)` with `vm.onVehicleChanged()` in the setter — side effects in a Binding setter violate SwiftUI data flow.
**Fix**: Replace with `.onChange(of: vm.selectedVehicle) { vm.onVehicleChanged() }`.

---

## P4 — Error Handling

### E1 · Propagate fetch errors
**All ViewModels** using `(try? modelContext.fetch(descriptor)) ?? []`
**Fix**: Replace with explicit `do/catch`. On catch: set an `@Published var fetchError: String?`, log via `os.log(.error, ...)`, display an inline error banner. Never silently return `[]` without knowing why.

### E2 · Surface Persistence.save() failures
**File**: `Fuel/Services/DataStore.swift` (`Persistence.save()`)
**Issue**: Save result ignored at all call sites.
**Fix**: `Persistence.save()` should throw (or return `Result`). Call sites use `try` or handle explicitly. Show a non-blocking toast/alert on save failure.

### E3 · User-friendly Volvo API errors
**File**: `Fuel/ViewModels/AddFillUpViewModel.swift`, `Fuel/ViewModels/EditFillUpViewModel.swift`
**Issue**: Raw `VolvoAPIError` description (including HTTP body) shown directly in UI.
**Fix**: Add `var userMessage: String` to `VolvoAPIError` with friendly descriptions per case. Keep raw body in `internalDescription` for logging only.

### E4 · Photo load failure placeholder
**File**: `Fuel/Views/FillUpDetailView.swift`
**Issue**: Corrupted photos silently disappear (`if let image = UIImage(data:) { ... }`).
**Fix**: Show `Image(systemName: "photo.badge.exclamationmark")` placeholder when decode fails.

---

## Execution Order

| Phase | Items | Risk |
|---|---|---|
| 1 | S1, S2, S3, S4 | Low — no behavior change, security hardening |
| 2 | A1, Q1, Q2 | Low — pure extraction, logic unchanged |
| 3 | A4, A5, Q3, Q5 | Low — structural, no logic change |
| 4 | D1, D2, D3 | Medium — data migration and caching |
| 5 | A2, A3, Q4 | Medium — ViewModel initialization changes |
| 6 | D4, D5, E1, E2, E3, E4 | Low-Medium — additive error handling |

Items within each phase can be worked in parallel. Do not mix phases — complete all security items before any architectural changes to keep diffs clean and reviewable.

---

## Out of Scope (deferred)

- Localization — separate project
- Analytics/telemetry — separate project
- Unit tests — should be added incrementally as each ViewModel is refactored (A1, A2, A3)
- Offline queue for Volvo API — separate project
