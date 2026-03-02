import Foundation

enum TimeZoneSelection {
    static let localIdentifier = "local"

    static func resolve(
        identifier: String?,
        fallback: TimeZone = .current
    ) -> TimeZone {
        guard let identifier else {
            return fallback
        }
        if identifier == localIdentifier {
            return .current
        }
        return TimeZone(identifier: identifier) ?? fallback
    }
}
