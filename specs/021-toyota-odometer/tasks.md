# Tasks: Toyota Odometer Integration

**Input**: Design documents from `specs/021-toyota-odometer/`
**Branch**: `021-toyota-odometer`
**Available docs**: plan.md, data-model.md, research.md
**Note**: No spec.md present; user stories derived from plan.md phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 = Account connection · US2 = Vehicle detail sync status · US3 = Fill-up odometer fetch

---

## Phase 1: Setup

**Purpose**: Register new Swift files in the Xcode project so they compile.

- [x] T001 Add ToyotaAPIConstants.swift, ToyotaAPIClient.swift, ToyotaOdometerService.swift, ToyotaSettingsView.swift references and build phase entries in `Fuel.xcodeproj/project.pbxproj`

**Checkpoint**: Project builds (files not yet populated — compiler will error until Phase 2)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core service layer and data model. MUST complete before any user story.

**⚠️ CRITICAL**: All US1/US2/US3 work depends on this phase.

- [x] T002 Create `Fuel/Services/ToyotaAPIConstants.swift` — enum with all hardcoded constants (`clientID`, `basicAuthHeader`, `apiKey`, `appVersion`, `brand`, `tokenURL`, `telemetryURL`) plus Keychain accessors (`isConfigured`, `savedUsername`)
- [x] T003 [P] Create `ToyotaAPIError` enum in `Fuel/Services/ToyotaAPIClient.swift` — cases: `loginFailed`, `tokenRefreshFailed`, `requestFailed`, `unexpectedResponse`; each with `errorDescription` (technical) and `userMessage` (UI-friendly string)
- [x] T004 Implement `ToyotaAPIClient.login(username:password:)` in `Fuel/Services/ToyotaAPIClient.swift` — POST to `ToyotaAPIConstants.tokenURL` with `grant_type=password`, `client_id=oneapp`, `redirect_uri`, `code_verifier=plain`; parse `access_token` + `refresh_token` from response; throw `loginFailed` on non-200
- [x] T005 Implement `ToyotaAPIClient.refreshAccessToken(refreshToken:)` in `Fuel/Services/ToyotaAPIClient.swift` — POST to `ToyotaAPIConstants.tokenURL` with `grant_type=refresh_token`; return new `(accessToken, refreshToken)` tuple; throw `tokenRefreshFailed` on failure
- [x] T006 Implement `ToyotaAPIClient.fetchOdometer(vin:accessToken:)` in `Fuel/Services/ToyotaAPIClient.swift` — GET `ToyotaAPIConstants.telemetryURL`; headers: `authorization: Bearer {accessToken}`, `x-api-key`, `x-guid` (new UUID), `x-correlationid` (new UUID), `x-appversion`, `x-brand: "T"`, `vin: {vin}`; parse `payload.odometer.value` from JSON; return `Int` (km)
- [x] T007 Create `Fuel/Services/ToyotaOdometerService.swift` — `@Observable final class` with `isFetching: Bool = false` and `fetchError: String?`; method `fetchOdometer(vin:) async -> (km: Int, syncedAt: Date)?`; internal flow: load `toyota.refreshToken` from Keychain → `refreshAccessToken` → save new refresh token → `fetchOdometer` → return result; on any error set `fetchError` to `error.userMessage` and return `nil`
- [x] T008 Add `var toyotaLastSyncAt: Date?` to `Vehicle` in `Fuel/Models/Vehicle.swift` (after `volvoLastSyncAt`)

**Checkpoint**: App compiles. Service layer complete; can be manually tested via Xcode debugger.

---

## Phase 3: User Story 1 — Account Connection (P1) 🎯 MVP

**Goal**: User can connect their Toyota account via Settings → Integrations → Toyota and disconnect it.

**Independent Test**: Open app → Settings → Integrations → Toyota → enter valid MyToyota credentials → tap Sign In → status shows connected with email displayed → tap Disconnect → status returns to disconnected.

- [x] T009 [US1] Create `Fuel/Views/ToyotaSettingsView.swift` — disconnected state: `Section("Account")` with `TextField` for email, `SecureField` for password, `Button("Sign In")` with async action + `ProgressView` spinner during sign-in; disclaimer footer: *"Toyota Connected Services (EU only). Unofficial API — may stop working without notice."*
- [x] T010 [US1] Add connected state to `ToyotaSettingsView` — show `LabeledContent("Signed in as", value: username)`, green status icon, `Button("Disconnect", role: .destructive)`; toggle between states based on `ToyotaAPIConstants.isConfigured`
- [x] T011 [US1] Wire sign-in action in `ToyotaSettingsView` — call `ToyotaAPIClient().login(username:password:)`, on success save `toyota.refreshToken` and `toyota.username` to `KeychainService`, clear password field, transition to connected state; on failure display error inline below form
- [x] T012 [US1] Wire disconnect action in `ToyotaSettingsView` — delete `toyota.refreshToken` and `toyota.username` from `KeychainService`, transition to disconnected state
- [x] T013 [US1] Add Toyota `NavigationLink` to `Fuel/Views/IntegrationsView.swift` — row with Toyota logo/icon placeholder, label "Toyota", green dot when `ToyotaAPIConstants.isConfigured`, navigates to `ToyotaSettingsView`

**Checkpoint**: User Story 1 fully functional. Settings → Integrations → Toyota shows sign-in form and manages connection state.

---

## Phase 4: User Story 2 — Vehicle Detail Sync Status (P2)

**Goal**: Vehicle detail screen shows Toyota last-sync timestamp when Toyota is configured and vehicle has a VIN.

**Independent Test**: Toyota configured + vehicle has VIN → vehicle detail shows Toyota section with "Not yet synced" (before first fetch) or relative timestamp after a fetch.

- [x] T014 [US2] Add Toyota section to `Fuel/Views/VehicleDetailView.swift` — conditional on `ToyotaAPIConstants.isConfigured && vehicle.vin != nil`; section header "Toyota"; show `LabeledContent("Last sync") { Text(syncAt.formatted(.relative(presentation: .named))) }` when `vehicle.toyotaLastSyncAt != nil`, else `Text("Not yet synced").foregroundStyle(.secondary)`

**Checkpoint**: User Story 2 fully functional. Toyota section appears/disappears correctly based on configuration and VIN presence.

---

## Phase 5: User Story 3 — Fill-Up Odometer Fetch (P3)

**Goal**: When logging or editing a fill-up, user can tap a button to pre-fill the odometer from Toyota.

**Independent Test**: Toyota configured + vehicle has VIN → Add Fill-Up → odometer row shows Toyota fetch button → tap → spinner → odometer field populated with current reading.

- [x] T015 [US3] Add `let toyotaService = ToyotaOdometerService()` and `fetchToyotaOdometer() async` to `Fuel/ViewModels/AddFillUpViewModel.swift` — guard `selectedVehicle?.vin != nil && ToyotaAPIConstants.isConfigured`; call `toyotaService.fetchOdometer(vin:)`; on success convert km→miles if `effectiveDistanceUnit == .miles`, write to `odometerText`, update `selectedVehicle?.toyotaLastSyncAt = result.syncedAt`
- [x] T016 [P] [US3] Add same `toyotaService` + `fetchToyotaOdometer()` implementation to `Fuel/ViewModels/EditFillUpViewModel.swift` (identical logic to T015)
- [x] T017 [US3] Add Toyota fetch button to odometer row in `Fuel/Views/AddFillUpView.swift` — show when `ToyotaAPIConstants.isConfigured && viewModel.selectedVehicle?.vin != nil`; button with `arrow.down.circle` icon (or `t.circle` for Toyota); show `ProgressView` when `toyotaService.isFetching`; show `toyotaService.fetchError` as red `.caption` text below row; if Volvo also configured, show both buttons side by side
- [x] T018 [P] [US3] Add same Toyota fetch button to odometer row in `Fuel/Views/EditFillUpView.swift` (identical pattern to T017)

**Checkpoint**: User Story 3 fully functional. Odometer can be fetched from Toyota during fill-up entry.

---

## Phase 6: Polish

**Purpose**: Error edge cases and UX finishing touches.

- [x] T019 [P] Verify error message in `ToyotaSettingsView` when login fails with bad credentials — show inline error below password field (not alert)
- [x] T020 [P] Verify `ToyotaSettingsView` handles network timeout gracefully — show "Check your internet connection" user message
- [x] T021 Add "Re-enter credentials" prompt when `tokenRefreshFailed` is returned during odometer fetch in `ToyotaOdometerService` — set `fetchError` to `"Session expired. Re-enter credentials in Settings → Integrations → Toyota."`

---

## Dependencies

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2 complete. No dependency on US2 or US3.
- **US2 (P2)**: Requires Phase 2 complete (needs `toyotaLastSyncAt` on Vehicle). Independent of US1 at code level (but logically requires US1 to see data).
- **US3 (P3)**: Requires Phase 2 complete. Independent of US1/US2 at code level.

### Within Each Phase

- T003 can start in parallel with T002 (different concerns, same file — coordinate)
- T004 must follow T003 (uses `ToyotaAPIError`)
- T005 can start after T003 (parallel with T004 — different method in same struct)
- T006 can start after T003 (parallel with T004/T005)
- T007 requires T005 + T006 complete
- T008 is fully independent of T002–T007

---

## Parallel Opportunities

```
Phase 2 (after T003):
  T004 login()           ← parallel
  T005 refreshToken()    ← parallel
  T006 fetchOdometer()   ← parallel
  T008 Vehicle.swift     ← parallel with all above

Phase 5:
  T015 AddFillUpViewModel   ← parallel
  T016 EditFillUpViewModel  ← parallel (same logic)
  (T017/T018 depend on T015/T016)

Phase 6:
  T019 + T020 + T021 all parallel
```

---

## Implementation Strategy

### MVP (US1 only — Phases 1–3)

1. Phase 1: Register files in Xcode project
2. Phase 2: Build service layer (T002–T008)
3. Phase 3: Settings UI (T009–T013)
4. **STOP**: Test sign-in / disconnect manually on device
5. Ship US1 if validated

### Incremental Delivery

1. Phases 1–3 → Toyota connection works ✅
2. Phase 4 (T014) → Sync status visible in vehicle detail ✅
3. Phase 5 (T015–T018) → Odometer fetch in fill-up ✅
4. Phase 6 (T019–T021) → Edge cases handled ✅

---

## Total: 21 tasks across 6 phases

| Phase | Tasks | User Story | Parallelizable |
|---|---|---|---|
| 1 Setup | 1 | — | No |
| 2 Foundational | 7 | — | T003–T006, T008 |
| 3 US1 Account | 5 | US1 | No (sequential UI wiring) |
| 4 US2 Vehicle Detail | 1 | US2 | — |
| 5 US3 Fill-Up Fetch | 4 | US3 | T015‖T016, T017‖T018 |
| 6 Polish | 3 | — | T019‖T020‖T021 |
