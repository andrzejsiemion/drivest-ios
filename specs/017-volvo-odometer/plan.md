# Plan: Volvo API Odometer Integration

## Context

The app currently requires the user to type their odometer reading manually when logging a fill-up. For users with a connected Volvo, the odometer is available via the Volvo Cars Connected Vehicle API v2. This feature fetches the current odometer automatically from Volvo and pre-fills the field, saving manual entry and reducing transcription errors.

**Scope**: personal-use app. No in-app OAuth login flow. User obtains their Volvo ID `refresh_token` once externally (via Postman / Volvo Developer Portal), pastes it into Settings. The app silently handles token refresh on every API call.

---

## Architecture Overview

```
Settings → Volvo section
  └── Enter refresh_token (stored in Keychain)
  └── Fetch linked vehicles → user maps VIN → app Vehicle

Add Fill-Up form
  └── If vehicle has volvoVIN + token in Keychain → "↓ Fetch from Volvo" button
      └── Refreshes access token → GET /odometer → fills field
```

**No new SPM dependencies.** Uses only built-in `URLSession` + `Security` framework (Keychain).

---

## Developer Credentials Setup

Create `Fuel/Services/VolvoAPIConstants.swift` (add to `.gitignore`):

```swift
enum VolvoAPIConstants {
    static let clientID     = "YOUR_CLIENT_ID"
    static let clientSecret = "YOUR_CLIENT_SECRET"
    static let vccAPIKey    = "YOUR_VCC_API_KEY"
}
```

The user registers an app at developer.volvocars.com, selects scopes `openid`, `conve:vehicle_relation`, `conve:odometer_status`, and obtains these three values plus a `refresh_token` (via Postman or curl against the token endpoint).

---

## New Files

### `Fuel/Services/KeychainService.swift`
Minimal Keychain wrapper using `SecItemAdd` / `SecItemCopyMatching` / `SecItemDelete`.

```swift
enum KeychainService {
    static func save(_ value: String, for key: String)
    static func load(for key: String) -> String?
    static func delete(for key: String)
}
// Keys used:
// "volvo.refreshToken"
// "volvo.accessToken"
```

### `Fuel/Services/VolvoAPIClient.swift`
Three async methods using `URLSession.shared`:

```swift
struct VolvoAPIClient {
    // 1. POST to token endpoint with refresh_token → returns new access + refresh tokens
    func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String)

    // 2. GET /connected-vehicle/v2/vehicles → list of VINs
    func fetchVehicles(accessToken: String) async throws -> [String]

    // 3. GET /connected-vehicle/v2/vehicles/{vin}/odometer → km value + timestamp
    func fetchOdometer(vin: String, accessToken: String) async throws -> (km: Int, timestamp: Date)
}
```

Token endpoint: `https://volvoid.eu.volvocars.com/as/token.oauth2`
API base URL: `https://api.volvocars.com/connected-vehicle/v2`
Required headers on API calls: `Authorization: Bearer <token>` + `vcc-api-key: <key>`

### `Fuel/Views/VolvoSettingsView.swift`
NavigationStack sub-view opened from SettingsView:

- **Top section**: TextField to paste `refresh_token` + "Save" button → stores in Keychain
- **Vehicles section**: After token is saved, "Load vehicles from Volvo" button fetches VIN list and shows each VIN. Each VIN row has a picker to link it to one of the app's Vehicles (sets `vehicle.volvoVIN`)
- **Status**: Shows last sync time per linked vehicle
- **Disconnect**: Clears Keychain token + clears `volvoVIN` on all Vehicles

---

## Modified Files

### `Fuel/Models/Vehicle.swift`
Add two optional properties:
```swift
var volvoVIN: String?          // linked Volvo VIN (17 chars)
var volvoLastSyncAt: Date?     // last successful odometer fetch
```
SwiftData handles migration automatically for optional additions.

### `Fuel/Views/SettingsView.swift`
Add a new section:
```swift
Section("Connected Services") {
    NavigationLink("Volvo") {
        VolvoSettingsView()
    }
    // Show "Connected" badge if Keychain token present
}
```

### `Fuel/Views/AddFillUpView.swift`
In the odometer `HStack`, add a button when the selected vehicle has `volvoVIN`:
```swift
if vm.selectedVehicle?.volvoVIN != nil {
    Button {
        Task { await vm.fetchVolvoOdometer() }
    } label: {
        if vm.isFetchingOdometer {
            ProgressView().scaleEffect(0.7)
        } else {
            Image(systemName: "arrow.down.circle")
        }
    }
    .buttonStyle(.plain)
    .foregroundStyle(.tint)
}
```

### `Fuel/ViewModels/AddFillUpViewModel.swift`
Add:
```swift
var isFetchingOdometer = false

func fetchVolvoOdometer() async {
    guard let vin = selectedVehicle?.volvoVIN,
          let refreshToken = KeychainService.load(for: "volvo.refreshToken")
    else { return }

    isFetchingOdometer = true
    defer { isFetchingOdometer = false }

    do {
        let client = VolvoAPIClient()
        let tokens = try await client.refreshAccessToken(refreshToken: refreshToken)
        KeychainService.save(tokens.refreshToken, for: "volvo.refreshToken")
        let result = try await client.fetchOdometer(vin: vin, accessToken: tokens.accessToken)
        // Convert km → vehicle's distance unit if needed
        let display = selectedVehicle?.effectiveDistanceUnit == .miles
            ? Double(result.km) * 0.621371
            : Double(result.km)
        odometerText = String(format: "%.0f", display)
        selectedVehicle?.volvoLastSyncAt = result.timestamp
    } catch {
        // Silent fail — user can still type manually
    }
}
```

### `Fuel/Views/EditFillUpView.swift`
Same fetch button pattern as AddFillUpView, next to odometer field.

### `Fuel.xcodeproj/project.pbxproj`
Register new files: `KeychainService.swift`, `VolvoAPIClient.swift`, `VolvoSettingsView.swift`, `VolvoAPIConstants.swift`.

---

## Data Flow

```
User pastes refresh_token → Keychain["volvo.refreshToken"]
  ↓
VolvoSettingsView taps "Load vehicles"
  → POST /token (refresh_token) → access_token
  → GET /vehicles → ["YV1XZ…", …]
  → User picks which app Vehicle each VIN maps to
  → vehicle.volvoVIN = "YV1XZ…"

User opens Add Fill-Up
  → ↓ button visible (vehicle.volvoVIN != nil)
  → Tap → POST /token → new access_token + refresh_token stored
  → GET /vehicles/{vin}/odometer
  → odometerText = "<km converted to vehicle unit>"
  → vehicle.volvoLastSyncAt = result.timestamp
```

---

## Units

Volvo API always returns km. Convert if vehicle is set to miles:

```swift
let display = vehicle.effectiveDistanceUnit == .miles
    ? Double(result.km) * 0.621371
    : Double(result.km)
odometerText = String(format: "%.0f", display)
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| No token in Keychain | Fetch button hidden |
| Token refresh fails (401) | Inline error under odometer field, button stays |
| Network unavailable | Silent fail — user types manually |
| Volvo API 429 (rate limit) | Silent fail — user types manually |
| VIN not linked | Fetch button hidden |

---

## Critical Files

| File | Status |
|---|---|
| `Fuel/Models/Vehicle.swift` | Modify — add `volvoVIN`, `volvoLastSyncAt` |
| `Fuel/Services/KeychainService.swift` | New |
| `Fuel/Services/VolvoAPIClient.swift` | New |
| `Fuel/Services/VolvoAPIConstants.swift` | New (git-ignored) |
| `Fuel/Views/VolvoSettingsView.swift` | New |
| `Fuel/Views/SettingsView.swift` | Modify — add nav link |
| `Fuel/Views/AddFillUpView.swift` | Modify — add fetch button |
| `Fuel/Views/EditFillUpView.swift` | Modify — add fetch button |
| `Fuel/ViewModels/AddFillUpViewModel.swift` | Modify — add `fetchVolvoOdometer()` |
| `Fuel.xcodeproj/project.pbxproj` | Modify — register new files |

---

## Verification

1. Add `VolvoAPIConstants.swift` with real credentials (git-ignored)
2. Obtain a `refresh_token` via curl/Postman against the Volvo token endpoint with your Volvo ID credentials
3. In app Settings → Volvo: paste refresh_token, tap "Load vehicles" → VIN list appears
4. Map VIN to a Vehicle
5. Open Add Fill-Up for that vehicle → ↓ button appears next to odometer
6. Tap → spinner → odometer field fills with current reading from Volvo
7. Verify unit conversion if vehicle is set to miles
8. Disconnect in Settings → button disappears, VIN cleared
