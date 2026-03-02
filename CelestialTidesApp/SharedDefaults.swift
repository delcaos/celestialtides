import Foundation

enum SharedDefaults {
    static let suiteName = "group.app.delcaos.celestialtides"
    static let store = UserDefaults(suiteName: suiteName)

    enum Key {
        static let customLatitude = "customLatitude"
        static let customLongitude = "customLongitude"
        static let offsetHours = "offsetHours"
        static let offsetMinutes = "offsetMinutes"
        static let selectedTimeZone = "selectedTimeZone"
        static let hoursBeforeNow = "hoursBeforeNow"
        static let hoursAfterNow = "hoursAfterNow"
        static let hasSeenExplainer = "hasSeenExplainer"
        static let isTideCalibrated = "isTideCalibrated"
    }
}
