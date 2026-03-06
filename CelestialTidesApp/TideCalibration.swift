import Foundation

extension TideCalculations {
    public static func findNextHighTide(
        location: CelestialComputationLocation,
        celestialOffsetHours: Double,
        referenceDate: Date,
        horizonHours: Double = 18.0,
        stepMinutes: Double = 1.0
    ) -> TideExtremum? {
        let paddedStart = referenceDate.addingTimeInterval(-2 * 3600)
        let paddedHorizon = horizonHours + 4.0

        let forecast = buildTideForecast(
            location: location,
            hours: paddedHorizon,
            stepMinutes: stepMinutes,
            celestialOffsetHours: celestialOffsetHours,
            startTime: paddedStart
        )

        return findTideExtrema(points: forecast)
            .first(where: { $0.type == .high && $0.timestamp >= referenceDate })
    }

    private static func signedWrappedDeltaSeconds(from earlierDate: Date, to laterDate: Date) -> Double {
        let cycleSeconds = semidiurnalPeriodHours * 3600.0
        var deltaSeconds = laterDate.timeIntervalSince(earlierDate).truncatingRemainder(dividingBy: cycleSeconds)

        if deltaSeconds > cycleSeconds / 2.0 {
            deltaSeconds -= cycleSeconds
        } else if deltaSeconds < -cycleSeconds / 2.0 {
            deltaSeconds += cycleSeconds
        }

        return deltaSeconds
    }

    private static func toHourMinuteOffset(_ offsetHours: Double) -> (hours: Int, minutes: Int) {
        TideConfigurationLimits.offsetComponents(fromHours: offsetHours)
    }

    public static func calculateCelestialOffset(
        nextHighTide: Date,
        location: CelestialComputationLocation,
        referenceDate: Date = Date()
    ) -> (hours: Int, minutes: Int) {
        let cycleMinutes = Int(round(semidiurnalPeriodHours * 60.0))
        var bestOffsetHours: Double = 0.0
        var bestAbsErrorSeconds = Double.infinity

        func evaluate(_ candidateOffsetHours: Double) {
            let normalized = TideConfigurationLimits.normalizeOffsetHours(candidateOffsetHours)
            guard let predictedHigh = findNextHighTide(
                location: location,
                celestialOffsetHours: normalized,
                referenceDate: referenceDate
            ) else {
                return
            }

            let signedError = signedWrappedDeltaSeconds(from: predictedHigh.timestamp, to: nextHighTide)
            let absError = abs(signedError)

            if absError < bestAbsErrorSeconds {
                bestAbsErrorSeconds = absError
                bestOffsetHours = normalized
            }
        }

        for minute in stride(from: 0, through: cycleMinutes, by: 20) {
            evaluate(Double(minute) / 60.0)
        }

        let bestMinuteSeed = Int(round(bestOffsetHours * 60.0))
        for minute in (bestMinuteSeed - 40)...(bestMinuteSeed + 40) {
            evaluate(Double(minute) / 60.0)
        }

        return toHourMinuteOffset(bestOffsetHours)
    }
}
