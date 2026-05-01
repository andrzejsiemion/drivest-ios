# Data Model: Vehicle Photo

**Date**: 2026-04-20
**Storage**: SwiftData (iOS 17+)

## Entity Changes

### Vehicle (extended)

Adds one optional field to the existing Vehicle entity.

| Field | Type | Constraints | Notes |
|-------|------|-------------|-------|
| photoData | Data? | Optional, max ~500KB | JPEG-compressed image data, resized to 300×300px max |

**Validation Rules**:
- `photoData` may be nil (no photo assigned)
- When set, data size must not exceed 500KB (enforced at write time by compression service)
- Photo is replaced atomically (old data overwritten, not versioned)

**Lifecycle**:
- Created: nil (no photo on new vehicle by default)
- Updated: user adds/replaces photo → compressed Data written
- Removed: user removes photo → set to nil
- Deleted: cascade with Vehicle (SwiftData handles automatically)

## Migration Notes

- Adding an optional `Data?` field is a lightweight migration — SwiftData handles automatically
- Existing vehicles get nil for photoData (no photo, placeholder shown)
- No data transformation needed on upgrade
