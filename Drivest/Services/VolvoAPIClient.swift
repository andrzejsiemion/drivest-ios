import Foundation

struct VolvoAPIClient {

    private let tokenURL = URL(string: "https://volvoid.eu.volvocars.com/as/token.oauth2")!
    private let apiBase  = URL(string: "https://api.volvocars.com/connected-vehicle/v2")!

    // MARK: - Token refresh

    /// Exchange the stored refresh_token for a new access_token + refresh_token.
    func refreshAccessToken(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let credentials = "\(VolvoAPIConstants.clientID):\(VolvoAPIConstants.clientSecret)"
        let encoded = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")

        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw VolvoAPIError.tokenRefreshFailed(statusCode: statusCode, body: body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let access  = json["access_token"]  as? String,
              let refresh = json["refresh_token"] as? String
        else { throw VolvoAPIError.unexpectedResponse }

        return (accessToken: access, refreshToken: refresh)
    }

    // MARK: - Vehicle list

    /// Returns the list of VINs linked to the authenticated Volvo account.
    func fetchVehicles(accessToken: String) async throws -> [String] {
        let url = apiBase.appendingPathComponent("vehicles")
        let data = try await get(url: url, accessToken: accessToken)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let items = json["data"] as? [[String: Any]] ?? []
        return items.compactMap { $0["vin"] as? String }
    }

    // MARK: - Odometer

    /// Fetches the current odometer for the given VIN. Returns km value and last-reported timestamp.
    func fetchOdometer(vin: String, accessToken: String) async throws -> (km: Int, timestamp: Date) {
        let url = apiBase.appendingPathComponent("vehicles/\(vin)/odometer")
        let data = try await get(url: url, accessToken: accessToken)

        let json  = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let inner = (json["data"] as? [String: Any])?["odometer"] as? [String: Any]
        guard let km = inner?["value"] as? Int else { throw VolvoAPIError.unexpectedResponse }

        var timestamp = Date()
        if let ts = inner?["timestamp"] as? String {
            timestamp = ISO8601DateFormatter().date(from: ts) ?? Date()
        }
        return (km: km, timestamp: timestamp)
    }

    // MARK: - Recharge Status (SoC)

    /// Fetches battery state of charge and electric range for the given VIN from the Volvo Energy API.
    func fetchRechargeStatus(vin: String, accessToken: String) async throws -> (socPercent: Int?, electricRangeKm: Int?) {
        let energyBase = URL(string: "https://api.volvocars.com/energy/v2/vehicles/\(vin)/recharge-status")!
        let data = try await get(url: energyBase, accessToken: accessToken)

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let dataObj = json["data"] as? [String: Any] ?? [:]

        let socPercent = (dataObj["batteryChargeLevel"] as? [String: Any])?["value"] as? Int
        let electricRangeKm = (dataObj["electricRange"] as? [String: Any])?["value"] as? Int

        return (socPercent: socPercent, electricRangeKm: electricRangeKm)
    }

    // MARK: - Private

    private func get(url: URL, accessToken: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(VolvoAPIConstants.vccAPIKey,  forHTTPHeaderField: "vcc-api-key")
        request.setValue("application/json",           forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            throw VolvoAPIError.requestFailed(statusCode: statusCode, body: body)
        }
        return data
    }
}

// MARK: - Errors

enum VolvoAPIError: LocalizedError {
    case tokenRefreshFailed(statusCode: Int, body: String)
    case requestFailed(statusCode: Int, body: String)
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .tokenRefreshFailed(let code, let body):
            return "Token refresh failed (\(code)): \(body)"
        case .requestFailed(let code, let body):
            return "API request failed (\(code)): \(body)"
        case .unexpectedResponse:
            return "Unexpected response from Volvo API."
        }
    }

    var userMessage: String {
        switch self {
        case .tokenRefreshFailed:
            return "Could not refresh Volvo session. Please re-enter your token in Settings → Integrations → Volvo."
        case .requestFailed(let code, _):
            return code == 401
                ? "Invalid API credentials. Check Settings → Integrations → Volvo."
                : "Volvo API unavailable. Try again later."
        case .unexpectedResponse:
            return "Unexpected response from Volvo. Try again later."
        }
    }
}
