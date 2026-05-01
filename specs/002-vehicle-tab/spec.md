# Feature Specification: Vehicle Tab

**Feature Branch**: `002-vehicle-tab`
**Created**: 2026-04-20
**Status**: Clarified
**Input**: User description: "add vehicle tab - it should contain name, make, model, description field, distance units (km/miles) fuel type (pb95, pb 98, diesel, lpg, ev etc), fuel units (liters, kWH, ETC)"

## Clarifications

### Session 2026-04-20

- Q: Where should the Vehicle tab sit in the navigation? → A: Third tab in the tab bar: History, Vehicles, Summary.
- Q: How should efficiency be displayed for different fuel types/units? → A: User chooses efficiency display format per vehicle independently.
- Q: How should existing vehicles (created before this feature) handle new fields? → A: New fields left empty/nil until user manually edits each vehicle.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Add a New Vehicle (Priority: P1)

As a vehicle owner, I want to add a vehicle with detailed information (name, make, model, fuel type, and preferred units) so that the app can track fuel costs accurately for each of my vehicles with the correct measurements.

**Why this priority**: Without the ability to create a vehicle with its properties, no fill-ups can be logged or efficiency calculated with correct units.

**Independent Test**: Can be fully tested by navigating to the Vehicle tab, tapping "Add Vehicle", filling in the form fields, saving, and seeing the vehicle appear in the vehicle list.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** I tap the "Vehicles" tab (second tab in the tab bar), **Then** I see a list of my vehicles (or an empty state prompting me to add one).
2. **Given** I am on the Vehicle tab, **When** I tap the "Add" button, **Then** I see a form with fields: name, make, model, description, distance units, fuel type, fuel units, and efficiency display format.
3. **Given** I am on the add vehicle form, **When** I fill in the required fields (name) and tap "Save", **Then** the vehicle is persisted and appears in my vehicle list.
4. **Given** I am on the add vehicle form, **When** I select a fuel type (e.g., PB95, PB98, Diesel, LPG, EV, CNG), **Then** the selection is saved with the vehicle.
5. **Given** I am on the add vehicle form, **When** I choose distance units, **Then** I can select between kilometers and miles.
6. **Given** I am on the add vehicle form, **When** I choose fuel units, **Then** I can select from liters, gallons, or kWh (depending on fuel type context).
7. **Given** I am on the add vehicle form, **When** I choose an efficiency display format, **Then** I can select from L/100km, kWh/100km, MPG, or other unit combinations appropriate to the vehicle's fuel type and distance units.

---

### User Story 2 - Edit an Existing Vehicle (Priority: P2)

As a vehicle owner, I want to edit my vehicle's details so that I can correct mistakes or update information when things change (e.g., switching fuel type after a conversion).

**Why this priority**: Editing is essential for data accuracy but secondary to initial creation.

**Independent Test**: Can be tested by selecting an existing vehicle, tapping edit, changing a field, saving, and verifying the change persists.

**Acceptance Scenarios**:

1. **Given** I have a vehicle in my list, **When** I tap on it, **Then** I see the vehicle's details.
2. **Given** I am viewing a vehicle's details, **When** I tap "Edit", **Then** I can modify any field (name, make, model, description, distance units, fuel type, fuel units, efficiency display format).
3. **Given** I have changed a field, **When** I tap "Save", **Then** the changes are persisted and reflected in the vehicle list.
4. **Given** I have a pre-existing vehicle with nil/empty new fields, **When** I tap "Edit", **Then** I see the new fields (make, model, description, fuel type, fuel units, distance units, efficiency display format) ready to be filled in.

---

### User Story 3 - Delete a Vehicle (Priority: P3)

As a vehicle owner, I want to delete a vehicle I no longer own so that my vehicle list stays relevant.

**Why this priority**: Deletion is a housekeeping feature, less frequently needed than creation or editing.

**Independent Test**: Can be tested by swiping to delete a vehicle and confirming it is removed along with its fill-up history.

**Acceptance Scenarios**:

1. **Given** I have a vehicle in my list, **When** I swipe to delete or tap a delete action, **Then** I am asked to confirm deletion (since this removes all associated fill-ups).
2. **Given** I confirm deletion, **When** the action completes, **Then** the vehicle and all its fill-ups are permanently removed.
3. **Given** I cancel deletion, **When** the confirmation is dismissed, **Then** the vehicle remains unchanged.

---

### Edge Cases

- What happens when the user tries to save a vehicle without a name? → The Save button is disabled and the name field is highlighted as required.
- What happens when the user selects EV as fuel type? → Fuel units automatically default to kWh; liter/gallon options are hidden.
- What happens when the user changes distance units on a vehicle that already has fill-ups? → Existing fill-up data is not converted; only future entries use the new unit. A warning informs the user.
- What happens when the user deletes the only vehicle? → The app returns to an empty state on the Vehicle tab with guidance to add a new vehicle.
- What happens when the user selects a fuel type that doesn't match the fuel units? → The fuel units picker is filtered to show only compatible options (e.g., kWh only for EV; liters/gallons for combustion fuels).
- What happens when a pre-existing vehicle has nil/empty new fields? → The vehicle is displayed with its name only; new fields show as empty/unset. The user can edit the vehicle at any time to fill them in. Fill-ups for such vehicles continue to use the app's original defaults (km, liters, L/100km) until the user configures the vehicle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a dedicated Vehicle tab as the second tab in a three-tab bar layout (History, Vehicles, Summary).
- **FR-002**: System MUST allow users to add a new vehicle with the following fields: name (required), make (optional), model (optional), description (optional), distance units (required, default: km), fuel type (required, default: PB95), fuel units (required, default: liters), efficiency display format (required, default: L/100km).
- **FR-003**: System MUST support the following fuel types: PB95, PB98, Diesel, LPG, EV, CNG.
- **FR-004**: System MUST support the following distance units: kilometers, miles.
- **FR-005**: System MUST support the following fuel units: liters, gallons, kWh.
- **FR-006**: System MUST filter available fuel units based on selected fuel type (kWh only available for EV; liters and gallons for combustion/LPG/CNG fuels).
- **FR-007**: System MUST allow users to edit all vehicle fields after creation.
- **FR-008**: System MUST allow users to delete a vehicle with a confirmation prompt that warns about associated fill-up data loss.
- **FR-009**: System MUST cascade-delete all fill-ups when a vehicle is deleted.
- **FR-010**: System MUST display the vehicle list showing name, make/model, and fuel type for quick identification.
- **FR-011**: System MUST use the vehicle's configured distance and fuel units when displaying fill-up data and efficiency calculations for that vehicle.
- **FR-012**: System MUST allow users to choose an efficiency display format per vehicle (e.g., L/100km, kWh/100km, MPG).
- **FR-013**: Pre-existing vehicles (created before this feature) MUST retain all existing data; new fields (make, model, description, fuel type, fuel units, distance units, efficiency display format) MUST be nil/empty until the user edits them. Fill-ups for unconfigured vehicles continue using original app defaults.

### Key Entities

- **Vehicle** (enhanced): Represents a user's vehicle. Attributes: name, make (optional), model (optional), description (optional), distance units (optional, nil for legacy), fuel type (optional, nil for legacy), fuel units (optional, nil for legacy), efficiency display format (optional, nil for legacy), initial odometer, last-used timestamp. Has many fill-ups.
- **FuelType**: Enumeration of supported fuel types (PB95, PB98, Diesel, LPG, EV, CNG).
- **DistanceUnit**: Enumeration of supported distance measurements (kilometers, miles).
- **FuelUnit**: Enumeration of supported fuel volume/energy measurements (liters, gallons, kWh).
- **EfficiencyDisplayFormat**: Enumeration of supported efficiency display formats (L/100km, kWh/100km, MPG, etc.).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add a new vehicle with all fields in under 45 seconds.
- **SC-002**: Vehicle tab displays all registered vehicles within 1 second of navigation.
- **SC-003**: 100% of fuel type / fuel unit incompatible combinations are prevented by the UI (no invalid state can be saved).
- **SC-004**: Deleting a vehicle removes all associated data with zero orphaned records.
- **SC-005**: All vehicle fields are editable and changes persist immediately after save.
- **SC-006**: Pre-existing vehicles remain fully functional after upgrade with no data loss and no mandatory user action.

## Assumptions

- The app uses a three-tab navigation: History, Vehicles, Summary.
- The existing Vehicle model will be extended with new optional fields (make, model, description, distance units, fuel type, fuel units, efficiency display format) rather than creating a separate entity.
- Pre-existing vehicles retain nil/empty new fields until the user manually edits them; the app falls back to original defaults (km, liters, L/100km) for unconfigured vehicles.
- Efficiency display format is a per-vehicle user preference, independent of the underlying calculation.
- The fuel type list is extensible in future versions but fixed for v1.
- No VIN lookup or external database integration — all fields are manually entered.
