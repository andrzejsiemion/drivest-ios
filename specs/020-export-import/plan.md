# Plan: Per-Vehicle Data Export & Import

## Context

Users need to back up, transfer, or archive vehicle data as a portable file that can be saved to iCloud Drive, shared via AirDrop, emailed, or restored. Scope is per-vehicle: one file = one vehicle + all its fill-ups, cost entries, and (future) charging sessions.

---

## Key Design Decisions

### D1: File format — JSON with versioning
JSON is chosen over CSV because:
- Single file contains vehicle metadata + all related records (no zip required)
- Human-readable and editable if needed
- Easy to parse back without a schema migration
- `version` field in the envelope allows format evolution without breaking old files

CSV conversion is handled by a standalone Python script (`tools/fuelbackup_to_csv.py`) outside the app. User exports `.fuelbackup` from the app, runs the script locally if they want spreadsheet access. This keeps the iOS app simpler and avoids maintaining two export code paths.

### D2: File extension — `.fuelbackup`
A custom UTType `com.fuel.backup` with extension `.fuelbackup` registered in Info.plist. Benefits:
- Files app shows the correct icon and app association
- Opening a `.fuelbackup` file from Mail / Files / AirDrop launches the app and triggers import
- Clearly distinguished from generic JSON files

### D3: Import conflict strategy — user choice per import
When importing a file that contains a vehicle whose name already exists in the app:
- **Replace**: delete existing vehicle data, import fresh (destructive, confirmation required)
- **Merge**: skip records with duplicate date+odometer, import only new ones
- **New vehicle**: import as a new vehicle with suffix " (imported)" appended to name

User picks the strategy in an import confirmation sheet.

### D4: Export scope — vehicle + all child records
One export includes:
- Vehicle metadata (all fields including volvoVIN, photo)
- All FillUps with photos embedded as base64
- All CostEntries with attachments as base64
- (Future) ChargingSession records if present

Photos are embedded in the file. This keeps the export self-contained (one file, no sidecars). Large photo sets will produce large files — acceptable for personal backup use.

### D5: Entry point — VehicleDetailView action menu
Export and import actions live in `VehicleDetailView` toolbar menu (not in Settings). This makes the per-vehicle scope obvious and keeps the global Settings clean.

Import from the vehicle detail also allows importing directly into an existing vehicle (merge strategy) or creating a new one.

A global "Import" entry point also exists in Settings → a dedicated "Data" section — for importing a file when no vehicle yet exists (fresh install restore).

---

## JSON Envelope Format

File: `VehicleName_2026-04-23.fuelbackup`

```json
{
  "version": 1,
  "exportedAt": "2026-04-23T14:30:00Z",
  "appVersion": "1.0",
  "vehicle": {
    "id": "6E3A...",
    "name": "V90",
    "make": "Volvo",
    "model": "V90",
    "descriptionText": null,
    "initialOdometer": 0,
    "distanceUnit": "km",
    "fuelType": "diesel",
    "fuelUnit": "liters",
    "efficiencyDisplayFormat": "litersPer100km",
    "secondTankFuelType": null,
    "secondTankFuelUnit": null,
    "volvoVIN": "YV1PWH1V5P1192973",
    "photoData": "<base64>",
    "lastUsedAt": "2026-04-23T...",
    "createdAt": "2024-01-01T..."
  },
  "fillUps": [
    {
      "id": "...",
      "date": "2026-04-23T12:00:00Z",
      "pricePerLiter": 6.45,
      "volume": 48.2,
      "totalCost": 310.89,
      "odometerReading": 53822,
      "isFullTank": true,
      "efficiency": 6.8,
      "fuelType": "diesel",
      "currencyCode": "PLN",
      "exchangeRate": null,
      "note": null,
      "photos": ["<base64>", "<base64>"],
      "createdAt": "2026-04-23T12:05:00Z"
    }
  ],
  "costEntries": [
    {
      "id": "...",
      "date": "2026-03-15T...",
      "title": "Annual service",
      "amount": 850.00,
      "currencyCode": "PLN",
      "exchangeRate": null,
      "category": "service",
      "note": null,
      "attachments": ["<base64>"],
      "createdAt": "..."
    }
  ],
  "chargingSessions": []
}
```

---

## New Files

### `Fuel/Services/VehicleExporter.swift`
```swift
struct VehicleExporter {
    /// Serialises vehicle + all child records to JSON Data.
    static func export(vehicle: Vehicle) throws -> Data

    /// Suggested filename: "V90_2026-04-23.fuelbackup"
    static func filename(for vehicle: Vehicle) -> String
    // No CSV method — use tools/fuelbackup_to_csv.py instead
}
```

### `Fuel/Services/VehicleImporter.swift`
```swift
struct VehicleImporter {
    enum ConflictStrategy { case replace, merge, createNew }

    struct ImportPreview {
        let vehicleName: String
        let fillUpCount: Int
        let costEntryCount: Int
        let chargingSessionCount: Int
        let hasPhotos: Bool
        let exportedAt: Date
        let conflictingVehicle: Vehicle?   // non-nil if name already exists
    }

    /// Parses the file and returns a preview without touching the database.
    static func preview(from data: Data, existingVehicles: [Vehicle]) throws -> ImportPreview

    /// Performs the actual import into the model context.
    static func `import`(
        from data: Data,
        into modelContext: ModelContext,
        strategy: ConflictStrategy
    ) throws -> Vehicle
}
```

### `Fuel/Services/BackupCodable.swift`
Codable structs that mirror each model for JSON encoding/decoding. These are **separate** from the SwiftData `@Model` classes — they act as a stable serialisation layer insulated from SwiftData schema changes:

```swift
struct VehicleBackup: Codable { ... }
struct FillUpBackup: Codable { ... }
struct CostEntryBackup: Codable { ... }
struct ChargingSessionBackup: Codable { ... }
struct BackupEnvelope: Codable {
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let vehicle: VehicleBackup
    let fillUps: [FillUpBackup]
    let costEntries: [CostEntryBackup]
    let chargingSessions: [ChargingSessionBackup]
}
```

### `Fuel/Views/ImportConfirmationSheet.swift`
Sheet shown after a file is selected for import:
```
Import Vehicle Data
─────────────────────────────────────
Vehicle:    V90
Fill-ups:   142 entries
Costs:      23 entries
Exported:   23 Apr 2026, 14:30

⚠️ "V90" already exists in your app.

How would you like to proceed?
  ○ Replace existing data  (destructive)
  ○ Merge — add new entries only
  ○ Import as new vehicle

         [Cancel]   [Import]
```

---

## Modified Files

### `Fuel/Views/VehicleDetailView.swift`
Add toolbar menu button (`.topBarTrailing` ellipsis menu):
```swift
Menu {
    Button("Export Vehicle Data") { exportVehicle() }
    Button("Import Vehicle Data...") { showImportPicker = true }
} label: {
    Image(systemName: "ellipsis.circle")
}
```

State additions:
```swift
@State private var showImportPicker = false
@State private var showImportConfirmation = false
@State private var importPreview: VehicleImporter.ImportPreview?
@State private var importFileData: Data?
@State private var exportError: String?
```

Export flow:
1. `VehicleExporter.export(vehicle:)` → `Data`
2. Write to temp file with `.fuelbackup` extension
3. Present `ShareLink` or `UIActivityViewController` → user saves to Files / shares

Import flow:
1. `.fileImporter(isPresented:allowedContentTypes:)` with `[.fuelbackup, .json]`
2. Security-scoped resource access → read `Data`
3. `VehicleImporter.preview(from:existingVehicles:)` → `ImportPreview`
4. Present `ImportConfirmationSheet`
5. On confirm: `VehicleImporter.import(from:into:strategy:)`

### `Fuel/Views/SettingsView.swift`
Add "Data" section:
```swift
Section("Data") {
    Button("Import Vehicle from File...") { showGlobalImportPicker = true }
}
```
Uses same import flow as VehicleDetailView but strategy is always `.createNew`.

### `Fuel.xcodeproj` / `Info.plist`
Register UTType:
```xml
<key>UTExportedTypeDeclarations</key>
<array>
  <dict>
    <key>UTTypeIdentifier</key>    <string>com.fuel.backup</string>
    <key>UTTypeDescription</key>   <string>Fuel Vehicle Backup</string>
    <key>UTTypeConformsTo</key>    <array><string>public.json</string></array>
    <key>UTTypeTagSpecification</key>
    <dict>
      <key>public.filename-extension</key><array><string>fuelbackup</string></array>
    </dict>
  </dict>
</array>

<key>CFBundleDocumentTypes</key>
<array>
  <dict>
    <key>CFBundleTypeName</key>  <string>Fuel Vehicle Backup</string>
    <key>LSItemContentTypes</key><array><string>com.fuel.backup</string></array>
    <key>CFBundleTypeRole</key>  <string>Editor</string>
  </dict>
</array>
```

Add `onOpenURL` / `onContinueUserActivity` in `FuelApp.swift` to handle file open from Files app.

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Unsupported version field | "This backup was created with a newer version of the app." |
| Malformed JSON | "File is not a valid Fuel backup." |
| Corrupt base64 photo | Skip photo, import record without it, show warning count |
| Disk full during export | Show alert with OS error message |
| Replace strategy — confirm | Require explicit confirmation alert before deletion |
| Merge with zero new records | "All records already exist — nothing was imported." |

---

## CSV Conversion (Python script, outside the app)

See `tools/fuelbackup_to_csv.py`. Run locally after exporting from the app:

```bash
python3 tools/fuelbackup_to_csv.py V90_2026-04-23.fuelbackup
# Produces:
#   V90_fillups.csv
#   V90_costs.csv
#   V90_charging.csv   (if charging sessions present)
```

---

## Execution Order

| Phase | Items | Notes |
|---|---|---|
| 1 | `BackupCodable.swift` — all Codable structs | No UI, pure data layer |
| 2 | `VehicleExporter` — export + CSV | Testable in isolation |
| 3 | `VehicleImporter` — preview + import with all 3 strategies | Most complex logic |
| 4 | `ImportConfirmationSheet` | UI for conflict resolution |
| 5 | `VehicleDetailView` export/import wiring | Main entry point |
| 6 | Info.plist UTType + `FuelApp.swift` file open handler | System integration |
| 7 | `SettingsView` global import entry point | Secondary entry point |
