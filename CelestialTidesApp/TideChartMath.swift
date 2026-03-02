import Foundation
import CoreGraphics
import SwiftUI

enum TideChartMath {
    static func panelValueToY(_ value: Double, min: Double, max: Double, top: CGFloat, height: CGFloat) -> CGFloat {
        let normalized = (value - min) / (max - min)
        return top + height - CGFloat(normalized) * height
    }
    
    static func indexToX(_ index: Int, total: Int, width: CGFloat) -> CGFloat {
        if total <= 1 { return width / 2 }
        return CGFloat(index) / CGFloat(total - 1) * width
    }
    
    static func timeToX(_ time: Date, points: [TideForecastPoint], width: CGFloat) -> CGFloat {
        guard let first = points.first, let last = points.last else { return width / 2 }
        let startMs = first.timestamp.timeIntervalSince1970
        let endMs = last.timestamp.timeIntervalSince1970
        if endMs == startMs { return width / 2 }
        
        let timeDt = time.timeIntervalSince1970
        let ratio = max(0, min(1, (timeDt - startMs) / (endMs - startMs)))
        return CGFloat(ratio) * width
    }

    static func sunColor(altitude: Double) -> Color {
        let clamped = max(-18.0, min(18.0, altitude))
        let t = (clamped + 18.0) / 36.0
        
        let nightR = 12.0, nightG = 18.0, nightB = 36.0
        let twiR = 250.0, twiG = 96.0, twiB = 114.0
        let dayR = 255.0, dayG = 210.0, dayB = 70.0
        
        let r, g, b: Double
        if t < 0.5 {
            let t2 = t * 2.0
            r = nightR + (twiR - nightR) * t2
            g = nightG + (twiG - nightG) * t2
            b = nightB + (twiB - nightB) * t2
        } else {
            let t2 = (t - 0.5) * 2.0
            r = twiR + (dayR - twiR) * t2
            g = twiG + (dayG - twiG) * t2
            b = twiB + (dayB - twiB) * t2
        }
        
        return Color(red: r/255, green: g/255, blue: b/255)
    }

    struct HoverInfo {
        let point: TideForecastPoint
        let crosshairX: CGFloat
    }

    static func currentNowX(currentTime: Date, points: [TideForecastPoint], width: CGFloat) -> CGFloat? {
        guard let first = points.first, let last = points.last else { return nil }
        guard currentTime >= first.timestamp && currentTime <= last.timestamp else { return nil }
        return timeToX(currentTime, points: points, width: width)
    }

    static func closestPoint(forX x: CGFloat, width: CGFloat, points: [TideForecastPoint]) -> TideForecastPoint? {
        guard !points.isEmpty, let first = points.first, let last = points.last else { return nil }

        let totalSeconds = last.timestamp.timeIntervalSince(first.timestamp)
        guard totalSeconds > 0 else { return nil }

        let ratio = Double(max(0, min(1, x / width)))
        let targetTime = first.timestamp.addingTimeInterval(totalSeconds * ratio)
        return TideCalculations.nearestPoint(in: points, to: targetTime)
    }

    static func currentFocusInfo(width: CGFloat, selectedPoint: TideForecastPoint?, points: [TideForecastPoint]) -> HoverInfo? {
        if let selectedPoint, let resolved = TideCalculations.nearestPoint(in: points, to: selectedPoint.timestamp) {
            return HoverInfo(point: resolved, crosshairX: timeToX(resolved.timestamp, points: points, width: width))
        }

        return nil
    }

    static func resolvedNowLabelY(
        nowX: CGFloat,
        chartMin: Double,
        chartMax: Double,
        top: CGFloat,
        height: CGFloat,
        width: CGFloat,
        extrema: [TideExtremum],
        points: [TideForecastPoint]
    ) -> CGFloat {
        let highBadgeWidth: CGFloat = 62
        let highBadgeHeight: CGFloat = 32
        let nowLabelWidth: CGFloat = 46
        let nowLabelHeight: CGFloat = 22
        let highBadgeTopMin: CGFloat = 4

        let minY = top + nowLabelHeight / 2 + 4
        let maxY = top + height - nowLabelHeight / 2 - 6
        var candidateY = top + height * 0.30

        for _ in 0..<10 {
            let nowRect = CGRect(
                x: nowX - nowLabelWidth / 2,
                y: candidateY - nowLabelHeight / 2,
                width: nowLabelWidth,
                height: nowLabelHeight
            )

            let overlapsHighBadge = extrema.contains { extremum in
                guard extremum.type == .high else { return false }
                let highX = timeToX(extremum.timestamp, points: points, width: width)
                let highY = panelValueToY(extremum.tidePercent, min: chartMin, max: chartMax, top: top, height: height)
                let highBadgeTop = max(top + highBadgeTopMin, highY - 42)
                let highBadgeRect = CGRect(
                    x: highX - highBadgeWidth / 2,
                    y: highBadgeTop,
                    width: highBadgeWidth,
                    height: highBadgeHeight
                )
                return nowRect.intersects(highBadgeRect.insetBy(dx: -2, dy: -2))
            }

            if !overlapsHighBadge {
                break
            }

            candidateY += 18
            if candidateY > maxY {
                break
            }
        }

        return min(max(candidateY, minY), maxY)
    }
}
