# Research: Vehicle Tab

**Date**: 2026-04-20
**Status**: Complete — no NEEDS CLARIFICATION items identified

## Decisions

### 1. Vehicle Model Migration Strategy

- **Decision**: Add new fields as optional properties (nil by default) to the existing `Vehicle` SwiftData model. No data migration script needed — SwiftData handles lightweight migrations for added optional fields automatically.
- **Rationale**: SwiftData supports automatic schema migration when adding optional stored properties. Pre-existing vehicles get nil for new fields, which matches the clarification that legacy vehicles remain unchanged until edited.
- **Alternatives considered**: Versioned schema migration with default values (unnecessary complexity for optional fields), separate "VehicleProfile" entity (violates single-entity simplicity).

### 2. Enum Storage in SwiftData

- **Decision**: Store enums as raw String values in SwiftData. Define enums conforming to `String, Codable, CaseIterable` for picker integration.
- **Rationale**: SwiftData natively supports `Codable` enum storage. String raw values are human-readable in debug and survive refactoring better than Int-based enums.
- **Alternatives considered**: Int raw values (less debuggable), separate lookup table (over-engineered for fixed enum sets).

### 3. Fuel Unit Filtering Logic

- **Decision**: Define a static mapping from FuelType → [FuelUnit] that the picker consumes. When fuel type changes, reset fuel unit to the first compatible option if the current selection is incompatible.
- **Rationale**: Simple, testable, and deterministic. The mapping is: EV → [kWh], all others → [liters, gallons]. No runtime computation needed.
- **Alternatives considered**: Dynamic filtering at the view layer only (harder to test), protocol-based compatibility check (over-abstract for 2 cases).

### 4. Efficiency Display Format Options

- **Decision**: Support L/100km, kWh/100km, MPG (US), and km/L as display formats. Store as enum on the Vehicle. The underlying calculation always computes in base units (liters + km), then converts for display.
- **Rationale**: These are the globally common formats. Computing in base units and converting at display time avoids storing derived data and keeps the calculation service simple.
- **Alternatives considered**: Store efficiency in the user's chosen format (makes comparisons and format changes harder), compute on-demand from raw fill-up data (wasteful, already calculated at save).

### 5. Tab Navigation Architecture

- **Decision**: Introduce a `ContentView` with a `TabView` containing three tabs: FillUpListView (History), VehicleListView (Vehicles), SummaryView (Summary). The current app entry point will use ContentView instead of directly showing FillUpListView.
- **Rationale**: TabView is the standard iOS pattern for peer-level navigation. Three tabs is well within Apple HIG recommendations (max 5). Keeps all primary features at depth 0.
- **Alternatives considered**: NavigationSplitView sidebar (iPad-oriented, over-complex for phone-first), keeping vehicles only accessible from fill-up form (buries the feature).

### 6. Backward Compatibility for Fill-Ups

- **Decision**: When a vehicle has nil unit fields, the EfficiencyCalculator and fill-up display default to km/liters/L/100km (the v1 assumptions). No code path should crash on nil — always fall back gracefully.
- **Rationale**: Matches clarification that pre-existing vehicles work unchanged. Users who never configure units get the same experience as before this feature.
- **Alternatives considered**: Force migration on app launch (rejected by user — chose "leave nil until edited"), show degraded UI for unconfigured vehicles (confusing).
