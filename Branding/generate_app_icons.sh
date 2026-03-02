#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANDING_DIR="$ROOT_DIR/Branding"
ICONSET_DIR="$ROOT_DIR/CelestialTidesApp/Assets.xcassets/AppIcon.appiconset"
MARK_SVG="$BRANDING_DIR/celestial-tides-logo-mark.svg"
MASTER_PNG="$BRANDING_DIR/celestial-tides-logo-mark-1024.png"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "Missing dependency: rsvg-convert"
  exit 1
fi

if ! command -v sips >/dev/null 2>&1; then
  echo "Missing dependency: sips"
  exit 1
fi

mkdir -p "$ICONSET_DIR"
rsvg-convert -w 1024 -h 1024 "$MARK_SVG" -o "$MASTER_PNG"

while IFS=":" read -r filename pixels; do
  sips -z "$pixels" "$pixels" "$MASTER_PNG" --out "$ICONSET_DIR/$filename" >/dev/null
done <<'EOF'
Icon-App-20x20@1x.png:20
Icon-App-20x20@2x.png:40
Icon-App-20x20@3x.png:60
Icon-App-29x29@1x.png:29
Icon-App-29x29@2x.png:58
Icon-App-29x29@3x.png:87
Icon-App-40x40@1x.png:40
Icon-App-40x40@2x.png:80
Icon-App-40x40@3x.png:120
Icon-App-60x60@2x.png:120
Icon-App-60x60@3x.png:180
Icon-App-76x76@1x.png:76
Icon-App-76x76@2x.png:152
Icon-App-83.5x83.5@2x.png:167
Icon-App-1024x1024@1x.png:1024
EOF

echo "Generated app icons in $ICONSET_DIR"
