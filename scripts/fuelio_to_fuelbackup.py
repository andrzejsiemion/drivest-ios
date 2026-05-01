#!/usr/bin/env python3
"""
fuelio_to_fuelbackup.py
=======================
Converts a Fuelio CSV export to a .drivestbackup JSON file for the Fuel app.

Usage:
    python3 fuelio_to_fuelbackup.py <input.csv> [output.drivestbackup]

    If output path is omitted, the file is saved next to the CSV with the
    same base name and a .drivestbackup extension.

Example:
    python3 fuelio_to_fuelbackup.py ~/Downloads/V90_export.csv

Bug fixed vs. previous manual import
--------------------------------------
Fuelio CSV rows are not guaranteed to be in chronological + odometer order.
When two fill-ups share the same date but the one with the LOWER odometer
appeared later in the CSV, the import produced a downward "dip" in the
odometer chart. This script sorts all fill-ups by (date asc, odometer asc)
before writing the backup, which eliminates the dip.

Fuelio FuelType code → Fuel app fuelType mapping
--------------------------------------------------
  0   = Petrol (generic)       → pb95
  100 = Super                  → pb98
  110 = E10 / Super E10        → pb98  (V90 / premium cars in Poland)
  200 = Diesel                 → diesel
  210 = Diesel E               → diesel
  300 = LPG                    → lpg
  400 = CNG                    → cng
  500 = Electric               → ev

Adjust FUEL_TYPE_MAP below if your vehicle uses a different grade.

Currency
--------
Fuelio stores the total cost already converted to the home currency.
Foreign purchases appear with a note like "(34.39 EURO 4.3)", meaning
34.39 EUR at 4.30 PLN/EUR = 147.88 PLN.  The script keeps the note
as-is and sets currencyCode=PLN / exchangeRate=1.0 so the app shows
the correct PLN amount. You can post-edit individual fill-ups in the
app if you want to record the original foreign currency instead.
"""

import csv
import json
import re
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Mapping tables
# ---------------------------------------------------------------------------

FUEL_TYPE_MAP: dict[str, str] = {
    "0":   "pb95",
    "100": "pb98",
    "110": "pb98",   # E10/Super E10 — common premium blend for V90 in Poland
    "200": "diesel",
    "210": "diesel",
    "300": "lpg",
    "400": "cng",
    "500": "ev",
}

DIST_UNIT_MAP: dict[str, str] = {
    "0": "km",
    "1": "mi",
}

FUEL_UNIT_MAP: dict[str, str] = {
    "0": "l",
    "1": "gal",
    "2": "gal",
    "3": "kwh",
}

EFFICIENCY_FORMAT_MAP: dict[str, str] = {
    "km": "l100km",
    "mi": "mpg",
}

# Pattern: "(34.39 EURO 4.3)" or "(57.83 EUR 4.3)" embedded in Fuelio notes
FOREIGN_CURRENCY_RE = re.compile(
    r"\(\s*[\d.]+\s+[A-Z]+\s+[\d.]+\s*\)"
)


# ---------------------------------------------------------------------------
# CSV parsing
# ---------------------------------------------------------------------------

def parse_fuelio_csv(filepath: Path) -> dict[str, list[dict]]:
    """
    Parse a Fuelio multi-section CSV into a dict keyed by section name.
    Each value is a list of row dicts (header-keyed).
    """
    sections: dict[str, list[dict]] = {}
    current: str | None = None
    header: list[str] | None = None
    rows: list[dict] = []

    with filepath.open(newline="", encoding="utf-8-sig") as fh:
        reader = csv.reader(fh)
        for row in reader:
            if not row or all(cell == "" for cell in row):
                continue
            cell0 = row[0].strip()
            if cell0.startswith("##"):
                # flush previous section
                if current is not None and header is not None:
                    sections[current] = rows
                current = cell0[2:].strip()
                header = None
                rows = []
            elif header is None and current is not None:
                header = row
            elif current is not None and header is not None:
                if len(row) >= len(header):
                    rows.append(dict(zip(header, row)))

    if current is not None and header is not None:
        sections[current] = rows

    return sections


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def new_id() -> str:
    return str(uuid.uuid4()).lower()

def to_iso(date_str: str, fmt: str = "%Y-%m-%d") -> str:
    """Return midnight-UTC ISO-8601 string for a date string."""
    dt = datetime.strptime(date_str.strip(), fmt)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")

def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def safe_float(value: str, default: float = 0.0) -> float:
    try:
        return float(value) if value.strip() else default
    except (ValueError, AttributeError):
        return default

def map_fuel(fuelio_code: str) -> str:
    return FUEL_TYPE_MAP.get(fuelio_code.strip(), "pb95")


# ---------------------------------------------------------------------------
# Conversion
# ---------------------------------------------------------------------------

def convert(csv_path: Path, output_path: Path | None = None) -> None:
    sections = parse_fuelio_csv(csv_path)

    # ---- Vehicle ----------------------------------------------------------
    vehicle_rows = sections.get("Vehicle", [])
    if not vehicle_rows:
        print("ERROR: No ## Vehicle section found.", file=sys.stderr)
        sys.exit(1)

    vr = vehicle_rows[0]
    dist_unit   = DIST_UNIT_MAP.get(vr.get("DistUnit", "0"), "km")
    fuel_unit   = FUEL_UNIT_MAP.get(vr.get("FuelUnit", "0"), "l")
    tank1_type  = vr.get("Tank1Type", "110")
    tank2_type  = vr.get("Tank2Type", "0")
    tank_count  = int(safe_float(vr.get("TankCount", "1")))
    vin         = vr.get("VIN", "").strip() or None
    ts          = now_iso()

    vehicle: dict = {
        "id":                     new_id(),
        "name":                   vr.get("Name", "Vehicle").strip(),
        "make":                   vr.get("Make", "").strip() or None,
        "model":                  vr.get("Model", "").strip() or None,
        "descriptionText":        vr.get("Description", "").strip() or None,
        "initialOdometer":        0.0,
        "distanceUnit":           dist_unit,
        "fuelType":               map_fuel(tank1_type),
        "fuelUnit":               fuel_unit,
        "efficiencyDisplayFormat": EFFICIENCY_FORMAT_MAP.get(dist_unit, "l100km"),
        "secondTankFuelType":     None,
        "secondTankFuelUnit":     None,
        "vin":                    vin,
        "photoData":              None,
        "lastUsedAt":             ts,
        "createdAt":              ts,
    }

    if tank_count >= 2 and tank2_type not in ("0", ""):
        fu2_unit = FUEL_UNIT_MAP.get(vr.get("FuelUnitTank2", "0"), "l")
        vehicle["secondTankFuelType"] = map_fuel(tank2_type)
        vehicle["secondTankFuelUnit"] = fu2_unit

    # ---- Fill-ups ---------------------------------------------------------
    log_rows = sections.get("Log", [])
    fill_ups: list[dict] = []

    for row in log_rows:
        date_str = row.get("Date", "").strip()
        if not date_str:
            continue

        odo          = safe_float(row.get("Odo (km)", "0"))
        volume       = safe_float(row.get("Fuel (l)", "0"))
        is_full      = row.get("Full", "0").strip() == "1"
        total_cost   = safe_float(row.get("Price", "0"))
        price_per_l  = safe_float(row.get("VolumePrice", "0"))
        eff_raw      = safe_float(row.get("l/100km", "0"))
        efficiency   = eff_raw if (is_full and eff_raw > 0) else None
        fuel_code    = row.get("FuelType", tank1_type).strip()
        note_raw     = row.get("Notes", "").strip()
        note         = note_raw or None

        fill_ups.append({
            "id":             new_id(),
            "date":           to_iso(date_str),
            "createdAt":      to_iso(date_str),
            "odometerReading": odo,
            "volume":         volume,
            "totalCost":      total_cost,
            "pricePerLiter":  price_per_l,
            "isFullTank":     is_full,
            "efficiency":     efficiency,
            "fuelType":       map_fuel(fuel_code),
            "currencyCode":   "PLN",
            "exchangeRate":   1.0,
            "discount":       None,
            "note":           note,
            "photos":         [],
        })

    # KEY FIX: sort by date then odometer to eliminate same-date dips
    fill_ups.sort(key=lambda fu: (fu["date"], fu["odometerReading"]))

    # ---- Costs ------------------------------------------------------------
    cost_rows = sections.get("Costs", [])
    cost_entries: list[dict] = []

    for row in cost_rows:
        date_str = row.get("Date", "").strip()
        if not date_str:
            continue
        cost_entries.append({
            "id":           new_id(),
            "date":         to_iso(date_str),
            "createdAt":    to_iso(date_str),
            "title":        row.get("CostTitle", "Cost").strip(),
            "amount":       safe_float(row.get("Cost", "0")),
            "currencyCode": "PLN",
            "exchangeRate": 1.0,
            "categoryName": None,
            "note":         row.get("Notes", "").strip() or None,
            "attachments":  [],
        })

    # ---- Envelope ---------------------------------------------------------
    envelope = {
        "version":         1,
        "appVersion":      "1.0",
        "exportedAt":      now_iso(),
        "vehicle":         vehicle,
        "fillUps":         fill_ups,
        "costEntries":     cost_entries,
        "chargingSessions": [],
        "energySnapshots": [],
        "electricityBills": [],
    }

    # ---- Write ------------------------------------------------------------
    if output_path is None:
        output_path = csv_path.with_suffix(".drivestbackup")

    with output_path.open("w", encoding="utf-8") as fh:
        json.dump(envelope, fh, indent=2, ensure_ascii=False)

    # ---- Report -----------------------------------------------------------
    print(f"✓  {len(fill_ups)} fill-ups, {len(cost_entries)} costs")
    print(f"   Saved → {output_path}")

    # Highlight same-date groups (the dip candidates)
    from collections import defaultdict
    by_date: dict[str, list[float]] = defaultdict(list)
    for fu in fill_ups:
        by_date[fu["date"][:10]].append(fu["odometerReading"])

    multi = {d: odos for d, odos in by_date.items() if len(odos) > 1}
    if multi:
        print(f"\n⚠  {len(multi)} date(s) with multiple fill-ups — sorted by odometer:")
        for d in sorted(multi):
            odos = sorted(multi[d])
            diff = odos[-1] - odos[0]
            print(f"   {d}  odometers: {odos}  (spread {diff:.0f} km)")

    # Warn about any remaining odometer decreases after sorting
    decreases = []
    prev_odo = -1.0
    for fu in fill_ups:
        if fu["odometerReading"] < prev_odo:
            decreases.append((fu["date"][:10], prev_odo, fu["odometerReading"]))
        prev_odo = fu["odometerReading"]

    if decreases:
        print(f"\n⛔  {len(decreases)} odometer decrease(s) remain after sorting")
        print("   These entries have genuinely incorrect odometer data in the CSV:")
        for d, prev, curr in decreases:
            print(f"   {d}  {prev:.0f} → {curr:.0f}  (down {prev - curr:.0f} km)")
        print("   Fix them in the CSV before importing, or delete them in the app after import.")
    else:
        print("\n✓  No odometer decreases — chart will be monotonically increasing.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: python3 {Path(sys.argv[0]).name} <input.csv> [output.drivestbackup]")
        sys.exit(1)

    csv_file = Path(sys.argv[1]).expanduser().resolve()
    out_file = Path(sys.argv[2]).expanduser().resolve() if len(sys.argv) > 2 else None

    if not csv_file.exists():
        print(f"ERROR: File not found: {csv_file}", file=sys.stderr)
        sys.exit(1)

    convert(csv_file, out_file)
