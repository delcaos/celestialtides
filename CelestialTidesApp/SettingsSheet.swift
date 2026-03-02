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
    
    @State private var viewModel = SettingsViewModel()
    
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
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    Button("Done", action: onDone)
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
            }
            .onChange(of: coordinatesInput) { _, _ in
                viewModel.handleCoordinateChange(
                    customLatitude: $customLatitude,
                    customLongitude: $customLongitude,
                    offsetHours: offsetHours,
                    offsetMinutes: offsetMinutes
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
