import SwiftUI

public struct TideChart: View {
    public var points: [TideForecastPoint]
    public var extrema: [TideExtremum]
    public var timeZone: TimeZone
    public var currentTime: Date
    public var showsDayLabels: Bool
    public var selectedPoint: TideForecastPoint?
    public var onPointSelected: ((TideForecastPoint) -> Void)?
    public var onPan: ((TimeInterval) -> Void)?
    
    @GestureState private var dragTranslationX: CGFloat = 0

    public init(
        points: [TideForecastPoint],
        extrema: [TideExtremum],
        timeZone: TimeZone = .current,
        currentTime: Date = Date(),
        showsDayLabels: Bool = true,
        selectedPoint: TideForecastPoint? = nil,
        onPointSelected: ((TideForecastPoint) -> Void)? = nil,
        onPan: ((TimeInterval) -> Void)? = nil
    ) {
        self.points = points
        self.extrema = extrema
        self.timeZone = timeZone
        self.currentTime = currentTime
        self.showsDayLabels = showsDayLabels
        self.selectedPoint = selectedPoint
        self.onPointSelected = onPointSelected
        self.onPan = onPan
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let panelHeight = height
            let topMargin: CGFloat = 0
            
            let chartMax: Double = 100.0
            let chartMin: Double = -100.0
            let nowX = TideChartMath.currentNowX(currentTime: currentTime, points: points, width: width)
            let focusInfo = TideChartMath.currentFocusInfo(width: width, selectedPoint: selectedPoint, points: points)
            
            ZStack {
                
                if !points.isEmpty {
                    let maxStops = 40
                    let step = max(1, points.count / maxStops)
                    let stops: [Gradient.Stop] = {
                        var tempStops: [Gradient.Stop] = []
                        for index in stride(from: 0, to: points.count, by: step) {
                            let location = CGFloat(index) / CGFloat(max(1, points.count - 1))
                            tempStops.append(.init(color: TideChartMath.sunColor(altitude: points[index].sunAltitudeDeg), location: location))
                        }
                        if let last = points.last, (points.count - 1) % step != 0 {
                            tempStops.append(.init(color: TideChartMath.sunColor(altitude: last.sunAltitudeDeg), location: 1.0))
                        }
                        return tempStops
                    }()
                    LinearGradient(gradient: Gradient(stops: stops), startPoint: .leading, endPoint: .trailing)
                        .edgesIgnoringSafeArea(.all)
                        .allowsHitTesting(false)
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 24/255, green: 28/255, blue: 36/255),
                            Color(red: 16/255, green: 20/255, blue: 28/255)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
                }
                
                // Current Time (NOW) line
                if let nowX {
                    Path { path in
                        path.move(to: CGPoint(x: nowX, y: 0))
                        path.addLine(to: CGPoint(x: nowX, y: height))
                    }
                    .stroke(Color(red: 34/255, green: 211/255, blue: 238/255).opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
                
                MidnightLinesView(
                    points: points,
                    timeZone: timeZone,
                    width: width,
                    panelHeight: panelHeight,
                    topMargin: topMargin,
                    showsDayLabels: showsDayLabels
                )
                
                TidePathView(
                    points: points,
                    width: width,
                    height: height,
                    panelHeight: panelHeight,
                    topMargin: topMargin,
                    chartMin: chartMin,
                    chartMax: chartMax
                )
                
                ExtremaBadgesView(
                    extrema: extrema,
                    points: points,
                    width: width,
                    panelHeight: panelHeight,
                    topMargin: topMargin,
                    chartMin: chartMin,
                    chartMax: chartMax,
                    timeZone: timeZone
                )
                
                MoonUpIntervalsView(
                    points: points,
                    width: width,
                    panelHeight: panelHeight,
                    topMargin: topMargin,
                    chartMin: chartMin,
                    chartMax: chartMax
                )
                
                // Interactive hover details
                if let focusInfo {
                    let pointY = TideChartMath.panelValueToY(focusInfo.point.tidePercent, min: chartMin, max: chartMax, top: topMargin, height: panelHeight)

                    Path { path in
                        path.move(to: CGPoint(x: focusInfo.crosshairX, y: topMargin))
                        path.addLine(to: CGPoint(x: focusInfo.crosshairX, y: topMargin + panelHeight))
                    }
                    .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))

                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                        .position(x: focusInfo.crosshairX, y: pointY)
                }

                // NOW label is intentionally drawn last so it stays on top.
                if let nowX {
                    let nowLabelY = TideChartMath.resolvedNowLabelY(
                        nowX: nowX,
                        chartMin: chartMin,
                        chartMax: chartMax,
                        top: topMargin,
                        height: panelHeight,
                        width: width,
                        extrema: extrema,
                        points: points
                    )

                    let nowColor = Color(red: 34/255, green: 211/255, blue: 238/255)

                    Text("NOW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(nowColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(nowColor.opacity(0.6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .position(x: nowX, y: nowLabelY)
                        .zIndex(100)
                }
            }
            .offset(x: dragTranslationX)
            .contentShape(Rectangle())
            .environment(\.colorScheme, .dark)
            .gesture(
                DragGesture(coordinateSpace: .local)
                    .updating($dragTranslationX) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        guard let first = points.first, let last = points.last else { return }
                        let totalSeconds = last.timestamp.timeIntervalSince(first.timestamp)
                        guard totalSeconds > 0, width > 0 else { return }
                        let secondsPerPixel = totalSeconds / width
                        let timeShift = -TimeInterval(value.translation.width * secondsPerPixel)
                        onPan?(timeShift)
                    }
            )
            .simultaneousGesture(SpatialTapGesture(coordinateSpace: .local).onEnded { value in
                if let selected = TideChartMath.closestPoint(forX: value.location.x, width: width, points: points) {
                    onPointSelected?(selected)
                }
            })
        }
    }
}

public struct AccessoryCircularTideView: View {
    public var points: [TideForecastPoint]
    public var extrema: [TideExtremum]
    public var currentTime: Date

    public init(points: [TideForecastPoint], extrema: [TideExtremum], currentTime: Date) {
        self.points = points
        self.extrema = extrema
        self.currentTime = currentTime
    }

    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            if points.isEmpty {
                ZStack {
                    Circle().strokeBorder(Color.primary.opacity(0.3), lineWidth: 2)
                    Text("--")
                        .font(.system(size: 10))
                }
            } else {
                let sortedPoints = points.sorted(by: { $0.timestamp < $1.timestamp })
                let displayMin = -100.0
                let displayMax = 100.0

                TimelineView(.periodic(from: Date(), by: 60.0)) { context in
                    let nextExtremum = extrema.first(where: { $0.timestamp > context.date })
                    let isRising = nextExtremum?.type == .high
                    
                    ZStack {
                        // Background Chart
                        Path { path in
                            var first = true
                            for point in sortedPoints {
                                let x = TideChartMath.timeToX(point.timestamp, points: sortedPoints, width: width)
                                let y = TideChartMath.panelValueToY(point.tidePercent, min: displayMin, max: displayMax, top: 0, height: height)
                                if first {
                                    path.move(to: CGPoint(x: x, y: y))
                                    first = false
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.primary.opacity(0.5), style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                        
                        // Current time indicator and Up/Down Arrow
                        if let nowX = TideChartMath.currentNowX(currentTime: context.date, points: sortedPoints, width: width) {
                            Path { path in
                                path.move(to: CGPoint(x: nowX, y: 0))
                                path.addLine(to: CGPoint(x: nowX, y: height))
                            }
                            .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            
                            if let current = TideCalculations.nearestPoint(in: sortedPoints, to: context.date) {
                                let y = TideChartMath.panelValueToY(current.tidePercent, min: displayMin, max: displayMax, top: 0, height: height)
                                
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 6, height: 6)
                                    .position(x: nowX, y: y)
                            }
                            
                            // (No center icon as per user request to remove arrow and waves)
                        }
                        
                        // Border to make it look circular
                        Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1.5)
                    }
                    .clipShape(Circle())
                }
            }
        }
    }
}

public struct AccessoryRectangularTideView: View {
    public var points: [TideForecastPoint]
    public var extrema: [TideExtremum]
    public var currentTime: Date

    public init(points: [TideForecastPoint], extrema: [TideExtremum], currentTime: Date) {
        self.points = points
        self.extrema = extrema
        self.currentTime = currentTime
    }

    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            if points.isEmpty {
                let nowX = width / 2
                Path { path in
                    path.move(to: CGPoint(x: nowX, y: 0))
                    path.addLine(to: CGPoint(x: nowX, y: height))
                }
                .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                
                Text("No Data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .position(x: nowX, y: height / 2)
            } else {
                let sortedPoints = points.sorted(by: { $0.timestamp < $1.timestamp })
                let displayMin = -100.0
                let displayMax = 100.0

                TimelineView(.periodic(from: Date(), by: 60.0)) { context in
                    // Draw current time line first so it's behind the curve
                    if let nowX = TideChartMath.currentNowX(currentTime: context.date, points: sortedPoints, width: width) {
                        Path { path in
                            path.move(to: CGPoint(x: nowX, y: 0))
                            path.addLine(to: CGPoint(x: nowX, y: height))
                        }
                        .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        
                        // Draw a dot for current time
                        if let current = TideCalculations.nearestPoint(in: sortedPoints, to: context.date) {
                            let y = TideChartMath.panelValueToY(current.tidePercent, min: displayMin, max: displayMax, top: 0, height: height)
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 8, height: 8)
                                .position(x: nowX, y: y)
                        }
                    }
                }

                // Draw a simple path
                Path { path in
                    var first = true
                    for point in sortedPoints {
                        let x = TideChartMath.timeToX(point.timestamp, points: sortedPoints, width: width)
                        let y = TideChartMath.panelValueToY(point.tidePercent, min: displayMin, max: displayMax, top: 0, height: height)
                        if first {
                            path.move(to: CGPoint(x: x, y: y))
                            first = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        .padding(.vertical, 4)
    }
}

public struct AccessoryInlineTideView: View {
    public var points: [TideForecastPoint]
    public var extrema: [TideExtremum]
    public var currentTime: Date
    public var timeZone: TimeZone

    public init(points: [TideForecastPoint], extrema: [TideExtremum], currentTime: Date, timeZone: TimeZone) {
        self.points = points
        self.extrema = extrema
        self.currentTime = currentTime
        self.timeZone = timeZone
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    public var body: some View {
        TimelineView(.periodic(from: Date(), by: 60.0)) { context in
            if let nextExtremum = extrema.first(where: { $0.timestamp > context.date }) {
                let label = nextExtremum.type == .high ? "High" : "Low"
                let timeStr = timeString(for: nextExtremum.timestamp)
                
                ViewThatFits {
                    Text(Image(systemName: "water.waves")).bold() + Text(" \(label) tide at \(timeStr)")
                    Text("\(label) tide at \(timeStr)")
                    Text("\(label) at \(timeStr)")
                }
            } else {
                Text("Tides • No Data")
            }
        }
    }
}
