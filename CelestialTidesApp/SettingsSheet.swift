import SwiftUI
import MapKit

struct SettingsSheet: View {
    @Binding var selectedTimeZone: String
    @Binding var customLatitude: Double
    @Binding var customLongitude: Double
    @Binding var offsetHours: Int
    @Binding var offsetMinutes: Int
    @Binding var hoursBeforeNow: Int
    @Binding var hoursAfterNow: Int
    
    @AppStorage(SharedDefaults.Key.isTideCalibrated, store: SharedDefaults.store) private var isTideCalibrated: Bool = true
    
    @State private var viewModel = SettingsViewModel()
    @State private var hasAppeared = false
    
    let onUseCurrentLocation: () -> Void
    let onDone: () -> Void

    private var resolvedTimeZone: TimeZone {
        TimeZoneSelection.resolve(identifier: selectedTimeZone)
    }

    private struct CoordinatesInput: Equatable {
        let latitude: Double
        let longitude: Double
    }

    private struct HoursWindowInput: Equatable {
        let before: Int
        let after: Int
    }

    private var coordinatesInput: CoordinatesInput {
        CoordinatesInput(latitude: customLatitude, longitude: customLongitude)
    }

    private var hoursWindowInput: HoursWindowInput {
        HoursWindowInput(before: hoursBeforeNow, after: hoursAfterNow)
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        NavigationStack {
            Form {
                LocationSettingsSection(
                    selectedTimeZone: $selectedTimeZone,
                    customLatitude: $customLatitude,
                    customLongitude: $customLongitude,
                    mapCameraPosition: $bindableViewModel.mapCameraPosition,
                    isMapUpdatingCoords: $bindableViewModel.isMapUpdatingCoords,
                    onUseCurrentLocation: onUseCurrentLocation,
                    updateMapCamera: {
                        viewModel.updateMapCamera(customLatitude: customLatitude, customLongitude: customLongitude)
                    }
                )

                CelestialOffsetSettingsSection(
                    offsetHours: $offsetHours,
                    offsetMinutes: $offsetMinutes,
                    nextHighTide: $bindableViewModel.nextHighTide,
                    showingInfoAlert: $bindableViewModel.showingInfoAlert,
                    isTideCalibrated: $isTideCalibrated,
                    resolvedTimeZone: resolvedTimeZone,
                    isInternalUpdate: viewModel.isInternalUpdate,
                    calculateOffset: {
                        viewModel.calculateOffset(
                            offsetHours: $offsetHours,
                            offsetMinutes: $offsetMinutes,
                            customLatitude: customLatitude,
                            customLongitude: customLongitude,
                            resolvedTimeZone: resolvedTimeZone
                        )
                    },
                    updateNextHighTideFromOffset: {
                        viewModel.updateNextHighTideFromOffset(
                            offsetHours: offsetHours,
                            offsetMinutes: offsetMinutes,
                            customLatitude: customLatitude,
                            customLongitude: customLongitude
                        )
                    },
                    normalizeOffsetFieldsIfNeeded: {
                        viewModel.normalizeOffsetFieldsIfNeeded(
                            offsetHours: $offsetHours,
                            offsetMinutes: $offsetMinutes,
                            customLatitude: customLatitude,
                            customLongitude: customLongitude
                        )
                    },
                    isInternalUpdateAction: {
                        viewModel.isInternalUpdate = true
                    },
                    isInternalUpdateFinishedAction: {
                        viewModel.isInternalUpdate = false
                    }
                )
                
                Section("Chart Time Range") {
                    HStack {
                        Text("Hours Before Now")
                        Spacer()
                        TextField("Hours", value: $hoursBeforeNow, format: .number)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                    HStack {
                        Text("Hours After Now")
                        Spacer()
                        TextField("Hours", value: $hoursAfterNow, format: .number)
                            .multilineTextAlignment(.trailing)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    }
                }
                
                Section("How it works") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Celestial Tides computes the gravitational pull from the moon and sun to estimate tide levels completely offline. No internet connection is required.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        FeatureRow(
                            icon: "chart.xyaxis.line",
                            title: "Interactive Chart",
                            description: "The main graph displays upcoming tide levels. Drag left or right to look into the future. You can tap anywhere on the curve to see the exact forecasted tide level for that time."
                        )

                        FeatureRow(
                            icon: "location.fill",
                            title: "Custom Locations",
                            description: "Enter your coordinates above to generate tide forecasts tailored exactly to your specified area."
                        )
                        
                        FeatureRow(
                            icon: "apps.iphone",
                            title: "Home Screen Widget",
                            description: "Add the Celestial Tides widget to your iOS home screen to see the forecast at a glance."
                        )
                        
                        Image("WidgetScreenshot")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
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
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button("Done", action: onDone)
                        .disabled(!isTideCalibrated)
                }
            }
            .onAppear {
                viewModel.sanitizeInitialState(
                    customLatitude: $customLatitude,
                    customLongitude: $customLongitude,
                    offsetHours: $offsetHours,
                    offsetMinutes: $offsetMinutes,
                    hoursBeforeNow: $hoursBeforeNow,
                    hoursAfterNow: $hoursAfterNow
                )
                viewModel.updateMapCamera(customLatitude: customLatitude, customLongitude: customLongitude)
                viewModel.updateNextHighTideFromOffset(
                    offsetHours: offsetHours,
                    offsetMinutes: offsetMinutes,
                    customLatitude: customLatitude,
                    customLongitude: customLongitude
                )
                DispatchQueue.main.async {
                    hasAppeared = true
                }
            }
            .onChange(of: coordinatesInput) { oldCoords, newCoords in
                if hasAppeared && oldCoords != newCoords {
                    isTideCalibrated = false
                    viewModel.nextHighTide = nil
                }
                viewModel.handleCoordinateChange(
                    customLatitude: $customLatitude,
                    customLongitude: $customLongitude
                )
            }
            .onChange(of: hoursWindowInput) { _, _ in
                viewModel.clampHoursWindow(hoursBeforeNow: $hoursBeforeNow, hoursAfterNow: $hoursAfterNow)
            }
            .alert("Help: Next High Tide", isPresented: $bindableViewModel.showingInfoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Celestial Tides estimates tides from sun/moon positions, lunar phase, declination, and Earth-Sun distance. Enter the next observed high tide to calibrate your local celestial offset. Forecasts are approximate and may differ from official local stations.")
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
        .padding(.vertical, 4)
    }
}

