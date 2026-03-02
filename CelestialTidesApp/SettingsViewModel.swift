import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
@MainActor
public final class SettingsViewModel {
    public var nextHighTide: Date? = nil
    public var mapCameraPosition: MapCameraPosition = .automatic
    public var showingInfoAlert: Bool = false
    public var isInternalUpdate: Bool = false
    public var isMapUpdatingCoords: Bool = false

    public init() {}

    @discardableResult
    public func normalizeOffsetFieldsIfNeeded(offsetHours: Binding<Int>, offsetMinutes: Binding<Int>, customLatitude: Double, customLongitude: Double) -> Bool {
        let normalized = TideConfigurationLimits.normalizeOffsetComponents(hours: offsetHours.wrappedValue, minutes: offsetMinutes.wrappedValue)
        guard normalized.hours != offsetHours.wrappedValue || normalized.minutes != offsetMinutes.wrappedValue else {
            return false
        }

        isInternalUpdate = true
        let newHours = normalized.hours
        let newMinutes = normalized.minutes
        offsetHours.wrappedValue = newHours
        offsetMinutes.wrappedValue = newMinutes
        Task { @MainActor in
            self.isInternalUpdate = false
            self.updateNextHighTideFromOffset(
                offsetHours: newHours,
                offsetMinutes: newMinutes,
                customLatitude: customLatitude,
                customLongitude: customLongitude
            )
        }
        return true
    }

    public func clampHoursWindow(hoursBeforeNow: Binding<Int>, hoursAfterNow: Binding<Int>) {
        let boundedBefore = TideConfigurationLimits.clampHoursBeforeNow(hoursBeforeNow.wrappedValue)
        let boundedAfter = TideConfigurationLimits.clampHoursAfterNow(hoursAfterNow.wrappedValue)

        if boundedBefore != hoursBeforeNow.wrappedValue {
            hoursBeforeNow.wrappedValue = boundedBefore
        }
        if boundedAfter != hoursAfterNow.wrappedValue {
            hoursAfterNow.wrappedValue = boundedAfter
        }
    }

    public func sanitizeInitialState(
        customLatitude: Binding<Double>,
        customLongitude: Binding<Double>,
        offsetHours: Binding<Int>,
        offsetMinutes: Binding<Int>,
        hoursBeforeNow: Binding<Int>,
        hoursAfterNow: Binding<Int>
    ) {
        let latitude = TideConfigurationLimits.clampLatitude(customLatitude.wrappedValue)
        let longitude = TideConfigurationLimits.clampLongitude(customLongitude.wrappedValue)
        if latitude != customLatitude.wrappedValue {
            customLatitude.wrappedValue = latitude
        }
        if longitude != customLongitude.wrappedValue {
            customLongitude.wrappedValue = longitude
        }
        clampHoursWindow(hoursBeforeNow: hoursBeforeNow, hoursAfterNow: hoursAfterNow)
        _ = normalizeOffsetFieldsIfNeeded(offsetHours: offsetHours, offsetMinutes: offsetMinutes, customLatitude: customLatitude.wrappedValue, customLongitude: customLongitude.wrappedValue)
    }

    public func handleCoordinateChange(
        customLatitude: Binding<Double>,
        customLongitude: Binding<Double>
    ) {
        let clampedLat = TideConfigurationLimits.clampLatitude(customLatitude.wrappedValue)
        let clampedLon = TideConfigurationLimits.clampLongitude(customLongitude.wrappedValue)

        if clampedLat != customLatitude.wrappedValue {
            customLatitude.wrappedValue = clampedLat
            return
        }
        if clampedLon != customLongitude.wrappedValue {
            customLongitude.wrappedValue = clampedLon
            return
        }

        if !isMapUpdatingCoords {
            updateMapCamera(customLatitude: customLatitude.wrappedValue, customLongitude: customLongitude.wrappedValue)
        }
    }
    
    public func updateMapCamera(customLatitude: Double, customLongitude: Double) {
        let center = CLLocationCoordinate2D(
            latitude: TideConfigurationLimits.clampLatitude(customLatitude),
            longitude: TideConfigurationLimits.clampLongitude(customLongitude)
        )
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        mapCameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
    
    public func calculateOffset(
        offsetHours: Binding<Int>,
        offsetMinutes: Binding<Int>,
        customLatitude: Double,
        customLongitude: Double,
        resolvedTimeZone: TimeZone
    ) {
        guard let validNextHighTide = nextHighTide else { return }
        let referenceNow = roundedToMinute(Date())
        let normalizedNextHighTide = normalizedNextHighTideDate(from: validNextHighTide, now: referenceNow, resolvedTimeZone: resolvedTimeZone)
        let loc = CelestialComputationLocation(
            latitude: TideConfigurationLimits.clampLatitude(customLatitude),
            longitude: TideConfigurationLimits.clampLongitude(customLongitude)
        )
        let result = TideCalculations.calculateCelestialOffset(
            nextHighTide: normalizedNextHighTide,
            location: loc,
            referenceDate: referenceNow
        )
        isInternalUpdate = true
        offsetHours.wrappedValue = result.hours
        offsetMinutes.wrappedValue = result.minutes
        Task { @MainActor in
            isInternalUpdate = false
        }
    }
    
    public func updateNextHighTideFromOffset(
        offsetHours: Int,
        offsetMinutes: Int,
        customLatitude: Double,
        customLongitude: Double
    ) {
        let normalizedOffset = TideConfigurationLimits.normalizeOffsetComponents(hours: offsetHours, minutes: offsetMinutes)
        let totalOffset = Double(normalizedOffset.hours) + Double(normalizedOffset.minutes) / 60.0
        let now = roundedToMinute(Date())
        let location = CelestialComputationLocation(
            latitude: TideConfigurationLimits.clampLatitude(customLatitude),
            longitude: TideConfigurationLimits.clampLongitude(customLongitude)
        )

        if let nextHigh = TideCalculations.findNextHighTide(
            location: location,
            celestialOffsetHours: totalOffset,
            referenceDate: now
        ) {
            isInternalUpdate = true
            nextHighTide = nextHigh.timestamp
            Task { @MainActor in
                isInternalUpdate = false
            }
        }
    }

    private func normalizedNextHighTideDate(from timeOnlyDate: Date, now: Date, resolvedTimeZone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = resolvedTimeZone

        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnlyDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)

        var candidateComponents = DateComponents()
        candidateComponents.year = todayComponents.year
        candidateComponents.month = todayComponents.month
        candidateComponents.day = todayComponents.day
        candidateComponents.hour = timeComponents.hour
        candidateComponents.minute = timeComponents.minute
        candidateComponents.second = 0

        guard let todayAtSelectedTime = calendar.date(from: candidateComponents) else {
            return timeOnlyDate
        }

        if todayAtSelectedTime >= now {
            return todayAtSelectedTime
        }

        return calendar.date(byAdding: .day, value: 1, to: todayAtSelectedTime) ?? todayAtSelectedTime
    }

    private func roundedToMinute(_ date: Date) -> Date {
        let secondsSinceEpoch = date.timeIntervalSince1970
        let roundedSeconds = floor(secondsSinceEpoch / 60.0) * 60.0
        return Date(timeIntervalSince1970: roundedSeconds)
    }
}
