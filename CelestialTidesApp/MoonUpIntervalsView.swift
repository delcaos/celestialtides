import SwiftUI

struct MoonUpInterval {
    let start: Date
    let end: Date
}

struct MoonUpIntervalsView: View {
    let points: [TideForecastPoint]
    let width: CGFloat
    let panelHeight: CGFloat
    let topMargin: CGFloat
    let chartMin: Double
    let chartMax: Double

    var body: some View {
        if !points.isEmpty {
            let moonUpIntervals = calculateMoonUpIntervals(from: points)
            let middleY = TideChartMath.panelValueToY(0, min: chartMin, max: chartMax, top: topMargin, height: panelHeight)
            let moonBarY = middleY

            ForEach(moonUpIntervals, id: \.start) { interval in
                let startX = TideChartMath.timeToX(interval.start, points: points, width: width)
                let endX = TideChartMath.timeToX(interval.end, points: points, width: width)
                
                Path { path in
                    path.move(to: CGPoint(x: startX, y: moonBarY))
                    path.addLine(to: CGPoint(x: endX, y: moonBarY))
                }
                .stroke(Color.white.opacity(0.44), style: StrokeStyle(lineWidth: 2, lineCap: .round))

                Image(systemName: "moonrise.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.52))
                    .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                    .position(x: startX, y: moonBarY)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Moon up")

                Image(systemName: "moonset.fill")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.52))
                    .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                    .position(x: endX, y: moonBarY)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Moon down")
            }
        }
    }

    private func calculateMoonUpIntervals(from points: [TideForecastPoint]) -> [MoonUpInterval] {
        guard points.count > 1, let first = points.first, let last = points.last else { return [] }

        var intervals: [MoonUpInterval] = []
        var currentStart: Date? = first.moonAltitudeDeg >= 0 ? first.timestamp : nil

        for (pt1, pt2) in zip(points, points.dropFirst()) {
            if pt1.moonAltitudeDeg < 0 && pt2.moonAltitudeDeg >= 0 {
                currentStart = crossingTimestamp(from: pt1, to: pt2)
            } else if pt1.moonAltitudeDeg >= 0 && pt2.moonAltitudeDeg < 0 {
                let intervalEnd = crossingTimestamp(from: pt1, to: pt2)
                let intervalStart = currentStart ?? pt1.timestamp
                if intervalEnd > intervalStart {
                    intervals.append(MoonUpInterval(start: intervalStart, end: intervalEnd))
                }
                currentStart = nil
            }
        }

        if let start = currentStart, last.timestamp > start {
            intervals.append(MoonUpInterval(start: start, end: last.timestamp))
        }

        return intervals
    }

    private func crossingTimestamp(from start: TideForecastPoint, to end: TideForecastPoint) -> Date {
        let altitudeDelta = end.moonAltitudeDeg - start.moonAltitudeDeg
        guard altitudeDelta != 0 else { return end.timestamp }
        let crossingRatio = max(0.0, min(1.0, -start.moonAltitudeDeg / altitudeDelta))
        let segmentDuration = end.timestamp.timeIntervalSince(start.timestamp)
        return start.timestamp.addingTimeInterval(segmentDuration * crossingRatio)
    }
}
