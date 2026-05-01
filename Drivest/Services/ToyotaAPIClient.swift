import Foundation
import CryptoKit

struct ToyotaAPIClient {

    // MARK: - Login

    /// Initial authentication: email + password → (accessToken, refreshToken).
    /// The refresh token should be saved to Keychain; the access token is short-lived.
    func login(username: String, password: String) async throws -> (accessToken: String, refreshToken: String) {
        var request = URLRequest(url: ToyotaAPIConstants.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(ToyotaAPIConstants.basicAuthHeader, forHTTPHeaderField: "authorization")

        let body = [
            "client_id": ToyotaAPIConstants.clientID,
            "grant_type": "password",
            "username": username,
            "password": password,
            "redirect_uri": ToyotaAPIConstants.redirectURI,
            "code_verifier": "plain",
            "scope": "openid profile",
        ]
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
        .joined(separator: "&")
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ToyotaAPIError.loginFailed(statusCode: statusCode, body: body)
        }

        return try parseTokenResponse(data)
    }

    // MARK: - Token refresh

    /// Exchange a stored refresh token for a new access token + rotated refresh token.
    func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        var request = URLRequest(url: ToyotaAPIConstants.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(ToyotaAPIConstants.basicAuthHeader, forHTTPHeaderField: "authorization")

        let body = [
            "client_id": ToyotaAPIConstants.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "redirect_uri": ToyotaAPIConstants.redirectURI,
            "code_verifier": "plain",
        ]
        .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
        .joined(separator: "&")
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ToyotaAPIError.tokenRefreshFailed(statusCode: statusCode, body: body)
        }

        return try parseTokenResponse(data)
    }

    // MARK: - Odometer

    /// Fetch the current odometer reading (km) for the given VIN.
    func fetchOdometer(vin: String, accessToken: String) async throws -> Int {
        var request = URLRequest(url: ToyotaAPIConstants.telemetryURL)
        request.httpMethod = "GET"
        let userUUID = parseUUID(from: accessToken) ?? UUID().uuidString.lowercased()
        let clientRef = hmacClientRef(userUUID: userUUID)
        request.setValue("Bearer \(accessToken)",            forHTTPHeaderField: "authorization")
        request.setValue(ToyotaAPIConstants.apiKey,          forHTTPHeaderField: "x-api-key")
        request.setValue(userUUID,                           forHTTPHeaderField: "x-guid")
        request.setValue(userUUID,                           forHTTPHeaderField: "guid")
        request.setValue(UUID().uuidString,                  forHTTPHeaderField: "x-correlationid")
        request.setValue(ToyotaAPIConstants.appVersion,      forHTTPHeaderField: "x-appversion")
        request.setValue(ToyotaAPIConstants.brand,           forHTTPHeaderField: "x-brand")
        request.setValue(ToyotaAPIConstants.channel,         forHTTPHeaderField: "x-channel")
        request.setValue(clientRef,                          forHTTPHeaderField: "x-client-ref")
        request.setValue(ToyotaAPIConstants.region,          forHTTPHeaderField: "x-region")
        request.setValue(ToyotaAPIConstants.userAgent,       forHTTPHeaderField: "user-agent")
        request.setValue(vin,                                forHTTPHeaderField: "vin")
        request.setValue("application/json",                 forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ToyotaAPIError.requestFailed(statusCode: statusCode, body: body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let payload = json["payload"] as? [String: Any] ?? [:]
        let odometer = payload["odometer"] as? [String: Any] ?? [:]
        guard let value = odometer["value"] as? Int else {
            throw ToyotaAPIError.unexpectedResponse
        }
        return value
    }

    // MARK: - SoC

    /// Fetches battery state of charge (0–100) for the given VIN from the Toyota telemetry endpoint.
    /// Returns nil if the vehicle firmware does not expose SoC data.
    func fetchSoC(vin: String, accessToken: String) async throws -> Int? {
        var request = URLRequest(url: ToyotaAPIConstants.telemetryURL)
        request.httpMethod = "GET"
        let userUUID = parseUUID(from: accessToken) ?? UUID().uuidString.lowercased()
        let clientRef = hmacClientRef(userUUID: userUUID)
        request.setValue("Bearer \(accessToken)",            forHTTPHeaderField: "authorization")
        request.setValue(ToyotaAPIConstants.apiKey,          forHTTPHeaderField: "x-api-key")
        request.setValue(userUUID,                           forHTTPHeaderField: "x-guid")
        request.setValue(userUUID,                           forHTTPHeaderField: "guid")
        request.setValue(UUID().uuidString,                  forHTTPHeaderField: "x-correlationid")
        request.setValue(ToyotaAPIConstants.appVersion,      forHTTPHeaderField: "x-appversion")
        request.setValue(ToyotaAPIConstants.brand,           forHTTPHeaderField: "x-brand")
        request.setValue(ToyotaAPIConstants.channel,         forHTTPHeaderField: "x-channel")
        request.setValue(clientRef,                          forHTTPHeaderField: "x-client-ref")
        request.setValue(ToyotaAPIConstants.region,          forHTTPHeaderField: "x-region")
        request.setValue(ToyotaAPIConstants.userAgent,       forHTTPHeaderField: "user-agent")
        request.setValue(vin,                                forHTTPHeaderField: "vin")
        request.setValue("application/json",                 forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw ToyotaAPIError.requestFailed(statusCode: statusCode, body: body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let payload = json["payload"] as? [String: Any] ?? [:]

        if let evStatus = payload["evDetailedStatus"] as? [String: Any],
           let chargeStatus = evStatus["chargeStatus"] as? [String: Any],
           let value = chargeStatus["value"] as? Int {
            return value
        }
        if let soc = payload["soc"] as? [String: Any], let value = soc["value"] as? Int {
            return value
        }
        return nil
    }

    // MARK: - Private

    /// Extract the `uuid` claim from a JWT access token without full verification.
    private func parseUUID(from jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = String(parts[1])
        let rem = b64.count % 4
        if rem != 0 { b64 += String(repeating: "=", count: 4 - rem) }
        guard let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuidStr = json["uuid"] as? String
        else { return nil }
        return uuidStr
    }

    /// Compute HMAC-SHA256(key: appVersion, message: userUUID) — required by Toyota API.
    private func hmacClientRef(userUUID: String) -> String {
        let keyData = Data(ToyotaAPIConstants.appVersion.utf8)
        let msgData = Data(userUUID.utf8)
        let key = SymmetricKey(data: keyData)
        let mac = HMAC<SHA256>.authenticationCode(for: msgData, using: key)
        return mac.map { String(format: "%02x", $0) }.joined()
    }

    private func parseTokenResponse(_ data: Data) throws -> (accessToken: String, refreshToken: String) {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let access  = json["access_token"]  as? String,
              let refresh = json["refresh_token"] as? String
        else { throw ToyotaAPIError.unexpectedResponse }
        return (accessToken: access, refreshToken: refresh)
    }
}

// MARK: - Errors

enum ToyotaAPIError: LocalizedError {
    case loginFailed(statusCode: Int, body: String)
    case tokenRefreshFailed(statusCode: Int, body: String)
    case requestFailed(statusCode: Int, body: String)
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .loginFailed(let code, let body):
            return "Toyota login failed (\(code)): \(body)"
        case .tokenRefreshFailed(let code, let body):
            return "Toyota token refresh failed (\(code)): \(body)"
        case .requestFailed(let code, let body):
            return "Toyota API request failed (\(code)): \(body)"
        case .unexpectedResponse:
            return "Unexpected response from Toyota API."
        }
    }

    var userMessage: String {
        switch self {
        case .loginFailed(let code, _):
            return code == 401
                ? "Incorrect email or password. Please try again."
                : "Could not connect to Toyota. Check your internet connection."
        case .tokenRefreshFailed:
            return "Session expired. Re-enter credentials in Settings → Integrations → Toyota."
        case .requestFailed(let code, _):
            return code == 401
                ? "Session expired. Re-enter credentials in Settings → Integrations → Toyota."
                : "Toyota API unavailable. Try again later."
        case .unexpectedResponse:
            return "Unexpected response from Toyota. Try again later."
        }
    }
}
