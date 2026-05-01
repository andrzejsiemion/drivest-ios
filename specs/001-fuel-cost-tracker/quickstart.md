# Quickstart: Fuel Cost Tracker

## Prerequisites

- Xcode 15.0+ (for Swift 5.9 and iOS 17 SDK)
- macOS 14.0+ (Sonoma)
- iOS 17.0+ simulator or physical device

## Setup

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd fuel
   ```

2. Open the Xcode project:
   ```bash
   open Fuel.xcodeproj
   ```
   (No `Package.resolved` or dependency fetch needed — zero third-party
   packages.)

3. Select a simulator (iPhone SE or iPhone 15 Pro Max recommended for
   testing both small and large screens).

4. Build and run (⌘R).

## First Run

1. The app opens to an empty history list with an empty state prompt.
2. Tap the floating "+" button to add your first vehicle (prompted on
   first launch if no vehicles exist).
3. Enter vehicle name and current odometer reading.
4. Tap "+" again to log your first fill-up.

## Running Tests

```bash
# Unit tests
xcodebuild test -scheme Fuel -destination 'platform=iOS Simulator,name=iPhone 16'

# UI tests
xcodebuild test -scheme FuelUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or in Xcode: ⌘U to run all tests.

## Project Structure

```
Fuel/
├── Models/          # SwiftData @Model classes
├── ViewModels/      # @Observable business logic
├── Views/           # SwiftUI views
��── Services/        # Efficiency calculation
└── Resources/       # Assets

FuelTests/           # Unit tests (XCTest)
FuelUITests/         # UI tests (XCUITest)
```

## Key Patterns

- **MVVM**: Views observe ViewModels via `@Observable`; ViewModels
  access SwiftData ModelContext for persistence.
- **Auto-calculation**: The fill-up form computes the third field
  (price/volume/total) from the other two in real-time.
- **Efficiency**: Calculated on save for full-tank entries using the
  full-tank-to-full-tank accumulation method.

## Verification Checklist

After implementation, verify:

- [ ] Add a vehicle → appears in vehicle list
- [ ] Log a full-tank fill-up → appears in history
- [ ] Log a second full-tank fill-up → efficiency badge shows L/100km
- [ ] Log a partial fill between two fulls → efficiency at next full
      accounts for all intermediate fuel
- [ ] View summary → monthly breakdown matches manual addition
- [ ] Works in airplane mode (fully offline)
- [ ] Rotate device → layout adapts without clipping
- [ ] Enable Dynamic Type (largest) → text remains readable
