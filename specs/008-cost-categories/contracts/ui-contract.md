# UI Contract: Cost Categories Feature

**Feature**: Vehicle Cost Categories
**Date**: 2026-04-20

---

## CostListView (Costs Tab Root)

```
NavigationStack
└── Group
    ├── [Empty State — no cost entries]
    │   └── EmptyStateView
    │       ├── title: "No Costs Yet"
    │       ├── message: "Track insurance, maintenance, and other vehicle expenses."
    │       └── actionButton: "Add Cost" → presents AddCostView sheet
    │
    └── [Populated State — cost entries exist]
        ├── List
        │   ├── Section("Total")
        │   │   └── LabeledContent("Total Spent") { formatted amount }
        │   └── Section("Entries") [sorted by date descending]
        │       └── ForEach(CostEntry)
        │           └── CostRow
        │               ├── category icon + category name
        │               ├── formatted amount (right-aligned)
        │               ├── date (subheadline)
        │               └── note (caption, if present)
        │           └── .swipeActions(.trailing)
        │               └── Button(role: .destructive) "Delete"
        └── .toolbar
            └── ToolbarItem(.topBarTrailing)
                └── Button "+" → presents AddCostView sheet
```

### Multi-Vehicle Selector

If multiple vehicles exist, show vehicle picker in `.principal` toolbar position (mirrors FillUpListView pattern):

```
.toolbar
└── ToolbarItem(.principal)  [only when vehicles.count > 1]
    └── Picker("Vehicle", selection: $selectedVehicle) { vehicle names }
        └── .pickerStyle(.menu)
```

---

## AddCostView (Sheet)

```
NavigationStack
└── Form
    ├── Section("Category")
    │   └── Picker("Category", selection: $category)
    │       └── ForEach(CostCategory.allCases) { Text($0.displayName) }
    ├── Section("Amount")
    │   └── TextField("0.00", text: $amountText)
    │       └── .keyboardType(.decimalPad)
    ├── Section("Date")
    │   └── DatePicker("Date", selection: $date, displayedComponents: .date)
    └── Section("Note (Optional)")
        └── TextField("Add a note...", text: $noteText)
.navigationTitle("Add Cost")
.toolbar
    ├── ToolbarItem(.cancellationAction) → Button("Cancel") { dismiss }
    └── ToolbarItem(.confirmationAction) → Button("Save") { save; dismiss }
        └── .disabled(!isValid)
```

---

## Validation Contract

| Field | Rule | Error behaviour |
|-------|------|-----------------|
| amount | Must parse to Double > 0 | Save button disabled |
| category | Always has a default (first case) | N/A — always valid |
| date | Defaults to today | N/A — always valid |

---

## Transition Contract

| User Action | Result |
|-------------|--------|
| Tap "+" toolbar button | AddCostView sheet presented |
| Tap "Add Cost" in empty state | AddCostView sheet presented |
| Tap "Save" in AddCostView | Entry saved → sheet dismissed → list updated |
| Tap "Cancel" in AddCostView | Sheet dismissed, no change |
| Swipe left on CostRow | Delete button revealed |
| Tap "Delete" on CostRow | Entry deleted from list |
| Change vehicle in picker | List reloads for selected vehicle |
