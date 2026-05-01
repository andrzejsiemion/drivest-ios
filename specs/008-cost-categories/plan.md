# Implementation Plan: Vehicle Cost Categories

**Branch**: `008-cost-categories` | **Date**: 2026-04-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/008-cost-categories/spec.md`

## Summary

Replace the Costs tab content with a new non-fuel cost tracking feature. Users can log cost entries by category (Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets), amount, and date — associated with a specific vehicle. Adds a new `CostEntry` SwiftData model, two ViewModels, two Views, and wires everything into the existing app container and tab bar.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData (existing)
**Storage**: SwiftData — new `CostEntry` model added via automatic lightweight migration
**Testing**: XCTest / XCUITest
**Target Platform**: iOS 17+
**Project Type**: Mobile app (SwiftUI, MVVM, `@Observable`)
**Performance Goals**: N/A — local data only, small dataset
**Constraints**: No new third-party dependencies; follow existing MVVM + `@Observable` pattern
**Scale/Scope**: 6 new files, 3 modified files

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Single-responsibility ViewModels; pattern mirrors FillUp implementation |
| II. Simple UX | ✅ Pass | Add entry in ≤4 taps; empty state guides first use |
| III. Responsive Design | ✅ Pass | SwiftUI Form/List adapt to all device sizes |
| IV. Minimal Dependencies | ✅ Pass | SwiftData + SwiftUI only |
| iOS Platform Constraints | ✅ Pass | Swift 5.9+, iOS 17+; automatic SwiftData migration |

**Gate**: No violations — implementation approved.

## Project Structure

### Documentation (this feature)

```text
specs/008-cost-categories/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Architecture decisions
├── data-model.md        # CostEntry entity + CostCategory enum
├── contracts/
│   └── ui-contract.md   # CostListView + AddCostView UI contracts
└── tasks.md             # Phase 2 output (/speckit-tasks — not yet created)
```

### Source Code (repository root)

```text
Fuel/
├── Models/
│   ├── CostCategory.swift      ← NEW  (enum: 7 categories)
│   ├── CostEntry.swift         ← NEW  (@Model: id, date, category, amount, note?, vehicle?)
│   └── Vehicle.swift           ← MODIFIED (add costEntries relationship)
│
├── ViewModels/
│   ├── CostListViewModel.swift ← NEW  (@Observable: fetch/delete per vehicle)
│   └── AddCostViewModel.swift  ← NEW  (@Observable: form state + save)
│
├── Views/
│   ├── CostListView.swift      ← NEW  (Costs tab root: list + empty state + toolbar)
│   ├── AddCostView.swift       ← NEW  (sheet: form for new cost entry)
│   └── ContentView.swift       ← MODIFIED (Costs tab: VehicleListView → CostListView)
│
└── FuelApp.swift               ← MODIFIED (add CostEntry.self to modelContainer)
```

**Structure Decision**: Single project, existing SwiftUI MVVM layout. New files follow established naming and directory conventions.

## Implementation Patterns to Follow

### Model pattern (follow CostEntry.swift after FillUp.swift)

```swift
@Model
final class CostEntry {
    var id: UUID
    var date: Date
    var category: CostCategory
    var amount: Double
    var note: String?
    var createdAt: Date
    var vehicle: Vehicle?

    init(date: Date, category: CostCategory, amount: Double, note: String? = nil) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.amount = amount
        self.note = note
        self.createdAt = Date()
    }
}
```

### Vehicle relationship addition

```swift
// In Vehicle.swift — add alongside existing fillUps relationship:
@Relationship(deleteRule: .cascade, inverse: \CostEntry.vehicle)
var costEntries: [CostEntry] = []
```

### FuelApp model container update

```swift
.modelContainer(for: [Vehicle.self, FillUp.self, CostEntry.self])
```

### ViewModel pattern (follow AddFillUpViewModel.swift)

```swift
@Observable
final class AddCostViewModel {
    private let modelContext: ModelContext
    var date: Date = Date()
    var category: CostCategory = .insurance
    var amountText: String = ""
    var noteText: String = ""
    var selectedVehicle: Vehicle?

    var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }
    var isValid: Bool { (amount ?? 0) > 0 }

    func save() {
        guard let amount, let vehicle = selectedVehicle else { return }
        let entry = CostEntry(date: date, category: category, amount: amount,
                              note: noteText.isEmpty ? nil : noteText)
        entry.vehicle = vehicle
        modelContext.insert(entry)
        try? modelContext.save()
    }
}
```

## Complexity Tracking

No constitution violations — table not required.
