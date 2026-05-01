# Implementation Plan: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Branch**: `023-ev-energy-snapshot` | **Date**: 2026-04-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/023-ev-energy-snapshot/spec.md`

## Summary

Add automatic daily (or more frequent) energy snapshot collection from manufacturer APIs (Volvo/Toyota) for EV vehicles, stored locally for 6 months. When users receive an electricity bill they enter end date, total kWh, and total cost; the app reconciles this against stored snapshots to calculate real-world kWh/100km efficiency and cost/km.

**Technical approach**: Two new SwiftData models (`EnergySnapshot`, `ElectricityBill`) backed by pure-function reconciliation logic. Background scheduling via Apple's `BGAppRefreshTask`. New API methods on existing `VolvoAPIClient` (Energy API SoC endpoint) and `ToyotaAPIClient` (SoC field from telemetry). Feature gated on `vehicle.fuelType == .ev`.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, BackgroundTasks (all Apple frameworks — no new third-party dependencies)
**Storage**: SwiftData (existing ModelContainer, two new models added)
**Testing**: XCTest
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iPhone + iPad)
**Performance Goals**: Snapshot fetch completes in <5 seconds per vehicle; bill reconciliation calculation is synchronous and instant (<50ms)
**Constraints**: Offline-capable; no server dependency; background execution subject to iOS scheduling policy
**Scale/Scope**: Typically 1–3 EV vehicles per user; up to ~180 snapshots per vehicle per 6-month retention window

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| I. Clean Code | ✓ Pass | MVVM, single-responsibility services, no dead code |
| II. Simple UX | ✓ Pass | Settings section + list views; "Fetch Now" one-tap; bill entry minimal fields |
| III. Responsive Design | ✓ Pass | SwiftUI adaptive layouts; existing patterns followed |
| IV. Minimal Dependencies | ✓ Pass | `BackgroundTasks` is Apple framework; `CryptoKit` already imported; zero new 3rd-party packages |
| iOS 17.0+ | ✓ Pass | No APIs below iOS 17 used |
| SwiftData | ✓ Pass | Two new `@Model` classes; additive to existing container |
| No server dependency | ✓ Pass | Local-only; manufacturer API calls are user-initiated integrations already present |
| MVVM | ✓ Pass | New ViewModels for snapshot history and bill list/add |

**No violations. No complexity justification required.**

## Project Structure

### Documentation (this feature)

```text
specs/023-ev-energy-snapshot/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── ui-contracts.md  # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (additions/modifications)

```text
Fuel/
├── FuelApp.swift                         # MODIFY: register BGTaskManager, add new models to container, call purge on active
├── Info.plist                            # MODIFY: add BGTaskSchedulerPermittedIdentifiers key
├── Fuel.entitlements                     # CREATE: background fetch entitlement
│
├── Models/
│   ├── EnergySnapshot.swift              # CREATE: SwiftData @Model
│   ├── ElectricityBill.swift             # CREATE: SwiftData @Model
│   ├── FetchFrequency.swift              # CREATE: enum (daily/twiceDaily/every6h/every12h)
│   └── Vehicle.swift                     # MODIFY: add energySnapshots + electricityBills relationships + isEV
│
├── Services/
│   ├── SnapshotFetchService.swift        # CREATE: @Observable, orchestrates Volvo/Toyota fetch + saves snapshot
│   ├── BillReconciliationService.swift   # CREATE: pure function — calculates efficiency from snapshots
│   ├── SnapshotPurgeService.swift        # CREATE: deletes snapshots older than 6 months
│   ├── BackgroundTaskManager.swift       # CREATE: registers + schedules BGAppRefreshTask
│   ├── VolvoAPIClient.swift              # MODIFY: add fetchRechargeStatus() → (socPercent: Int?, electricRangeKm: Int?)
│   ├── ToyotaAPIClient.swift             # MODIFY: add fetchSoC() → Int? (reads evDetailedStatus.chargeStatus.value)
│   └── BackupCodable.swift              # MODIFY: add EnergySnapshotBackup + ElectricityBillBackup structs; update BackupEnvelope
│
├── ViewModels/
│   ├── SnapshotHistoryViewModel.swift    # CREATE: loads/groups snapshots by month, triggers fetch
│   ├── BillListViewModel.swift           # CREATE: loads bills sorted by date
│   └── AddBillViewModel.swift            # CREATE: form fields + save with reconciliation
│
└── Views/
    ├── ContentView.swift                 # MODIFY: add EV tab when any vehicle is EV; show consecutive-failure banner
    ├── SettingsView.swift                # MODIFY: add "EV Background Sync" section (toggle, frequency, time, fetch now, last synced)
    ├── EVSnapshotHistoryView.swift       # CREATE: grouped list of EnergySnapshot rows
    ├── ElectricityBillListView.swift     # CREATE: list of ElectricityBill rows with status badge
    ├── AddElectricityBillView.swift      # CREATE: form — date, kWh, cost, note
    └── ElectricityBillDetailView.swift   # CREATE: read-only display of bill + reconciliation metrics
```

Also update `Fuel/Services/VehicleExporter.swift` and `VehicleImporter.swift` to export/import snapshot and bill data.

## Execution Order

| Phase | Tasks | Depends on |
|---|---|---|
| 1 — Model Foundation | `EnergySnapshot`, `ElectricityBill`, `FetchFrequency`, Vehicle relationships, ModelContainer update | — |
| 2 — Services (pure logic) | `BillReconciliationService`, `SnapshotPurgeService` | Phase 1 |
| 3 — API Extensions | `VolvoAPIClient.fetchRechargeStatus()`, `ToyotaAPIClient.fetchSoC()` | Phase 1 |
| 4 — Fetch Orchestration | `SnapshotFetchService`, `BackgroundTaskManager`, entitlements + Info.plist | Phase 2, 3 |
| 5 — ViewModels | `SnapshotHistoryViewModel`, `BillListViewModel`, `AddBillViewModel` | Phase 2, 3 |
| 6 — Views | All new views + ContentView/SettingsView modifications | Phase 5 |
| 7 — Backup | Extend `BackupCodable`, `VehicleExporter`, `VehicleImporter` | Phase 1 |

## Key Implementation Notes

### Volvo SoC API
New endpoint on separate base URL `https://api.volvocars.com/energy/v2/vehicles/{vin}/recharge-status`. Same Bearer token + `vcc-api-key` header as existing odometer call. Add `fetchRechargeStatus(vin:accessToken:)` to `VolvoAPIClient` returning `(socPercent: Int?, electricRangeKm: Int?)`.

### Toyota SoC Field
Read `payload.evDetailedStatus.chargeStatus.value` from existing `/v3/telemetry` response. Fall back to `payload.soc.value` if absent. Return `nil` if neither key present — snapshot still saved without SoC.

### Background Task Registration
Must be called before `applicationDidFinishLaunching` completes (iOS requirement). Call `BackgroundTaskManager.register()` as the first statement in `FuelApp.init()`. Identifier: `"com.fuel.snapshot.fetch"`.

### Consecutive Failure Alert
`UserDefaults.standard.integer(forKey: "snapshotFailures_\(vehicle.id)")` tracked per vehicle. Alert shown as a `@State` banner in `ContentView` when any vehicle's counter ≥ 3. Banner links to Integrations/Settings screen for reconnection.

### Feature Gating
`vehicle.isEV` (`fuelType == .ev`) gates all snapshot collection and bill entry. The EV tab in `ContentView` appears only when `selectedVehicle?.isEV == true`. No background fetch is scheduled if no EV vehicle exists.

### Bill Reconciliation
Fully synchronous, pure computation in `BillReconciliationService.reconcile(...)`. Called at save time in `AddBillViewModel.save()`. Calculated fields stored on the `ElectricityBill` model — no recomputation needed for history display.
