import SwiftUI

struct AppExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How it works", systemImage: "questionmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("Celestial Tides computes the gravitational pull from the moon and sun to estimate tide levels completely offline. No internet connection is required.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "chart.xyaxis.line",
                            title: "Interactive Chart",
                            description: "The main graph displays upcoming tide levels. Drag left or right to look into the future. You can tap anywhere on the curve to see the exact forecasted tide level for that time."
                        )

                        FeatureRow(
                            icon: "location.fill",
                            title: "Custom Locations",
                            description: "Tap the gear icon on the main screen to set your geographic coordinates and time zone. The app will immediately generate tide forecasts tailored exactly to your specified area."
                        )
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Label("Home Screen Widget", systemImage: "apps.iphone")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text("Add the Celestial Tides widget to your iOS home screen to see the forecast at a glance.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Image("WidgetScreenshot")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                Text("Moon Rise & Set")
                                    .fontWeight(.semibold)
                            }
                            Text("The circles inside the graph represent when the moon rises (solid) and sets (hollow) over your location. This helps you correlate tidal intensity with the moon's position.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 32)

                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sun.max.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                Text("Day vs Night")
                                    .fontWeight(.semibold)
                            }
                            Text("The background color of the chart changes dynamically to indicate daytime (brighter background) and nighttime (darker background) hours.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 32)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("About Celestial Tides")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done").bold()
                    }
                }
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
