import SwiftUI

struct LastSelectionPanel: View {
    let lastSelectedPoint: TideForecastPoint?
    let timeFormatter: (Date) -> String
    let trendLabelProvider: (Date) -> String
    let phaseNameProvider: (Double) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last Selected Point")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            if let selected = lastSelectedPoint {
                let selectedTrend = trendLabelProvider(selected.timestamp)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    LastSelectionCell(label: "Time", value: timeFormatter(selected.timestamp))
                    LastSelectionCell(label: "Tide", value: String(format: "%+.0f%%", selected.tidePercent))
                    LastSelectionCell(label: "Trend", value: selectedTrend)
                    LastSelectionCell(label: "Sun Alt", value: String(format: "%+.1f deg", selected.sunAltitudeDeg))
                    LastSelectionCell(label: "Moon Alt", value: String(format: "%+.1f deg", selected.moonAltitudeDeg))
                    LastSelectionCell(label: "Illum", value: String(format: "%.0f%%", selected.moonIlluminationFraction * 100))
                    LastSelectionCell(label: "Moon Force", value: String(format: "%+.0f%%", selected.moonContributionPercent))
                    LastSelectionCell(label: "Sun Force", value: String(format: "%+.0f%%", selected.sunContributionPercent))
                    LastSelectionCell(label: "Phase", value: phaseNameProvider(selected.moonPhaseAngleDeg))
                }
            } else {
                Text("Tap or drag on the chart to lock in a point and inspect details here.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
