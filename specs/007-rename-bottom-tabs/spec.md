# Feature Specification: Rename Bottom Tab Labels

**Feature Branch**: `008-rename-bottom-tabs`
**Created**: 2026-04-20
**Status**: Draft
**Input**: User description: "modify bottom menu - change history to fuel, and vehicles to costs, and Summary to Statistics"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Renamed Bottom Tab Labels (Priority: P1)

As a user of the app, I want the bottom navigation tabs to use clearer, more meaningful labels — "Fuel" instead of "History", "Costs" instead of "Vehicles", and "Statistics" instead of "Summary" — so that the purpose of each tab is immediately obvious from the terminology.

**Why this priority**: All three renames are part of a single cohesive change to improve navigation clarity. This is the only deliverable and is required for the feature to be complete.

**Independent Test**: Launch the app, observe the bottom tab bar, and confirm all three labels match the new names without any functional regression.

**Acceptance Scenarios**:

1. **Given** I launch the app, **When** I view the bottom navigation bar, **Then** I see three tabs labelled "Fuel", "Costs", and "Statistics" (in that order).
2. **Given** I tap the "Fuel" tab, **When** the tab activates, **Then** the same fill-up history content that was previously under "History" is displayed.
3. **Given** I tap the "Costs" tab, **When** the tab activates, **Then** the same vehicle list content that was previously under "Vehicles" is displayed.
4. **Given** I tap the "Statistics" tab, **When** the tab activates, **Then** the same summary/analytics content that was previously under "Summary" is displayed.
5. **Given** the tab labels have been renamed, **When** I use the app on any supported device size, **Then** the labels are fully visible and not truncated.

---

### Edge Cases

- Tab icons remain unchanged — only the text labels are renamed.
- If the system uses the tab label for accessibility (VoiceOver), the updated labels must be used there too.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bottom navigation tab previously labelled "History" MUST be relabelled "Fuel".
- **FR-002**: The bottom navigation tab previously labelled "Vehicles" MUST be relabelled "Costs".
- **FR-003**: The bottom navigation tab previously labelled "Summary" MUST be relabelled "Statistics".
- **FR-004**: The "Fuel" and "Statistics" tab icons MUST remain unchanged. The "Costs" tab icon MUST be updated to a tools/wrench icon to better represent vehicle costs and maintenance.
- **FR-005**: Tab order (Fuel, Costs, Statistics) MUST remain unchanged.
- **FR-006**: All tab content and navigation behaviour MUST remain functionally identical after the rename.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three bottom tab labels display the new names ("Fuel", "Costs", "Statistics") on every supported device size without truncation.
- **SC-002**: 100% of existing tab functionality remains accessible and unbroken after the rename.
- **SC-003**: VoiceOver reads the updated tab names correctly.

## Assumptions

- The "Fuel" (fuel pump) and "Statistics" (bar chart) tab icons are unchanged. The "Costs" tab icon is updated from a car to a tools/wrench icon to better reflect vehicle running costs.
- The tab order is preserved: Fuel (first), Costs (second), Statistics (third).
- This is a purely cosmetic change with no impact on data models, navigation logic, or business rules.
- No localisation changes are in scope — only the default (English) strings are updated.
