# Data Model: Vehicle Cost Categories

**Feature**: Non-fuel cost tracking on the Costs tab
**Date**: 2026-04-20

## New Entity: CostEntry

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | UUID | ✅ | Auto-generated on init |
| `date` | Date | ✅ | Defaults to current date |
| `category` | CostCategory | ✅ | One of 7 predefined values |
| `amount` | Double | ✅ | Must be > 0 |
| `note` | String? | ❌ | Optional free-text |
| `vehicle` | Vehicle? | ✅ (logical) | SwiftData relationship |
| `createdAt` | Date | ✅ | Auto-generated on init |

**Validation rules:**
- `amount` must be > 0
- `category` must be one of the predefined `CostCategory` enum cases
- `vehicle` must be set before saving (enforced by ViewModel)

**State transitions:** None — CostEntry is immutable after creation (edit is out of scope v1).

---

## New Enum: CostCategory

```
CostCategory (String, Codable, CaseIterable, Identifiable)
├── insurance   → "Insurance"
├── service     → "Service"
├── tolls       → "Tolls"
├── wash        → "Wash"
├── parking     → "Parking"
├── maintenance → "Maintenance"
└── tickets     → "Tickets"
```

Each case has a `displayName: String` computed property for UI display.

---

## Modified Entity: Vehicle

| Addition | Type | Notes |
|----------|------|-------|
| `costEntries` | [CostEntry] | Cascade-delete relationship; inverse of `CostEntry.vehicle` |

Existing Vehicle fields are unchanged.

---

## Relationships

```
Vehicle (1) ──── (many) FillUp      [existing, cascade delete]
Vehicle (1) ──── (many) CostEntry   [NEW, cascade delete]
CostEntry (many) ──── (1) Vehicle   [inverse]
```

---

## Computed / Derived Values

These are computed at ViewModel layer, not stored:

| Value | Source | Used In |
|-------|--------|---------|
| Total amount per vehicle | SUM(CostEntry.amount) WHERE vehicle == selected | CostListView header |
| Total per category | SUM(CostEntry.amount) GROUP BY category | Future summary view |
