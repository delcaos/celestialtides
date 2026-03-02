import WidgetKit
import SwiftUI
#if canImport(CelestialTidesApp)
import CelestialTidesApp
#endif

struct Provider: TimelineProvider {
    private let timelineStepMinutes = 15
    private let forecastWindowHours = 24

    func placeholder(in context: Context) -> TideEntry {
        TideEntry(date: Date(), points: [], extrema: [], timeZone: .current)
    }

    func getSnapshot(in context: Context, completion: @escaping (TideEntry) -> Void) {
        completion(TideEntry(date: Date(), points: [], extrema: [], timeZone: .current))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TideEntry>) -> Void) {
        let currentDate = Date()
        let endOfForecast = Calendar.current.date(byAdding: .hour, value: forecastWindowHours, to: currentDate)
            ?? currentDate.addingTimeInterval(Double(forecastWindowHours) * 3_600)
        
        let config = TideCalculations.getConfiguration()
        
        let data = TideCalculations.getTideData(config: config, date: currentDate)
        
        var entries: [TideEntry] = []
        var currentEntryDate = currentDate
        
        // Generate an entry every 15 minutes to keep the NOW line moving
        while currentEntryDate < endOfForecast {
            let entry = TideEntry(
                date: currentEntryDate,
                points: data.points,
                extrema: data.extrema,
                timeZone: config.timeZone
            )
            entries.append(entry)
            currentEntryDate = Calendar.current.date(byAdding: .minute, value: timelineStepMinutes, to: currentEntryDate) ?? endOfForecast
        }
        
        // Refresh at the end of the forecast
        completion(Timeline(entries: entries, policy: .after(endOfForecast)))
    }
}

struct TideEntry: TimelineEntry {
    let date: Date
    let points: [TideForecastPoint]
    let extrema: [TideExtremum]
    let timeZone: TimeZone
}

struct CelestialTidesWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 0) {
            if entry.points.isEmpty {
                Text("Loading Tides...")
            } else {
                TideChart(
                    points: entry.points,
                    extrema: entry.extrema,
                    timeZone: entry.timeZone,
                    currentTime: entry.date,
                    showsDayLabels: false
                )
            }
        }
        .containerBackground(Color(red: 4/255, green: 24/255, blue: 33/255), for: .widget)
    }
}

@main
struct CelestialTidesWidget: Widget {
    let kind: String = "CelestialTidesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CelestialTidesWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Celestial Tides")
        .description("Estimates tides offline from sun/moon positions, lunar phase, declination, and Earth-Sun distance. Results may differ from local stations.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
