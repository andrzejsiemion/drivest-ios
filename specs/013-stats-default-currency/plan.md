# Implementation Plan: Statistics in Default Currency with Historical Exchange Rates

**Branch**: `013-stats-default-currency` | **Date**: 2026-04-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/013-stats-default-currency/spec.md`

## Summary

Statistics views must display all aggregated cost totals with the default currency symbol, making it unambiguous which currency the figures represent. The historical exchange rate accuracy (using per-entry stored rates, never the current Settings rate) is already correctly implemented from feature 012-dual-currency. The remaining work is purely a display concern: reading the configured default currency and appending its symbol to cost figures in `SummaryTabView` (main Statistics tab) and `SummaryView` (legacy modal).

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, SwiftData, Charts (Apple frameworks only)
**Storage**: SwiftData (`FillUp`, `CostEntry` models); UserDefaults (`@AppStorage` for currency settings)
**Testing**: XCTest
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iPhone/iPad)
**Performance Goals**: Instant display on Statistics tab load
**Constraints**: No server dependency; fully offline; no third-party packages
**Scale/Scope**: Single-user, per-device data; typically <1000 fill-up entries

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Clean Code | ✅ Pass | Changes are additive and minimal; `@AppStorage` reads are in the view layer (display concern) |
| II. Simple UX | ✅ Pass | Currency label is a suffix on existing rows — no new interaction required |
| III. Responsive Design | ✅ Pass | Currency symbol is short text; no layout impact |
| IV. Minimal Dependencies | ✅ Pass | No new dependencies; uses only `@AppStorage` and `CurrencyDefinition` already in project |
| iOS Platform Constraints | ✅ Pass | SwiftUI, SwiftData, iOS 17+, MVVM — no violations |
| Development Workflow | ✅ Pass | UI changes must be verified on iPhone SE + iPhone 17 Pro Max simulators |

No gate violations. No Complexity Tracking section needed.

## Project Structure

### Documentation (this feature)

```text
specs/013-stats-default-currency/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (affected files)

```text
Fuel/
├── Views/
│   ├── ContentView.swift          # SummaryTabView + SummaryContentSection
│   └── SummaryView.swift          # Legacy statistics modal
└── ViewModels/
    └── SummaryViewModel.swift     # No changes needed (already correct)
```

**Structure Decision**: Single iOS project; only two view files require modification. No new files.

## Implementation Plan

### Phase 1: Currency Label in SummaryTabView

**File**: `Fuel/Views/ContentView.swift`

**Changes to `SummaryTabView`**:
- Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""`
- Compute `var defaultCurrencySymbol: String? { CurrencyDefinition.currency(for: defaultCurrencyCode)?.symbol }`
- Pass `currencySymbol: defaultCurrencySymbol` to `SummaryContentSection`

**Changes to `SummaryContentSection`**:
- Add parameter `currencySymbol: String? = nil`
- On the "Total Spent" `LabeledContent`, display `"\(String(format: "%.2f", viewModel.totalCost)) \(symbol)"` when symbol is non-nil, otherwise plain `"%.2f"`
- On monthly breakdown cost display, same pattern

### Phase 2: Currency Label in SummaryView (legacy modal)

**File**: `Fuel/Views/SummaryView.swift`

**Changes**:
- Add `@AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""`
- Compute `private var currencySymbol: String? { CurrencyDefinition.currency(for: defaultCurrencyCode)?.symbol }`
- Update "Total Spent" `LabeledContent` to append symbol when non-nil
- Update monthly breakdown cost `Text` to append symbol when non-nil

## Design Decisions

1. **Currency symbol placement**: Trailing suffix in the value text (e.g., "415.00 zł"). Consistent with the pattern in `FillUpRow` and `CostRow`.
2. **No symbol when unconfigured**: When `defaultCurrencyCode` is empty, `CurrencyDefinition.currency(for:)` returns nil and no symbol is shown. Backward compatible.
3. **View layer reads @AppStorage**: Currency code is a settings concern, not a statistics-computation concern. The ViewModel aggregates; the view formats.
4. **SummaryViewModel untouched**: All conversion logic is already correct. No changes needed.
