#!/usr/bin/env python3
"""
Convert a .fuelbackup file (JSON) to CSV files.

Usage:
    python3 tools/fuelbackup_to_csv.py MyVehicle_2026-04-23.fuelbackup

Output:
    MyVehicle_fillups.csv
    MyVehicle_costs.csv
    MyVehicle_charging.csv  (if charging sessions present)
"""
import json, csv, sys, os, base64
from datetime import datetime

def iso(s):
    if not s:
        return ""
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).strftime("%Y-%m-%d %H:%M")
    except Exception:
        return s

def write_csv(path, rows, fieldnames):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print(f"  -> {path} ({len(rows)} rows)")

def main():
    if len(sys.argv) < 2:
        print("Usage: fuelbackup_to_csv.py <file.fuelbackup>")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    version = data.get("version", 0)
    if version != 1:
        print(f"Warning: unknown backup version {version}, proceeding anyway")

    vehicle = data.get("vehicle", {})
    base = os.path.splitext(path)[0]  # strip .fuelbackup, use same directory

    # --- Fill-ups ---
    fillups = data.get("fillUps", [])
    if fillups:
        fields = ["date", "odometer", "price_per_unit", "volume", "total_cost",
                  "currency", "exchange_rate", "fuel_type", "full_tank",
                  "efficiency", "note"]
        rows = []
        for f in fillups:
            rows.append({
                "date":           iso(f.get("date")),
                "odometer":       f.get("odometerReading", ""),
                "price_per_unit": f.get("pricePerLiter", ""),
                "volume":         f.get("volume", ""),
                "total_cost":     f.get("totalCost", ""),
                "currency":       f.get("currencyCode", ""),
                "exchange_rate":  f.get("exchangeRate", ""),
                "fuel_type":      f.get("fuelType", ""),
                "full_tank":      "yes" if f.get("isFullTank") else "no",
                "efficiency":     f.get("efficiency", ""),
                "note":           f.get("note", ""),
            })
        write_csv(f"{base}_fillups.csv", rows, fields)

    # --- Costs ---
    costs = data.get("costEntries", [])
    if costs:
        fields = ["date", "title", "amount", "currency", "exchange_rate", "category", "note"]
        rows = []
        for c in costs:
            rows.append({
                "date":          iso(c.get("date")),
                "title":         c.get("title", ""),
                "amount":        c.get("amount", ""),
                "currency":      c.get("currencyCode", ""),
                "exchange_rate": c.get("exchangeRate", ""),
                "category":      c.get("categoryName", ""),
                "note":          c.get("note", ""),
            })
        write_csv(f"{base}_costs.csv", rows, fields)

    # --- Charging sessions ---
    sessions = data.get("chargingSessions", [])
    if sessions:
        fields = ["date", "odometer", "energy_kwh", "start_soc", "end_soc",
                  "electric_range", "total_cost", "currency", "full_charge",
                  "efficiency_wh_per_km", "note"]
        rows = []
        for s in sessions:
            rows.append({
                "date":               iso(s.get("date")),
                "odometer":           s.get("odometerReading", ""),
                "energy_kwh":         s.get("energyAddedKwh", ""),
                "start_soc":          s.get("startSoC", ""),
                "end_soc":            s.get("endSoC", ""),
                "electric_range":     s.get("electricRange", ""),
                "total_cost":         s.get("totalCost", ""),
                "currency":           s.get("currencyCode", ""),
                "full_charge":        "yes" if s.get("isFullCharge") else "no",
                "efficiency_wh_per_km": s.get("efficiency", ""),
                "note":               s.get("note", ""),
            })
        write_csv(f"{base}_charging.csv", rows, fields)

    print(f"\nDone. Vehicle: {vehicle.get('name')} | Exported: {iso(data.get('exportedAt'))}")

if __name__ == "__main__":
    main()
