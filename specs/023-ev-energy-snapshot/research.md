# Research: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Branch**: `023-ev-energy-snapshot` | **Date**: 2026-04-25

---

## Decision 1: Background Scheduling Strategy

**Decision**: Use `BGAppRefreshTask` from Apple's `BackgroundTasks` framework for periodic background fetch.

**Rationale**: `BGAppRefreshTask` is the correct iOS primitive for periodic background work. It requires registering a task identifier in `Info.plist` (`BGTaskSchedulerPermittedIdentifiers`), declaring the "Background fetch" capability in the `.entitlements` file, and registering a handler in `FuelApp.init()` via `BGTaskScheduler.shared.register(...)`. After each execution the handler must reschedule the next fetch using `BGTaskScheduler.shared.submit(...)`.

**Constraints**:
- iOS does not guarantee exact timing; the system honours requests opportunistically based on battery, network, and usage patterns. A user who frequently opens the app will receive more frequent background execution.
- Minimum schedulable interval is approximately 15 minutes; scheduling a 5-minute interval is ignored.
- If the app has not been foregrounded recently, iOS may suppress background refresh entirely. The "Fetch Now" button (FR-016) provides a fallback for users in this situation.

**Alternatives considered**:
- `BGProcessingTask`: designed for long-running CPU/network tasks (uploads, ML). Overkill and harder to schedule at specific times.
- `UNUserNotificationCenter` + background push: requires a server to send the push. Violates the no-server-dependency constraint.
- Timer in foreground only: misses the "closed app" requirement entirely.

---

## Decision 2: Volvo Battery SoC Endpoint

**Decision**: Use Volvo Energy API v2 endpoint `GET /energy/v2/vehicles/{vin}/recharge-status`.

**Rationale**: The Volvo Connected Vehicle API (`/connected-vehicle/v2`) used for odometer does not return battery SoC. The Energy API is a separate base URL (`https://api.volvocars.com/energy/v2/vehicles/{vin}/recharge-status`) that returns `batteryChargeLevel.value` (integer, 0–100 percentage). The same `accessToken` and `vcc-api-key` headers used for the odometer call are valid for the Energy API — no additional OAuth scope is required for developer API access.

**Response shape** (relevant fields):
```json
{
  "data": {
    "batteryChargeLevel": { "value": 78, "unit": "PERCENTAGE" },
    "electricRange": { "value": 312, "unit": "KILOMETERS" }
  }
}
```

**Alternatives considered**:
- Connected Vehicle v2 `/vehicles/{vin}/windows`, `/doors`, etc.: none contain SoC.
- Polling odometer endpoint for efficiency proxy: unreliable and inaccurate.

---

## Decision 3: Toyota Battery SoC Field

**Decision**: Read `payload.evDetailedStatus.chargeStatus.value` from the existing `/v3/telemetry` endpoint. Fall back to `payload.soc.value` if `evDetailedStatus` is absent (vehicle firmware varies).

**Rationale**: The `/v3/telemetry` endpoint already used for odometer returns the full vehicle telemetry payload. PHEVs and BEVs expose SoC under `evDetailedStatus.chargeStatus.value` (integer 0–100). Older firmware may expose it under the top-level `soc.value` key. Returning `nil` for SoC when neither field is present is acceptable — the snapshot is still stored with the odometer value.

**Alternatives considered**:
- Separate SoC-specific Toyota endpoint: no such dedicated endpoint exists in the current ctpa-oneapi implementation.

---

## Decision 4: Consecutive Failure Tracking

**Decision**: Track the consecutive failure count per vehicle using `UserDefaults` with key `snapshotFailures_<vehicleID>`. Reset to 0 on any successful fetch for that vehicle.

**Rationale**: SwiftData requires a model context (main actor) which may not be available during background task execution. `UserDefaults` is safe to write from any thread, requires no schema migration, and is appropriate for this lightweight counter.

**Threshold**: 3 consecutive failures triggers the in-app persistent alert (FR-017). The alert is a `@AppStorage`-driven banner in `ContentView`/`SettingsView` rather than a push notification (no server needed).

---

## Decision 5: Snapshot Boundary Selection for Bill Reconciliation

**Decision**: For each bill reconciliation period, select the snapshot with the **minimum time delta** from the period-start date (previous bill's `endDate`) and the snapshot with the minimum time delta from the period-end date (current bill's `endDate`). Distance = `endSnapshot.odometerKm − startSnapshot.odometerKm`.

**Rationale**: Using closest-by-timestamp boundaries gives the most accurate odometer range without interpolation, consistent with the spec's assumption. The approach is deterministic and produces verifiable results — the user can see which snapshot was used for start and end if needed.

**Edge cases**:
- If no snapshot exists within 7 days of the start or end boundary, distance calculation is skipped and the bill is marked `hasSnapshotData = false`.
- If end boundary snapshot odometer < start boundary odometer (rollback or vehicle change): calculation is skipped; bill marked `hasSnapshotData = false`.

---

## Decision 6: Schedule Configuration Storage

**Decision**: Store schedule config in `UserDefaults` via `@AppStorage` keys (not SwiftData), since schedule is per-app and applies globally.

**Keys**:
- `snapshotFetchEnabled` (Bool, default `true`)
- `snapshotFetchFrequencyRawValue` (String, default `"daily"`)
- `snapshotFetchHour` (Int, default `5`)
- `snapshotFetchMinute` (Int, default `0`)
- `snapshotLastFetchAt` (Double/TimeInterval, default `0`)

**Rationale**: No need for SwiftData model overhead for a single-instance configuration. `@AppStorage` makes it reactive in SwiftUI settings views automatically.

---

## Decision 7: No Entitlements File — Needs Creation

**Decision**: The project currently has no `.entitlements` file. One must be created at `Fuel/Fuel.entitlements` and linked in the Xcode project's "Signing & Capabilities" tab.

**Required entitlement**:
```xml
<key>com.apple.developer.background-task-scheduler-allowed-identifiers</key>
<array>
    <string>com.fuel.snapshot.fetch</string>
</array>
```

**Note**: The Xcode project file (`project.pbxproj`) must reference the entitlements file via the `CODE_SIGN_ENTITLEMENTS` build setting. This cannot be done by editing Swift files alone — the developer must add the "Background Modes → Background fetch" capability in Xcode's project editor, which generates both the entitlements file and the Info.plist key automatically.

---

## Decision 8: New Models Added to ModelContainer

**Decision**: Add `EnergySnapshot` and `ElectricityBill` to the existing `ModelContainer` in `FuelApp.init()`.

```swift
container = try ModelContainer(for: Vehicle.self, FillUp.self, CostEntry.self, CostCategory.self,
                               EnergySnapshot.self, ElectricityBill.self)
```

**Rationale**: SwiftData automatically handles schema migration for new models; no migration plan needed when only adding new model types (existing data is untouched).
