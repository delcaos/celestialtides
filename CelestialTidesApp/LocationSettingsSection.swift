import SwiftUI
import MapKit

struct LocationSettingsSection: View {
    @Binding var selectedTimeZone: String
    @Binding var customLatitude: Double
    @Binding var customLongitude: Double
    @Binding var mapCameraPosition: MapCameraPosition
    @Binding var isMapUpdatingCoords: Bool
    
    let onUseCurrentLocation: () -> Void
    let updateMapCamera: () -> Void
    
    var body: some View {
        Section("Location") {
            Picker("Timezone", selection: $selectedTimeZone) {
                Text("Local Timezone").tag(TimeZoneSelection.localIdentifier)
                Divider()
                ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { tz in
                    Text(tz.replacingOccurrences(of: "/", with: " / ")).tag(tz)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location Coordinates")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Latitude", value: $customLatitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                    TextField("Longitude", value: $customLongitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                }
                
                Text("Tap Map to Pick Location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                MapReader { proxy in
                    Map(position: $mapCameraPosition, interactionModes: .all) {
                        Marker(
                            "Target",
                            coordinate: CLLocationCoordinate2D(
                                latitude: TideConfigurationLimits.clampLatitude(customLatitude),
                                longitude: TideConfigurationLimits.clampLongitude(customLongitude)
                            )
                        )
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture { position in
                        if let coordinate = proxy.convert(position, from: .local) {
                            isMapUpdatingCoords = true
                            customLatitude = coordinate.latitude
                            customLongitude = coordinate.longitude
                            DispatchQueue.main.async { isMapUpdatingCoords = false }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            Button(action: {
                onUseCurrentLocation()
                updateMapCamera()
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Use Current Location")
                }
            }
        }
    }
}
