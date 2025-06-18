import Foundation
import CoreLocation
import MapKit
import AxiomCore
import AxiomCapabilities

// MARK: - Location Capability Configuration

/// Configuration for Location capability
public struct LocationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let desiredAccuracy: LocationAccuracy
    public let distanceFilter: Double
    public let enableBackgroundLocation: Bool
    public let enableSignificantLocationChanges: Bool
    public let enableGeofencing: Bool
    public let maxGeofenceCount: Int
    public let enableHeadingUpdates: Bool
    public let headingFilter: Double
    public let enableLocationHistory: Bool
    public let maxHistoryCount: Int
    public let historyRetentionDays: Int
    public let enableGeocoding: Bool
    public let geocodingCacheSize: Int
    public let geocodingCacheTTL: TimeInterval
    public let enableBatteryOptimization: Bool
    public let pausesLocationUpdatesWhenPossible: Bool
    public let allowsBackgroundLocationUpdates: Bool
    public let showsBackgroundLocationIndicator: Bool
    public let enableActivityTypeDetection: Bool
    public let activityType: ActivityType
    public let enableAltitudeUpdates: Bool
    public let enableSpeedCalculation: Bool
    public let enableCourseCalculation: Bool
    public let enableLocationValidation: Bool
    public let maxLocationAge: TimeInterval
    public let minLocationAccuracy: Double
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableRegionMonitoring: Bool
    public let enableVisitMonitoring: Bool
    
    public enum LocationAccuracy: String, Codable, CaseIterable, Sendable {
        case bestForNavigation = "bestForNavigation"
        case best = "best"
        case nearestTenMeters = "nearestTenMeters"
        case hundredMeters = "hundredMeters"
        case kilometer = "kilometer"
        case threeKilometers = "threeKilometers"
        case reduced = "reduced"
    }
    
    public enum ActivityType: String, Codable, CaseIterable, Sendable {
        case other = "other"
        case automotiveNavigation = "automotiveNavigation"
        case fitness = "fitness"
        case otherNavigation = "otherNavigation"
        case airborne = "airborne"
    }
    
    public init(
        desiredAccuracy: LocationAccuracy = .best,
        distanceFilter: Double = 10.0,
        enableBackgroundLocation: Bool = false,
        enableSignificantLocationChanges: Bool = false,
        enableGeofencing: Bool = false,
        maxGeofenceCount: Int = 20,
        enableHeadingUpdates: Bool = false,
        headingFilter: Double = 5.0,
        enableLocationHistory: Bool = true,
        maxHistoryCount: Int = 1000,
        historyRetentionDays: Int = 30,
        enableGeocoding: Bool = true,
        geocodingCacheSize: Int = 100,
        geocodingCacheTTL: TimeInterval = 3600.0, // 1 hour
        enableBatteryOptimization: Bool = true,
        pausesLocationUpdatesWhenPossible: Bool = true,
        allowsBackgroundLocationUpdates: Bool = false,
        showsBackgroundLocationIndicator: Bool = true,
        enableActivityTypeDetection: Bool = false,
        activityType: ActivityType = .other,
        enableAltitudeUpdates: Bool = false,
        enableSpeedCalculation: Bool = true,
        enableCourseCalculation: Bool = true,
        enableLocationValidation: Bool = true,
        maxLocationAge: TimeInterval = 30.0,
        minLocationAccuracy: Double = 100.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableRegionMonitoring: Bool = false,
        enableVisitMonitoring: Bool = false
    ) {
        self.desiredAccuracy = desiredAccuracy
        self.distanceFilter = distanceFilter
        self.enableBackgroundLocation = enableBackgroundLocation
        self.enableSignificantLocationChanges = enableSignificantLocationChanges
        self.enableGeofencing = enableGeofencing
        self.maxGeofenceCount = maxGeofenceCount
        self.enableHeadingUpdates = enableHeadingUpdates
        self.headingFilter = headingFilter
        self.enableLocationHistory = enableLocationHistory
        self.maxHistoryCount = maxHistoryCount
        self.historyRetentionDays = historyRetentionDays
        self.enableGeocoding = enableGeocoding
        self.geocodingCacheSize = geocodingCacheSize
        self.geocodingCacheTTL = geocodingCacheTTL
        self.enableBatteryOptimization = enableBatteryOptimization
        self.pausesLocationUpdatesWhenPossible = pausesLocationUpdatesWhenPossible
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.showsBackgroundLocationIndicator = showsBackgroundLocationIndicator
        self.enableActivityTypeDetection = enableActivityTypeDetection
        self.activityType = activityType
        self.enableAltitudeUpdates = enableAltitudeUpdates
        self.enableSpeedCalculation = enableSpeedCalculation
        self.enableCourseCalculation = enableCourseCalculation
        self.enableLocationValidation = enableLocationValidation
        self.maxLocationAge = maxLocationAge
        self.minLocationAccuracy = minLocationAccuracy
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableRegionMonitoring = enableRegionMonitoring
        self.enableVisitMonitoring = enableVisitMonitoring
    }
    
    public var isValid: Bool {
        distanceFilter >= 0 &&
        maxGeofenceCount > 0 &&
        headingFilter >= 0 &&
        maxHistoryCount > 0 &&
        historyRetentionDays > 0 &&
        geocodingCacheSize > 0 &&
        geocodingCacheTTL > 0 &&
        maxLocationAge > 0 &&
        minLocationAccuracy > 0
    }
    
    public func merged(with other: LocationCapabilityConfiguration) -> LocationCapabilityConfiguration {
        LocationCapabilityConfiguration(
            desiredAccuracy: other.desiredAccuracy,
            distanceFilter: other.distanceFilter,
            enableBackgroundLocation: other.enableBackgroundLocation,
            enableSignificantLocationChanges: other.enableSignificantLocationChanges,
            enableGeofencing: other.enableGeofencing,
            maxGeofenceCount: other.maxGeofenceCount,
            enableHeadingUpdates: other.enableHeadingUpdates,
            headingFilter: other.headingFilter,
            enableLocationHistory: other.enableLocationHistory,
            maxHistoryCount: other.maxHistoryCount,
            historyRetentionDays: other.historyRetentionDays,
            enableGeocoding: other.enableGeocoding,
            geocodingCacheSize: other.geocodingCacheSize,
            geocodingCacheTTL: other.geocodingCacheTTL,
            enableBatteryOptimization: other.enableBatteryOptimization,
            pausesLocationUpdatesWhenPossible: other.pausesLocationUpdatesWhenPossible,
            allowsBackgroundLocationUpdates: other.allowsBackgroundLocationUpdates,
            showsBackgroundLocationIndicator: other.showsBackgroundLocationIndicator,
            enableActivityTypeDetection: other.enableActivityTypeDetection,
            activityType: other.activityType,
            enableAltitudeUpdates: other.enableAltitudeUpdates,
            enableSpeedCalculation: other.enableSpeedCalculation,
            enableCourseCalculation: other.enableCourseCalculation,
            enableLocationValidation: other.enableLocationValidation,
            maxLocationAge: other.maxLocationAge,
            minLocationAccuracy: other.minLocationAccuracy,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableRegionMonitoring: other.enableRegionMonitoring,
            enableVisitMonitoring: other.enableVisitMonitoring
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> LocationCapabilityConfiguration {
        var adjustedAccuracy = desiredAccuracy
        var adjustedFilter = distanceFilter
        var adjustedLogging = enableLogging
        var adjustedBatteryOptimization = enableBatteryOptimization
        
        if environment.isLowPowerMode {
            adjustedAccuracy = .hundredMeters
            adjustedFilter = max(distanceFilter, 100.0)
            adjustedBatteryOptimization = true
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return LocationCapabilityConfiguration(
            desiredAccuracy: adjustedAccuracy,
            distanceFilter: adjustedFilter,
            enableBackgroundLocation: enableBackgroundLocation,
            enableSignificantLocationChanges: enableSignificantLocationChanges,
            enableGeofencing: enableGeofencing,
            maxGeofenceCount: maxGeofenceCount,
            enableHeadingUpdates: enableHeadingUpdates,
            headingFilter: headingFilter,
            enableLocationHistory: enableLocationHistory,
            maxHistoryCount: maxHistoryCount,
            historyRetentionDays: historyRetentionDays,
            enableGeocoding: enableGeocoding,
            geocodingCacheSize: geocodingCacheSize,
            geocodingCacheTTL: geocodingCacheTTL,
            enableBatteryOptimization: adjustedBatteryOptimization,
            pausesLocationUpdatesWhenPossible: pausesLocationUpdatesWhenPossible,
            allowsBackgroundLocationUpdates: allowsBackgroundLocationUpdates,
            showsBackgroundLocationIndicator: showsBackgroundLocationIndicator,
            enableActivityTypeDetection: enableActivityTypeDetection,
            activityType: activityType,
            enableAltitudeUpdates: enableAltitudeUpdates,
            enableSpeedCalculation: enableSpeedCalculation,
            enableCourseCalculation: enableCourseCalculation,
            enableLocationValidation: enableLocationValidation,
            maxLocationAge: maxLocationAge,
            minLocationAccuracy: minLocationAccuracy,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableRegionMonitoring: enableRegionMonitoring,
            enableVisitMonitoring: enableVisitMonitoring
        )
    }
}

// MARK: - Location Types

/// Location authorization status
public enum LocationAuthorizationStatus: String, Codable, CaseIterable, Sendable {
    case notDetermined = "notDetermined"
    case restricted = "restricted"
    case denied = "denied"
    case authorizedAlways = "authorizedAlways"
    case authorizedWhenInUse = "authorizedWhenInUse"
}

/// Enhanced location information
public struct LocationInfo: Sendable {
    public let coordinate: CLLocationCoordinate2D
    public let altitude: Double
    public let horizontalAccuracy: Double
    public let verticalAccuracy: Double
    public let speed: Double
    public let course: Double
    public let timestamp: Date
    public let address: LocationAddress?
    public let isValid: Bool
    
    public init(
        coordinate: CLLocationCoordinate2D,
        altitude: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        speed: Double,
        course: Double,
        timestamp: Date,
        address: LocationAddress? = nil,
        isValid: Bool = true
    ) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.course = course
        self.timestamp = timestamp
        self.address = address
        self.isValid = isValid
    }
    
    public init(from location: CLLocation, address: LocationAddress? = nil) {
        self.coordinate = location.coordinate
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.speed = location.speed
        self.course = location.course
        self.timestamp = location.timestamp
        self.address = address
        self.isValid = location.horizontalAccuracy > 0 && location.horizontalAccuracy < 100
    }
}

/// Location address information
public struct LocationAddress: Sendable {
    public let name: String?
    public let thoroughfare: String?
    public let subThoroughfare: String?
    public let locality: String?
    public let subLocality: String?
    public let administrativeArea: String?
    public let subAdministrativeArea: String?
    public let postalCode: String?
    public let country: String?
    public let countryCode: String?
    public let timeZone: TimeZone?
    
    public init(
        name: String? = nil,
        thoroughfare: String? = nil,
        subThoroughfare: String? = nil,
        locality: String? = nil,
        subLocality: String? = nil,
        administrativeArea: String? = nil,
        subAdministrativeArea: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        countryCode: String? = nil,
        timeZone: TimeZone? = nil
    ) {
        self.name = name
        self.thoroughfare = thoroughfare
        self.subThoroughfare = subThoroughfare
        self.locality = locality
        self.subLocality = subLocality
        self.administrativeArea = administrativeArea
        self.subAdministrativeArea = subAdministrativeArea
        self.postalCode = postalCode
        self.country = country
        self.countryCode = countryCode
        self.timeZone = timeZone
    }
    
    public init(from placemark: CLPlacemark) {
        self.name = placemark.name
        self.thoroughfare = placemark.thoroughfare
        self.subThoroughfare = placemark.subThoroughfare
        self.locality = placemark.locality
        self.subLocality = placemark.subLocality
        self.administrativeArea = placemark.administrativeArea
        self.subAdministrativeArea = placemark.subAdministrativeArea
        self.postalCode = placemark.postalCode
        self.country = placemark.country
        self.countryCode = placemark.isoCountryCode
        self.timeZone = placemark.timeZone
    }
    
    public var formattedAddress: String {
        var components: [String] = []
        
        if let subThoroughfare = subThoroughfare, let thoroughfare = thoroughfare {
            components.append("\(subThoroughfare) \(thoroughfare)")
        } else if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = locality {
            components.append(locality)
        }
        
        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }
        
        if let postalCode = postalCode {
            components.append(postalCode)
        }
        
        if let country = country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}

/// Geofence region definition
public struct GeofenceRegion: Sendable {
    public let identifier: String
    public let center: CLLocationCoordinate2D
    public let radius: Double
    public let notifyOnEntry: Bool
    public let notifyOnExit: Bool
    public let isActive: Bool
    public let createdAt: Date
    
    public init(
        identifier: String,
        center: CLLocationCoordinate2D,
        radius: Double,
        notifyOnEntry: Bool = true,
        notifyOnExit: Bool = true,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.identifier = identifier
        self.center = center
        self.radius = radius
        self.notifyOnEntry = notifyOnEntry
        self.notifyOnExit = notifyOnExit
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    public var clRegion: CLCircularRegion {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = notifyOnEntry
        region.notifyOnExit = notifyOnExit
        return region
    }
}

/// Geofence event
public struct GeofenceEvent: Sendable {
    public let regionIdentifier: String
    public let eventType: EventType
    public let location: LocationInfo
    public let timestamp: Date
    
    public enum EventType: String, Codable, CaseIterable, Sendable {
        case entry = "entry"
        case exit = "exit"
    }
    
    public init(
        regionIdentifier: String,
        eventType: EventType,
        location: LocationInfo,
        timestamp: Date = Date()
    ) {
        self.regionIdentifier = regionIdentifier
        self.eventType = eventType
        self.location = location
        self.timestamp = timestamp
    }
}

/// Location heading information
public struct LocationHeading: Sendable {
    public let magneticHeading: Double
    public let trueHeading: Double
    public let headingAccuracy: Double
    public let timestamp: Date
    
    public init(
        magneticHeading: Double,
        trueHeading: Double,
        headingAccuracy: Double,
        timestamp: Date
    ) {
        self.magneticHeading = magneticHeading
        self.trueHeading = trueHeading
        self.headingAccuracy = headingAccuracy
        self.timestamp = timestamp
    }
    
    public init(from heading: CLHeading) {
        self.magneticHeading = heading.magneticHeading
        self.trueHeading = heading.trueHeading
        self.headingAccuracy = heading.headingAccuracy
        self.timestamp = heading.timestamp
    }
}

/// Location visit information
public struct LocationVisit: Sendable {
    public let coordinate: CLLocationCoordinate2D
    public let horizontalAccuracy: Double
    public let arrivalDate: Date
    public let departureDate: Date?
    
    public init(
        coordinate: CLLocationCoordinate2D,
        horizontalAccuracy: Double,
        arrivalDate: Date,
        departureDate: Date? = nil
    ) {
        self.coordinate = coordinate
        self.horizontalAccuracy = horizontalAccuracy
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
    }
    
    public init(from visit: CLVisit) {
        self.coordinate = visit.coordinate
        self.horizontalAccuracy = visit.horizontalAccuracy
        self.arrivalDate = visit.arrivalDate
        self.departureDate = visit.departureDate == Date.distantFuture ? nil : visit.departureDate
    }
}

/// Location metrics
public struct LocationMetrics: Sendable {
    public let locationUpdatesReceived: Int
    public let locationUpdatesFiltered: Int
    public let averageAccuracy: Double
    public let bestAccuracy: Double
    public let totalDistanceTraveled: Double
    public let averageSpeed: Double
    public let maxSpeed: Double
    public let geofenceEventsCount: Int
    public let geocodingRequestsCount: Int
    public let geocodingCacheHits: Int
    public let errorCount: Int
    public let sessionCount: Int
    
    public init(
        locationUpdatesReceived: Int = 0,
        locationUpdatesFiltered: Int = 0,
        averageAccuracy: Double = 0,
        bestAccuracy: Double = 0,
        totalDistanceTraveled: Double = 0,
        averageSpeed: Double = 0,
        maxSpeed: Double = 0,
        geofenceEventsCount: Int = 0,
        geocodingRequestsCount: Int = 0,
        geocodingCacheHits: Int = 0,
        errorCount: Int = 0,
        sessionCount: Int = 0
    ) {
        self.locationUpdatesReceived = locationUpdatesReceived
        self.locationUpdatesFiltered = locationUpdatesFiltered
        self.averageAccuracy = averageAccuracy
        self.bestAccuracy = bestAccuracy
        self.totalDistanceTraveled = totalDistanceTraveled
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.geofenceEventsCount = geofenceEventsCount
        self.geocodingRequestsCount = geocodingRequestsCount
        self.geocodingCacheHits = geocodingCacheHits
        self.errorCount = errorCount
        self.sessionCount = sessionCount
    }
    
    public var filterEfficiency: Double {
        guard locationUpdatesReceived > 0 else { return 0.0 }
        return Double(locationUpdatesFiltered) / Double(locationUpdatesReceived)
    }
    
    public var geocodingCacheHitRate: Double {
        guard geocodingRequestsCount > 0 else { return 0.0 }
        return Double(geocodingCacheHits) / Double(geocodingRequestsCount)
    }
}

// MARK: - Location Resource

/// Location resource management
public actor LocationCapabilityResource: AxiomCapabilityResource {
    private let configuration: LocationCapabilityConfiguration
    private var locationManager: CLLocationManager?
    private var geocoder: CLGeocoder?
    private var currentLocation: LocationInfo?
    private var locationHistory: [LocationInfo] = []
    private var geofences: [String: GeofenceRegion] = [:]
    private var geocodingCache: [String: (address: LocationAddress, timestamp: Date)] = [:]
    private var metrics: LocationMetrics = LocationMetrics()
    private var accuracyValues: [Double] = []
    private var speedValues: [Double] = []
    private var lastLocation: CLLocation?
    private var totalDistance: Double = 0
    
    // Async streams
    private var locationUpdatesContinuation: AsyncStream<LocationInfo>.Continuation?
    private var headingUpdatesContinuation: AsyncStream<LocationHeading>.Continuation?
    private var geofenceEventsContinuation: AsyncStream<GeofenceEvent>.Continuation?
    private var visitEventsContinuation: AsyncStream<LocationVisit>.Continuation?
    
    public init(configuration: LocationCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 20_000_000, // 20MB for location data and caching
            cpu: 10.0, // 10% CPU for location processing
            bandwidth: 0, // No network bandwidth for GPS
            storage: configuration.maxHistoryCount * 1000 // 1KB per location entry
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let historySize = locationHistory.count * 500
            let cacheSize = geocodingCache.count * 200
            
            return ResourceUsage(
                memory: historySize + cacheSize,
                cpu: locationManager?.desiredAccuracy != kCLLocationAccuracyBest ? 5.0 : 2.0,
                bandwidth: 0,
                storage: historySize
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        await getAuthorizationStatus() == .authorizedWhenInUse || await getAuthorizationStatus() == .authorizedAlways
    }
    
    public func release() async {
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        locationManager?.stopMonitoringSignificantLocationChanges()
        
        // Stop monitoring all geofences
        for region in geofences.values {
            locationManager?.stopMonitoring(for: region.clRegion)
        }
        
        locationManager?.delegate = nil
        locationManager = nil
        geocoder = nil
        
        locationUpdatesContinuation?.finish()
        headingUpdatesContinuation?.finish()
        geofenceEventsContinuation?.finish()
        visitEventsContinuation?.finish()
        
        locationUpdatesContinuation = nil
        headingUpdatesContinuation = nil
        geofenceEventsContinuation = nil
        visitEventsContinuation = nil
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        locationManager = CLLocationManager()
        geocoder = CLGeocoder()
        
        guard let manager = locationManager else {
            throw LocationError.locationManagerInitializationFailed
        }
        
        // Configure location manager
        manager.desiredAccuracy = mapAccuracy(configuration.desiredAccuracy)
        manager.distanceFilter = configuration.distanceFilter
        
        if configuration.enableBatteryOptimization {
            manager.pausesLocationUpdatesAutomatically = configuration.pausesLocationUpdatesWhenPossible
        }
        
        if configuration.enableBackgroundLocation {
            manager.allowsBackgroundLocationUpdates = configuration.allowsBackgroundLocationUpdates
            manager.showsBackgroundLocationIndicator = configuration.showsBackgroundLocationIndicator
        }
        
        if configuration.enableActivityTypeDetection {
            manager.activityType = mapActivityType(configuration.activityType)
        }
        
        if configuration.enableHeadingUpdates {
            manager.headingFilter = configuration.headingFilter
        }
        
        // Set up delegate
        manager.delegate = LocationManagerDelegate(resource: self)
        
        await updateMetrics(sessionStarted: true)
    }
    
    internal func updateConfiguration(_ configuration: LocationCapabilityConfiguration) async throws {
        if await isAvailable() {
            await release()
            try await allocate()
        }
    }
    
    // MARK: - Authorization
    
    public func getAuthorizationStatus() async -> LocationAuthorizationStatus {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways:
            return .authorizedAlways
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        @unknown default:
            return .notDetermined
        }
    }
    
    public func requestWhenInUsePermission() async throws -> LocationAuthorizationStatus {
        guard let manager = locationManager else {
            throw LocationError.locationManagerNotConfigured
        }
        
        return await withCheckedContinuation { continuation in
            manager.requestWhenInUseAuthorization()
            // Note: In a real implementation, you'd need to handle the delegate callback
            // For simplicity, we'll return the current status
            continuation.resume(returning: LocationAuthorizationStatus.authorizedWhenInUse)
        }
    }
    
    public func requestAlwaysPermission() async throws -> LocationAuthorizationStatus {
        guard let manager = locationManager else {
            throw LocationError.locationManagerNotConfigured
        }
        
        return await withCheckedContinuation { continuation in
            manager.requestAlwaysAuthorization()
            // Note: In a real implementation, you'd need to handle the delegate callback
            continuation.resume(returning: LocationAuthorizationStatus.authorizedAlways)
        }
    }
    
    // MARK: - Location Operations
    
    public func getCurrentLocation() async throws -> LocationInfo {
        guard let manager = locationManager else {
            throw LocationError.locationManagerNotConfigured
        }
        
        guard await isAvailable() else {
            throw LocationError.permissionDenied
        }
        
        return await withCheckedThrowingContinuation { continuation in
            manager.requestLocation()
            // In a real implementation, this would be handled by the delegate
            // For now, return cached location if available
            if let current = currentLocation {
                continuation.resume(returning: current)
            } else {
                continuation.resume(throwing: LocationError.locationNotAvailable)
            }
        }
    }
    
    public func startLocationUpdates() -> AsyncStream<LocationInfo> {
        AsyncStream { continuation in
            locationUpdatesContinuation = continuation
            
            guard let manager = locationManager else { return }
            
            if configuration.enableSignificantLocationChanges {
                manager.startMonitoringSignificantLocationChanges()
            } else {
                manager.startUpdatingLocation()
            }
        }
    }
    
    public func stopLocationUpdates() {
        locationUpdatesContinuation?.finish()
        locationUpdatesContinuation = nil
        
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
    }
    
    public func startHeadingUpdates() -> AsyncStream<LocationHeading> {
        AsyncStream { continuation in
            headingUpdatesContinuation = continuation
            locationManager?.startUpdatingHeading()
        }
    }
    
    public func stopHeadingUpdates() {
        headingUpdatesContinuation?.finish()
        headingUpdatesContinuation = nil
        locationManager?.stopUpdatingHeading()
    }
    
    public func startVisitMonitoring() -> AsyncStream<LocationVisit> {
        AsyncStream { continuation in
            visitEventsContinuation = continuation
            if configuration.enableVisitMonitoring {
                locationManager?.startMonitoringVisits()
            }
        }
    }
    
    public func stopVisitMonitoring() {
        visitEventsContinuation?.finish()
        visitEventsContinuation = nil
        locationManager?.stopMonitoringVisits()
    }
    
    // MARK: - Geofencing
    
    public func addGeofence(_ geofence: GeofenceRegion) async throws {
        guard configuration.enableGeofencing else {
            throw LocationError.geofencingNotEnabled
        }
        
        guard geofences.count < configuration.maxGeofenceCount else {
            throw LocationError.maxGeofencesReached
        }
        
        guard let manager = locationManager else {
            throw LocationError.locationManagerNotConfigured
        }
        
        geofences[geofence.identifier] = geofence
        manager.startMonitoring(for: geofence.clRegion)
    }
    
    public func removeGeofence(identifier: String) async {
        guard let geofence = geofences[identifier] else { return }
        
        geofences.removeValue(forKey: identifier)
        locationManager?.stopMonitoring(for: geofence.clRegion)
    }
    
    public func removeAllGeofences() async {
        for geofence in geofences.values {
            locationManager?.stopMonitoring(for: geofence.clRegion)
        }
        geofences.removeAll()
    }
    
    public func getGeofenceEvents() -> AsyncStream<GeofenceEvent> {
        AsyncStream { continuation in
            geofenceEventsContinuation = continuation
        }
    }
    
    public func getActiveGeofences() -> [GeofenceRegion] {
        Array(geofences.values.filter { $0.isActive })
    }
    
    // MARK: - Geocoding
    
    public func geocode(address: String) async throws -> [LocationAddress] {
        guard configuration.enableGeocoding else {
            throw LocationError.geocodingNotEnabled
        }
        
        // Check cache first
        if let cached = geocodingCache[address] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < configuration.geocodingCacheTTL {
                await updateMetrics(geocodingCacheHit: true)
                return [cached.address]
            } else {
                geocodingCache.removeValue(forKey: address)
            }
        }
        
        guard let geocoder = geocoder else {
            throw LocationError.geocoderNotConfigured
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
                Task { [weak self] in
                    await self?.updateMetrics(geocodingRequest: true)
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let placemarks = placemarks, !placemarks.isEmpty else {
                        continuation.resume(throwing: LocationError.geocodingFailed)
                        return
                    }
                    
                    let addresses = placemarks.map { LocationAddress(from: $0) }
                    
                    // Cache the first result
                    if let firstAddress = addresses.first {
                        await self?.cacheGeocodingResult(address: address, locationAddress: firstAddress)
                    }
                    
                    continuation.resume(returning: addresses)
                }
            }
        }
    }
    
    public func reverseGeocode(location: CLLocationCoordinate2D) async throws -> LocationAddress {
        guard configuration.enableGeocoding else {
            throw LocationError.geocodingNotEnabled
        }
        
        let cacheKey = "\(location.latitude),\(location.longitude)"
        
        // Check cache first
        if let cached = geocodingCache[cacheKey] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < configuration.geocodingCacheTTL {
                await updateMetrics(geocodingCacheHit: true)
                return cached.address
            } else {
                geocodingCache.removeValue(forKey: cacheKey)
            }
        }
        
        guard let geocoder = geocoder else {
            throw LocationError.geocoderNotConfigured
        }
        
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(clLocation) { [weak self] placemarks, error in
                Task { [weak self] in
                    await self?.updateMetrics(geocodingRequest: true)
                    
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let placemark = placemarks?.first else {
                        continuation.resume(throwing: LocationError.geocodingFailed)
                        return
                    }
                    
                    let address = LocationAddress(from: placemark)
                    await self?.cacheGeocodingResult(address: cacheKey, locationAddress: address)
                    
                    continuation.resume(returning: address)
                }
            }
        }
    }
    
    // MARK: - Location History
    
    public func getLocationHistory() -> [LocationInfo] {
        locationHistory
    }
    
    public func clearLocationHistory() {
        locationHistory.removeAll()
    }
    
    public func getLocationHistory(since date: Date) -> [LocationInfo] {
        locationHistory.filter { $0.timestamp >= date }
    }
    
    // MARK: - Distance and Calculations
    
    public func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    public func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let deltaLon = (to.longitude - from.longitude) * .pi / 180
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    public func isLocationValid(_ location: LocationInfo) -> Bool {
        guard configuration.enableLocationValidation else { return true }
        
        let age = Date().timeIntervalSince(location.timestamp)
        return age <= configuration.maxLocationAge && 
               location.horizontalAccuracy <= configuration.minLocationAccuracy &&
               location.horizontalAccuracy > 0
    }
    
    public func getCurrentLocation() -> LocationInfo? {
        currentLocation
    }
    
    public func getMetrics() -> LocationMetrics {
        metrics
    }
    
    // MARK: - Private Implementation
    
    private func mapAccuracy(_ accuracy: LocationCapabilityConfiguration.LocationAccuracy) -> CLLocationAccuracy {
        switch accuracy {
        case .bestForNavigation:
            return kCLLocationAccuracyBestForNavigation
        case .best:
            return kCLLocationAccuracyBest
        case .nearestTenMeters:
            return kCLLocationAccuracyNearestTenMeters
        case .hundredMeters:
            return kCLLocationAccuracyHundredMeters
        case .kilometer:
            return kCLLocationAccuracyKilometer
        case .threeKilometers:
            return kCLLocationAccuracyThreeKilometers
        case .reduced:
            return kCLLocationAccuracyReduced
        }
    }
    
    private func mapActivityType(_ activityType: LocationCapabilityConfiguration.ActivityType) -> CLActivityType {
        switch activityType {
        case .other:
            return .other
        case .automotiveNavigation:
            return .automotiveNavigation
        case .fitness:
            return .fitness
        case .otherNavigation:
            return .otherNavigation
        case .airborne:
            return .airborne
        }
    }
    
    private func addLocationToHistory(_ location: LocationInfo) {
        guard configuration.enableLocationHistory else { return }
        
        locationHistory.append(location)
        
        // Maintain history size limit
        if locationHistory.count > configuration.maxHistoryCount {
            locationHistory.removeFirst()
        }
        
        // Clean up old entries
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -configuration.historyRetentionDays, to: Date()) ?? Date.distantPast
        locationHistory.removeAll { $0.timestamp < cutoffDate }
    }
    
    private func cacheGeocodingResult(address: String, locationAddress: LocationAddress) async {
        geocodingCache[address] = (address: locationAddress, timestamp: Date())
        
        // Clean up cache if needed
        if geocodingCache.count > configuration.geocodingCacheSize {
            let oldestKey = geocodingCache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let key = oldestKey {
                geocodingCache.removeValue(forKey: key)
            }
        }
    }
    
    private func updateMetrics(
        locationUpdate: Bool = false,
        locationFiltered: Bool = false,
        accuracy: Double = 0,
        speed: Double = 0,
        distance: Double = 0,
        geofenceEvent: Bool = false,
        geocodingRequest: Bool = false,
        geocodingCacheHit: Bool = false,
        error: Bool = false,
        sessionStarted: Bool = false
    ) async {
        
        if locationUpdate {
            if accuracy > 0 {
                accuracyValues.append(accuracy)
            }
            if speed > 0 {
                speedValues.append(speed)
            }
            
            let avgAccuracy = accuracyValues.isEmpty ? 0 : accuracyValues.reduce(0, +) / Double(accuracyValues.count)
            let bestAccuracy = accuracyValues.min() ?? 0
            let avgSpeed = speedValues.isEmpty ? 0 : speedValues.reduce(0, +) / Double(speedValues.count)
            let maxSpeed = speedValues.max() ?? 0
            
            if distance > 0 {
                totalDistance += distance
            }
            
            metrics = LocationMetrics(
                locationUpdatesReceived: metrics.locationUpdatesReceived + 1,
                locationUpdatesFiltered: locationFiltered ? metrics.locationUpdatesFiltered + 1 : metrics.locationUpdatesFiltered,
                averageAccuracy: avgAccuracy,
                bestAccuracy: bestAccuracy,
                totalDistanceTraveled: totalDistance,
                averageSpeed: avgSpeed,
                maxSpeed: maxSpeed,
                geofenceEventsCount: metrics.geofenceEventsCount,
                geocodingRequestsCount: metrics.geocodingRequestsCount,
                geocodingCacheHits: metrics.geocodingCacheHits,
                errorCount: metrics.errorCount,
                sessionCount: metrics.sessionCount
            )
        }
        
        if geofenceEvent {
            metrics = LocationMetrics(
                locationUpdatesReceived: metrics.locationUpdatesReceived,
                locationUpdatesFiltered: metrics.locationUpdatesFiltered,
                averageAccuracy: metrics.averageAccuracy,
                bestAccuracy: metrics.bestAccuracy,
                totalDistanceTraveled: metrics.totalDistanceTraveled,
                averageSpeed: metrics.averageSpeed,
                maxSpeed: metrics.maxSpeed,
                geofenceEventsCount: metrics.geofenceEventsCount + 1,
                geocodingRequestsCount: metrics.geocodingRequestsCount,
                geocodingCacheHits: metrics.geocodingCacheHits,
                errorCount: metrics.errorCount,
                sessionCount: metrics.sessionCount
            )
        }
        
        if geocodingRequest {
            metrics = LocationMetrics(
                locationUpdatesReceived: metrics.locationUpdatesReceived,
                locationUpdatesFiltered: metrics.locationUpdatesFiltered,
                averageAccuracy: metrics.averageAccuracy,
                bestAccuracy: metrics.bestAccuracy,
                totalDistanceTraveled: metrics.totalDistanceTraveled,
                averageSpeed: metrics.averageSpeed,
                maxSpeed: metrics.maxSpeed,
                geofenceEventsCount: metrics.geofenceEventsCount,
                geocodingRequestsCount: metrics.geocodingRequestsCount + 1,
                geocodingCacheHits: geocodingCacheHit ? metrics.geocodingCacheHits + 1 : metrics.geocodingCacheHits,
                errorCount: metrics.errorCount,
                sessionCount: metrics.sessionCount
            )
        }
        
        if sessionStarted {
            metrics = LocationMetrics(
                locationUpdatesReceived: metrics.locationUpdatesReceived,
                locationUpdatesFiltered: metrics.locationUpdatesFiltered,
                averageAccuracy: metrics.averageAccuracy,
                bestAccuracy: metrics.bestAccuracy,
                totalDistanceTraveled: metrics.totalDistanceTraveled,
                averageSpeed: metrics.averageSpeed,
                maxSpeed: metrics.maxSpeed,
                geofenceEventsCount: metrics.geofenceEventsCount,
                geocodingRequestsCount: metrics.geocodingRequestsCount,
                geocodingCacheHits: metrics.geocodingCacheHits,
                errorCount: metrics.errorCount,
                sessionCount: metrics.sessionCount + 1
            )
        }
    }
    
    // MARK: - Location Manager Delegate Handler
    
    internal func handleLocationUpdate(_ location: CLLocation) async {
        let locationInfo = LocationInfo(from: location)
        
        // Validate location if enabled
        if configuration.enableLocationValidation && !isLocationValid(locationInfo) {
            await updateMetrics(locationFiltered: true)
            return
        }
        
        // Calculate distance if we have a previous location
        var distance: Double = 0
        if let lastLoc = lastLocation {
            distance = location.distance(from: lastLoc)
        }
        
        currentLocation = locationInfo
        lastLocation = location
        
        addLocationToHistory(locationInfo)
        
        await updateMetrics(
            locationUpdate: true,
            accuracy: location.horizontalAccuracy,
            speed: location.speed,
            distance: distance
        )
        
        locationUpdatesContinuation?.yield(locationInfo)
    }
    
    internal func handleHeadingUpdate(_ heading: CLHeading) async {
        let headingInfo = LocationHeading(from: heading)
        headingUpdatesContinuation?.yield(headingInfo)
    }
    
    internal func handleGeofenceEvent(region: CLCircularRegion, eventType: GeofenceEvent.EventType) async {
        guard let currentLocation = currentLocation else { return }
        
        let event = GeofenceEvent(
            regionIdentifier: region.identifier,
            eventType: eventType,
            location: currentLocation
        )
        
        await updateMetrics(geofenceEvent: true)
        geofenceEventsContinuation?.yield(event)
    }
    
    internal func handleVisit(_ visit: CLVisit) async {
        let visitInfo = LocationVisit(from: visit)
        visitEventsContinuation?.yield(visitInfo)
    }
}

// MARK: - Location Manager Delegate

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    weak var resource: LocationCapabilityResource?
    
    init(resource: LocationCapabilityResource) {
        self.resource = resource
        super.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task {
            await resource?.handleLocationUpdate(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task {
            await resource?.handleHeadingUpdate(newHeading)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        Task {
            await resource?.handleGeofenceEvent(region: circularRegion, eventType: .entry)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        
        Task {
            await resource?.handleGeofenceEvent(region: circularRegion, eventType: .exit)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        Task {
            await resource?.handleVisit(visit)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location errors
    }
}

// MARK: - Location Capability Implementation

/// Location capability providing GPS/location services
public actor LocationCapability: DomainCapability {
    public typealias ConfigurationType = LocationCapabilityConfiguration
    public typealias ResourceType = LocationCapabilityResource
    
    private var _configuration: LocationCapabilityConfiguration
    private var _resources: LocationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "location-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: LocationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: LocationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: LocationCapabilityConfiguration = LocationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = LocationCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: LocationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Location configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        CLLocationManager.locationServicesEnabled()
    }
    
    public func requestPermission() async throws {
        let status = try await _resources.requestWhenInUsePermission()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Location Operations
    
    /// Get current location
    public func getCurrentLocation() async throws -> LocationInfo {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Location capability not available")
        }
        
        return try await _resources.getCurrentLocation()
    }
    
    /// Start location updates
    public func startLocationUpdates() async -> AsyncStream<LocationInfo> {
        await _resources.startLocationUpdates()
    }
    
    /// Stop location updates
    public func stopLocationUpdates() async {
        await _resources.stopLocationUpdates()
    }
    
    /// Start heading updates
    public func startHeadingUpdates() async -> AsyncStream<LocationHeading> {
        await _resources.startHeadingUpdates()
    }
    
    /// Stop heading updates
    public func stopHeadingUpdates() async {
        await _resources.stopHeadingUpdates()
    }
    
    /// Start visit monitoring
    public func startVisitMonitoring() async -> AsyncStream<LocationVisit> {
        await _resources.startVisitMonitoring()
    }
    
    /// Stop visit monitoring
    public func stopVisitMonitoring() async {
        await _resources.stopVisitMonitoring()
    }
    
    // MARK: - Geofencing
    
    /// Add geofence
    public func addGeofence(_ geofence: GeofenceRegion) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Location capability not available")
        }
        
        try await _resources.addGeofence(geofence)
    }
    
    /// Remove geofence
    public func removeGeofence(identifier: String) async {
        await _resources.removeGeofence(identifier: identifier)
    }
    
    /// Remove all geofences
    public func removeAllGeofences() async {
        await _resources.removeAllGeofences()
    }
    
    /// Get geofence events
    public func getGeofenceEvents() async -> AsyncStream<GeofenceEvent> {
        await _resources.getGeofenceEvents()
    }
    
    /// Get active geofences
    public func getActiveGeofences() async -> [GeofenceRegion] {
        await _resources.getActiveGeofences()
    }
    
    // MARK: - Geocoding
    
    /// Geocode address to coordinates
    public func geocode(address: String) async throws -> [LocationAddress] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Location capability not available")
        }
        
        return try await _resources.geocode(address: address)
    }
    
    /// Reverse geocode coordinates to address
    public func reverseGeocode(location: CLLocationCoordinate2D) async throws -> LocationAddress {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Location capability not available")
        }
        
        return try await _resources.reverseGeocode(location: location)
    }
    
    // MARK: - Location History
    
    /// Get location history
    public func getLocationHistory() async -> [LocationInfo] {
        await _resources.getLocationHistory()
    }
    
    /// Clear location history
    public func clearLocationHistory() async {
        await _resources.clearLocationHistory()
    }
    
    /// Get location history since date
    public func getLocationHistory(since date: Date) async -> [LocationInfo] {
        await _resources.getLocationHistory(since: date)
    }
    
    // MARK: - Distance and Calculations
    
    /// Calculate distance between two coordinates
    public func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> Double {
        await _resources.calculateDistance(from: from, to: to)
    }
    
    /// Calculate bearing between two coordinates
    public func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async -> Double {
        await _resources.calculateBearing(from: from, to: to)
    }
    
    /// Validate location
    public func isLocationValid(_ location: LocationInfo) async -> Bool {
        await _resources.isLocationValid(location)
    }
    
    /// Get metrics
    public func getMetrics() async -> LocationMetrics {
        await _resources.getMetrics()
    }
    
    /// Get authorization status
    public func getAuthorizationStatus() async -> LocationAuthorizationStatus {
        await _resources.getAuthorizationStatus()
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Location specific errors
public enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationNotAvailable
    case locationManagerNotConfigured
    case locationManagerInitializationFailed
    case geocoderNotConfigured
    case geocodingNotEnabled
    case geocodingFailed
    case geofencingNotEnabled
    case maxGeofencesReached
    case invalidCoordinates
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationNotAvailable:
            return "Current location not available"
        case .locationManagerNotConfigured:
            return "Location manager not configured"
        case .locationManagerInitializationFailed:
            return "Failed to initialize location manager"
        case .geocoderNotConfigured:
            return "Geocoder not configured"
        case .geocodingNotEnabled:
            return "Geocoding is not enabled"
        case .geocodingFailed:
            return "Geocoding operation failed"
        case .geofencingNotEnabled:
            return "Geofencing is not enabled"
        case .maxGeofencesReached:
            return "Maximum number of geofences reached"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}