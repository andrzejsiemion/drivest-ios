import AppIntents
import SwiftData
import os

struct FetchOdometerIntent: AppIntent {
    static let title: LocalizedStringResource = "Fetch Odometer"
    static let description = IntentDescription(
        "Fetches the current odometer reading for all connected vehicles (Volvo, Toyota)."
    )
    static var openAppWhenRun: Bool = false

    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "FetchOdometerIntent")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        Self.log.info("FetchOdometerIntent started")
        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: Vehicle.self, FillUp.self, CostEntry.self, CostCategory.self,
                    EnergySnapshot.self, ElectricityBill.self, Reminder.self
            )
        } catch {
            Self.log.error("ModelContainer failed: \(error.localizedDescription)")
            return .result(value: "Error: \(error.localizedDescription)")
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<Vehicle>()
        let allVehicles = (try? context.fetch(descriptor)) ?? []
        let connected = allVehicles.filter { $0.hasConnectedOBD }
        Self.log.info("Vehicles: \(allVehicles.count) total, \(connected.count) connected")

        if connected.isEmpty {
            return .result(value: "No connected vehicles found (\(allVehicles.count) total)")
        }

        await SnapshotFetchService.shared.fetchAll(context: context)

        let errorMsg = SnapshotFetchService.shared.lastError
        if let errorMsg {
            Self.log.error("Fetch error: \(errorMsg)")
            return .result(value: "Error: \(errorMsg)")
        }

        return .result(value: "Fetched odometer for \(connected.count) vehicle(s)")
    }
}
