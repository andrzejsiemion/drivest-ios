# UI Contracts: Daily EV Energy Snapshot & Electricity Bill Reconciliation

**Branch**: `023-ev-energy-snapshot` | **Date**: 2026-04-25

These contracts describe the interface between Views and ViewModels. Each ViewModel exposes a defined set of published properties and actions; Views bind to these and must not access models or services directly.

---

## SnapshotHistoryViewModel

**File**: `Fuel/ViewModels/SnapshotHistoryViewModel.swift`

```swift
// Published state
var sections: [MonthSection<EnergySnapshot>]  // grouped by month, sorted descending
var isLoading: Bool
var errorMessage: String?

// Actions
func load(for vehicle: Vehicle)
func deleteSnapshot(_ snapshot: EnergySnapshot)
func triggerManualFetch(for vehicle: Vehicle) async
```

**Consumed by**: `EVSnapshotHistoryView`

---

## BillListViewModel

**File**: `Fuel/ViewModels/BillListViewModel.swift`

```swift
// Published state
var bills: [ElectricityBill]     // sorted by endDate descending
var isLoading: Bool
var errorMessage: String?

// Actions
func load(for vehicle: Vehicle)
func deleteBill(_ bill: ElectricityBill)
```

**Consumed by**: `ElectricityBillListView`

---

## AddBillViewModel

**File**: `Fuel/ViewModels/AddBillViewModel.swift`

```swift
// Form fields (bindable strings for TextFields)
var endDateText: Date
var totalKwhText: String
var totalCostText: String
var noteText: String

// Derived state
var isValid: Bool      // totalKwh > 0 && totalCost >= 0
var isSaving: Bool

// Actions
func save(for vehicle: Vehicle, in context: ModelContext) -> Bool
```

**Consumed by**: `AddElectricityBillView`

---

## EVSnapshotSettingsViewModel (or inline in SettingsView)

These settings are `@AppStorage` bindings exposed directly in the view — no dedicated ViewModel needed.

```swift
@AppStorage("snapshotFetchEnabled")   var fetchEnabled: Bool = true
@AppStorage("snapshotFetchFrequency") var fetchFrequency: String = "daily"
@AppStorage("snapshotFetchHour")      var fetchHour: Int = 5
@AppStorage("snapshotFetchMinute")    var fetchMinute: Int = 0
@AppStorage("snapshotLastFetchAt")    var lastFetchAt: Double = 0
```

Computed display: `var lastFetchDisplay: String` — formats `lastFetchAt` as "Today at 5:00 AM" or "Never".

"Fetch Now" calls `SnapshotFetchService.shared.fetchAll()` as a `Task`.

---

## SnapshotFetchService (Observable singleton)

**File**: `Fuel/Services/SnapshotFetchService.swift`

```swift
@Observable final class SnapshotFetchService {
    static let shared = SnapshotFetchService()

    var isFetching: Bool
    var lastError: String?

    // Fetches snapshots for all EV vehicles using their configured API
    func fetchAll(context: ModelContext) async

    // Fetch for a single vehicle (used by manual trigger and background handler)
    func fetch(vehicle: Vehicle, context: ModelContext) async throws
}
```

---

## BackgroundTaskManager

**File**: `Fuel/Services/BackgroundTaskManager.swift`

```swift
final class BackgroundTaskManager {
    static func register()                         // called once in FuelApp.init()
    static func scheduleNextFetch()                // submits BGAppRefreshTask
    static func handleFetch(_ task: BGAppRefreshTask, context: ModelContext)
}
```

---

## SnapshotPurgeService

**File**: `Fuel/Services/SnapshotPurgeService.swift`

```swift
enum SnapshotPurgeService {
    static func purgeExpired(context: ModelContext)  // deletes snapshots older than 6 months
}
```

Called on each `scenePhase == .active` transition in `FuelApp`.

---

## BillReconciliationService

**File**: `Fuel/Services/BillReconciliationService.swift`

```swift
enum BillReconciliationService {
    static func reconcile(_ bill: ElectricityBill,
                          snapshots: [EnergySnapshot],
                          previousBill: ElectricityBill?) -> ReconciliationResult
}

struct ReconciliationResult {
    let distanceKm: Double?
    let efficiencyKwhPer100km: Double?
    let costPerKm: Double?
    let hasSnapshotData: Bool
    let startSnapshotId: UUID?
    let endSnapshotId: UUID?
}
```

Pure function: no side effects, fully unit-testable.
