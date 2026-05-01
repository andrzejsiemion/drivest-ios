# Research: UI Polish Improvements

**Feature**: 014-ui-polish
**Date**: 2026-04-21

---

## Current State Analysis

### US1 — Price Precision

**Current code** (`FillUpListView.swift:195`):
```swift
Text(String(format: "%.2f L @ %.3f/L", fillUp.volume, fillUp.pricePerLiter))
```
Price per litre is always formatted with `%.3f` regardless of currency. The entry's `currencyCode: String?` is available on `FillUp`.

**Decision**: Use `%.3f` when `fillUp.currencyCode == "EUR"`, else `%.2f`. No entry-level currency → `%.2f`.

**Note**: The spec says "PLN = 2dp, EUR = 3dp". After review, EUR is the only currency in the supported list that conventionally uses 3 decimal places for fuel. All others (PLN, GBP, USD, CHF, SEK, NOK, DKK, HUF, etc.) use 2dp.

---

### US2 — Settings toolbar `+` button

**Current code** (`SettingsView.swift:88-98`):
```swift
ToolbarItem(placement: .primaryAction) {
    Button {
        showAddCategory = true
    } label: {
        Image(systemName: "plus")
    }
}
```
And the categories section (`SettingsView.swift:58-63`):
```swift
Section("Categories") {
    ForEach(categories) { category in
        Label(category.name, systemImage: category.iconName)
    }
    .onDelete(perform: deleteCategories)
}
```

**Decision**: Remove the `ToolbarItem(.primaryAction)` `+` button. Add a tappable "Add Category" `Button` row at the bottom of the ForEach in the Categories section. Tapping it still sets `showAddCategory = true`. The existing `AddCategoryView` sheet is reused unchanged.

**iOS pattern**: Standard iOS Settings-style lists use inline add rows (e.g., a row with `Image(systemName: "plus.circle.fill")` and "Add Category" label). This is cleaner and contextually obvious.

---

### US3 — FillUpDetailView redundant labels

**Current code** (`FillUpDetailView.swift:18-34`):
```swift
Section("Date") {
    LabeledContent("Date") { ... }    // "Date" appears twice
}
Section("Vehicle") {
    LabeledContent("Vehicle", value: vehicle.name)  // "Vehicle" appears twice
}
Section("Odometer") {
    LabeledContent("Reading") { ... }  // "Odometer"/"Reading" are paired
}
```

**Decision**: Merge single-row sections. Instead of a section header + a row with the same label, use a single `Section` that groups related info together:
- Eliminate "Date" section header; put date directly in a merged header section or the "Fuel" section preamble.
- Best approach: combine Date, Vehicle, and Odometer into one compact section without a header (or with a neutral header), using concise `LabeledContent` labels that are not redundant.

**Proposed layout**:
```
[no header / or blank]
  Date          21 April 2026 at 21:22
  Vehicle       TETON
  Odometer      2200 km

Fuel
  Fuel Type     Petrol
  Price/Unit    2.00 zł
  Volume        10.00 L
  Total Cost    20.00 zł

Details
  Full Tank     Yes
  Efficiency    10.0 L/100km

Note
  [note text]
```
This removes 3 redundant section headers (Date, Vehicle, Odometer) and merges them into a single clean section.

---

## Decision Log

| # | Decision | Rationale | Alternatives |
|---|----------|-----------|--------------|
| 1 | EUR → 3dp price, all others → 2dp | Matches real-world fuel pricing conventions | Could make configurable — over-engineering for this use case |
| 2 | Inline "Add Category" row at bottom of ForEach | Contextually obvious, standard iOS pattern; no toolbar clutter | Edit mode button, swipe-to-add — both more complex |
| 3 | Merge Date/Vehicle/Odometer into one section without redundant headers | Removes 3 label repetitions, reduces visual noise, all data preserved | Keep sections but rename labels — still wastes a section header line per item |
