import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SnapshotFetchService {
    static let shared = SnapshotFetchService()

    var isFetching = false
    var lastError: String?

    private init() {}

    // MARK: - Public

    func fetchAll(context: ModelContext) async {
        let descriptor = FetchDescriptor<Vehicle>()
        guard let vehicles = try? context.fetch(descriptor) else { return }
        let evVehicles = vehicles.filter { $0.isEV }
        guard !evVehicles.isEmpty else { return }

        isFetching = true
        lastError = nil
        defer { isFetching = false }

        for vehicle in evVehicles {
            do {
                try await fetch(vehicle: vehicle, context: context)
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func fetch(vehicle: Vehicle, context: ModelContext) async throws {
        let make = vehicle.make?.lowercased() ?? ""
        guard let vin = vehicle.vin, !vin.isEmpty else { return }

        var odometerKm: Double = 0
        var socPercent: Int?

        if make == "volvo" {
            guard let refreshToken = KeychainService.load(for: KeychainService.volvoRefreshToken) else {
                incrementFailureCount(for: vehicle)
                return
            }
            do {
                let client = VolvoAPIClient()
                let tokens = try await client.refreshAccessToken(refreshToken: refreshToken)
                KeychainService.save(tokens.refreshToken, for: KeychainService.volvoRefreshToken)
                let odometer = try await client.fetchOdometer(vin: vin, accessToken: tokens.accessToken)
                odometerKm = Double(odometer.km)
                let recharge = try? await client.fetchRechargeStatus(vin: vin, accessToken: tokens.accessToken)
                socPercent = recharge?.socPercent
            } catch {
                incrementFailureCount(for: vehicle)
                throw error
            }
        } else if make == "toyota" {
            guard let refreshToken = KeychainService.load(for: KeychainService.toyotaRefreshToken) else {
                incrementFailureCount(for: vehicle)
                return
            }
            do {
                let client = ToyotaAPIClient()
                let tokens = try await client.refreshAccessToken(refreshToken: refreshToken)
                KeychainService.save(tokens.refreshToken, for: KeychainService.toyotaRefreshToken)
                let km = try await client.fetchOdometer(vin: vin, accessToken: tokens.accessToken)
                odometerKm = Double(km)
                socPercent = try? await client.fetchSoC(vin: vin, accessToken: tokens.accessToken)
            } catch {
                incrementFailureCount(for: vehicle)
                throw error
            }
        } else {
            return
        }

        let snapshot = EnergySnapshot(
            fetchedAt: Date(),
            odometerKm: odometerKm,
            socPercent: socPercent,
            source: make,
            vehicle: vehicle
        )
        context.insert(snapshot)
        try context.save()
        resetFailureCount(for: vehicle)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "snapshotLastFetchAt")
    }

    // MARK: - Failure tracking

    private func failureKey(for vehicle: Vehicle) -> String {
        "snapshotFailures_\(vehicle.id.uuidString)"
    }

    private func incrementFailureCount(for vehicle: Vehicle) {
        let key = failureKey(for: vehicle)
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }

    private func resetFailureCount(for vehicle: Vehicle) {
        UserDefaults.standard.set(0, forKey: failureKey(for: vehicle))
    }
}
