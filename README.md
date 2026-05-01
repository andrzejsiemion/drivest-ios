# Drivest

A vehicle cost and fuel tracking app for iOS, built with SwiftUI and SwiftData.

## Features

- **Fuel & fill-up tracking** — log every fill-up with price, volume, odometer, and efficiency calculations
- **Cost tracking** — record any vehicle expense by category (insurance, service, tyres, etc.)
- **Cost reminders** — set time-based or distance-based reminders for recurring expenses
- **EV support** — electricity bill tracking and energy snapshot history for electric vehicles
- **Statistics** — spending summaries with time filters and odometer charts
- **Multi-currency** — default currency with additional currencies and live NBP exchange rates
- **Connected services** — Volvo and Toyota odometer integration via official APIs
- **Export / Import** — back up and restore vehicle data
- **Multi-language** — English and Polish
- **Dark Mode** — full support

## Requirements

- iOS 17.0+
- Xcode 15+

## Getting Started

```bash
git clone https://github.com/andrzejsiemion/drivest-ios.git
cd drivest-ios
open Drivest.xcodeproj
```

Build and run on simulator or device — no additional setup required. The app works fully offline with no server dependency.

### Connected Services (optional)

Volvo and Toyota integrations require credentials stored in the iOS Keychain via Settings → Integrations. No API keys need to be configured to build the app.

For the debug scripts in `scripts/`, copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

## Architecture

- **UI**: SwiftUI
- **Data**: SwiftData (local, offline-first)
- **Architecture**: MVVM
- **Dependencies**: Apple frameworks only (no third-party packages)

## License

MIT — see [LICENSE](LICENSE)

## Author

Andrzej Siemion — [@andrzejsiemion](https://github.com/andrzejsiemion)
