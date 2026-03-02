# Forecast Algorithm

## Summary

The engine estimates a normalized tide index by combining:

- lunar semidiurnal component
- solar semidiurnal component
- declination modulation
- spring/neap modulation from lunar phase alignment
- Earth-Sun distance scaling on the solar component

Output is mapped to `tidePercent` in `[-100, 100]`.

## Steps Per Sample

1. Compute sun/moon RA/Dec from date (J2000-based approximations).
2. Convert RA/Dec to local hour angle and altitude using sidereal time.
3. Build lunar + solar semidiurnal signals with configured offset.
4. Apply declination, phase, and distance factors.
5. Normalize contributions and clamp final tide index.

## Forecast Window Construction

- Sampling interval: configurable `stepMinutes` (minimum 1 minute).
- Start time aligned to sample boundary for stable rendering.
- Forecast is capped by an internal max sample count.

## Extrema Detection

- Scan tide curve slope changes.
- Positive-to-negative slope transition = high tide.
- Negative-to-positive slope transition = low tide.
- Flat sections are tolerated via epsilon trend handling.

## Limits

This is an offline celestial approximation, not a station-assimilated model.  
Local effects like bathymetry, wind, pressure, river flow, and resonance are not modeled.
