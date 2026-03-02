# Architecture

## Core Principle

The codebase is split into:

- pure tide engine logic (`Foundation` only)
- app UI/state (`SwiftUI`)
- widget rendering (`WidgetKit`)

This keeps forecasting math testable and reusable from app + widget targets.

## Modules

- `CelestialTidesApp/TideCalculations.swift`
  - celestial position math
  - tide contribution model
  - forecast sampling + extrema detection
- `CelestialTidesApp/TideConfiguration.swift`
  - typed runtime configuration
  - limits/defaults/normalization rules
- `CelestialTidesApp/TideRuntime.swift`
  - read persisted settings
  - assemble runtime `TideConfiguration`
  - build current tide data bundle
- `CelestialTidesApp/TideCalibration.swift`
  - compute next high tide
  - solve calibrated celestial offset
- `CelestialTidesApp/ContentView.swift`
  - top-level app orchestration and rendering
- `CelestialTidesApp/SettingsSheet.swift`
  - user-editable settings and validation UI
- `CelestialTidesApp/TideChart.swift`
  - reusable chart rendering and interactions

## Data Flow

1. UI reads/writes persisted values through `@AppStorage`.
2. `TideCalculations.getConfiguration()` sanitizes persisted values.
3. `TideCalculations.getTideData()` builds a forecast window.
4. UI + widget render points and extrema.

## Shared Defaults Contract

`SharedDefaults.swift` defines:

- app-group suite name
- all persisted keys

No other file should hardcode key names or suite identifiers.
