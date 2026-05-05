import SwiftUI
import SwiftData
import UserNotifications

@main
struct DrivestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    private let selectionStore = VehicleSelectionStore()
    private let importCoordinator = ImportCoordinator()
    private let nbpService = NBPExchangeRateService()
    private let deepLinkRouter = DeepLinkRouter()
    @AppStorage("appAppearance") private var appearance: String = "system"
    @State private var showLanguageChangedAlert = false
    @State private var showSplash = true

    private static let languageCodeKey = "activeLanguageCode"

    init() {
        do {
            container = try ModelContainer(for: Vehicle.self, FillUp.self, CostEntry.self, CostCategory.self,
                                           EnergySnapshot.self, ElectricityBill.self, Reminder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        seedCategoriesIfNeeded()
        restoreVehicleSelection()
        NotificationDelegate.shared.router = deepLinkRouter
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(selectionStore)
                    .environment(importCoordinator)
                    .environment(nbpService)
                    .environment(deepLinkRouter)
                    .onChange(of: scenePhase) {
                        if scenePhase == .active {
                            Task { await nbpService.fetchIfNeeded() }
                            checkLanguageChange()
                            SnapshotPurgeService.purgeAndDeduplicate(context: container.mainContext)
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
            .onAppear { applyAppearance() }
            .onChange(of: appearance) { applyAppearance() }
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

    private func applyAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let style: UIUserInterfaceStyle = appearance == "light" ? .light : appearance == "dark" ? .dark : .unspecified
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = style
        }
    }

    private func restoreVehicleSelection() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Vehicle>()
        let vehicles = (try? context.fetch(descriptor)) ?? []
        selectionStore.restoreSelection(from: vehicles)
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    var router: DeepLinkRouter?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await MainActor.run {
            router?.handle(userInfo: userInfo)
        }
    }
}
