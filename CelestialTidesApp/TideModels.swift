import Foundation

public struct CelestialComputationLocation {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct CelestialComputationResult {
    public var sunAltitudeDeg: Double
    public var sunHourAngleDeg: Double
    public var sunDeclinationDeg: Double
    public var moonAltitudeDeg: Double
    public var moonHourAngleDeg: Double
    public var moonDeclinationDeg: Double
    public var moonPhaseAngleDeg: Double
    public var moonIlluminationFraction: Double
    public var earthSunDistanceAu: Double
}

public struct TideContributionInputs {
    public var latitudeDeg: Double
    public var celestialOffsetHours: Double
    public var sunHourAngleDeg: Double
    public var moonHourAngleDeg: Double
    public var sunDeclinationDeg: Double
    public var moonDeclinationDeg: Double
    public var moonPhaseAngleDeg: Double
    public var earthSunDistanceAu: Double
}

public struct TideContributionResult {
    public var sunContribution: Double
    public var moonContribution: Double
    public var sunContributionPercent: Double
    public var moonContributionPercent: Double
    public var tideIndex: Double
    public var springNeapFactor: Double
    public var solarDistanceFactor: Double
}

public struct TideForecastPoint {
    public var timestamp: Date
    public var sunAltitudeDeg: Double
    public var moonAltitudeDeg: Double
    public var sunContribution: Double
    public var moonContribution: Double
    public var sunContributionPercent: Double
    public var moonContributionPercent: Double
    public var moonPhaseAngleDeg: Double
    public var moonIlluminationFraction: Double
    public var earthSunDistanceAu: Double
    public var tideIndex: Double
    public var tidePercent: Double
}

public struct TideExtremum {
    public enum ExtremumType: String {
        case high = "High"
        case low = "Low"
    }

    public var type: ExtremumType
    public var timestamp: Date
    public var tidePercent: Double
}
