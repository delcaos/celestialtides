import Foundation

public final class TideCalculations {
    public static let maxTideIndexAbs: Double = 1.0
    static let maxForecastSamples = 60_000

    static let degToRad = Double.pi / 180.0
    static let radToDeg = 180.0 / Double.pi

    public static let lunarDayHours = 24.8412
    public static let semidiurnalPeriodHours = lunarDayHours / 2.0
    static let degreesPerLunarHour = 360.0 / lunarDayHours

    static let lunarWeight = 0.78
    static let solarWeight = 0.22

    static let moonDeclinationGain = 0.18
    static let sunDeclinationGain = 0.06

    static let springNeapBase = 0.78
    static let springNeapVariation = 0.44

    static let minSolarDistanceAu = 0.97
    static let maxSolarDistanceAu = 1.03
    static let minSolarDistanceFactor = 0.92
    static let maxSolarDistanceFactor = 1.08

    static let maxLunarAmplitude = lunarWeight * (1.0 + moonDeclinationGain) * (springNeapBase + springNeapVariation)
    static let maxSolarAmplitude = solarWeight * (1.0 + sunDeclinationGain) * (springNeapBase + springNeapVariation) * maxSolarDistanceFactor
    static let contributionNormalizer = maxLunarAmplitude + maxSolarAmplitude

    static let solarSpeedRatio = 15.0 / degreesPerLunarHour

    static func toRadians(_ deg: Double) -> Double { deg * degToRad }
    static func toDegrees(_ rad: Double) -> Double { rad * radToDeg }

    static func clamp(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
        min(maxVal, max(minVal, value))
    }

    static func toSignedPercent(_ value: Double, _ maxAbs: Double) -> Double {
        guard maxAbs > 0 else { return 0 }
        return clamp((value / maxAbs) * 100.0, -100.0, 100.0)
    }

    static func normalize360(_ degrees: Double) -> Double {
        let value = degrees.truncatingRemainder(dividingBy: 360.0)
        return value < 0 ? value + 360.0 : value
    }

    static func normalize180(_ degrees: Double) -> Double {
        let value = normalize360(degrees)
        return value >= 180.0 ? value - 360.0 : value
    }

    public static func calculateTideContributions(inputs: TideContributionInputs) -> TideContributionResult {
        let latitudeDeg = clamp(inputs.latitudeDeg, -90.0, 90.0)
        let celestialOffsetHours = TideConfigurationLimits.normalizeOffsetHours(inputs.celestialOffsetHours)

        let offsetDeg = celestialOffsetHours * degreesPerLunarHour
        let moonSemidiurnal = cos(2.0 * toRadians(inputs.moonHourAngleDeg - offsetDeg))
        let sunSemidiurnal = cos(2.0 * toRadians(inputs.sunHourAngleDeg - offsetDeg * solarSpeedRatio))

        let moonDeclinationFactor = 1.0 + moonDeclinationGain * cos(toRadians(latitudeDeg - inputs.moonDeclinationDeg))
        let sunDeclinationFactor = 1.0 + sunDeclinationGain * cos(toRadians(latitudeDeg - inputs.sunDeclinationDeg))

        let phaseAlignment = abs(cos(toRadians(normalize360(inputs.moonPhaseAngleDeg))))
        let springNeapFactor = springNeapBase + springNeapVariation * phaseAlignment

        let distanceAu = clamp(inputs.earthSunDistanceAu, minSolarDistanceAu, maxSolarDistanceAu)
        let inverseCube = pow(1.0 / distanceAu, 3.0)
        let solarDistanceFactor = clamp(inverseCube, minSolarDistanceFactor, maxSolarDistanceFactor)

        let rawMoonContribution = lunarWeight * moonSemidiurnal * moonDeclinationFactor * springNeapFactor
        let rawSunContribution = solarWeight * sunSemidiurnal * sunDeclinationFactor * springNeapFactor * solarDistanceFactor

        let moonContribution = rawMoonContribution / contributionNormalizer
        let sunContribution = rawSunContribution / contributionNormalizer
        let moonContributionPercent = toSignedPercent(rawMoonContribution, maxLunarAmplitude)
        let sunContributionPercent = toSignedPercent(rawSunContribution, maxSolarAmplitude)
        let tideIndex = clamp(moonContribution + sunContribution, -maxTideIndexAbs, maxTideIndexAbs)

        return TideContributionResult(
            sunContribution: sunContribution,
            moonContribution: moonContribution,
            sunContributionPercent: sunContributionPercent,
            moonContributionPercent: moonContributionPercent,
            tideIndex: tideIndex,
            springNeapFactor: springNeapFactor,
            solarDistanceFactor: solarDistanceFactor
        )
    }
}
