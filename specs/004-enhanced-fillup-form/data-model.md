# Data Model: Enhanced Fill-Up Form

**Date**: 2026-04-20
**Storage**: SwiftData (iOS 17+)

## Entity Changes

### FillUp (enhanced)

Adds two optional fields to the existing FillUp entity.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| note | String? | Optional, max 200 characters | User-provided context for the fill-up |
| fuelType | FuelType? | Optional | Fuel type used for this specific fill-up (may differ from vehicle default) |

**Validation Rules**:
- `note` must be ≤200 characters (enforced at form level; truncated silently if exceeded)
- `fuelType` is informational — does not affect efficiency calculation logic

**Default Behavior** (nil fields):
- Legacy fill-ups get nil for both fields (no migration action needed)
- New fill-ups get fuelType prefilled from vehicle; note is user-entered or nil

## Migration Notes

- SwiftData handles lightweight migration automatically for new optional fields
- Existing FillUp records get nil for `note` and `fuelType`
- No data transformation needed on upgrade
