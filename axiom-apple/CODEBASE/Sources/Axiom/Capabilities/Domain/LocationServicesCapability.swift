import Foundation
@preconcurrency import CoreLocation

// MARK: - Location Services Configuration

/// Configuration for location services capability
public struct LocationServicesConfiguration: CapabilityConfiguration {
    public let desiredAccuracy: CLLocationAccuracy
    public let distanceFilter: CLLocationDistance
    public let allowsBackgroundLocationUpdates: Bool
    public let requestsAlwaysAuthorization: Bool
    public let activityType: CLActivityType
    public let requestTimeout: TimeInterval
    
    public init(
        desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
        distanceFilter: CLLocationDistance = kCLDistanceFilterNone,
        allowsBackgroundLocationUpdates: Bool = false,
        requestsAlwaysAuthorization: Bool = false,
        activityType: CLActivityType = .other,
        requestTimeout: TimeInterval = 30.0
    ) {
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilter = distanceFilter
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.requestsAlwaysAuthorization = requestsAlwaysAuthorization
        self.activityType = activityType
        self.requestTimeout = requestTimeout
    }
    
    public var isValid: Bool {
        return requestTimeout > 0
    }
    
    public func merged(with other: LocationServicesConfiguration) -> LocationServicesConfiguration {
        return LocationServicesConfiguration(
            desiredAccuracy: other.desiredAccuracy,
            distanceFilter: other.distanceFilter,
            allowsBackgroundLocationUpdates: other.allowsBackgroundLocationUpdates,
            requestsAlwaysAuthorization: other.requestsAlwaysAuthorization,
            activityType: other.activityType,
            requestTimeout: other.requestTimeout
        )
    }
    
    public func adjusted(for environment: CapabilityEnvironment) -> LocationServicesConfiguration {
        var adjustedAccuracy = desiredAccuracy
        var adjustedTimeout = requestTimeout
        
        if environment.isLowPowerMode {
            // Use less accurate location to save battery
            adjustedAccuracy = kCLLocationAccuracyHundredMeters
            adjustedTimeout *= 1.5
        }
        
        if environment.isDebug {
            adjustedTimeout *= 2.0 // More lenient in debug
        }
        
        return LocationServicesConfiguration(
            desiredAccuracy: adjustedAccuracy,
            distanceFilter: distanceFilter,
            allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates,
            requestsAlwaysAuthorization: requestsAlwaysAuthorization,
            activityType: activityType,
            requestTimeout: adjustedTimeout
        )
    }
}

// MARK: - LocationServicesConfiguration Codable Implementation

extension LocationServicesConfiguration: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.desiredAccuracy = try container.decode(CLLocationAccuracy.self, forKey: .desiredAccuracy)
        self.distanceFilter = try container.decode(CLLocationDistance.self, forKey: .distanceFilter)
        self.allowsBackgroundLocationUpdates = try container.decode(Bool.self, forKey: .allowsBackgroundLocationUpdates)
        self.requestsAlwaysAuthorization = try container.decode(Bool.self, forKey: .requestsAlwaysAuthorization)
        
        let activityTypeRawValue = try container.decode(Int.self, forKey: .activityType)
        self.activityType = CLActivityType(rawValue: activityTypeRawValue) ?? .other
        
        self.requestTimeout = try container.decode(TimeInterval.self, forKey: .requestTimeout)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(desiredAccuracy, forKey: .desiredAccuracy)
        try container.encode(distanceFilter, forKey: .distanceFilter)
        try container.encode(allowsBackgroundLocationUpdates, forKey: .allowsBackgroundLocationUpdates)
        try container.encode(requestsAlwaysAuthorization, forKey: .requestsAlwaysAuthorization)
        try container.encode(activityType.rawValue, forKey: .activityType)
        try container.encode(requestTimeout, forKey: .requestTimeout)
    }
    
    private enum CodingKeys: String, CodingKey {
        case desiredAccuracy
        case distanceFilter
        case allowsBackgroundLocationUpdates
        case requestsAlwaysAuthorization
        case activityType
        case requestTimeout
    }
}

// MARK: - Location Data Types

/// Location update result
public struct LocationUpdate: Sendable, Codable {
    public let coordinate: CLLocationCoordinate2D
    public let altitude: CLLocationDistance
    public let horizontalAccuracy: CLLocationAccuracy
    public let verticalAccuracy: CLLocationAccuracy
    public let timestamp: Date
    public let speed: CLLocationSpeed
    public let course: CLLocationDirection
    
    public init(from location: CLLocation) {
        self.coordinate = location.coordinate
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.course = location.course
    }
    
    public init(
        coordinate: CLLocationCoordinate2D,
        altitude: CLLocationDistance = 0,
        horizontalAccuracy: CLLocationAccuracy = 0,
        verticalAccuracy: CLLocationAccuracy = 0,
        timestamp: Date = Date(),
        speed: CLLocationSpeed = 0,
        course: CLLocationDirection = 0
    ) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.speed = speed
        self.course = course
    }
}

/// Authorization status for location services
public enum LocationAuthorizationStatus: Sendable, Codable {
    case notDetermined
    case restricted
    case denied
    case authorizedAlways
    case authorizedWhenInUse
    
    public init(from status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorizedAlways:
            self = .authorizedAlways
        case .authorizedWhenInUse:
            self = .authorizedWhenInUse
        @unknown default:
            self = .notDetermined
        }
    }
}

// MARK: - Location Services Resource

/// Resource management for location services
public actor LocationServicesResource: CapabilityResource {
    private var isLocationManagerActive: Bool = false
    private var _isAvailable: Bool = true
    private let configuration: LocationServicesConfiguration
    
    public init(configuration: LocationServicesConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 5_000_000, // 5MB max for location services
            cpu: 10.0, // 10% CPU max
            bandwidth: 1_000, // 1KB/s for location data
            storage: 0
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            if isLocationManagerActive {
                return ResourceUsage(
                    memory: 2_000_000, // 2MB when active
                    cpu: 5.0, // 5% CPU when active
                    bandwidth: 500, // 500 bytes/s
                    storage: 0
                )
            } else {
                return ResourceUsage(memory: 0, cpu: 0, bandwidth: 0, storage: 0)
            }
        }
    }
    
    public func isAvailable() async -> Bool {
        return _isAvailable && CLLocationManager.locationServicesEnabled()
    }
    
    public func release() async {
        isLocationManagerActive = false
    }
    
    public func activateLocationManager() async throws {
        guard await isAvailable() else {
            throw CapabilityError.resourceAllocationFailed("Location services not available")
        }
        isLocationManagerActive = true
    }
    
    public func deactivateLocationManager() async {
        isLocationManagerActive = false
    }
    
    public func setAvailable(_ available: Bool) async {
        _isAvailable = available
    }
}

// MARK: - Location Services Capability

/// Location services capability providing GPS, compass, and location-based functionality
public actor LocationServicesCapability: DomainCapability {
    public typealias ConfigurationType = LocationServicesConfiguration
    public typealias ResourceType = LocationServicesResource
    
    private var _configuration: LocationServicesConfiguration
    private var _resources: LocationServicesResource
    private var _environment: CapabilityEnvironment
    private var _state: CapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
    
    private var locationManager: CLLocationManager?
    private var locationDelegate: LocationDelegate?
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    private var locationStreamContinuation: AsyncStream<LocationUpdate>.Continuation?
    private var authStatusStreamContinuation: AsyncStream<LocationAuthorizationStatus>.Continuation?
    
    public nonisolated var id: String { "location-services-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStateStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: LocationServicesConfiguration {
        get async { _configuration }
    }
    
    public var resources: LocationServicesResource {
        get async { _resources }
    }
    
    public var environment: CapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: LocationServicesConfiguration = LocationServicesConfiguration(),
        environment: CapabilityEnvironment = CapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = LocationServicesResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStateStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    private func setLocationStreamContinuation(_ continuation: AsyncStream<LocationUpdate>.Continuation) {
        self.locationStreamContinuation = continuation
    }
    
    private func setAuthStatusStreamContinuation(_ continuation: AsyncStream<LocationAuthorizationStatus>.Continuation) {
        self.authStatusStreamContinuation = continuation
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: LocationServicesConfiguration) async throws {
        guard configuration.isValid else {
            throw CapabilityError.initializationFailed("Invalid location services configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        await updateLocationManager()
    }
    
    public func handleEnvironmentChange(_ environment: CapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    // MARK: - ExtendedCapability Protocol
    
    public func isSupported() async -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    public func requestPermission() async throws {
        guard let manager = locationManager else {
            throw CapabilityError.notAvailable("Location manager not initialized")
        }
        
        let currentStatus = manager.authorizationStatus
        if currentStatus == .notDetermined {
            if _configuration.requestsAlwaysAuthorization {
                manager.requestAlwaysAuthorization()
            } else {
                manager.requestWhenInUseAuthorization()
            }
            
            // Wait for authorization change
            for await status in authorizationStatusStream {
                if status != .notDetermined {
                    break
                }
            }
        }
        
        let finalStatus = manager.authorizationStatus
        #if os(iOS) || os(watchOS) || os(tvOS)
        guard finalStatus == .authorizedAlways || finalStatus == .authorizedWhenInUse else {
            throw CapabilityError.permissionRequired("Location access denied")
        }
        #else
        guard finalStatus == .authorizedAlways else {
            throw CapabilityError.permissionRequired("Location access denied")
        }
        #endif
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Capability Protocol
    
    public func activate() async throws {
        guard await _resources.isAvailable() else {
            throw CapabilityError.initializationFailed("Location services not available")
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            throw CapabilityError.notAvailable("Location services disabled")
        }
        
        try await setupLocationManager()
        try await requestPermission()
        try await _resources.activateLocationManager()
        
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.unavailable)
        await _resources.deactivateLocationManager()
        
        locationManager?.stopUpdatingLocation()
        #if os(iOS) || os(watchOS)
        locationManager?.stopUpdatingHeading()
        #endif
        locationManager = nil
        locationDelegate = nil
        
        stateStreamContinuation?.finish()
        locationStreamContinuation?.finish()
        authStatusStreamContinuation?.finish()
    }
    
    private func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    private func setupLocationManager() async throws {
        let manager = CLLocationManager()
        let delegate = await MainActor.run { LocationDelegate() }
        
        // Configure delegate callbacks
        await MainActor.run {
            delegate.onLocationUpdate = { [weak self] location in
                Task { [weak self] in
                    await self?.handleLocationUpdate(location)
                }
            }
            
            delegate.onAuthorizationChange = { [weak self] status in
                Task { [weak self] in
                    await self?.handleAuthorizationChange(status)
                }
            }
            
            delegate.onError = { [weak self] error in
                Task { [weak self] in
                    await self?.handleLocationError(error)
                }
            }
        }
        
        manager.delegate = delegate
        await updateLocationManagerConfiguration(manager)
        
        self.locationManager = manager
        self.locationDelegate = delegate
    }
    
    private func updateLocationManager() async {
        guard let manager = locationManager else { return }
        await updateLocationManagerConfiguration(manager)
    }
    
    private func updateLocationManagerConfiguration(_ manager: CLLocationManager) async {
        manager.desiredAccuracy = _configuration.desiredAccuracy
        manager.distanceFilter = _configuration.distanceFilter
        manager.activityType = _configuration.activityType
        
        if _configuration.allowsBackgroundLocationUpdates {
            manager.allowsBackgroundLocationUpdates = true
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation) async {
        let update = LocationUpdate(from: location)
        locationStreamContinuation?.yield(update)
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) async {
        let authStatus = LocationAuthorizationStatus(from: status)
        authStatusStreamContinuation?.yield(authStatus)
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if _state != .available {
                await transitionTo(.available)
            }
        case .denied, .restricted:
            await transitionTo(.restricted)
        case .notDetermined:
            await transitionTo(.unknown)
        @unknown default:
            await transitionTo(.unknown)
        }
    }
    
    private func handleLocationError(_ error: Error) async {
        await transitionTo(.restricted)
    }
    
    // MARK: - Location Services API
    
    /// Start receiving location updates
    public func startLocationUpdates() async throws {
        guard _state == .available else {
            throw CapabilityError.notAvailable("Location services not available")
        }
        
        guard let manager = locationManager else {
            throw CapabilityError.notAvailable("Location manager not initialized")
        }
        
        manager.startUpdatingLocation()
    }
    
    /// Stop receiving location updates
    public func stopLocationUpdates() async {
        locationManager?.stopUpdatingLocation()
    }
    
    /// Get current location once
    public func getCurrentLocation() async throws -> LocationUpdate {
        guard _state == .available else {
            throw CapabilityError.notAvailable("Location services not available")
        }
        
        guard let manager = locationManager else {
            throw CapabilityError.notAvailable("Location manager not initialized")
        }
        
        manager.requestLocation()
        
        // Wait for location update with timeout
        let _ = _configuration.requestTimeout
        let _ = ContinuousClock.now
        
        for await location in locationUpdatesStream {
            return location
        }
        
        throw CapabilityError.initializationFailed("Location request timed out")
    }
    
    /// Stream of location updates
    public var locationUpdatesStream: AsyncStream<LocationUpdate> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setLocationStreamContinuation(continuation)
            }
        }
    }
    
    /// Stream of authorization status changes
    public var authorizationStatusStream: AsyncStream<LocationAuthorizationStatus> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setAuthStatusStreamContinuation(continuation)
                if let manager = await self?.locationManager {
                    let status = LocationAuthorizationStatus(from: manager.authorizationStatus)
                    continuation.yield(status)
                }
            }
        }
    }
    
    /// Get current authorization status
    public func getAuthorizationStatus() async -> LocationAuthorizationStatus {
        guard let manager = locationManager else {
            return .notDetermined
        }
        return LocationAuthorizationStatus(from: manager.authorizationStatus)
    }
    
    /// Check if location services are enabled on device
    public func isLocationServicesEnabled() async -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
}

// MARK: - Location Manager Delegate

@MainActor
private class LocationDelegate: NSObject, @preconcurrency CLLocationManagerDelegate {
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onError: ((Error) -> Void)?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onAuthorizationChange?(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error)
    }
}

// MARK: - Registration Extension

extension CapabilityRegistry {
    /// Register location services capability
    public func registerLocationServices() async throws {
        let capability = LocationServicesCapability()
        try await register(
            capability,
            requirements: [
                CapabilityDiscoveryService.Requirement(
                    type: .systemFeature("CoreLocation"),
                    isMandatory: true
                ),
                CapabilityDiscoveryService.Requirement(
                    type: .permission("NSLocationWhenInUseUsageDescription"),
                    isMandatory: true
                )
            ],
            category: "system",
            metadata: CapabilityMetadata(
                name: "Location Services",
                description: "GPS and location-based services capability",
                version: "1.0.0",
                documentation: "Provides GPS location, compass heading, and location-based functionality",
                supportedPlatforms: ["iOS", "macOS"],
                minimumOSVersion: "14.0",
                tags: ["location", "gps", "system"],
                dependencies: ["CoreLocation"]
            )
        )
    }
}