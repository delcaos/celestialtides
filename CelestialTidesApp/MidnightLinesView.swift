import SwiftUI

struct MidnightLinesView: View {
    let points: [TideForecastPoint]
    let timeZone: TimeZone
    let width: CGFloat
    let panelHeight: CGFloat
    let topMargin: CGFloat
    let showsDayLabels: Bool

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    private func formatDay(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = Self.dayFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        if let first = points.first, let last = points.last {
            let days: [Date] = {
                var calendar = Calendar.current
                calendar.timeZone = timeZone
                
                var current = calendar.startOfDay(for: first.timestamp)
                if current <= first.timestamp {
                     current = calendar.date(byAdding: .day, value: 1, to: current)!
                }
                
                var result: [Date] = []
                while current <= last.timestamp {
                    result.append(current)
                    current = calendar.date(byAdding: .day, value: 1, to: current)!
                }
                return result
            }()
            
            ForEach(days, id: \.self) { current in
                let x = TideChartMath.timeToX(current, points: points, width: width)
                let clampedLabelX = min(max(x + 24, 34), width - 34)
                let dayLabelY = topMargin + panelHeight - 12
                
                Path { path in
                    path.move(to: CGPoint(x: x, y: topMargin))
                    path.addLine(to: CGPoint(x: x, y: topMargin + panelHeight))
                }
                .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                
                if showsDayLabels {
                    Text(formatDay(current, timeZone: timeZone))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                        .position(x: clampedLabelX, y: dayLabelY)
                }
            }
        }
    }
}
