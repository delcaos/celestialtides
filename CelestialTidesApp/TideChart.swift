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
