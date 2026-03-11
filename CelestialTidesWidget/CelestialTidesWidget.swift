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
        if context.isPreview {
            completion(TideEntry(date: Date(), points: [], extrema: [], timeZone: .current))
        } else {
            let currentDate = Date()
            let config = TideCalculations.getConfiguration()
            let allData = TideCalculations.getTideData(config: config, date: currentDate)
            completion(TideEntry(date: currentDate, points: allData.points, extrema: allData.extrema, timeZone: config.timeZone))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TideEntry>) -> Void) {
        let currentDate = Date()
        let config = TideCalculations.getConfiguration()
        
        let endOfForecast = Calendar.current.date(byAdding: .hour, value: config.hoursAfterNow, to: currentDate)
            ?? currentDate.addingTimeInterval(Double(config.hoursAfterNow) * 3_600)
        
        // Fetch the full continuous data set natively
        let allData = TideCalculations.getTideData(config: config, date: currentDate)
        
        // Single Entry containing the complete curve for the widget to render using native views
        let entry = TideEntry(
            date: currentDate,
            points: allData.points,
            extrema: allData.extrema,
            timeZone: config.timeZone
        )
        
        // WidgetKit will render the curve and then fetch new data tomorrow
        completion(Timeline(entries: [entry], policy: .after(endOfForecast)))
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
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                AccessoryCircularTideView(points: entry.points, extrema: entry.extrema, currentTime: entry.date)
            case .accessoryRectangular:
                AccessoryRectangularTideView(points: entry.points, extrema: entry.extrema, currentTime: entry.date)
            case .accessoryInline:
                AccessoryInlineTideView(points: entry.points, extrema: entry.extrema, currentTime: entry.date, timeZone: entry.timeZone)
            default:
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
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
