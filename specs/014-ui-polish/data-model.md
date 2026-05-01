# Data Model: UI Polish Improvements

**Feature**: 014-ui-polish
**Date**: 2026-04-21

---

## No Model Changes Required

All three improvements are purely view-layer changes. No new model fields, no new entities, no migrations.

---

## Relevant Existing Fields

### FillUp (used for price formatting)

| Field | Type | Relevance |
|-------|------|-----------|
| `pricePerLiter` | `Double` | The value being formatted — 2dp or 3dp depending on currency |
| `currencyCode` | `String?` | Determines precision: `"EUR"` → 3dp, anything else (including nil) → 2dp |

---

## View State Changes

### SettingsView

- Remove: `ToolbarItem(.primaryAction)` `+` button
- Add: Inline `Button` row at the bottom of the Categories `ForEach`, triggering the existing `showAddCategory` state

### FillUpDetailView

- Merge three single-row sections (Date, Vehicle, Odometer) into one combined section
- Remove redundant section headers that duplicate the row label
- No new state properties needed
