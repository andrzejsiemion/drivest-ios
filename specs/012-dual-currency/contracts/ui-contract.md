# UI Contract: Dual Currency Support

**Feature**: 012-dual-currency
**Date**: 2026-04-21

## Settings — Currency Section

```
┌─ Settings ─────────────────────────┐
│                                    │
│ ┌─ Currency ─────────────────────┐ │
│ │ Default Currency     [PLN zł ▼]│ │
│ │ Secondary Currency   [EUR €  ▼]│ │
│ │ Exchange Rate        [4.30   ] │ │
│ │ (1 EUR = 4.30 PLN)            │ │
│ └────────────────────────────────┘ │
│                                    │
│ ┌─ Categories ───────────────────┐ │
│ │ ...                            │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

## Add Fill-Up — Currency Toggle

```
┌─ Add Fill-Up ──────────────────────┐
│                                    │
│ ┌─ Fuel ─────────────────────────┐ │
│ │ Price per Unit     [1.65] [EUR]│ │
│ │ Volume             [35.0]      │ │
│ │ Total Cost         [57.75][EUR]│ │
│ │   ≈ 248.33 PLN                │ │
│ └────────────────────────────────┘ │
└────────────────────────────────────┘
```

- `[EUR]` is a tappable pill button — tap toggles to `[PLN]`
- `≈ 248.33 PLN` conversion line appears only when secondary currency is active
- Same pattern applies to Add Cost form's amount field

## Fill-Up List — Dual Display

```
┌──────────────────────────────────┐
│ 21 Apr 2026              57.75 € │
│ 35.0 L · 1950 km    ≈ 248.33 zł │
│ 7.2 L/100km            +150 km  │
└──────────────────────────────────┘
```

- Original currency amount on the right (primary)
- Converted equivalent below (secondary, dimmed) — only shown when currency differs from default

## Behavior Rules

| Action | Result |
|--------|--------|
| No currencies configured | No symbols shown anywhere, no toggle, identical to current behavior |
| Only default currency set | Currency symbol shown, no toggle (no secondary) |
| Both currencies set | Symbol shown, toggle available in forms |
| Tap currency pill | Toggles between default ↔ secondary |
| Save entry in secondary | Stores original amount, currency code, and exchange rate |
| View statistics | All amounts converted to default currency using per-entry rates |
| Change exchange rate | Only affects future entries |
