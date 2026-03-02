import SwiftUI

struct TidePathView: View {
    let points: [TideForecastPoint]
    let width: CGFloat
    let height: CGFloat
    let panelHeight: CGFloat
    let topMargin: CGFloat
    let chartMin: Double
    let chartMax: Double

    var body: some View {
        if !points.isEmpty {
            let tidePath = Path { path in
                for (index, point) in points.enumerated() {
                    let x = TideChartMath.indexToX(index, total: points.count, width: width)
                    let y = TideChartMath.panelValueToY(point.tidePercent, min: chartMin, max: chartMax, top: topMargin, height: panelHeight)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }

            // Fill under the curve
            Path { path in
                path.addPath(tidePath)
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            tidePath
                .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }
}
