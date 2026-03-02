import Foundation

extension TideCalculations {
    public static func buildTideForecast(
        location: CelestialComputationLocation,
        hours: Double,
        stepMinutes: Double,
        celestialOffsetHours: Double,
        startTime: Date
    ) -> [TideForecastPoint] {
        let stepMins = max(1.0, round(stepMinutes))
        let hr = max(0.0, hours)
        let totalSamples = min(Int(floor((hr * 60.0) / stepMins)) + 1, maxForecastSamples)

        // Stabilize chart points by aligning the start time to the nearest step boundary
        let stepSeconds = stepMins * 60.0
        let timestampSeconds = startTime.timeIntervalSince1970
        let alignedStartSeconds = floor(timestampSeconds / stepSeconds) * stepSeconds
        let alignedStartTime = Date(timeIntervalSince1970: alignedStartSeconds)

        var points: [TideForecastPoint] = []
        points.reserveCapacity(totalSamples)

        let clampedLatitude = clamp(location.latitude, -90.0, 90.0)
        let latitudeRad = toRadians(clampedLatitude)
        let sinLatitude = sin(latitudeRad)
        let cosLatitude = cos(latitudeRad)
        let clampedLocation = CelestialComputationLocation(latitude: clampedLatitude, longitude: location.longitude)

        for index in 0..<totalSamples {
            let timestamp = alignedStartTime.addingTimeInterval(Double(index) * stepSeconds)
            let angles = calculateCelestialState(
                date: timestamp,
                location: clampedLocation,
                cachedLatitudeRad: latitudeRad,
                cachedSinLatitude: sinLatitude,
                cachedCosLatitude: cosLatitude
            )
            let inputs = TideContributionInputs(
                latitudeDeg: clampedLatitude,
                celestialOffsetHours: celestialOffsetHours,
                sunHourAngleDeg: angles.sunHourAngleDeg,
                moonHourAngleDeg: angles.moonHourAngleDeg,
                sunDeclinationDeg: angles.sunDeclinationDeg,
                moonDeclinationDeg: angles.moonDeclinationDeg,
                moonPhaseAngleDeg: angles.moonPhaseAngleDeg,
                earthSunDistanceAu: angles.earthSunDistanceAu
            )
            let contributions = calculateTideContributions(inputs: inputs)

            let percent = clamp((contributions.tideIndex / maxTideIndexAbs) * 100.0, -100.0, 100.0)

            points.append(TideForecastPoint(
                timestamp: timestamp,
                sunAltitudeDeg: angles.sunAltitudeDeg,
                moonAltitudeDeg: angles.moonAltitudeDeg,
                sunContribution: contributions.sunContribution,
                moonContribution: contributions.moonContribution,
                sunContributionPercent: contributions.sunContributionPercent,
                moonContributionPercent: contributions.moonContributionPercent,
                moonPhaseAngleDeg: angles.moonPhaseAngleDeg,
                moonIlluminationFraction: angles.moonIlluminationFraction,
                earthSunDistanceAu: angles.earthSunDistanceAu,
                tideIndex: contributions.tideIndex,
                tidePercent: percent
            ))
        }
        return points
    }

    public static func findTideExtrema(points: [TideForecastPoint]) -> [TideExtremum] {
        guard points.count >= 3 else { return [] }

        var extrema: [TideExtremum] = []
        let trendEpsilon = 1e-9

        func getTrend(next: Double, current: Double) -> Int {
            let delta = next - current
            if abs(delta) <= trendEpsilon { return 0 }
            return delta > 0 ? 1 : -1
        }

        var previousTrend = getTrend(next: points[1].tidePercent, current: points[0].tidePercent)

        for index in 1..<(points.count - 1) {
            let current = points[index].tidePercent
            let next = points[index + 1].tidePercent
            let nextTrend = getTrend(next: next, current: current)

            if previousTrend > 0 && nextTrend < 0 {
                extrema.append(TideExtremum(type: .high, timestamp: points[index].timestamp, tidePercent: current))
            } else if previousTrend < 0 && nextTrend > 0 {
                extrema.append(TideExtremum(type: .low, timestamp: points[index].timestamp, tidePercent: current))
            }

            if nextTrend != 0 {
                previousTrend = nextTrend
            }
        }

        return extrema
    }
}
