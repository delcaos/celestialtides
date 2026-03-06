import SwiftUI

struct ExtremaBadgesView: View {
    let extrema: [TideExtremum]
    let points: [TideForecastPoint]
    let width: CGFloat
    let panelHeight: CGFloat
    let topMargin: CGFloat
    let chartMin: Double
    let chartMax: Double
    let timeZone: TimeZone

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private func formatTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = Self.timeFormatter
        formatter.timeZone = timeZone
        return formatter.string(from: date).lowercased().replacingOccurrences(of: " ", with: "")
    }

    var body: some View {
        ForEach(extrema, id: \.timestamp) { extremum in
            let x = TideChartMath.timeToX(extremum.timestamp, points: points, width: width)
            let tideY = TideChartMath.panelValueToY(extremum.tidePercent, min: chartMin, max: chartMax, top: topMargin, height: panelHeight)
            let isHigh = extremum.type == .high
            
            let badgeWidth: CGFloat = 66
            let badgeHeight: CGFloat = 34
            let badgeY = isHigh ? max(topMargin + 6, tideY - 44) : min(topMargin + panelHeight - badgeHeight - 6, tideY + 14)
            
            let primaryColor = isHigh ? Color(red: 255/255, green: 59/255, blue: 48/255) : Color(red: 175/255, green: 82/255, blue: 222/255)
            let textColor = Color.white
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(primaryColor, lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                .position(x: x, y: tideY)
            
            // Badge rect
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.thickMaterial)
                .frame(width: badgeWidth, height: badgeHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(primaryColor.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
                .position(x: x, y: badgeY + badgeHeight / 2)
            
            // Badge text
            VStack(spacing: 1) {
                Text(extremum.type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(primaryColor)
                
                Text(formatTime(extremum.timestamp, timeZone: timeZone))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(textColor.opacity(0.95))
            }
            .position(x: x, y: badgeY + badgeHeight / 2)
        }
    }
}
