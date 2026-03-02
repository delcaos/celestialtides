# Celestial Tides

Celestial Tides is an offline iOS tide app and widget.
Forecasts are estimated from sun/moon geometry plus a local celestial offset calibration.

## Requirements

- iOS 17 deployment target
- Xcode 15+ (for iOS 17 SDK and Swift 5.9+)
- Swift 5.9+ (`swift --version`)
- XcodeGen (`xcodegen --version`)

Install XcodeGen if needed:

```bash
brew install xcodegen
```

## Quick Start

1. Build the core engine package:

   ```bash
   swift build
   ```

2. Regenerate the Xcode project from the canonical spec:

   ```bash
   xcodegen generate
   ```

3. Open and run:

   ```bash
   open CelestialTides.xcodeproj
   ```

## Current Repo Notes

- `project.yml` is the source of truth for app/widget build settings.
- `CelestialTides.xcodeproj/project.pbxproj` is generated from `project.yml` and should not be hand-edited.
- `Package.swift` includes only core tide-engine sources for fast command-line builds.
- `swift test` currently reports `no tests found` because `Tests/CelestialTidesAppTests/` has no checked-in test files right now.

## Project Layout

- `CelestialTidesApp/`: iOS app UI + shared tide engine
- `CelestialTidesWidget/`: WidgetKit extension
- `Tests/CelestialTidesAppTests/`: test directory (currently empty)
- `Branding/`: logo/icon assets and generation scripts
- `docs/`: architecture and implementation docs

## Documentation

- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Algorithm](docs/algorithm.md)
- [Calibration](docs/calibration.md)
