import Foundation

extension TideCalculations {
    static func daysSinceJ2000(_ date: Date) -> Double {
        // Julian date of J2000.0 is 2451545.0
        // UNIX epoch (1970-01-01) is Julian date 2440587.5
        // Seconds per day = 86400
        let secondsSinceEpoch = date.timeIntervalSince1970
        let julianDate = (secondsSinceEpoch / 86400.0) + 2440587.5
        return julianDate - 2_451_545.0
    }

    static func localSiderealDegrees(daysJ2000: Double, longitudeDeg: Double) -> Double {
        let t = daysJ2000 / 36_525.0
        let gmst = 280.46061837 + 360.98564736629 * daysJ2000 + 0.000387933 * t * t - (t * t * t) / 38_710_000.0
        return normalize360(gmst + longitudeDeg)
    }



    static func getSunRaDec(daysJ2000: Double) -> (raDeg: Double, decDeg: Double, eclipticLongitudeDeg: Double, meanAnomalyDeg: Double) {
        let meanLongitude = normalize360(280.459 + 0.98564736 * daysJ2000)
        let meanAnomaly = normalize360(357.529 + 0.98560028 * daysJ2000)
        let meanAnomalyRad = toRadians(meanAnomaly)

        let eclipticLongitude = normalize360(
            meanLongitude + 1.915 * sin(meanAnomalyRad) + 0.02 * sin(2.0 * meanAnomalyRad)
        )

        let obliquityDeg = 23.439 - 0.00000036 * daysJ2000
        let obliquityRad = toRadians(obliquityDeg)
        let eclipticLongitudeRad = toRadians(eclipticLongitude)

        let y = cos(obliquityRad) * sin(eclipticLongitudeRad)
        let x = cos(eclipticLongitudeRad)

        let raDeg = normalize360(toDegrees(atan2(y, x)))
        let decDeg = toDegrees(asin(sin(obliquityRad) * sin(eclipticLongitudeRad)))

        return (raDeg, decDeg, eclipticLongitude, meanAnomaly)
    }

    static func getMoonRaDec(daysJ2000: Double) -> (raDeg: Double, decDeg: Double, eclipticLongitudeDeg: Double) {
        let lPrime = normalize360(218.316 + 13.176396 * daysJ2000)
        let mMoon = normalize360(134.963 + 13.064993 * daysJ2000)
        let mSun = normalize360(357.529 + 0.98560028 * daysJ2000)
        let d = normalize360(297.85 + 12.190749 * daysJ2000)
        let f = normalize360(93.272 + 13.22935 * daysJ2000)

        let lonDeg = normalize360(
            lPrime +
            6.289 * sin(toRadians(mMoon)) +
            1.274 * sin(toRadians(2.0 * d - mMoon)) +
            0.658 * sin(toRadians(2.0 * d)) +
            0.214 * sin(toRadians(2.0 * mMoon)) -
            0.186 * sin(toRadians(mSun))
        )

        let latDeg =
            5.128 * sin(toRadians(f)) +
            0.28 * sin(toRadians(mMoon + f)) +
            0.277 * sin(toRadians(mMoon - f)) +
            0.173 * sin(toRadians(2.0 * d - f))

        let obliquityDeg = 23.439 - 0.00000036 * daysJ2000
        let obliquityRad = toRadians(obliquityDeg)
        let lonRad = toRadians(lonDeg)
        let latRad = toRadians(latDeg)

        let x = cos(lonRad) * cos(latRad)
        let y = sin(lonRad) * cos(latRad) * cos(obliquityRad) - sin(latRad) * sin(obliquityRad)
        let z = sin(lonRad) * cos(latRad) * sin(obliquityRad) + sin(latRad) * cos(obliquityRad)

        let raDeg = normalize360(toDegrees(atan2(y, x)))
        let decDeg = toDegrees(asin(z))

        return (raDeg, decDeg, lonDeg)
    }

    static func getEarthSunDistanceAu(sunMeanAnomalyDeg: Double) -> Double {
        let meanAnomalyRad = toRadians(sunMeanAnomalyDeg)
        return 1.00014 - 0.01671 * cos(meanAnomalyRad) - 0.00014 * cos(2.0 * meanAnomalyRad)
    }

    static func altitudeFromRaDec(
        rightAscensionDeg: Double,
        declinationDeg: Double,
        location: CelestialComputationLocation,
        daysJ2000: Double,
        latitudeRad: Double,
        sinLatitude: Double,
        cosLatitude: Double
    ) -> (altitudeDeg: Double, hourAngleDeg: Double) {
        let declinationRad = toRadians(declinationDeg)

        let lstDeg = localSiderealDegrees(daysJ2000: daysJ2000, longitudeDeg: location.longitude)
        let hourAngleDeg = normalize180(lstDeg - rightAscensionDeg)
        let hourAngleRad = toRadians(hourAngleDeg)

        let sinAltitude = sin(declinationRad) * sinLatitude + cos(declinationRad) * cosLatitude * cos(hourAngleRad)
        let altitudeDeg = toDegrees(asin(clamp(sinAltitude, -1.0, 1.0)))

        return (altitudeDeg, hourAngleDeg)
    }

    public static func calculateCelestialState(
        date: Date,
        location: CelestialComputationLocation,
        cachedLatitudeRad: Double? = nil,
        cachedSinLatitude: Double? = nil,
        cachedCosLatitude: Double? = nil
    ) -> CelestialComputationResult {
        let lat = clamp(location.latitude, -90.0, 90.0)
        let lon = clamp(location.longitude, -180.0, 180.0)
        let loc = CelestialComputationLocation(latitude: lat, longitude: lon)

        let daysJ2000 = daysSinceJ2000(date)
        let sun = getSunRaDec(daysJ2000: daysJ2000)
        let moon = getMoonRaDec(daysJ2000: daysJ2000)

        let latRad = cachedLatitudeRad ?? toRadians(lat)
        let sinLat = cachedSinLatitude ?? sin(latRad)
        let cosLat = cachedCosLatitude ?? cos(latRad)

        let sunAltitude = altitudeFromRaDec(
            rightAscensionDeg: sun.raDeg,
            declinationDeg: sun.decDeg,
            location: loc,
            daysJ2000: daysJ2000,
            latitudeRad: latRad,
            sinLatitude: sinLat,
            cosLatitude: cosLat
        )

        let moonAltitude = altitudeFromRaDec(
            rightAscensionDeg: moon.raDeg,
            declinationDeg: moon.decDeg,
            location: loc,
            daysJ2000: daysJ2000,
            latitudeRad: latRad,
            sinLatitude: sinLat,
            cosLatitude: cosLat
        )

        let moonPhaseAngleDeg = normalize360(moon.eclipticLongitudeDeg - sun.eclipticLongitudeDeg)
        let moonIlluminationFraction = clamp(0.5 * (1.0 - cos(toRadians(moonPhaseAngleDeg))), 0.0, 1.0)
        let earthSunDistanceAu = getEarthSunDistanceAu(sunMeanAnomalyDeg: sun.meanAnomalyDeg)

        return CelestialComputationResult(
            sunAltitudeDeg: sunAltitude.altitudeDeg,
            sunHourAngleDeg: sunAltitude.hourAngleDeg,
            sunDeclinationDeg: sun.decDeg,
            moonAltitudeDeg: moonAltitude.altitudeDeg,
            moonHourAngleDeg: moonAltitude.hourAngleDeg,
            moonDeclinationDeg: moon.decDeg,
            moonPhaseAngleDeg: moonPhaseAngleDeg,
            moonIlluminationFraction: moonIlluminationFraction,
            earthSunDistanceAu: earthSunDistanceAu
        )
    }
}
