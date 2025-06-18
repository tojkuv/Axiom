import Foundation
import CoreLocation
import AxiomCore
import AxiomCapabilities

// MARK: - CoreLocation Sendable Conformance
// CoreLocation framework types don't conform to Sendable by default
extension CLLocation: @unchecked Sendable {}
extension CLLocationCoordinate2D: @unchecked Sendable {}
extension CLCircularRegion: @unchecked Sendable {}
extension CLRegion: @unchecked Sendable {}

public actor LocationServicesCapability: NSObject, AxiomCapability {
    public let id = UUID()
    public let name = "LocationServices"
    public let version = "1.0.0"
    
    private let locationManager = CLLocationManager()
    private var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var isTracking: Bool = false
    
    private var locationUpdateContinuation: AsyncStream<CLLocation>.Continuation?
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    
    public override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }
    
    public func activate() async throws {
        authorizationStatus = locationManager.authorizationStatus
        
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationServicesError.locationServicesDisabled
        }
        
        if authorizationStatus == .notDetermined {
            try await requestLocationPermission()
        } else if !isAuthorized {
            throw LocationServicesError.accessDenied
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10 meters
    }
    
    public func deactivate() async {
        stopLocationUpdates()
        stopMonitoringRegions()
    }
    
    public var isAvailable: Bool {
        return CLLocationManager.locationServicesEnabled() && isAuthorized
    }
    
    private var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }
    
    private func requestLocationPermission() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            
            #if os(iOS)
            locationManager.requestWhenInUseAuthorization()
            #else
            // On macOS, location permission is handled differently
            locationManager.requestAlwaysAuthorization()
            #endif
        }
    }
    
    // MARK: - Location Tracking
    
    public func startLocationUpdates() async throws -> AsyncStream<CLLocation> {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        isTracking = true
        locationManager.startUpdatingLocation()
        
        return AsyncStream { continuation in
            self.locationUpdateContinuation = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.clearLocationContinuation()
                }
            }
        }
    }
    
    public func stopLocationUpdates() {
        guard isTracking else { return }
        
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationUpdateContinuation?.finish()
        locationUpdateContinuation = nil
    }
    
    public func getCurrentLocation() async throws -> CLLocation {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            locationManager.requestLocation()
            
            // Store continuation for one-time location update
            Task {
                var received = false
                for await location in try await startLocationUpdates() {
                    if !received {
                        received = true
                        continuation.resume(returning: location)
                        stopLocationUpdates()
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Region Monitoring
    
    public func startMonitoring(region: CLRegion) async throws {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: type(of: region)) else {
            throw LocationServicesError.regionMonitoringNotAvailable
        }
        
        locationManager.startMonitoring(for: region)
    }
    
    public func stopMonitoring(region: CLRegion) async throws {
        locationManager.stopMonitoring(for: region)
    }
    
    public func stopMonitoringRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    public func getMonitoredRegions() async -> Set<CLRegion> {
        return locationManager.monitoredRegions
    }
    
    // MARK: - Geofencing
    
    public func createCircularRegion(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        identifier: String,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = false
    ) -> CLCircularRegion {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        return region
    }
    
    // MARK: - Significant Location Changes
    
    public func startSignificantLocationChangeMonitoring() async throws {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            throw LocationServicesError.significantLocationChangeNotAvailable
        }
        
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    public func stopSignificantLocationChangeMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    // MARK: - Visit Monitoring
    
    public func startVisitMonitoring() async throws {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        #if os(iOS)
        locationManager.startMonitoringVisits()
        #else
        throw LocationServicesError.visitMonitoringNotAvailable
        #endif
    }
    
    public func stopVisitMonitoring() {
        #if os(iOS)
        locationManager.stopMonitoringVisits()
        #endif
    }
    
    // MARK: - Heading
    
    public func startHeadingUpdates() async throws -> AsyncStream<CLHeading> {
        guard isAvailable else {
            throw LocationServicesError.accessDenied
        }
        
        guard CLLocationManager.headingAvailable() else {
            throw LocationServicesError.headingNotAvailable
        }
        
        locationManager.startUpdatingHeading()
        
        return AsyncStream { continuation in
            // Note: This would require additional delegate handling for heading updates
            continuation.onTermination = { [weak self] _ in
                #if os(iOS)
                Task { [weak self] in
                    await self?.stopHeadingUpdatesInternal()
                }
                #endif
            }
        }
    }
    
    public func stopHeadingUpdates() {
        #if os(iOS)
        locationManager.stopUpdatingHeading()
        #endif
    }
    
    // MARK: - Conversion Methods
    
    public func convertToLocationData(_ location: CLLocation) -> LocationData {
        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            timestamp: location.timestamp,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil
        )
    }
    
    public func convertToLocationReminder(
        from region: CLCircularRegion,
        triggerOnEntry: Bool = true,
        triggerOnExit: Bool = false
    ) -> LocationReminder {
        return LocationReminder(
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            radius: region.radius,
            triggerOnEntry: triggerOnEntry,
            triggerOnExit: triggerOnExit,
            locationName: region.identifier
        )
    }
    
    public func convertToCircularRegion(from locationReminder: LocationReminder, identifier: String) -> CLCircularRegion {
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(
                latitude: locationReminder.latitude,
                longitude: locationReminder.longitude
            ),
            radius: locationReminder.radius,
            identifier: identifier
        )
        region.notifyOnEntry = locationReminder.triggerOnEntry
        region.notifyOnExit = locationReminder.triggerOnExit
        return region
    }
    
    // MARK: - Utility Methods
    
    public func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    public func isLocationInRegion(_ location: CLLocationCoordinate2D, region: CLCircularRegion) -> Bool {
        let distance = calculateDistance(from: location, to: region.center)
        return distance <= region.radius
    }
    
    // MARK: - Geocoding
    
    public func reverseGeocode(location: CLLocation) async throws -> [CLPlacemark] {
        let geocoder = CLGeocoder()
        return try await geocoder.reverseGeocodeLocation(location)
    }
    
    public func geocode(addressString: String) async throws -> [CLPlacemark] {
        let geocoder = CLGeocoder()
        return try await geocoder.geocodeAddressString(addressString)
    }
    
    public func getLocationName(for location: CLLocation) async throws -> String? {
        let placemarks = try await reverseGeocode(location: location)
        return placemarks.first?.name
    }
    
    public func getLocationAddress(for location: CLLocation) async throws -> String? {
        let placemarks = try await reverseGeocode(location: location)
        guard let placemark = placemarks.first else { return nil }
        
        var addressComponents: [String] = []
        
        if let name = placemark.name {
            addressComponents.append(name)
        }
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    // MARK: - Movement Detection
    
    public func analyzeMovementPattern(locations: [CLLocation]) -> MovementPattern? {
        guard locations.count >= 2 else { return nil }
        
        let sortedLocations = locations.sorted { $0.timestamp < $1.timestamp }
        guard let firstLocation = sortedLocations.first,
              let lastLocation = sortedLocations.last else { return nil }
        
        let duration = lastLocation.timestamp.timeIntervalSince(firstLocation.timestamp)
        let totalDistance = calculateTotalDistance(locations: sortedLocations)
        let averageSpeed = totalDistance / duration
        
        let activityType = determineActivityType(averageSpeed: averageSpeed, locations: sortedLocations)
        
        return MovementPattern(
            startDate: firstLocation.timestamp,
            endDate: lastLocation.timestamp,
            activityType: activityType,
            distance: totalDistance,
            duration: duration,
            locations: sortedLocations.map { convertToLocationData($0) },
            averageSpeed: averageSpeed
        )
    }
    
    private func calculateTotalDistance(locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 1..<locations.count {
            totalDistance += locations[i-1].distance(from: locations[i])
        }
        return totalDistance
    }
    
    private func determineActivityType(averageSpeed: Double, locations: [CLLocation]) -> ActivityType {
        // Speed in meters per second
        if averageSpeed < 1.0 {
            return .stationary
        } else if averageSpeed < 2.0 {
            return .walking
        } else if averageSpeed < 6.0 {
            return .running
        } else if averageSpeed < 15.0 {
            return .cycling
        } else {
            return .driving
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationServicesCapability: CLLocationManagerDelegate {
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { [weak self] in
            await self?.handleLocationUpdate(location)
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { [weak self] in
            await self?.handleAuthorizationChange(status)
        }
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        // Could emit region entry events here
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        // Could emit region exit events here
    }
    
    nonisolated public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "unknown") with error: \(error)")
    }
    
    #if os(iOS)
    nonisolated public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        print("Did visit location at: \(visit.coordinate)")
        // Could emit visit events here
    }
    #endif
}

// MARK: - Actor-isolated helper methods

extension LocationServicesCapability {
    private func handleLocationUpdate(_ location: CLLocation) {
        locationUpdateContinuation?.yield(location)
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        if let continuation = authorizationContinuation {
            authorizationContinuation = nil
            
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                continuation.resume()
            case .denied, .restricted:
                continuation.resume(throwing: LocationServicesError.accessDenied)
            case .notDetermined:
                // Wait for user decision
                break
            @unknown default:
                continuation.resume(throwing: LocationServicesError.unknown)
            }
        }
    }
    
    private func clearLocationContinuation() {
        locationUpdateContinuation = nil
    }
    
    private func stopHeadingUpdatesInternal() {
        #if os(iOS)
        locationManager.stopUpdatingHeading()
        #endif
    }
}

public enum LocationServicesError: Error, LocalizedError {
    case locationServicesDisabled
    case accessDenied
    case regionMonitoringNotAvailable
    case significantLocationChangeNotAvailable
    case visitMonitoringNotAvailable
    case headingNotAvailable
    case geocodingFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled"
        case .accessDenied:
            return "Access to location services was denied"
        case .regionMonitoringNotAvailable:
            return "Region monitoring is not available"
        case .significantLocationChangeNotAvailable:
            return "Significant location change monitoring is not available"
        case .visitMonitoringNotAvailable:
            return "Visit monitoring is not available"
        case .headingNotAvailable:
            return "Heading information is not available"
        case .geocodingFailed:
            return "Geocoding failed"
        case .unknown:
            return "Unknown location services error"
        }
    }
}