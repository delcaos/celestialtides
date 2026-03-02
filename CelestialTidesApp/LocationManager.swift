import Foundation
import CoreLocation

public class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published public var location: CLLocation?
    @Published public var authorizationStatus: CLAuthorizationStatus
    @Published public var errorMessage: String?
    
    public var onLocationUpdated: ((CLLocation) -> Void)?
    
    public override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private var isRequestingLocation = false
    
    public func requestLocation() {
        errorMessage = nil
        isRequestingLocation = true
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if hasLocationAuthorization {
            manager.requestLocation()
        } else {
            errorMessage = "Location permission denied. Please enable it in Settings."
            isRequestingLocation = false
        }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        if hasLocationAuthorization {
            if isRequestingLocation {
                manager.requestLocation()
            }
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            if isRequestingLocation {
                errorMessage = "Location permission denied."
                isRequestingLocation = false
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            location = newLocation
            isRequestingLocation = false
            onLocationUpdated?(newLocation)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isRequestingLocation = false
        if let clErr = error as? CLError {
            switch clErr.code {
            case .locationUnknown:
                errorMessage = "Location is currently unknown."
            case .denied:
                errorMessage = "Location access denied."
            case .network:
                errorMessage = "Network error while getting location."
            default:
                errorMessage = "Location error: \(error.localizedDescription)"
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }

    private var hasLocationAuthorization: Bool {
        #if os(macOS)
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorized
        #else
        return authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
        #endif
    }
}
