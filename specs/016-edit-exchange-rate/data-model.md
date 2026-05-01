# Data Model: Edit Exchange Rate

## Existing Entities — Changes Required

### FillUp (`Fuel/Models/FillUp.swift`)

**Current state**: Missing `currencyCode` and `exchangeRate` fields.

**Required additions** (migration-safe — nil-default optionals, no init change):
```
var currencyCode: String?    // ISO 4217 code of the currency used at recording time, e.g. "EUR"
var exchangeRate: Double?    // Rate to convert from currencyCode to defaultCurrency at recording time
var photoData: Data?         // Binary image data, compressed; nil when no photo attached
```

**Validation rules**:
- `exchangeRate` MUST be > 0 when not nil
- `currencyCode` is not editable after save (only exchange rate is editable via this feature)
- `photoData` is unrelated to this feature but was previously added and must be retained

---

### CostEntry (`Fuel/Models/CostEntry.swift`)

**Current state**: Missing `currencyCode`, `exchangeRate`, and `photoData` fields.

**Required additions** (same migration-safe pattern):
```
var currencyCode: String?    // ISO 4217 code of the currency used at recording time
var exchangeRate: Double?    // Rate to convert from currencyCode to defaultCurrency
var photoData: Data?         // Binary image data, compressed; nil when no photo attached
```

**Validation rules**: Same as FillUp.

---

## ViewModels — Changes Required

### EditFillUpViewModel (`Fuel/ViewModels/EditFillUpViewModel.swift`)

**Add**:
- `var exchangeRateText: String` — initialized from `String(format: "%.4f", fillUp.exchangeRate ?? 1.0)` when `fillUp.exchangeRate != nil`, otherwise `""`
- `var hasSecondaryCurrency: Bool` — computed: `fillUp.currencyCode != nil`
- `var exchangeRate: Double?` — computed: parsed from `exchangeRateText` using locale-aware parsing
- `isValid` guard: include `!hasSecondaryCurrency || (exchangeRate != nil && exchangeRate! > 0)`
- In `save()`: `fillUp.exchangeRate = hasSecondaryCurrency ? exchangeRate : fillUp.exchangeRate`

---

### EditCostViewModel (`Fuel/ViewModels/EditCostViewModel.swift`)

**Add**:
- `var exchangeRateText: String` — initialized from `costEntry.exchangeRate`
- `var hasSecondaryCurrency: Bool` — computed: `costEntry.currencyCode != nil`
- `var exchangeRate: Double?` — computed: locale-aware parse of `exchangeRateText`
- `isValid` guard: include exchange rate validation
- In `save()`: `costEntry.exchangeRate = hasSecondaryCurrency ? exchangeRate : costEntry.exchangeRate`

---

## Views — Changes Required

### EditFillUpView (`Fuel/Views/EditFillUpView.swift`)

Add a conditional `Section` after the Fuel section (or within it) that appears only when `fillUp.currencyCode != nil`:
```
Section("Exchange Rate") {
    HStack {
        Text("Rate (\(fillUp.currencyCode!) → \(defaultCurrency))")
        Spacer()
        TextField("1.0000", text: $vm.exchangeRateText)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
    }
}
```

### EditCostView (`Fuel/Views/EditCostView.swift`)

Same pattern as EditFillUpView, conditional on `costEntry.currencyCode != nil`.

---

## No Schema Version Bump Required

SwiftData automatically handles adding optional properties with nil defaults. Existing records will have `nil` for `currencyCode`, `exchangeRate`, and `photoData`, which is the correct default (no currency conversion, no photo).
