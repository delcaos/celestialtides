import Foundation

extension TideCalculations {
    private static func storedOffsetHours(defaults: UserDefaults?) -> Double? {
        guard let defaults,
              defaults.object(forKey: SharedDefaults.Key.offsetHours) != nil,
              defaults.object(forKey: SharedDefaults.Key.offsetMinutes) != nil else {
            return nil
        }
        let offsetHours = defaults.integer(forKey: SharedDefaults.Key.offsetHours)
        let offsetMinutes = defaults.integer(forKey: SharedDefaults.Key.offsetMinutes)
        return Double(offsetHours) + Double(offsetMinutes) / 60.0
    }

    public static func getConfiguration(
        customLatitude: Double? = nil,
        customLongitude: Double? = nil,
        customOffsetHours: Double? = nil,
        customTimeZoneIdentifier: String? = nil,
        customHoursBeforeNow: Int? = nil,
        customHoursAfterNow: Int? = nil
    ) -> TideConfiguration {
        let sharedDefaults = SharedDefaults.store

        let storedHoursBefore = sharedDefaults?.object(forKey: SharedDefaults.Key.hoursBeforeNow) as? Int
            ?? TideConfigurationLimits.defaultHoursBeforeNow
        let storedHoursAfter = sharedDefaults?.object(forKey: SharedDefaults.Key.hoursAfterNow) as? Int
            ?? TideConfigurationLimits.defaultHoursAfterNow
        let targetHoursBeforeNow = TideConfigurationLimits.clampHoursBeforeNow(customHoursBeforeNow ?? storedHoursBefore)
        let targetHoursAfterNow = TideConfigurationLimits.clampHoursAfterNow(customHoursAfterNow ?? storedHoursAfter)

        let targetLatitude = TideConfigurationLimits.clampLatitude(
            customLatitude ?? sharedDefaults?.double(forKey: SharedDefaults.Key.customLatitude) ?? 0.0
        )
        let targetLongitude = TideConfigurationLimits.clampLongitude(
            customLongitude ?? sharedDefaults?.double(forKey: SharedDefaults.Key.customLongitude) ?? 0.0
        )
        let targetOffsetHours = TideConfigurationLimits.normalizeOffsetHours(
            customOffsetHours ?? storedOffsetHours(defaults: sharedDefaults) ?? 0.0
        )
        let targetTimeZone = TimeZoneSelection.resolve(
            identifier: customTimeZoneIdentifier ?? sharedDefaults?.string(forKey: SharedDefaults.Key.selectedTimeZone),
            fallback: .current
        )

        return TideConfiguration(
            latitude: targetLatitude,
            longitude: targetLongitude,
            offsetHours: targetOffsetHours,
            timeZone: targetTimeZone,
            hoursBeforeNow: targetHoursBeforeNow,
            hoursAfterNow: targetHoursAfterNow
        )
    }

    public static func getTideData(
        config: TideConfiguration,
        date: Date = Date()
    ) -> (points: [TideForecastPoint], extrema: [TideExtremum]) {
        let location = CelestialComputationLocation(latitude: config.latitude, longitude: config.longitude)

        let before = max(0, config.hoursBeforeNow)
        let after = max(1, config.hoursAfterNow)
        let totalHours = Double(before + after)
        let pastDate = Calendar.current.date(byAdding: .hour, value: -before, to: date) ?? date

        let points = buildTideForecast(
            location: location,
            hours: totalHours,
            stepMinutes: 1,
            celestialOffsetHours: config.offsetHours,
            startTime: pastDate
        )

        let extrema = findTideExtrema(points: points)
        return (points, extrema)
    }

    public static func normalizedFutureRange(
        start: Date,
        end: Date,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let normalizedStart = calendar.startOfDay(for: start)
        let normalizedEnd = calendar.startOfDay(for: end)
        return (start: normalizedStart, end: max(normalizedStart, normalizedEnd))
    }

    public static func getFutureExtrema(
        config: TideConfiguration,
        rangeStart: Date,
        rangeEnd: Date,
        calendar: Calendar = .current
    ) -> [TideExtremum] {
        let normalizedRange = normalizedFutureRange(start: rangeStart, end: rangeEnd, calendar: calendar)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: normalizedRange.end)
            ?? normalizedRange.end.addingTimeInterval(86_400)

        guard endExclusive > normalizedRange.start else {
            return []
        }

        let location = CelestialComputationLocation(latitude: config.latitude, longitude: config.longitude)
        let totalMinutes = max(60.0, endExclusive.timeIntervalSince(normalizedRange.start) / 60.0)
        let stepMinutes = max(1.0, ceil(totalMinutes / 60_000.0))
        let totalHours = endExclusive.timeIntervalSince(normalizedRange.start) / 3_600.0

        let forecast = buildTideForecast(
            location: location,
            hours: totalHours,
            stepMinutes: stepMinutes,
            celestialOffsetHours: config.offsetHours,
            startTime: normalizedRange.start
        )

        return findTideExtrema(points: forecast)
            .filter { $0.timestamp >= normalizedRange.start && $0.timestamp < endExclusive }
    }

    public static func nearestPoint(in points: [TideForecastPoint], to targetDate: Date) -> TideForecastPoint? {
        points.min(by: {
            abs($0.timestamp.timeIntervalSince(targetDate)) < abs($1.timestamp.timeIntervalSince(targetDate))
        })
    }
}
