# Tasks: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Input**: Design documents from `specs/023-ev-energy-snapshot/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ui-contracts.md ✓, quickstart.md ✓

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization — entitlements, Info.plist background task key, ModelContainer update.

- [X] T001 Create `Fuel/Fuel.entitlements` with `com.apple.developer.background-task-scheduler-allowed-identifiers` array containing `"com.fuel.snapshot.fetch"` — then link it in Xcode project settings under Signing & Capabilities → add "Background Modes" capability with "Background fetch" checked (this generates the entitlements file reference in `project.pbxproj`)
- [X] T002 Add `BGTaskSchedulerPermittedIdentifiers` array with string `"com.fuel.snapshot.fetch"` to `Fuel/Info.plist`
- [X] T003 Add `FetchFrequency` enum to `Fuel/Models/FetchFrequency.swift` with cases `daily`, `twiceDaily`, `every6Hours`, `every12Hours`; add `var displayName: String` and `var intervalSeconds: TimeInterval` computed properties; conform to `String`, `CaseIterable`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and Vehicle relationships that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Create `Fuel/Models/EnergySnapshot.swift` — `@Model final class EnergySnapshot` with fields: `id: UUID`, `fetchedAt: Date`, `odometerKm: Double`, `socPercent: Int?`, `source: String`, `vehicle: Vehicle?`, `createdAt: Date`; add `init` setting `id = UUID()`, `createdAt = Date()`
- [X] T005 Create `Fuel/Models/ElectricityBill.swift` — `@Model final class ElectricityBill` with fields: `id: UUID`, `endDate: Date`, `totalKwh: Double`, `totalCost: Double`, `currencyCode: String?`, `distanceKm: Double?`, `efficiencyKwhPer100km: Double?`, `costPerKm: Double?`, `hasSnapshotData: Bool`, `startSnapshotId: UUID?`, `endSnapshotId: UUID?`, `vehicle: Vehicle?`, `createdAt: Date`; add `init` with required fields
- [X] T006 Modify `Fuel/Models/Vehicle.swift` — add `@Relationship(deleteRule: .cascade, inverse: \EnergySnapshot.vehicle) var energySnapshots: [EnergySnapshot]` and `@Relationship(deleteRule: .cascade, inverse: \ElectricityBill.vehicle) var electricityBills: [ElectricityBill]`; add `var isEV: Bool { fuelType == .ev }`; initialize both arrays to `[]` in `Vehicle.init`
- [X] T007 Modify `Fuel/FuelApp.swift` — extend `ModelContainer` initializer to include `EnergySnapshot.self, ElectricityBill.self` in the `for:` argument list

**Checkpoint**: Foundation ready — all models exist, Vehicle has EV computed property and relationships.

---

## Phase 3: User Story 1 — Automated Daily Snapshots (Priority: P1) 🎯 MVP

**Goal**: Background fetch collects odometer + SoC from manufacturer APIs and stores `EnergySnapshot` records for EV vehicles. Snapshots older than 6 months are auto-purged.

**Independent Test**: Enable fetch for an EV vehicle, tap "Fetch Now" in settings (after Phase 6 UI), observe snapshot in history list with odometer value.

### Implementation

- [X] T008 [US1] Add `fetchRechargeStatus(vin: String, accessToken: String) async throws -> (socPercent: Int?, electricRangeKm: Int?)` to `Fuel/Services/VolvoAPIClient.swift` using Energy API base `https://api.volvocars.com/energy/v2/vehicles/{vin}/recharge-status`; parse `data.batteryChargeLevel.value` for SoC; use same `get(url:accessToken:)` private helper
- [X] T009 [US1] Add `fetchSoC(vin: String, accessToken: String) async throws -> Int?` to `Fuel/Services/ToyotaAPIClient.swift`; read `payload.evDetailedStatus.chargeStatus.value` first, fall back to `payload.soc.value`; return `nil` if neither key present; reuse existing telemetry URL and all required headers from `fetchOdometer`
- [X] T010 [US1] Create `Fuel/Services/SnapshotFetchService.swift` — `@Observable final class SnapshotFetchService` with `static let shared`, `var isFetching: Bool`, `var lastError: String?`; implement `func fetchAll(context: ModelContext) async` iterating all EV vehicles and calling `fetch(vehicle:context:)` for each; implement `func fetch(vehicle: Vehicle, context: ModelContext) async throws` that refreshes token (Volvo or Toyota based on `vehicle.make?.lowercased()`), calls odometer + SoC APIs, inserts new `EnergySnapshot` into context, saves, resets `snapshotFailures_<vehicle.id>` in UserDefaults to 0 on success; increments failure counter and checks ≥3 on failure
- [X] T011 [US1] Create `Fuel/Services/SnapshotPurgeService.swift` — `enum SnapshotPurgeService` with `static func purgeExpired(context: ModelContext)` that fetches all `EnergySnapshot` records where `fetchedAt < Calendar.current.date(byAdding: .month, value: -6, to: Date())!` and deletes them, then saves context
- [X] T012 [US1] Create `Fuel/Services/BackgroundTaskManager.swift` — `final class BackgroundTaskManager` with `static func register()` that calls `BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.fuel.snapshot.fetch", using: nil)` and handles the task by calling `SnapshotFetchService.shared.fetchAll(context:)` then `scheduleNextFetch()`; `static func scheduleNextFetch()` that reads UserDefaults schedule settings and submits a `BGAppRefreshTaskRequest` with the computed next earliest begin date; import `BackgroundTasks`
- [X] T013 [US1] Modify `Fuel/FuelApp.swift` — call `BackgroundTaskManager.register()` as first statement in `init()`; call `SnapshotPurgeService.purgeExpired(context: container.mainContext)` inside the `.active` scenePhase handler; call `BackgroundTaskManager.scheduleNextFetch()` in the `.active` handler when `snapshotFetchEnabled` is true
- [X] T014 [P] [US1] Create `Fuel/ViewModels/SnapshotHistoryViewModel.swift` — `@Observable final class SnapshotHistoryViewModel` with `var sections: [(monthLabel: String, snapshots: [EnergySnapshot])]`, `var isLoading: Bool`, `var errorMessage: String?`; implement `func load(for vehicle: Vehicle)` fetching and grouping snapshots by month descending using `MonthGrouper` or manual grouping; implement `func deleteSnapshot(_ snapshot: EnergySnapshot, context: ModelContext)`; implement `func triggerManualFetch(for vehicle: Vehicle, context: ModelContext) async` calling `SnapshotFetchService.shared.fetch(vehicle:context:)`
- [X] T015 [US1] Create `Fuel/Views/EVSnapshotHistoryView.swift` — `struct EVSnapshotHistoryView: View` with `let vehicle: Vehicle` and `@Environment(\.modelContext) private var modelContext`; `@State private var viewModel = SnapshotHistoryViewModel()`; show grouped list of snapshots with date, odometer (formatted with vehicle's distance unit), and SoC% (or "—" if nil); swipe-to-delete calling `viewModel.deleteSnapshot`; empty state with message "No snapshots yet"; call `viewModel.load(for: vehicle)` in `onAppear`
- [X] T016 [US1] Modify `Fuel/Views/SettingsView.swift` — add "EV Background Sync" section (visible only when `@AppStorage("snapshotFetchEnabled")` or always visible for discoverability — show section always, content gated by presence of EV vehicle); add toggle for enabled, `Picker` for `FetchFrequency`, `DatePicker`-style hour/minute pickers for fetch time, last-synced label formatted from `snapshotLastFetchAt`, "Fetch Now" button that calls `Task { await SnapshotFetchService.shared.fetchAll(context: modelContext) }` with a progress indicator; read AppStorage keys defined in research.md

**Checkpoint**: EV vehicle can collect snapshots (via "Fetch Now"), view history, and purge old records.

---

## Phase 4: User Story 2 — Configurable Fetch Schedule (Priority: P2)

**Goal**: User can change fetch frequency and time of day; schedule changes apply immediately to next fetch.

**Independent Test**: Change frequency to "Every 6 hours" and hour to 8; verify `BGAppRefreshTaskRequest.earliestBeginDate` reflects the new schedule on next call to `scheduleNextFetch()`.

### Implementation

- [X] T017 [US2] Extend `Fuel/Services/BackgroundTaskManager.swift` — in `scheduleNextFetch()` read `UserDefaults.standard.string(forKey: "snapshotFetchFrequency")` to determine `FetchFrequency`; compute `earliestBeginDate` as next occurrence of the configured hour/minute (today if time hasn't passed yet, tomorrow if it has); for sub-daily frequencies calculate next slot from current time + interval; submit `BGAppRefreshTaskRequest` with that date
- [X] T018 [US2] Extend `Fuel/Views/SettingsView.swift` EV section (from T016) — ensure `Picker` for frequency uses `FetchFrequency.allCases` with localized display names; add hour stepper (0–23) and minute stepper (0, 15, 30, 45 or free 0–59) with current value shown; `onChange` of any schedule field calls `BackgroundTaskManager.scheduleNextFetch()` so the new schedule takes effect immediately

**Checkpoint**: Changing frequency/time in settings immediately updates when the next background fetch will fire.

---

## Phase 5: User Story 3 — Electricity Bill Reconciliation (Priority: P3)

**Goal**: User enters electricity bills; app calculates kWh/100km and cost/km using stored snapshots.

**Independent Test**: Enter two bills with snapshots bracketing the period; verify calculated efficiency and cost/km appear in bill detail within 2 seconds of saving.

### Implementation

- [X] T019 [US3] Create `Fuel/Services/BillReconciliationService.swift` — `enum BillReconciliationService` with `struct ReconciliationResult { let distanceKm: Double?; let efficiencyKwhPer100km: Double?; let costPerKm: Double?; let hasSnapshotData: Bool; let startSnapshotId: UUID?; let endSnapshotId: UUID? }` and `static func reconcile(_ bill: ElectricityBill, snapshots: [EnergySnapshot], previousBill: ElectricityBill?) -> ReconciliationResult`; implement per data-model.md boundary logic (closest snapshot to each period boundary, 7-day gap check, odometer regression check)
- [X] T020 [US3] Create `Fuel/ViewModels/AddBillViewModel.swift` — `@Observable final class AddBillViewModel` with `var endDate: Date = Date()`, `var totalKwhText: String = ""`, `var totalCostText: String = ""`, `var noteText: String = ""`; `var isValid: Bool { Double(totalKwhText) != nil && (Double(totalCostText) ?? -1) >= 0 }`; `var isSaving: Bool`; implement `func save(for vehicle: Vehicle, context: ModelContext) -> Bool` that creates `ElectricityBill`, finds previous bill for vehicle, fetches snapshots in period, calls `BillReconciliationService.reconcile`, applies result fields to bill, inserts into context, saves
- [X] T021 [US3] Create `Fuel/ViewModels/BillListViewModel.swift` — `@Observable final class BillListViewModel` with `var bills: [ElectricityBill]`, `var isLoading: Bool`; `func load(for vehicle: Vehicle)` fetching and sorting bills by `endDate` descending; `func deleteBill(_ bill: ElectricityBill, context: ModelContext)`
- [X] T022 [US3] Create `Fuel/Views/AddElectricityBillView.swift` — `struct AddElectricityBillView: View` with `let vehicle: Vehicle` and `@Bindable var viewModel: AddBillViewModel`; form with `DatePicker` for end date, `TextField` for kWh (decimal pad), `TextField` for total cost (decimal pad) with currency symbol, optional note field; Save/Cancel toolbar buttons; Save calls `viewModel.save(for: vehicle, context: modelContext)` then dismisses
- [X] T023 [US3] Create `Fuel/Views/ElectricityBillDetailView.swift` — `struct ElectricityBillDetailView: View` with `let bill: ElectricityBill`; show billing period (previous bill endDate — this bill endDate), distance driven (with unit), total kWh from meter, total cost, kWh/100km, cost/km; if `!bill.hasSnapshotData` show "No snapshot data available for this period" warning; if first bill show "Baseline bill — efficiency shown from next bill"
- [X] T024 [US3] Create `Fuel/Views/ElectricityBillListView.swift` — `struct ElectricityBillListView: View` with `let vehicle: Vehicle`; `@State private var viewModel = BillListViewModel()`; list of bills sorted by date descending with period label, kWh, cost, and status badge ("Calculated" / "No data" / "Baseline"); floating `+` FAB to present `AddElectricityBillView`; swipe-to-delete; empty state "No bills yet — add your first electricity bill"; `onAppear` loads `viewModel.load(for: vehicle)`

**Checkpoint**: User can enter bills and see efficiency calculated from snapshot data.

---

## Phase 6: Integration — EV Tab & Failure Alert

**Purpose**: Wire new views into ContentView navigation; add consecutive-failure banner.

- [X] T025 Modify `Fuel/Views/ContentView.swift` — add a fourth tab "EV" (systemImage: `"bolt.car"`) containing a `TabView` or `NavigationStack` with two sections: "Snapshots" → `EVSnapshotHistoryView(vehicle: selectedVehicle)` and "Bills" → `ElectricityBillListView(vehicle: selectedVehicle)`; tab visible only when `selectedVehicle?.isEV == true`
- [X] T026 Modify `Fuel/Views/ContentView.swift` — add persistent banner overlay that reads `UserDefaults.standard.integer(forKey: "snapshotFailures_\(vehicle.id)")` for the selected EV vehicle; if value ≥ 3 show a dismissable yellow/orange banner "Unable to sync [Make] — reconnect in Integrations" with a `NavigationLink` or sheet to `IntegrationsView`; re-check on `onAppear` and when `scenePhase` becomes active

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Backup support, localisation strings, and code completeness.

- [X] T027 [P] Modify `Fuel/Services/BackupCodable.swift` — add `struct EnergySnapshotBackup: Codable` (id, fetchedAt, odometerKm, socPercent, source, createdAt) and `struct ElectricityBillBackup: Codable` (id, endDate, totalKwh, totalCost, currencyCode, distanceKm, efficiencyKwhPer100km, costPerKm, hasSnapshotData, startSnapshotId, endSnapshotId, createdAt); extend `BackupEnvelope` with `var energySnapshots: [EnergySnapshotBackup]` and `var electricityBills: [ElectricityBillBackup]`
- [X] T028 [P] Modify `Fuel/Services/VehicleExporter.swift` — populate `energySnapshots` and `electricityBills` fields in `BackupEnvelope` from vehicle's relationships
- [X] T029 [P] Modify `Fuel/Services/VehicleImporter.swift` — decode `energySnapshots` and `electricityBills` from `BackupEnvelope` and insert into context as new `EnergySnapshot` and `ElectricityBill` objects linked to the imported vehicle
- [X] T030 Add localization keys for all new UI strings to `Fuel/en.lproj/Localizable.strings` and `Fuel/pl.lproj/Localizable.strings`: "EV", "Snapshots", "Bills", "Background Sync", "Fetch Now", "Last synced", "Never", "Fetch Frequency", "Fetch Time", "Unable to sync — reconnect in Integrations", "No snapshots yet", "No bills yet — add your first electricity bill", "Baseline bill", "No snapshot data available", "Calculated", "Energy", "Cost per km", "Efficiency"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 — T008, T009 can run in parallel; T010 depends on T008+T009; T014 parallels T010; T015 depends on T014; T016 depends on T010+T014
- **Phase 4 (US2)**: Depends on Phase 3 completion (extends BackgroundTaskManager and SettingsView)
- **Phase 5 (US3)**: Depends on Phase 2 (models); T019 can start with Phase 2; T020 depends on T019; T021–T024 depend on T019+T020+T021
- **Phase 6 (Integration)**: Depends on Phase 3 + Phase 5 views existing
- **Phase 7 (Polish)**: Depends on Phase 2; T027–T029 can run in parallel with Phase 3 after T005

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 foundational models
- **US2 (P2)**: Extends US1 scheduling; depends on Phase 3
- **US3 (P3)**: Only needs Phase 2 models and `BillReconciliationService` (T019); independent of US1/US2 logic

### Parallel Opportunities

- T004 + T005 can run in parallel (different model files)
- T008 + T009 can run in parallel (different API client files)
- T014 + T008/T009 can run in parallel (different files)
- T027 + T028 + T029 can run in parallel (different files)

---

## Parallel Example: Phase 3 (US1)

```text
# Run in parallel (different files, no dependencies):
Task T008: Add fetchRechargeStatus to VolvoAPIClient.swift
Task T009: Add fetchSoC to ToyotaAPIClient.swift

# After T008 + T009 complete:
Task T010: Create SnapshotFetchService.swift (depends on both API methods)

# In parallel with T010:
Task T011: Create SnapshotPurgeService.swift (independent)
Task T012: Create BackgroundTaskManager.swift (can start with stub calls)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T007)
3. Complete Phase 3: US1 (T008–T016)
4. **STOP and VALIDATE**: Tap "Fetch Now" → see snapshot in EVSnapshotHistoryView
5. Feature is useful without bills (snapshot history has standalone value)

### Incremental Delivery

1. Phase 1 + 2 → Models and entitlements ready
2. Phase 3 (US1) → Snapshot collection + history + settings → Ship MVP
3. Phase 4 (US2) → Schedule configuration → Adds user control
4. Phase 5 (US3) → Bill reconciliation → Adds analytical value
5. Phase 6 → Integration into ContentView tabs
6. Phase 7 → Backup + localisation → Production ready

---

## Notes

- T001 requires Xcode GUI interaction to link the entitlements file — it cannot be fully automated via file edits alone; the `project.pbxproj` needs `CODE_SIGN_ENTITLEMENTS = Fuel/Fuel.entitlements` under the app target's build settings
- `BGAppRefreshTask` timing is controlled by iOS; "Fetch Now" (T016) is essential for testing without waiting for OS scheduling
- `SnapshotFetchService.fetch` must handle the case where `vehicle.make` is neither "volvo" nor "toyota" gracefully (log and skip, do not crash)
- All new `@Observable` classes follow the existing pattern from `VolvoOdometerService.swift`
- Distance display in `EVSnapshotHistoryView` should use `vehicle.effectiveDistanceUnit` for km/mi conversion
