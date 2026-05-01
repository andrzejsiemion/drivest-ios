import Foundation
import Observation

@Observable
final class ToyotaOdometerService: OdometerService {
    var isFetching = false
    var fetchError: String?

    func fetchOdometer(vin: String) async -> (km: Int, syncedAt: Date)? {
        guard let refreshToken = KeychainService.load(for: KeychainService.toyotaRefreshToken)
        else { return nil }

        isFetching = true
        fetchError = nil
        defer { isFetching = false }

        do {
            let client = ToyotaAPIClient()
            let tokens = try await client.refreshAccessToken(refreshToken: refreshToken)
            KeychainService.save(tokens.refreshToken, for: KeychainService.toyotaRefreshToken)
            let km = try await client.fetchOdometer(vin: vin, accessToken: tokens.accessToken)
            return (km: km, syncedAt: Date())
        } catch {
            fetchError = (error as? ToyotaAPIError)?.userMessage ?? error.localizedDescription
            return nil
        }
    }
}
