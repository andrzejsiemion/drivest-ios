# Research: Fill-Up Detail & Edit

**Date**: 2026-04-20
**Status**: Complete — no NEEDS CLARIFICATION items

## Decisions

### 1. Detail View Approach

- **Decision**: Create a dedicated `FillUpDetailView` as a read-only screen with an Edit toolbar button.
- **Rationale**: Separating detail (read) from edit (write) follows iOS conventions. Users see all data before deciding to edit. Navigation push from list row.
- **Alternatives considered**: Inline editing in the list (too cramped), direct edit on tap (risky — accidental edits), sheet modal for detail (breaks navigation flow).

### 2. Edit View Strategy

- **Decision**: Create a separate `EditFillUpView` with its own `EditFillUpViewModel`. The form mirrors the add fill-up layout but pre-populates all fields from the existing FillUp. Vehicle selector is hidden (not editable).
- **Rationale**: Reusing AddFillUpView would require significant conditional logic (add vs edit modes, different save paths). A dedicated edit view is cleaner. The auto-calculation logic can be extracted or duplicated (it's ~30 lines).
- **Alternatives considered**: Reuse AddFillUpView with mode flag (adds complexity, violates SRP), edit inline on detail screen (not enough space for auto-calc UX).

### 3. Efficiency Recalculation on Edit

- **Decision**: After saving an edit, call `EfficiencyCalculator.recalculateAll(for:allFillUps:)` for the vehicle. This recalculates efficiency for ALL full-tank entries of that vehicle, handling cascading changes.
- **Rationale**: Editing odometer or volume affects efficiency for the edited entry AND all subsequent entries. A full recalculation is simplest and correct — the dataset is small (per-vehicle, local only).
- **Alternatives considered**: Incremental recalc from edited entry forward (optimization not needed for small datasets).

### 4. Odometer Validation on Edit

- **Decision**: On save, validate that the edited odometer reading maintains monotonic ordering relative to adjacent fill-ups (previous and next by date).
- **Rationale**: Unlike adding (where we only check against the last entry), editing can break ordering in both directions. Must check both neighbors.
- **Alternatives considered**: Skip validation (risks corrupted efficiency calculations), auto-sort by odometer (changes user's date ordering).
