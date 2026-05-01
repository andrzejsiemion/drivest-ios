# Research: Toyota Odometer Integration

**Feature**: 021-toyota-odometer
**Date**: 2026-04-24

---

## 1. Toyota EU API — Authentication

**Decision**: Use OAuth2 refresh-token flow with hardcoded app credentials.

**Details**:
- **Token endpoint**: `https://b2c-login.toyota-europe.com/oauth2/realms/root/realms/tme/access_token`
- **Client ID / Secret**: Both are `"oneapp"` (baked into Toyota's own app)
- **Basic Auth header** (pre-computed): `basic b25lYXBwOm9uZWFwcA==` (base64 of `oneapp:oneapp`)
- **Initial login** (`grant_type: password`): POST username + password → receive `refresh_token` + `access_token`
- **Token refresh** (`grant_type: refresh_token`): POST stored refresh_token → receive new tokens
- **code_verifier**: hardcoded `"plain"` (PKCE placeholder, not real PKCE)
- **redirect_uri**: `"com.toyota.oneapp:/oauth2Callback"`

**User credentials required**: Email + password from the MyToyota (new) app account. No developer keys needed — they are hardcoded.

**Rationale**: Unlike Volvo (where the user must obtain a refresh token externally), Toyota's OAuth2 flow can be completed entirely within the app using username + password. Better UX.

**Alternatives considered**: Requiring user to paste a refresh token externally (like Volvo) — rejected because the initial login flow is well-understood and avoids extra setup steps.

---

## 2. Toyota EU API — Odometer Endpoint

**Decision**: Use `/v3/telemetry` endpoint with `vin` request header.

**Details**:
- **Base URL**: `https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io`
- **Endpoint**: `GET /v3/telemetry`
- **VIN passed as**: Request header `vin: {vin}`
- **Auth header**: `authorization: Bearer {access_token}`
- **API key** (hardcoded): `x-api-key: [TOYOTA_API_KEY]`
- **Required headers**:
  - `x-guid`: new UUID per request
  - `x-correlationid`: new UUID per request
  - `x-appversion`: app version string (e.g., `"4.12.0"`)
  - `x-brand`: `"T"` for Toyota, `"L"` for Lexus
  - `vin`: vehicle VIN

**Response JSON path**: `payload.odometer.value` (Int, in km)

```json
{
  "payload": {
    "odometer": {
      "unit": "km",
      "value": 12345
    }
  }
}
```

**Rationale**: This is the only known endpoint that returns real-time odometer data.

---

## 3. `x-client-ref` Header

**Decision**: Omit initially; add if API returns 403/401.

**Details**: The `x-client-ref` header is an HMAC-SHA256 hash used by the official Toyota app as a request signature. The pytoyoda library computes it, but the exact signing key and input are embedded in the library. The HA integration (ha_toyota) works without validating this header server-side in many cases — it appears to be a client-side integrity check that Toyota's backend does not always enforce.

**Rationale**: Implementing HMAC signing requires reverse-engineering the signing key — significant complexity. Attempting without it first is pragmatic.

**Risk**: If Toyota enforces this header, API calls will fail with 403. Mitigation: the error will be surfaced to the user with a clear message.

---

## 4. Eligibility Constraints

- **Region**: EU only (MyToyota connected Europe)
- **App version**: New MyToyota app only (not legacy MyT)
- **Vehicle**: Must be Toyota Connected Services eligible (newer models 2019+)
- **Brand**: Toyota or Lexus

These constraints should be documented in the settings UI.

---

## 5. API Stability

**Decision**: Proceed with implementation; display a prominent disclaimer in settings.

The API is unofficial and reverse-engineered. Toyota can change or revoke it without notice. The feature must fail gracefully (clear error messages, no crashes) so users are not left confused if it stops working.

**Alternatives considered**: Waiting for an official API — no such API exists for EU Toyota.

---

## 6. Volvo Integration — Architecture to Mirror

The existing Volvo integration provides the exact pattern to follow:

| Layer | Volvo | Toyota (new) |
|---|---|---|
| Constants | `VolvoAPIConstants.swift` | `ToyotaAPIConstants.swift` |
| HTTP client | `VolvoAPIClient.swift` | `ToyotaAPIClient.swift` |
| Observable service | `VolvoOdometerService.swift` | `ToyotaOdometerService.swift` |
| Settings UI | `VolvoSettingsView.swift` | `ToyotaSettingsView.swift` |
| Keychain keys | `volvo.refreshToken` etc. | `toyota.refreshToken`, `toyota.username` |
| Vehicle model | `vin`, `volvoLastSyncAt` | `toyotaVIN` (reuse `vin`), `toyotaLastSyncAt` |
| ViewModel hook | `fetchVolvoOdometer()` | `fetchToyotaOdometer()` |

**Key differences**:
1. No developer credentials — `ToyotaAPIConstants` has no user-configurable keys
2. Username + password login within the app (two-step: login → refresh token stored)
3. `x-guid` and `x-correlationid` headers must be generated per-request
4. `x-brand` header required (`"T"`)

---

## 7. Keychain Storage Plan

| Key | Value | Notes |
|---|---|---|
| `toyota.refreshToken` | OAuth2 refresh token | Rotated on each token refresh |
| `toyota.username` | User's email | Needed to re-authenticate if refresh token expires |

Password is NOT stored after initial login (obtain token, discard password immediately).
