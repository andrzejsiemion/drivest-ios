# Data Model: Fill-Up Detail & Edit

**Date**: 2026-04-20
**Storage**: SwiftData (iOS 17+)

## Entity Changes

No model changes needed. This feature operates on the existing FillUp entity with all its current fields (including note and fuelType from feature 004).

### FillUp (existing — read + write)

All existing fields are displayed on the detail screen and editable on the edit screen:

| Field | Display on Detail | Editable |
|-------|-------------------|----------|
| date | Yes | Yes |
| vehicle | Yes (name) | No (read-only) |
| odometerReading | Yes | Yes (with validation) |
| fuelType | Yes (if set) | Yes |
| pricePerLiter | Yes | Yes (auto-calc) |
| volume | Yes | Yes (auto-calc) |
| totalCost | Yes | Yes (auto-calc) |
| isFullTank | Yes | Yes |
| efficiency | Yes (if calculated) | No (derived) |
| note | Yes (if present) | Yes |

## Migration Notes

No migration needed — no model changes.
