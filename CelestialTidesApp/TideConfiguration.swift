import Foundation

public struct TideConfiguration {
    public var latitude: Double
    public var longitude: Double
    public var offsetHours: Double
    public var timeZone: TimeZone
    public var hoursBeforeNow: Int
    public var hoursAfterNow: Int

    public init(
        latitude: Double,
        longitude: Double,
        offsetHours: Double,
        timeZone: TimeZone,
        hoursBeforeNow: Int = TideConfigurationLimits.defaultHoursBeforeNow,
        hoursAfterNow: Int = TideConfigurationLimits.defaultHoursAfterNow
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.offsetHours = offsetHours
        self.timeZone = timeZone
        self.hoursBeforeNow = hoursBeforeNow
        self.hoursAfterNow = hoursAfterNow
    }
}

public enum TideConfigurationLimits {
    public static let minLatitude = -90.0
    public static let maxLatitude = 90.0
    public static let minLongitude = -180.0
    public static let maxLongitude = 180.0

    public static let minHoursBeforeNow = 0
    public static let maxHoursBeforeNow = 48
    public static let minHoursAfterNow = 1
    public static let maxHoursAfterNow = 168

    public static let defaultHoursBeforeNow = 6
    public static let defaultHoursAfterNow = 24

    public static func clampLatitude(_ value: Double) -> Double {
        guard value.isFinite else { return 0.0 }
        return min(maxLatitude, max(minLatitude, value))
    }

    public static func clampLongitude(_ value: Double) -> Double {
        guard value.isFinite else { return 0.0 }
        return min(maxLongitude, max(minLongitude, value))
    }

    public static func clampHoursBeforeNow(_ value: Int) -> Int {
        return min(maxHoursBeforeNow, max(minHoursBeforeNow, value))
    }

    public static func clampHoursAfterNow(_ value: Int) -> Int {
        return min(maxHoursAfterNow, max(minHoursAfterNow, value))
    }

    public static func normalizeOffsetHours(_ value: Double) -> Double {
        let safeValue = (value.isNaN || value.isInfinite) ? 0.0 : value
        let semidiurnal = TideCalculations.semidiurnalPeriodHours
        let wrapped = ((safeValue.truncatingRemainder(dividingBy: semidiurnal)) + semidiurnal)
            .truncatingRemainder(dividingBy: semidiurnal)
        return max(0.0, wrapped)
    }

    public static func offsetComponents(fromHours value: Double) -> (hours: Int, minutes: Int) {
        let cycleMinutes = max(1, Int(round(TideCalculations.semidiurnalPeriodHours * 60.0)))
        let wrappedHours = normalizeOffsetHours(value)
        let wrappedMinutes = ((Int(round(wrappedHours * 60.0)) % cycleMinutes) + cycleMinutes) % cycleMinutes
        return (hours: wrappedMinutes / 60, minutes: wrappedMinutes % 60)
    }

    public static func normalizeOffsetComponents(hours: Int, minutes: Int) -> (hours: Int, minutes: Int) {
        let totalHours = Double(hours) + Double(minutes) / 60.0
        return offsetComponents(fromHours: totalHours)
    }
}
