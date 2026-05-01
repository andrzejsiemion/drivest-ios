# Research: Enhanced Fill-Up Form

**Date**: 2026-04-20
**Status**: Complete — no NEEDS CLARIFICATION items

## Decisions

### 1. FillUp Fuel Type Field

- **Decision**: Add optional `fuelType: FuelType?` to FillUp model. Prefilled from vehicle settings on form open; editable for one-off overrides. Nil for legacy entries.
- **Rationale**: Records actual fuel used per fill-up (may differ from vehicle default). Enables future per-fill-up analytics by fuel type.
- **Alternatives considered**: Always use vehicle's fuel type (loses one-off override data), store as raw string (loses type safety).

### 2. Note Field Storage

- **Decision**: Add optional `note: String?` to FillUp model. Max 200 characters enforced at the form level.
- **Rationale**: Short contextual notes (station name, trip type) add user value without complex UI. 200 chars is sufficient for a sentence without encouraging long-form text.
- **Alternatives considered**: Separate "tags" system (over-engineered for v1), unlimited text (encourages misuse, complicates list display).

### 3. Form Field Order

- **Decision**: Top-to-bottom: Vehicle selector → Odometer → Fuel Type → Price per unit → Volume → Total Cost → Full Tank toggle → Note.
- **Rationale**: Matches the user's natural flow at a gas station: which car, what the odometer says, what fuel, how much it costs, total, and finally any notes. Vehicle first because it drives fuel type prefill.
- **Alternatives considered**: Keep existing order (misses prefill UX opportunity), note at top (illogical, notes are reflective not pre-planned).

### 4. Prefill Behavior

- **Decision**: On form open and on vehicle change, set fuel type to `vehicle.fuelType`. If vehicle has no fuel type (nil), leave fuel type field empty. User can always override.
- **Rationale**: Reduces data entry while preserving flexibility. Instant prefill with no async operation needed (local SwiftData read).
- **Alternatives considered**: Lock fuel type to vehicle (too rigid), don't prefill (defeats the purpose).
