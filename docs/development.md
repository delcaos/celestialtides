# Development

## Setup

1. `swift build`
2. `xcodegen generate`
3. `open CelestialTides.xcodeproj`

## Source of Truth

- Edit `project.yml` for app/widget target settings.
- Regenerate project after changes: `xcodegen generate`.
- Keep `Package.swift` aligned for fast core-engine test builds (it intentionally excludes SwiftUI/widget targets).

## File Organization Rules

- Put tide math/forecast logic in `TideCalculations.swift`.
- Put config defaults/limits in `TideConfiguration.swift`.
- Put persistence + config resolution in `TideRuntime.swift`.
- Put calibration search logic in `TideCalibration.swift`.
- Keep SwiftUI views focused; extract reusable view pieces to separate files.

## Safety Rules

- Do not duplicate defaults keys or app-group identifiers.
- Avoid adding `UserDefaults` reads directly in views other than `@AppStorage`.

## Typical Changes

### New persisted setting

1. Add key in `SharedDefaults.Key`.
2. Add `@AppStorage` binding in UI.
3. Sanitize in `TideCalculations.getConfiguration()`.
4. Add tests for fallback/sanitization behavior.

### Change forecast behavior

1. Update tide engine function.
2. Validate widget output still renders correctly.
