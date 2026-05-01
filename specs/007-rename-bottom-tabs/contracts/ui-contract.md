# UI Contract: Bottom Tab Bar Labels

**Feature**: Rename Bottom Tab Labels
**Date**: 2026-04-20

## Tab Bar Contract

```
TabView
├── Tab 1
│   ├── label: "Fuel"          (was: "History")
│   ├── icon:  fuelpump        (unchanged)
│   └── content: FillUpListView
│       └── navigationTitle: "Fuel"   (was: "History")
│
├── Tab 2
│   ├── label: "Costs"         (was: "Vehicles")
│   ├── icon:  wrench.and.screwdriver  (was: car.2)
│   └── content: VehicleListView
│       └── navigationTitle: "Costs"  (was: "Vehicles")
│
└── Tab 3
    ├── label: "Statistics"    (was: "Summary")
    ├── icon:  chart.bar       (unchanged)
    └── content: SummaryTabView / SummaryView
        └── navigationTitle: "Statistics"  (was: "Summary")
```

## String Change Map

| Location | Old String | New String |
|----------|-----------|-----------|
| `ContentView.swift` tabItem 1 | `"History"` | `"Fuel"` |
| `ContentView.swift` tabItem 2 label | `"Vehicles"` | `"Costs"` |
| `ContentView.swift` tabItem 2 icon | `car.2` | `wrench.and.screwdriver` |
| `ContentView.swift` tabItem 3 | `"Summary"` | `"Statistics"` |
| `ContentView.swift` navigationTitle (inline SummaryTabView) | `"Summary"` | `"Statistics"` |
| `FillUpListView.swift` navigationTitle | `"History"` | `"Fuel"` |
| `VehicleListView.swift` navigationTitle | `"Vehicles"` | `"Costs"` |
| `SummaryView.swift` navigationTitle | `"Summary"` | `"Statistics"` |

## Unchanged

- Tab icons for Fuel (`fuelpump`) and Statistics (`chart.bar`)
- Tab order
- All navigation behaviour and content
- Internal Swift type names (`VehicleListView`, `SummaryViewModel`, etc.)
- Empty state messages that reference tab content context
