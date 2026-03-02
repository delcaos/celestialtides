import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage(SharedDefaults.Key.customLatitude, store: SharedDefaults.store) private var customLatitude: Double = 0.0
    @AppStorage(SharedDefaults.Key.customLongitude, store: SharedDefaults.store) private var customLongitude: Double = 0.0
    @AppStorage(SharedDefaults.Key.offsetHours, store: SharedDefaults.store) private var offsetHours: Int = 0
    @AppStorage(SharedDefaults.Key.offsetMinutes, store: SharedDefaults.store) private var offsetMinutes: Int = 0
    @AppStorage(SharedDefaults.Key.selectedTimeZone, store: SharedDefaults.store) private var selectedTimeZone: String = TimeZoneSelection.localIdentifier
    @AppStorage(SharedDefaults.Key.hoursBeforeNow, store: SharedDefaults.store) private var hoursBeforeNow: Int = TideConfigurationLimits.defaultHoursBeforeNow
    @AppStorage(SharedDefaults.Key.hoursAfterNow, store: SharedDefaults.store) private var hoursAfterNow: Int = TideConfigurationLimits.defaultHoursAfterNow
    @AppStorage(SharedDefaults.Key.hasSeenExplainer, store: SharedDefaults.store) private var hasSeenExplainer: Bool = false
    @AppStorage(SharedDefaults.Key.isTideCalibrated, store: SharedDefaults.store) private var isTideCalibrated: Bool = true

    @StateObject private var locationManager = LocationManager()
    @State private var viewModel = TideViewModel()
    
    @State private var showSettings: Bool = false

    private struct ChartRefreshInput: Equatable {
        let selectedTimeZone: String
        let offsetHours: Int
        let offsetMinutes: Int
        let customLatitude: Double
        let customLongitude: Double
        let hoursBeforeNow: Int
        let hoursAfterNow: Int
        let chartCenterDate: Date
    }

    private struct FutureRefreshInput: Equatable {
        let selectedTimeZone: String
        let offsetHours: Int
        let offsetMinutes: Int
        let customLatitude: Double
        let customLongitude: Double
        let futureRangeStart: Date
        let futureRangeEnd: Date
    }

    private var chartRefreshInput: ChartRefreshInput {
        ChartRefreshInput(
            selectedTimeZone: selectedTimeZone,
            offsetHours: offsetHours,
            offsetMinutes: offsetMinutes,
            customLatitude: customLatitude,
            customLongitude: customLongitude,
            hoursBeforeNow: hoursBeforeNow,
            hoursAfterNow: hoursAfterNow,
            chartCenterDate: viewModel.chartCenterDate
        )
    }

    private var futureRefreshInput: FutureRefreshInput {
        FutureRefreshInput(
            selectedTimeZone: selectedTimeZone,
            offsetHours: offsetHours,
            offsetMinutes: offsetMinutes,
            customLatitude: customLatitude,
            customLongitude: customLongitude,
            futureRangeStart: viewModel.futureRangeStart,
            futureRangeEnd: viewModel.futureRangeEnd
        )
    }
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel
        
        VStack(spacing: 0) {
            TopNavigationView(
                onSettingsTap: { showSettings = true }
            )

            ScrollView {
                if !isTideCalibrated {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Calibration Required")
                            .font(.title2.bold())
                        Text("Please set the next high tide for your new location in settings to calibrate the forecast.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button(action: { showSettings = true }) {
                            Text("Open Settings")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .padding(.horizontal, 32)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        chartContainer
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )

                        LastSelectionPanel(
                            lastSelectedPoint: viewModel.lastSelectedPoint,
                            timeFormatter: { date in
                                viewModel.detailDateTimeString(date, timeZone: resolvedTimeZone)
                            },
                            trendLabelProvider: viewModel.trendLabel(for:),
                            phaseNameProvider: viewModel.phaseName(for:)
                        )

                        FutureTidesTable(
                            futureRangeStart: $bindableViewModel.futureRangeStart,
                            futureRangeEnd: $bindableViewModel.futureRangeEnd,
                            futureExtrema: viewModel.futureExtrema,
                            dateStringProvider: { date in
                                viewModel.tableDateString(date, timeZone: resolvedTimeZone)
                            },
                            timeStringProvider: { date in
                                viewModel.tableTimeString(date, timeZone: resolvedTimeZone)
                            }
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            SettingsSheet(
                selectedTimeZone: $selectedTimeZone,
                customLatitude: $customLatitude,
                customLongitude: $customLongitude,
                offsetHours: $offsetHours,
                offsetMinutes: $offsetMinutes,
                hoursBeforeNow: $hoursBeforeNow,
                hoursAfterNow: $hoursAfterNow,
                onUseCurrentLocation: {
                    locationManager.requestLocation()
                },
                onDone: {
                    showSettings = false
                    WidgetCenter.shared.reloadAllTimelines()
                }
            )
            .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !hasSeenExplainer {
                showSettings = true
                hasSeenExplainer = true
            }
            locationManager.onLocationUpdated = { loc in
                customLatitude = loc.coordinate.latitude
                customLongitude = loc.coordinate.longitude
            }
            viewModel.clampFutureDateRange()
        }
        .onChange(of: viewModel.futureRangeStart) { _, _ in viewModel.clampFutureDateRange() }
        .onChange(of: viewModel.futureRangeEnd) { _, _ in viewModel.clampFutureDateRange() }
        .task(id: chartRefreshInput) {
            await viewModel.refreshChartData(config: chartConfiguration(for: chartRefreshInput))
        }
        .task(id: futureRefreshInput) {
            await viewModel.refreshFutureData(config: futureConfiguration(for: futureRefreshInput))
        }
        .alert("Location Error", isPresented: locationErrorBinding) {
            Button("OK", role: .cancel) {
                locationManager.errorMessage = nil
            }
        } message: {
            Text(locationManager.errorMessage ?? "Unable to determine location.")
        }
    }

    @ViewBuilder
    private var chartContainer: some View {
        if viewModel.points.isEmpty {
            Text("Loading Tides...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            TideChart(
                points: viewModel.points,
                extrema: viewModel.extrema,
                timeZone: resolvedTimeZone,
                currentTime: Date(),
                selectedPoint: viewModel.lastSelectedPoint,
                onPointSelected: { point in
                    viewModel.lastSelectedPoint = point
                },
                onPan: { timeShift in
                    viewModel.chartCenterDate = viewModel.chartCenterDate.addingTimeInterval(timeShift)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var resolvedTimeZone: TimeZone {
        TimeZoneSelection.resolve(identifier: selectedTimeZone)
    }

    private var locationErrorBinding: Binding<Bool> {
        Binding(
            get: { locationManager.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    locationManager.errorMessage = nil
                }
            }
        )
    }

    private func chartConfiguration(for input: ChartRefreshInput) -> TideConfiguration {
        let normalizedOffset = TideConfigurationLimits.normalizeOffsetComponents(
            hours: input.offsetHours,
            minutes: input.offsetMinutes
        )
        let totalOffset = Double(normalizedOffset.hours) + Double(normalizedOffset.minutes) / 60.0

        return TideConfiguration(
            latitude: input.customLatitude,
            longitude: input.customLongitude,
            offsetHours: totalOffset,
            timeZone: TimeZoneSelection.resolve(identifier: input.selectedTimeZone),
            hoursBeforeNow: input.hoursBeforeNow,
            hoursAfterNow: input.hoursAfterNow
        )
    }

    private func futureConfiguration(for input: FutureRefreshInput) -> TideConfiguration {
        let normalizedOffset = TideConfigurationLimits.normalizeOffsetComponents(
            hours: input.offsetHours,
            minutes: input.offsetMinutes
        )
        let totalOffset = Double(normalizedOffset.hours) + Double(normalizedOffset.minutes) / 60.0

        return TideConfiguration(
            latitude: input.customLatitude,
            longitude: input.customLongitude,
            offsetHours: totalOffset,
            timeZone: TimeZoneSelection.resolve(identifier: input.selectedTimeZone)
        )
    }
}

#Preview {
    ContentView()
}
