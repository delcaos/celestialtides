# Calibration

## Goal

Estimate a local celestial offset so predicted high tides align with an observed next high tide.

## Inputs

- `nextHighTide` (user-observed)
- location (`latitude`, `longitude`)
- `referenceDate` (usually now)

## Search Strategy

`calculateCelestialOffset` uses a two-pass search over one semidiurnal cycle:

1. Coarse sweep every 20 minutes across the cycle.
2. Fine sweep around the best coarse minute (`±40` minutes, 1-minute steps).

Each candidate:

- predicts next high tide via `findNextHighTide`
- measures wrapped time error to observed high tide
- keeps the minimum absolute wrapped error

## Output

- normalized `(hours, minutes)` offset within one semidiurnal cycle

## Notes

- Calibration is deterministic for a fixed model + inputs.
- If no high tide is found in the search horizon, that candidate is skipped.
