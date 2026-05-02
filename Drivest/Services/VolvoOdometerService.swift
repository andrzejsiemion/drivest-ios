import Foundation
import Observation

@Observable
final class VolvoOdometerService: OdometerService {
    var isFetching = false
    var fetchError: String?

    func fetchOdometer(vin: String) async -> (km: Int, syncedAt: Date)? {
        guard let refreshToken = KeychainService.load(for: KeychainService.volvoRefreshToken)
        else { return nil }

        guard VolvoAPIConstants.isConfigured else {
            fetchError = "Developer credentials missing. Add Client ID, Secret, and VCC API Key in Settings → Integrations → Volvo."
            return nil
        }

        isFetching = true
        fetchError = nil
        defer { isFetching = false }

        do {
            let client = VolvoAPIClient()
            let tokens = try await client.refreshAccessToken(refreshToken: refreshToken)
            KeychainService.save(tokens.refreshToken, for: KeychainService.volvoRefreshToken)
            let result = try await client.fetchOdometer(vin: vin, accessToken: tokens.accessToken)
            return (km: result.km, syncedAt: result.timestamp)
        } catch {
            fetchError = (error as? VolvoAPIError)?.userMessage ?? error.localizedDescription
            return nil
        }
    }
}
