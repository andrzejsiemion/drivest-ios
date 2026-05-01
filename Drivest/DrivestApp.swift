import SwiftUI
import SwiftData

@main
struct DrivestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    private let selectionStore = VehicleSelectionStore()
    private let importCoordinator = ImportCoordinator()
    private let nbpService = NBPExchangeRateService()
    @State private var showLanguageChangedAlert = false
    @State private var showSplash = true

    private static let languageCodeKey = "activeLanguageCode"

    init() {
        BackgroundTaskManager.register()
        do {
            container = try ModelContainer(for: Vehicle.self, FillUp.self, CostEntry.self, CostCategory.self,
                                           EnergySnapshot.self, ElectricityBill.self, CostReminder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        seedCategoriesIfNeeded()
        restoreVehicleSelection()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(selectionStore)
                    .environment(importCoordinator)
                    .environment(nbpService)
                    .onChange(of: scenePhase) { _, phase in
                        if phase == .active {
                            Task { await nbpService.fetchIfNeeded() }
                            checkLanguageChange()
                            SnapshotPurgeService.purgeExpired(context: container.mainContext)
                            if UserDefaults.standard.bool(forKey: "snapshotFetchEnabled") {
                                BackgroundTaskManager.scheduleNextFetch()
                            }
                        }
                    }
                    .onOpenURL { url in
                        guard url.pathExtension == "drivestbackup" || url.pathExtension == "fuelbackup" || url.pathExtension == "json" else { return }
                        importCoordinator.pendingURL = url
                    }
                    .alert("Language Changed", isPresented: $showLanguageChangedAlert) {
                        Button("Restart") { exit(0) }
                        Button("Later", role: .cancel) { }
                    } message: {
                        Text("Restart the app to apply the new language.")
                    }
                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .modelContainer(container)
    }

    private func checkLanguageChange() {
        let currentCode = Locale.current.language.languageCode?.identifier ?? "en"
        let storedCode = UserDefaults.standard.string(forKey: Self.languageCodeKey)
        if let storedCode {
            if storedCode != currentCode {
                UserDefaults.standard.set(currentCode, forKey: Self.languageCodeKey)
                showLanguageChangedAlert = true
            }
        } else {
            UserDefaults.standard.set(currentCode, forKey: Self.languageCodeKey)
        }
    }

    private func seedCategoriesIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "categoriesSeeded") else { return }
        let context = container.mainContext
        for (index, item) in CostCategory.defaults.enumerated() {
            let category = CostCategory(name: item.name, iconName: item.icon, sortOrder: index, isBuiltIn: true)
            context.insert(category)
        }
        Persistence.save(context)
        UserDefaults.standard.set(true, forKey: "categoriesSeeded")
    }

    private func restoreVehicleSelection() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Vehicle>()
        let vehicles = (try? context.fetch(descriptor)) ?? []
        selectionStore.restoreSelection(from: vehicles)
    }
}
