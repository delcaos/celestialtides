# Celestial Tides Branding

This folder contains release-ready logo and app icon assets for `Celestial Tides`.

## Source Files

- `celestial-tides-logo-mark.svg`: Primary logo mark used for app icon generation.
- `celestial-tides-wordmark.svg`: Horizontal wordmark for screenshots, website, and marketing.
- `celestial-tides-logo-mark-1024.png`: Master raster export from the logo mark.
- `celestial-tides-wordmark.png`: Raster export of the wordmark.

## App Store Icon Setup

Icons are generated to:

- `CelestialTidesApp/Assets.xcassets/AppIcon.appiconset`

The icon set includes all required iPhone/iPad sizes plus the `1024x1024` App Store marketing icon with no alpha channel.

## Regenerate Icons

If you update `celestial-tides-logo-mark.svg`, run:

```bash
./Branding/generate_app_icons.sh
```

Then open Xcode and archive/upload as usual.
