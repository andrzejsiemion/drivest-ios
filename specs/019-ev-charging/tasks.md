# Tasks: EV Charging Session Tracking

## Phase 1 — Model Foundation (Vehicle & EfficiencyDisplayFormat)

- [X] T001 FuelType.ev already exists — no action needed
- [X] T002 EfficiencyDisplayFormat.kwhPer100km already exists — no action needed
- [ ] T003 Add `miPerKwh` case to `EfficiencyDisplayFormat` with displayName, format(), and convert() in `Fuel/Models/EfficiencyDisplayFormat.swift`
- [ ] T004 Add `var fullChargeThreshold: Int = 80` stored property to Vehicle in `Fuel/Models/Vehicle.swift`
- [ ] T005 Add computed `var isEVCapable: Bool`, `var isPHEV: Bool`, `var isPureEV: Bool` to Vehicle in `Fuel/Models/Vehicle.swift`

## Phase 2 — ChargingSession Model

- [ ] T006 Create `Fuel/Models/ChargingSession.swift` — full SwiftData @Model with all fields per plan (id, date, energyAddedKwh, startSoC, endSoC, odometerReading, electricRange, isFullCharge, totalCost, currencyCode, exchangeRate, note, photos, efficiency, source, createdAt, vehicle)
- [ ] T007 Add `@Relationship(deleteRule: .cascade, inverse: \ChargingSession.vehicle) var chargingSessions: [ChargingSession]` to Vehicle in `Fuel/Models/Vehicle.swift`
- [ ] T008 Update `ChargingSessionBackup` placeholder in `Fuel/Services/BackupCodable.swift` with all exportable fields matching ChargingSession

## Phase 3 — Efficiency Calculator

- [ ] T009 Create `Fuel/Services/ChargingEfficiencyCalculator.swift` — static methods: `calculateEfficiency(for session: ChargingSession, in sessions: [ChargingSession]) -> Double?` (Wh/km), `formatEfficiency(_ whPerKm: Double?, for vehicle: Vehicle?) -> String`

## Phase 4 — Volvo API Layer

- [ ] T010 Add `fetchRechargeStatus(vin: String, accessToken: String) async throws -> RechargeStatus` to `Fuel/Services/VolvoAPIClient.swift` using Energy API base `https://api.volvocars.com/energy/v2/vehicles/{vin}/recharge-status`
- [ ] T011 Add `EnergyState` struct and `fetchEnergyState(vin:accessToken:) async throws -> EnergyState` to `Fuel/Services/VolvoAPIClient.swift`
- [ ] T012 Create `Fuel/Services/VolvoChargingService.swift` — `@Observable` class mirroring VolvoOdometerService, calls refreshAccessToken then fetchRechargeStatus, exposes isFetching/fetchError/RechargeStatus

## Phase 5 — Background Infrastructure

- [ ] T013 Add `BGTaskSchedulerPermittedIdentifiers` array with `"com.fuel.charging.fetch"` to `Fuel/Info.plist`
- [ ] T014 Add Background Modes → Background fetch capability to `Fuel/Fuel.entitlements` (or project capabilities)
- [ ] T015 Add charging AppPreferences properties to `Fuel/Services/AppPreferences.swift`: `chargingAutoFetchEnabled`, `chargingFetchHour`, `chargingFetchMinute`, `chargingLastFetchAt`
- [ ] T016 Add `FetchFrequency` enum (daily/twiceDaily/every6hours/every12hours) to `Fuel/Services/AppPreferences.swift`
- [ ] T017 Create `Fuel/Services/BackgroundTaskManager.swift` — `scheduleNextFetch()` and `handleFetch(_ task: BGAppRefreshTask)`, register handler in FuelApp.swift

## Phase 6 — ViewModels

- [ ] T018 Create `Fuel/ViewModels/ChargingListViewModel.swift` — mirrors FillUpListViewModel, fetches/groups ChargingSession by month using MonthGrouper, deleteSession()
- [ ] T019 Create `Fuel/ViewModels/AddChargingSessionViewModel.swift` — mirrors AddFillUpViewModel, fields: date/energyAddedKwhText/startSoCText/endSoCText/odometerText/totalCostText/isFullCharge/noteText/selectedPhotos, fetchVolvoRechargeStatus(), save() inserts ChargingSession, runs ChargingEfficiencyCalculator on save
- [ ] T020 Create `Fuel/ViewModels/EditChargingSessionViewModel.swift` — mirrors EditFillUpViewModel, loads existing ChargingSession, save() updates and recalculates efficiency

## Phase 7 — Views

- [ ] T021 Create `Fuel/Views/ChargingListView.swift` — mirrors FillUpListView, grouped-by-month list of ChargingSession rows, floating + FAB to add session, swipe-to-delete
- [ ] T022 Create `Fuel/Views/AddChargingSessionView.swift` — mirrors AddFillUpView, energy(kWh)/SoC start+end/odometer/cost fields, "Fetch from Volvo" button pre-fills endSoC+odometer, photo attachment
- [ ] T023 Create `Fuel/Views/EditChargingSessionView.swift` — mirrors EditFillUpView, same fields as Add
- [ ] T024 Create `Fuel/Views/ChargingDetailView.swift` — mirrors FillUpDetailView, read-only display of all ChargingSession fields with efficiency

## Phase 8 — Settings UI

- [ ] T025 Add "Background Sync" section to `Fuel/Views/SettingsView.swift` (or VolvoSettingsView) — toggle for auto-fetch, frequency picker, time picker, last-synced label, "Fetch Now" button

## Phase 9 — Integration

- [ ] T026 Add fullChargeThreshold Stepper to VehicleFormView in `Fuel/Views/VehicleFormView.swift` — shown only when primary or secondary fuelType == .ev, range 60–100
- [ ] T027 Update `Fuel/Views/VehicleFormView.swift` VehicleFormData and its Vehicle initializer to include fullChargeThreshold
- [ ] T028 Add PHEV dual-list support to `Fuel/Views/FillUpListView.swift` — segmented Picker (Gas | Electric) when selectedVehicle.isPHEV, Electric segment shows ChargingListViewModel sessions
- [ ] T029 Add conditional fourth Charging tab to `Fuel/Views/ContentView.swift` — visible only when any vehicle has fuelType == .ev
- [ ] T030 Add EV section to SummaryViewModel and SummaryView / ContentView stats section — total kWh, avg efficiency, cost per kWh, session count
- [ ] T031 Register BackgroundTaskManager in `Fuel/FuelApp.swift` — call scheduleNextFetch() on scene active if auto-fetch enabled
- [ ] T032 Update `Fuel/Services/VehicleExporter.swift` and `VehicleImporter.swift` to include ChargingSession data in backup

## Dependencies

- T007 depends on T006 (ChargingSession model must exist before Vehicle relationship)
- T008 depends on T006
- T009 depends on T006
- T012 depends on T010, T011
- T017 depends on T012, T015, T016
- T018 depends on T006
- T019 depends on T006, T009, T012
- T020 depends on T006, T009
- T021 depends on T018
- T022 depends on T019
- T023 depends on T020
- T024 depends on T006
- T025 depends on T015, T016, T017
- T028 depends on T018
- T029 depends on T021
- T030 depends on T018
- T031 depends on T017
- T032 depends on T006
