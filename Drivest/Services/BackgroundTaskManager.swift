import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundTaskManager {
    static let taskIdentifier = "app.drivest.snapshot.fetch"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleFetch(refreshTask)
        }
    }

    static func scheduleNextFetch() {
        guard UserDefaults.standard.bool(forKey: "snapshotFetchEnabled") else { return }

        let frequency = FetchFrequency(
            rawValue: UserDefaults.standard.string(forKey: "snapshotFetchFrequency") ?? ""
        ) ?? .daily

        let hour   = UserDefaults.standard.integer(forKey: "snapshotFetchHour")
        let minute = UserDefaults.standard.integer(forKey: "snapshotFetchMinute")

        let nextDate = nextFetchDate(frequency: frequency, hour: hour, minute: minute)

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = nextDate
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Private

    private static func handleFetch(_ task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task { @MainActor in
            do {
                let container = try ModelContainer(for: Vehicle.self, FillUp.self, CostEntry.self,
                                                   CostCategory.self, EnergySnapshot.self, ElectricityBill.self)
                let context = ModelContext(container)
                await SnapshotFetchService.shared.fetchAll(context: context)
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
            scheduleNextFetch()
        }
    }

    private static func nextFetchDate(frequency: FetchFrequency, hour: Int, minute: Int) -> Date {
        let now = Date()
        let calendar = Calendar.current

        if frequency == .daily {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour   = hour
            components.minute = minute
            components.second = 0
            if let candidate = calendar.date(from: components), candidate > now {
                return candidate
            }
            return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
        }

        return now.addingTimeInterval(frequency.intervalSeconds)
    }
}
