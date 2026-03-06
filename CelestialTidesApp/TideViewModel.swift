import Foundation
import Observation

@Observable
@MainActor
public final class TideViewModel {
    public var points: [TideForecastPoint] = []
    public var extrema: [TideExtremum] = []
    public var futureExtrema: [TideExtremum] = []
    public var lastSelectedPoint: TideForecastPoint?
    public var futureRangeStart: Date = Calendar.current.startOfDay(for: Date())
    public var futureRangeEnd: Date = Calendar.current.date(byAdding: .day, value: 30, to: Calendar.current.startOfDay(for: Date())) ?? Date()
    public var chartCenterDate: Date = Date()

    private static let tableDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    private static let tableTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private static let detailDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d - h:mm a"
        return formatter
    }()
    
    public init() {}

    public func refreshChartData(config: TideConfiguration) async {
        let selectionTime = lastSelectedPoint?.timestamp
        let centerDate = chartCenterDate
        let selectionTarget = selectionTime ?? Date()
        
        let output = await Task(priority: .userInitiated) {
            let data = TideCalculations.getTideData(config: config, date: centerDate)
            return (
                points: data.points,
                extrema: data.extrema
            )
        }.value
        
        guard !Task.isCancelled else { return }
        
        self.points = output.points
        self.extrema = output.extrema
        self.lastSelectedPoint = TideCalculations.nearestPoint(in: output.points, to: selectionTarget)
    }

    public func refreshFutureData(config: TideConfiguration) async {
        let rangeStart = self.futureRangeStart
        let rangeEnd = self.futureRangeEnd

        let output = await Task(priority: .utility) {
            TideCalculations.getFutureExtrema(
                config: config,
                rangeStart: rangeStart,
                rangeEnd: rangeEnd
            )
        }.value

        guard !Task.isCancelled else { return }
        self.futureExtrema = output
    }
    
    public func clampFutureDateRange() {
        let normalized = TideCalculations.normalizedFutureRange(start: futureRangeStart, end: futureRangeEnd)
        if normalized.start != futureRangeStart {
            futureRangeStart = normalized.start
        }
        if normalized.end != futureRangeEnd {
            futureRangeEnd = normalized.end
        }
    }

    public func tableDateString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = Self.tableDateFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    public func tableTimeString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = Self.tableTimeFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date).lowercased().replacingOccurrences(of: " ", with: "")
    }
    
    public func detailDateTimeString(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = Self.detailDateTimeFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    public func trendLabel(for date: Date) -> String {
        guard !points.isEmpty, let index = TideCalculations.nearestPointIndex(in: points, to: date) else {
            return "Stable"
        }

        let prevIndex = max(0, index - 1)
        let nextIndex = min(points.count - 1, index + 1)
        let delta = points[nextIndex].tidePercent - points[prevIndex].tidePercent
        if abs(delta) < 0.1 { return "Stable" }
        return delta > 0 ? "Rising" : "Falling"
    }
    
    public func phaseName(for angle: Double) -> String {
        let normalized = angle.truncatingRemainder(dividingBy: 360.0)
        let phaseAngle = normalized < 0 ? normalized + 360.0 : normalized

        switch phaseAngle {
        case 0..<22.5, 337.5...360: return "New"
        case 22.5..<67.5: return "Waxing Cresc."
        case 67.5..<112.5: return "First Quarter"
        case 112.5..<157.5: return "Waxing Gibb."
        case 157.5..<202.5: return "Full"
        case 202.5..<247.5: return "Waning Gibb."
        case 247.5..<292.5: return "Last Quarter"
        default: return "Waning Cresc."
        }
    }
}
