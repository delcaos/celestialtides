import SwiftUI

struct FutureTidesTable: View {
    @Binding var futureRangeStart: Date
    @Binding var futureRangeEnd: Date
    let futureExtrema: [TideExtremum]
    let dateStringProvider: (Date) -> String
    let timeStringProvider: (Date) -> String
    
    private var futureTableColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 88), alignment: .leading),
            GridItem(.flexible(minimum: 70), alignment: .leading),
            GridItem(.flexible(minimum: 56), alignment: .leading),
            GridItem(.flexible(minimum: 70), alignment: .trailing)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tide Table")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(futureExtrema.count) events")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FROM")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(0.5)
                    DatePicker("From", selection: $futureRangeStart, displayedComponents: .date)
                        .labelsHidden()
                        .blendMode(.screen)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("TO")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(0.5)
                    DatePicker("To", selection: $futureRangeEnd, in: futureRangeStart..., displayedComponents: .date)
                        .labelsHidden()
                        .blendMode(.screen)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            VStack(spacing: 0) {
                LazyVGrid(columns: futureTableColumns, spacing: 8) {
                    Text("DATE")
                    Text("TIME")
                    Text("TYPE")
                    Text("TIDE")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .kerning(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.04))

                Divider()
                    .overlay(Color.white.opacity(0.1))

                LazyVStack(spacing: 0) {
                    if futureExtrema.isEmpty {
                        Text("No tide extrema found in the selected range.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(Array(futureExtrema.enumerated()), id: \.offset) { index, extremum in
                            LazyVGrid(columns: futureTableColumns, spacing: 8) {
                                Text(dateStringProvider(extremum.timestamp))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(timeStringProvider(extremum.timestamp))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(extremum.type == .high ? "High" : "Low")
                                    .foregroundColor(extremum.type == .high ? Color(red: 255/255, green: 59/255, blue: 48/255) : Color(red: 175/255, green: 82/255, blue: 222/255))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(String(format: "%+.0f%%", extremum.tidePercent))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.02))

                            if index < futureExtrema.count - 1 {
                                Divider()
                                    .overlay(Color.white.opacity(0.06))
                            }
                        }
                    }
                }
            }
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
        }
    }
}
