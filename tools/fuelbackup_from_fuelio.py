#!/usr/bin/env python3
"""
fuelbackup_from_fuelio.py
Converts a Fuelio CSV export to a .fuelbackup JSON file importable by the Fuel app.

Usage:
    python3 tools/fuelbackup_from_fuelio.py <path/to/Fuelio_export.csv> [output.fuelbackup]

Fuelio fuel type codes → app rawValues:
    100  → pb95
    110  → pb98
    200  → diesel
    210  → diesel
    300  → lpg
    400  → cng
    600  → ev   (tank 2, EV)
    0    → null (not set)

Fuelio unit codes:
    DistUnit  0 → km,  1 → mi
    FuelUnit  0 → l,   1 → gal,  3 → kwh
    ConsumptionUnit  0 → l100km, 1 → mpg, 2 → kml, 3 → kwh100km
"""

import csv
import io
import json
import sys
import uuid
from datetime import datetime, timezone


# ── Fuelio code maps ──────────────────────────────────────────────────────────

FUEL_TYPE_MAP = {
    "0":   None,
    "1":   "pb95",
    "2":   "diesel",
    "3":   "lpg",
    "4":   "ev",
    "100": "pb95",
    "101": "pb95",
    "110": "pb98",
    "111": "pb98",
    "120": "pb95",   # E85 → closest match
    "200": "diesel",
    "201": "diesel",
    "210": "diesel",
    "211": "diesel",
    "300": "lpg",
    "301": "lpg",
    "400": "cng",
    "401": "cng",
    "500": "cng",    # hydrogen → no match, use cng as placeholder
    "600": "ev",
    "601": "ev",
}

FUEL_UNIT_MAP = {
    "0": "l",
    "1": "gal",
    "3": "kwh",
}

DIST_UNIT_MAP = {
    "0": "km",
    "1": "mi",
}

CONSUMPTION_UNIT_MAP = {
    "0": "l100km",
    "1": "mpg",
    "2": "kml",
    "3": "kwh100km",
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def iso(date_str: str) -> str:
    """Convert 'yyyy-MM-dd' to ISO8601 UTC string."""
    dt = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_sections(text: str) -> dict:
    """Split the Fuelio multi-section CSV into named dicts."""
    sections = {}
    current_name = None
    current_lines = []
    for line in text.splitlines():
        stripped = line.strip().strip('"')
        if stripped.startswith("## "):
            if current_name is not None:
                sections[current_name] = current_lines
            current_name = stripped[3:].strip()
            current_lines = []
        elif line.strip():
            current_lines.append(line)
    if current_name is not None:
        sections[current_name] = current_lines
    return sections


def read_section(lines: list) -> list[dict]:
    if len(lines) < 2:
        return []
    return list(csv.DictReader(io.StringIO("\n".join(lines))))


# ── Main conversion ───────────────────────────────────────────────────────────

def convert(csv_path: str, out_path: str, currency: str = "PLN") -> None:
    with open(csv_path, encoding="utf-8") as f:
        raw = f.read()

    sections = parse_sections(raw)

    # ── Vehicle ──────────────────────────────────────────────────────────────
    vehicles = read_section(sections.get("Vehicle", []))
    if not vehicles:
        sys.exit("ERROR: No Vehicle section found in CSV.")
    v = vehicles[0]

    dist_unit = DIST_UNIT_MAP.get(v.get("DistUnit", "0"), "km")
    fuel_unit = FUEL_UNIT_MAP.get(v.get("FuelUnit", "0"), "l")
    eff_format = CONSUMPTION_UNIT_MAP.get(v.get("ConsumptionUnit", "0"), "l100km")
    tank1_type = FUEL_TYPE_MAP.get(v.get("Tank1Type", "0"))
    tank2_type = FUEL_TYPE_MAP.get(v.get("Tank2Type", "0"))
    tank2_unit = FUEL_UNIT_MAP.get(v.get("FuelUnitTank2", "0"))

    # Only include second tank if it's actually set
    has_second_tank = tank2_type is not None and v.get("TankCount", "1") == "2"

    vehicle_backup = {
        "id": str(uuid.uuid4()),
        "name": v.get("Name", "Vehicle"),
        "make": v.get("Make") or None,
        "model": v.get("Model") or None,
        "descriptionText": v.get("Description") or None,
        "initialOdometer": 0.0,
        "distanceUnit": dist_unit,
        "fuelType": tank1_type,
        "fuelUnit": fuel_unit,
        "efficiencyDisplayFormat": eff_format,
        "secondTankFuelType": tank2_type if has_second_tank else None,
        "secondTankFuelUnit": tank2_unit if has_second_tank else None,
        "vin": v.get("VIN") or None,
        "photoData": None,
        "lastUsedAt": now_iso(),
        "createdAt": now_iso(),
    }

    # ── Fill-ups ──────────────────────────────────────────────────────────────
    log_rows = read_section(sections.get("Log", []))

    fill_ups = []
    for row in log_rows:
        date_str = row.get("Date", "").strip()
        if not date_str:
            continue

        efficiency_raw = float(row.get("l/100km", "0") or "0")
        efficiency = efficiency_raw if efficiency_raw > 0 else None

        note = row.get("Notes", "").strip()
        city = row.get("City", "").strip()
        if not note and city:
            note = city

        fuel_type_code = row.get("FuelType", "0").strip()
        fuel_type = FUEL_TYPE_MAP.get(fuel_type_code) or tank1_type or "pb95"

        fill_ups.append({
            "id": str(uuid.uuid4()),
            "date": iso(date_str),
            "pricePerLiter": float(row.get("VolumePrice", "0") or "0"),
            "volume": float(row.get("Fuel (l)", "0") or "0"),
            "totalCost": float(row.get("Price", "0") or "0"),
            "odometerReading": float(row.get("Odo (km)", "0") or "0"),
            "isFullTank": row.get("Full", "0").strip() == "1",
            "efficiency": efficiency,
            "fuelType": fuel_type,
            "currencyCode": currency,
            "exchangeRate": 1.0,
            "note": note if note else None,
            "photos": [],
            "createdAt": iso(date_str),
        })

    # Sort chronologically
    fill_ups.sort(key=lambda x: x["date"])

    # ── Costs ─────────────────────────────────────────────────────────────────
    cost_rows = read_section(sections.get("Costs", []))
    cost_categories = {
        row["CostTypeID"]: row["Name"]
        for row in read_section(sections.get("CostCategories", []))
    }

    cost_entries = []
    for row in cost_rows:
        date_str = row.get("Date", "").strip()
        if not date_str:
            continue
        category_id = row.get("CostTypeID", "").strip()
        category_name = cost_categories.get(category_id, row.get("CostTitle", ""))
        cost_entries.append({
            "id": str(uuid.uuid4()),
            "date": iso(date_str),
            "title": row.get("CostTitle", "").strip() or category_name,
            "amount": float(row.get("Cost", "0") or "0"),
            "currencyCode": currency,
            "exchangeRate": 1.0,
            "categoryName": category_name or None,
            "note": row.get("Notes", "").strip() or None,
            "attachments": [],
            "createdAt": iso(date_str),
        })

    # ── Envelope ──────────────────────────────────────────────────────────────
    envelope = {
        "version": 1,
        "exportedAt": now_iso(),
        "appVersion": "1.0",
        "vehicle": vehicle_backup,
        "fillUps": fill_ups,
        "costEntries": cost_entries,
        "chargingSessions": [],
    }

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(envelope, f, indent=2, ensure_ascii=False)

    print(f"Converted {len(fill_ups)} fill-ups and {len(cost_entries)} cost entries.")
    print(f"Output: {out_path}")


# ── Entry point ───────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    csv_path = sys.argv[1]
    out_path = sys.argv[2] if len(sys.argv) > 2 else csv_path.replace(".csv", ".fuelbackup")
    currency = sys.argv[3] if len(sys.argv) > 3 else "PLN"

    convert(csv_path, out_path, currency)
