# Feature Specification: Cost Category Settings

**Feature Branch**: `009-cost-category-settings`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "the ellipsis menu should also contain position named settings. Inside of settings user should be able to set categories for costs."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enable/Disable Cost Categories (Priority: P1)

A user wants to control which cost categories appear when logging an expense. They open the Settings screen (via the ··· ellipsis menu available on all tabs) and toggle categories on or off. Only enabled categories appear in the "Add Cost" category picker.

**Why this priority**: The core value of the feature — without the ability to toggle categories, the Settings screen has no purpose. This is the MVP and can be delivered and tested independently.

**Independent Test**: Open any tab → tap ··· → tap "Settings" → toggle "Tolls" off → go to Costs tab → tap + → open category picker → confirm "Tolls" is absent from the list.

**Acceptance Scenarios**:

1. **Given** the app is open on any tab, **When** the user taps ··· then "Settings", **Then** a Settings screen appears listing all cost categories (Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets) each with a toggle.
2. **Given** a category toggle is ON, **When** the user taps it to turn it OFF, **Then** the category is immediately hidden from the Add Cost category picker.
3. **Given** a category toggle is OFF, **When** the user taps it to turn it ON, **Then** the category reappears in the Add Cost category picker.
4. **Given** the user disables a category and closes Settings, **When** they reopen the app, **Then** the category remains disabled (preference is persisted).

---

### User Story 2 - Protect Existing Cost Entries (Priority: P2)

When a user disables a category that already has cost entries logged against it, those existing entries remain visible in the Costs list — only the picker for new entries is affected.

**Why this priority**: Data integrity. A user should never lose historical data by toggling a category off.

**Independent Test**: Log a cost entry with category "Wash" → go to Settings → disable "Wash" → return to Costs tab → confirm the existing "Wash" entry is still visible in the list.

**Acceptance Scenarios**:

1. **Given** one or more cost entries exist with category "Parking", **When** the user disables "Parking" in Settings, **Then** all existing "Parking" entries remain fully visible in the Costs list.
2. **Given** a category is disabled and has existing entries, **When** the user re-enables the category, **Then** the category reappears in the picker and existing entries are unaffected.

---

### Edge Cases

- What happens if the user disables all categories? The "Add Cost" picker shows an empty state or a prompt to enable at least one category in Settings.
- What happens if a future cost entry references a now-disabled category (e.g., imported data)? The entry is displayed using the category's name even if the category is toggled off.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The ··· ellipsis menu on all three tabs (Fuel, Costs, Statistics) MUST include a "Settings" menu item in addition to "Manage Vehicles".
- **FR-002**: Tapping "Settings" MUST open a dedicated Settings screen presented as a sheet or modal.
- **FR-003**: The Settings screen MUST display all cost categories (Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets) each with an enabled/disabled toggle.
- **FR-004**: Disabling a category MUST immediately remove it from the Add Cost category picker.
- **FR-005**: Enabling a category MUST immediately restore it in the Add Cost category picker.
- **FR-006**: Category enabled/disabled preferences MUST persist across app launches.
- **FR-007**: Existing cost entries with a disabled category MUST remain visible and unmodified in the Costs list.
- **FR-008**: If all categories are disabled, the Add Cost form MUST display a prompt directing the user to enable at least one category in Settings.

### Key Entities

- **CategoryPreference**: Represents a user's on/off preference for a single cost category. Attributes: category identifier, enabled flag. Persisted on-device.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can open Settings, disable a category, and confirm it is absent from the Add Cost picker — all within 30 seconds.
- **SC-002**: Category preferences survive an app restart — 100% of toggled states are restored correctly on next launch.
- **SC-003**: Zero existing cost entries are lost or modified when a category is disabled.
- **SC-004**: The Settings option is reachable from every tab without navigating away from the current tab first.

## Assumptions

- All 7 cost categories (Insurance, Service, Tolls, Wash, Parking, Maintenance, Tickets) are enabled by default on first launch.
- The Settings screen is scoped to cost category visibility only; other app-wide settings (currency, units, etc.) are out of scope for this feature.
- Category order in Settings matches the order they appear in the Add Cost picker (consistent ordering).
- The ··· menu already exists on all three tabs (implemented in a prior feature) — this feature adds a "Settings" item to that existing menu.
- "Manage Vehicles" remains in the ··· menu alongside the new "Settings" item.
