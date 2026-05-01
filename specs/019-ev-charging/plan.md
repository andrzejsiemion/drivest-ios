# Plan: EV Charging Session Tracking + Volvo API Integration

## Context

The app currently tracks fuel fill-ups for ICE vehicles. This feature adds parallel charging session tracking for EVs and PHEVs, with optional Volvo API read-back when the car finishes a charging cycle (reports full/target SoC reached).

**Scope:** Personal-use app. Data is pulled two ways: (1) automatically via a configurable background schedule (default: daily at 06:00), (2) manually via a "Fetch from Volvo" button at any time. When the background task detects a completed charging session since the last sync, it creates a draft `ChargingSession` and fires a local notification. User taps the notification → app opens → session is pre-filled for review and save.

**Target vehicles:** Pure EV, PHEV (dual-track — fuel fill-ups + charge sessions on the same vehicle), any vehicle the user marks as EV-capable.

---

## Key Design Decisions

### D1: Separate model, not extending FillUp
`ChargingSession` is a new SwiftData `@Model`. Sharing the `FillUp` model would pollute it with optional EV fields and break efficiency calculations. Both models follow the same shape: date, odometer, cost, currency, photos, vehicle relationship.

### D2: FuelType enum extended with EV
**Already implemented as `.ev` (not `.electric`).** When a vehicle's primary or secondary `fuelType == .ev`, the charging UI and tab become available. This handles PHEV naturally (secondTankFuelType = .ev). `compatibleFuelUnits` already returns `[.kilowattHours]` for `.ev`.

### D3: Efficiency unit for EVs
- Display: `kWh/100km` (default, metric) or `mi/kWh` (imperial)
- `EfficiencyDisplayFormat.kwhPer100km` — **already implemented**
- `EfficiencyDisplayFormat.miPerKwh` — **still needs to be added**
- Efficiency is calculated from consecutive full-charge sessions (same logic as full-tank fill-ups)

### D4: Scheduled background fetch + manual pull
Two fetch paths, same underlying logic:

**Scheduled (BGAppRefreshTask):**
- iOS `BGAppRefreshTask` runs at approximately the user-configured time. After each run, the next task is scheduled with `earliestBeginDate` = next occurrence of the configured time.
- iOS does not guarantee exact timing — it respects battery, network, and device usage patterns. Typical real-world accuracy: ±30–60 min of the requested time.
- Default schedule: once per day, preferred time 06:00.
- On completion: if car is not charging and SoC ≥ `fullChargeThreshold` AND `lastSyncAt` is before the current session started → create a pending `ChargingSession` draft and fire a `UNUserNotificationCenter` local notification.

**Manual:**
- "Fetch from Volvo" button in the Add/Edit charging form.
- Same API call, result pre-fills the form immediately without a notification.

### D5: New tab, not extending Fuel tab
A fourth "Charging" tab with the bolt icon. Only visible if at least one vehicle has `fuelType == .electric` or `secondTankFuelType == .electric`. Reuses the same tab header pattern as the Fuel tab.

### D6: PHEV dual-list in FillUpListView
For a vehicle where `secondTankFuelType == .electric` (PHEV), the Fuel tab shows **two segmented lists** rather than one:

```
[Fuel ▾]   [Gas | Electric]      ← segmented control in header
─────────────────────────────────
April 2026
  Fill-up  53 822 km   48.2 L    ← gas fill-up rows
March 2026
  Fill-up  51 100 km   50.1 L
```

Switching to "Electric" shows `ChargingSession` rows for the same vehicle in the same grouped-by-month layout.

**Implementation:**
- `FillUpListView` detects `selectedVehicle.isEVCapable && selectedVehicle.fuelType != .electric` (i.e. PHEV — has both tanks).
- When true, renders a `Picker`/segmented control: `["Gas", "Electric"]`.
- Selected segment switches between `FillUpListViewModel.groupedFillUps` and a `ChargingListViewModel.groupedSessions` instance held in the same view.
- Pure EV vehicles (`fuelType == .electric`, no gas tank) skip the segmented control entirely — the Fuel tab only shows the charging list for that vehicle (or the Fuel tab is hidden and only the Charging tab appears, TBD preference).
- The `+` FAB adds a fuel fill-up or a charging session depending on the active segment.

---

## Background Fetch Schedule Configuration

### AppPreferences additions
```swift
static var chargingAutoFetchEnabled: Bool       // default: true
static var chargingFetchHour: Int               // 0–23, default: 6
static var chargingFetchMinute: Int             // 0–59, default: 0
static var chargingFetchFrequency: FetchFrequency  // .daily | .twiceDaily | .everyNHours(n)
static var chargingLastFetchAt: Date?
```

### FetchFrequency enum
```swift
enum FetchFrequency: String, CaseIterable {
    case daily          // once per day at preferred time
    case twiceDaily     // at preferred time + 12h later
    case every6hours
    case every12hours
}
```

### BackgroundTaskManager (new service)
```swift
final class BackgroundTaskManager {
    static let taskIdentifier = "com.fuel.charging.fetch"

    /// Call on app launch and after each completed task.
    static func scheduleNextFetch()

    /// Registered handler — called by iOS when task fires.
    static func handleFetch(_ task: BGAppRefreshTask)
}
```

`scheduleNextFetch()` calculates `earliestBeginDate`:
- For `.daily`: next occurrence of `(fetchHour, fetchMinute)` — if today's time has passed, use tomorrow.
- For `.twiceDaily`: next of two daily windows.
- For `.everyNHours`: `Date() + n * 3600`.

`handleFetch()`:
1. Calls `VolvoChargingService.fetchRechargeStatus()` for all EV-capable vehicles with a VIN.
2. Compares result against `volvoLastSyncAt` — if new completed charge detected, inserts a pending `ChargingSession` (with `source = "volvo_background"`).
3. Fires local notification: *"V90 charged to 82% — tap to review session"*.
4. Updates `chargingLastFetchAt`.
5. Calls `task.setTaskCompleted(success: true)`.
6. Schedules next fetch.

### Required app setup (Info.plist + entitlements)
- `BGTaskSchedulerPermittedIdentifiers`: `["com.fuel.charging.fetch"]`
- Background Modes capability: `fetch`
- `UNUserNotificationCenter` authorization request on first EV vehicle setup.

### Settings UI — "Background Sync" section
New section in `IntegrationsView` → Volvo settings, or directly in a new "Sync" section of `SettingsView`:

```
Background Sync
┌─────────────────────────────────┐
│ Auto-fetch charging data   [ON] │
│ Frequency         [Once a day ▾]│
│ Preferred time         [06:00 ▾]│
│ Last synced      Today, 06:12   │
│ [Fetch Now]                     │
└─────────────────────────────────┘
Footer: "iOS may run the fetch within ~1 hour of the preferred time
         based on device usage patterns."
```

`Frequency` picker: "Once a day", "Twice a day", "Every 6 hours", "Every 12 hours".
When frequency is not `.daily`, the time picker is hidden.
"Fetch Now" button triggers an immediate manual fetch (same code path as the button in the form).

---

## Volvo API Scopes to Register

In the Volvo Developer Portal → your app → edit scopes, check the following and re-authenticate:

### Energy API (primary EV data source)
| Scope | What it unlocks | Required for |
|---|---|---|
| `energy:state:read` | Charging state, SoC %, estimated range, charging rate | Core EV fetch — **must have** |
| `energy:capability:read` | What charging standards the vehicle supports (AC/DC, max kW) | Optional — enriches UI |

### Connected Vehicle API (supplementary)
| Scope | What it unlocks | Required for |
|---|---|---|
| `conve:battery_charge_level` | Battery % via Connected Vehicle API (fallback if Energy API unavailable) | Optional fallback |
| `conve:fuel_status` | Current fuel tank level in litres/% | **Bonus**: auto-fetch fuel level on fill-up form |
| `conve:odometer_status` | Already registered | Already working |

**Already registered (no change needed):** `conve:odometer_status`, `openid`

**Minimum new scopes to enable EV feature:** `energy:state:read`
**Recommended full set:** `energy:state:read`, `energy:capability:read`, `conve:fuel_status`

### Re-authentication steps
After updating scopes in the portal:
1. Run `get_volvo_token.py` → new `refresh_token` that includes the new scopes
2. Paste into Settings → Integrations → Volvo → Account

---

## Energy API v2 Endpoints

**Base URL:** `https://api.volvocars.com/energy/v2`
(separate from the Connected Vehicle API base `https://api.volvocars.com/connected-vehicle/v2`)

**Headers required:** `Authorization: Bearer <token>`, `vcc-api-key: <key>` (same key as current)

### GET `/vehicles/{vin}/state`
Requires `energy:state:read`. Returns current energy state:
```json
{
  "data": {
    "batteryChargeLevel": { "value": 80, "unit": "percentage", "timestamp": "..." },
    "electricRange":      { "value": 38,  "unit": "km",         "timestamp": "..." },
    "chargingSystemStatus": {
      "value": "CHARGING_SYSTEM_IDLE",
      "timestamp": "..."
    },
    "chargingConnectionStatus": {
      "value": "CONNECTION_STATUS_DISCONNECTED",
      "timestamp": "..."
    },
    "estimatedChargingTime": { "value": 0, "unit": "minutes" }
  }
}
```

`chargingSystemStatus` values: `CHARGING_SYSTEM_IDLE`, `CHARGING_SYSTEM_CHARGING`, `CHARGING_SYSTEM_FAULT`, `CHARGING_SYSTEM_UNSPECIFIED`
`chargingConnectionStatus` values: `CONNECTION_STATUS_CONNECTED_AC`, `CONNECTION_STATUS_CONNECTED_DC`, `CONNECTION_STATUS_DISCONNECTED`, `CONNECTION_STATUS_FAULT`, `CONNECTION_STATUS_UNSPECIFIED`

**Charging-complete detection logic:**
```
chargingConnectionStatus == DISCONNECTED
  AND chargingSystemStatus == IDLE
  AND batteryChargeLevel.value >= vehicle.fullChargeThreshold
  AND batteryChargeLevel.timestamp > vehicle.volvoLastSyncAt
```

### GET `/vehicles/{vin}/capability`
Requires `energy:capability:read`. Returns supported charging types and max power.

### `VolvoAPIClient` additions
```swift
// Energy API base — separate from connected-vehicle base
private let energyAPIBase = URL(string: "https://api.volvocars.com/energy/v2")!

func fetchEnergyState(vin: String, accessToken: String) async throws -> EnergyState
func fetchEnergyCapability(vin: String, accessToken: String) async throws -> EnergyCapability

struct EnergyState {
    let socPercent: Int
    let electricRangeKm: Int?
    let isCharging: Bool
    let isConnected: Bool
    let chargingSystemStatus: String
    let timestamp: Date
}
```

---

## Data Model

### `ChargingSession` (new SwiftData @Model)
```swift
@Model
final class ChargingSession {
    var id: UUID
    var date: Date
    var energyAddedKwh: Double          // kWh added during session
    var startSoC: Double?               // % at start (optional — not always known)
    var endSoC: Double                  // % at end
    var odometerReading: Double
    var electricRange: Double?          // km/miles reported by car
    var isFullCharge: Bool              // endSoC >= 80% (configurable threshold)
    var totalCost: Double               // cost of charging session
    var currencyCode: String?
    var exchangeRate: Double?
    var note: String?
    var photos: [Data]
    var efficiency: Double?             // Wh/km — calculated from consecutive full charges
    var source: String                  // "manual" | "volvo_api"
    var createdAt: Date
    var vehicle: Vehicle?

    // Computed
    var allPhotos: [Data] { photos }    // No legacy single-photo here
}
```

### `Vehicle.swift` changes
```swift
var secondTankFuelType: FuelType?   // already exists — set to .electric for PHEV
// add:
var fullChargeThreshold: Int = 80   // % SoC considered "full charge" — user-configurable
var chargingSessions: [ChargingSession] = []   // inverse relationship
```

### `FuelType` enum change
```swift
case ev   // already implemented — triggers EV-specific UI
```

### `EfficiencyDisplayFormat` enum change
```swift
case kwhPer100km    // already implemented
case miPerKwh       // still needs to be added
```

---

## New Files

### `Fuel/Models/ChargingSession.swift`
Full SwiftData model as above.

### `Fuel/Services/VolvoChargingService.swift`
New `@Observable` service mirroring `VolvoOdometerService`:
```swift
@Observable
final class VolvoChargingService {
    var isFetching = false
    var fetchError: String?

    struct RechargeStatus {
        let socPercent: Int
        let electricRangeKm: Int?
        let isCharging: Bool
        let isConnected: Bool
        let timestamp: Date
    }

    func fetchRechargeStatus(for vehicle: Vehicle?) async -> RechargeStatus?
}
```

`VolvoAPIClient` gets a new method:
```swift
func fetchRechargeStatus(vin: String, accessToken: String) async throws -> VolvoAPIClient.RechargeStatus
```

### `Fuel/ViewModels/AddChargingSessionViewModel.swift`
Mirrors `AddFillUpViewModel`:
- Fields: `date`, `energyAddedKwhText`, `startSoCText`, `endSoCText`, `odometerText`, `totalCostText`, `isFullCharge`, `noteText`, `selectedPhotos`
- `fetchVolvoRechargeStatus()` async — fills `endSoCText` + `odometerText` from API
- `save()` creates and inserts `ChargingSession`
- Efficiency calculation: same full-charge window approach as `EfficiencyCalculator`

### `Fuel/ViewModels/ChargingListViewModel.swift`
Mirrors `FillUpListViewModel`:
- `sessions: [ChargingSession]`
- `groupedSessions: [(key: String, values: [ChargingSession])]`
- `fetchSessions(for vehicle: Vehicle?)`
- `deleteSession(_ session: ChargingSession)`

### `Fuel/ViewModels/EditChargingSessionViewModel.swift`
Mirrors `EditFillUpViewModel`.

### `Fuel/Views/ChargingListView.swift`
Fourth tab — mirrors `FillUpListView`. Shows sessions grouped by month. Same floating + button. Conditionally shown in ContentView.

### `Fuel/Views/AddChargingSessionView.swift`
Sheet view for adding a session — mirrors `AddFillUpView`. Key differences:
- Energy (kWh) field instead of Volume
- SoC start/end fields (0–100 integer)
- "Fetch from Volvo" pre-fills endSoC + odometer if car finished charging
- No fuel type picker

### `Fuel/Views/EditChargingSessionView.swift`

### `Fuel/Views/ChargingDetailView.swift`

### `Fuel/Services/ChargingEfficiencyCalculator.swift`
Separate calculator for Wh/km efficiency across consecutive full-charge sessions:
- Same logic as `EfficiencyCalculator` — finds previous full-charge, computes Wh/km from kWh added and km delta

---

## Modified Files

### `Fuel/Models/FuelType.swift`
`.ev` case already exists with `displayName = "EV"` and `compatibleFuelUnits = [.kilowattHours]`. **No change needed.**

### `Fuel/Models/Vehicle.swift`
- Add `var chargingSessions: [ChargingSession] = []`
- Add `var fullChargeThreshold: Int = 80`
- Add computed `var isEVCapable: Bool` — `fuelType == .ev || secondTankFuelType == .ev`
- Add computed `var isPHEV: Bool` — `fuelType != .ev && secondTankFuelType == .ev` (has both gas and EV)
- Add computed `var isPureEV: Bool` — `fuelType == .ev`

### `Fuel/Views/FillUpListView.swift`
PHEV dual-list support (see D6):
- Add `@State private var chargingListViewModel: ChargingListViewModel?`
- Add `@State private var activeSegment: FuelSegment = .gas` where `enum FuelSegment { case gas, electric }`
- When `selectedVehicle.isPHEV` (has both gas and electric tanks): render segmented `Picker` in the header area
- Active segment drives which list + which FAB action is shown
- `isPHEV` computed property on `Vehicle`: `fuelType != .electric && secondTankFuelType == .electric`

### `Fuel/Views/ContentView.swift`
Add fourth tab only for fleet with pure-EV vehicles. PHEV users get the dual-list in the Fuel tab instead:
```swift
if store.sortedVehicles(vehicles).contains(where: { $0.fuelType == .electric }) {
    ChargingListView()
        .tabItem { Label("Charging", systemImage: "bolt.fill") }
}
```
Pure EV (`fuelType == .electric`): no gas fill-ups, Fuel tab shows charging list only (segment control hidden). Charging tab also available for dedicated EV workflow.

### `Fuel/Views/VehicleFormView.swift`
When primary or secondary fuel type is `.electric`:
- Show `Stepper` for `fullChargeThreshold` (range 60–100, default 80)

### `Fuel/Views/SummaryViewModel.swift` / `SummaryTabView.swift`
Add EV section to statistics:
- Total kWh added
- Average efficiency (Wh/km or mi/kWh)
- Cost per kWh
- Sessions count

### `Fuel/Services/VolvoAPIClient.swift`
Add `fetchRechargeStatus(vin:accessToken:)` method.

---

## Data Flow

```
User finishes charging → opens app
  ↓
Charging tab → Add session (+)
  ↓
AddChargingSessionView appears
  → "Fetch from Volvo" (if VIN configured + recharge_status scope)
    → POST /token → access_token
    → GET /vehicles/{vin}/recharge-status
    → pre-fills: endSoC, electricRange, odometer (from separate call)
  → User enters/confirms: energyAddedKwh, startSoC, totalCost
  → Save → ChargingSession inserted
  → isFullCharge = (endSoC >= vehicle.fullChargeThreshold)
  → If isFullCharge: ChargingEfficiencyCalculator runs
```

---

## EV Efficiency Calculation

```
Sessions sorted by date (ascending) for the vehicle.
For session S at index i:
  if S.isFullCharge:
    find previous full-charge session P (walk backwards)
    if P exists:
      kmDelta = S.odometerReading - P.odometerReading
      S.efficiency = (S.energyAddedKwh * 1000) / kmDelta  // Wh/km
```

Display conversion:
- `kwhPer100km`: `efficiency / 10`
- `miPerKwh`: `1609.34 / efficiency`

---

## Volvo API Setup Required

User must add `energy:recharge_status` scope in the Volvo Developer Portal before re-authenticating. Add this instruction to `VolvoSettingsView` footer or a help text in the charging fetch error message.

---

## Execution Order

| Phase | Items | Notes |
|---|---|---|
| 1 | ~~`FuelType.ev`~~ (done), `Vehicle.isEVCapable`, `Vehicle.fullChargeThreshold`, `Vehicle.chargingSessions` | Model foundation — SwiftData migration auto |
| 2 | `ChargingSession` model, ~~`EfficiencyDisplayFormat.kwhPer100km`~~ (done), `EfficiencyDisplayFormat.miPerKwh` | New model |
| 3 | `ChargingEfficiencyCalculator` | Logic only, no UI |
| 4 | `VolvoAPIClient.fetchRechargeStatus`, `VolvoChargingService` | API layer |
| 5 | `AppPreferences` fetch settings, `BackgroundTaskManager` | Background infra — needs Info.plist + entitlement |
| 6 | `AddChargingSessionViewModel`, `EditChargingSessionViewModel`, `ChargingListViewModel` | ViewModels |
| 7 | `AddChargingSessionView`, `EditChargingSessionView`, `ChargingDetailView`, `ChargingListView` | UI |
| 8 | Background Sync settings UI in `SettingsView` | Config UI |
| 9 | `ContentView` tab wiring, `VehicleFormView` threshold field, `SummaryTabView` EV stats | Integration |

---

## Out of Scope

- Real-time charging monitoring (requires persistent background execution)
- Push notifications when charging completes
- Smart charging schedule integration
- Third-party charging network APIs (ChargePoint, ABRP, etc.)
- Automatic session import history from Volvo (bulk historical data)
