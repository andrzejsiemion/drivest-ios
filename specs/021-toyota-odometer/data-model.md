# Data Model: Toyota Odometer Integration

## Vehicle Model Changes

**Existing fields reused**:
- `vin: String?` — already present; Toyota VIN stored here (same as Volvo uses `vin`)

**New field**:
```swift
var toyotaLastSyncAt: Date?   // timestamp of last successful Toyota odometer fetch
```

No new SwiftData entity needed — one additional optional Date property on `Vehicle`.

---

## Keychain Keys

| Key | Type | Lifecycle |
|---|---|---|
| `toyota.refreshToken` | String | Written on successful login; updated on every token refresh; deleted on disconnect |
| `toyota.username` | String | Written on login; used for display in settings; deleted on disconnect |

---

## ToyotaAPIConstants

```swift
enum ToyotaAPIConstants {
    // Hardcoded — same values as Toyota's own app (from pytoyoda source)
    static let clientID = "oneapp"
    static let basicAuthHeader = "basic b25lYXBwOm9uZWFwcA=="    // base64("oneapp:oneapp")
    static let apiKey = "[TOYOTA_API_KEY]"
    static let appVersion = "4.12.0"
    static let brand = "T"
    static let tokenURL = URL(string: "https://b2c-login.toyota-europe.com/oauth2/realms/root/realms/tme/access_token")!
    static let telemetryURL = URL(string: "https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v3/telemetry")!

    static var isConfigured: Bool {
        KeychainService.load(for: "toyota.refreshToken") != nil
    }

    static var savedUsername: String? {
        KeychainService.load(for: "toyota.username")
    }
}
```

---

## ToyotaAPIClient (struct)

Responsible for raw HTTP calls only. Stateless.

```swift
struct ToyotaAPIClient {
    // Login: username + password → (accessToken, refreshToken)
    func login(username: String, password: String) async throws -> (accessToken: String, refreshToken: String)

    // Token refresh: refreshToken → (accessToken, newRefreshToken)
    func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String)

    // Odometer fetch: accessToken + vin → km reading
    func fetchOdometer(vin: String, accessToken: String) async throws -> Int
}
```

Error type: `ToyotaAPIError` enum with `errorDescription` and `userMessage`.

---

## ToyotaOdometerService (@Observable)

Stateful service used by ViewModels.

```swift
@Observable
final class ToyotaOdometerService {
    var isFetching = false
    var fetchError: String?

    func fetchOdometer(vin: String) async -> (km: Int, syncedAt: Date)?
}
```

Internal flow:
1. Load refresh token from Keychain
2. Call `ToyotaAPIClient.refreshAccessToken`
3. Save new refresh token to Keychain
4. Call `ToyotaAPIClient.fetchOdometer`
5. Return `(km, Date.now)`

---

## State Transitions

```
[Not configured]
    → user opens ToyotaSettingsView, enters email + password
    → login() called
    → on success: refresh token + username saved to Keychain
[Configured / Connected]
    → fetch button visible in Add/Edit Fill-Up (if vehicle has VIN)
    → tap fetch → ToyotaOdometerService.fetchOdometer()
    → on success: odometer text filled, toyotaLastSyncAt updated
    → on token expiry: error shown with "Re-enter credentials" prompt
[Disconnected]
    → user taps Disconnect in settings
    → Keychain entries deleted
[Not configured]
```
