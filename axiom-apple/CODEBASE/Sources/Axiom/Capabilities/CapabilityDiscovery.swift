import Foundation
import AVFoundation
import CoreLocation
@preconcurrency import UserNotifications
import Network

/// Service for discovering and validating system and custom capabilities
public actor AxiomCapabilityDiscoveryService {
    public static let shared = AxiomCapabilityDiscoveryService()
    
    private var registeredCapabilities: [String: AxiomCapabilityRegistration] = [:]
    private var discoveredCapabilities: Set<String> = []
    private let discoveryQueue = AsyncStream<DiscoveryRequest>.makeStream()
    
    private init() {}
    
    public struct AxiomCapabilityRegistration {
        let identifier: String
        let capability: any AxiomCapability
        let requirements: Set<Requirement>
        let validator: () async -> Bool
        let metadata: AxiomCapabilityMetadata
        
        public init(
            identifier: String,
            capability: any AxiomCapability,
            requirements: Set<Requirement>,
            validator: @escaping () async -> Bool,
            metadata: AxiomCapabilityMetadata
        ) {
            self.identifier = identifier
            self.capability = capability
            self.requirements = requirements
            self.validator = validator
            self.metadata = metadata
        }
    }
    
    public struct Requirement: Hashable, Sendable {
        let type: RequirementType
        let isMandatory: Bool
        
        public init(type: RequirementType, isMandatory: Bool = true) {
            self.type = type
            self.isMandatory = isMandatory
        }
        
        public enum RequirementType: Hashable, Sendable {
            case systemFeature(String)
            case permission(String)
            case dependency(String)
            case minimumOSVersion(String)
            case hardware(String)
        }
    }
    
    public struct DiscoveryRequest: Sendable {
        let identifier: String
        let priority: DiscoveryPriority
        
        public enum DiscoveryPriority: Sendable {
            case low, normal, high, immediate
        }
    }
    
    /// Register a capability with the discovery service
    public func register(
        capability: any AxiomCapability,
        identifier: String? = nil,
        requirements: Set<Requirement> = [],
        validator: @escaping () async -> Bool = { true },
        metadata: AxiomCapabilityMetadata
    ) async {
        let capabilityId = identifier ?? String(describing: type(of: capability))
        
        let registration = AxiomCapabilityRegistration(
            identifier: capabilityId,
            capability: capability,
            requirements: requirements,
            validator: validator,
            metadata: metadata
        )
        
        registeredCapabilities[capabilityId] = registration
    }
    
    /// Start capability discovery process
    public func discover() async throws {
        // Start discovery processing task
        Task {
            await processDiscoveryRequests()
        }
        
        // Discover system capabilities first
        await discoverSystemCapabilities()
        
        // Discover registered capabilities
        for (identifier, registration) in registeredCapabilities {
            let isAvailable = await validateAxiomCapability(registration)
            if isAvailable {
                discoveredCapabilities.insert(identifier)
                await notifyAxiomCapabilityDiscovered(identifier)
            }
        }
    }
    
    /// Check if a specific capability type is available
    public func hasAxiomCapability<C: AxiomCapability>(_ type: C.Type) -> Bool {
        let identifier = String(describing: type)
        return discoveredCapabilities.contains(identifier)
    }
    
    /// Check if a capability by identifier is available
    public func hasAxiomCapability(_ identifier: String) async -> Bool {
        return discoveredCapabilities.contains(identifier)
    }
    
    /// Get an instance of a specific capability type
    public func capability<C: AxiomCapability>(_ type: C.Type) async -> C? {
        let identifier = String(describing: type)
        guard discoveredCapabilities.contains(identifier),
              let registration = registeredCapabilities[identifier],
              let capability = registration.capability as? C else {
            return nil
        }
        return capability
    }
    
    /// Get capability by identifier
    public func capability(_ identifier: String) async -> (any AxiomCapability)? {
        guard discoveredCapabilities.contains(identifier),
              let registration = registeredCapabilities[identifier] else {
            return nil
        }
        return registration.capability
    }
    
    /// Notify that a capability has been registered
    public func capabilityRegistered(_ registration: AxiomCapabilityRegistration) async {
        // Process immediate discovery for the new capability
        let isAvailable = await validateAxiomCapability(registration)
        if isAvailable {
            discoveredCapabilities.insert(registration.identifier)
            await notifyAxiomCapabilityDiscovered(registration.identifier)
        }
    }
    
    /// Handle capability becoming available
    public func capabilityBecameAvailable(_ identifier: String) async {
        discoveredCapabilities.insert(identifier)
        await notifyAxiomCapabilityDiscovered(identifier)
    }
    
    /// Handle capability becoming unavailable
    public func capabilityBecameUnavailable(_ identifier: String) async {
        discoveredCapabilities.remove(identifier)
        await notifyAxiomCapabilityLost(identifier)
    }
    
    /// Get all discovered capability identifiers
    public func discoveredAxiomCapabilityIds() -> Set<String> {
        return discoveredCapabilities
    }
    
    /// Validate a capability against its requirements
    private func validateAxiomCapability(_ registration: AxiomCapabilityRegistration) async -> Bool {
        // Check all requirements
        for requirement in registration.requirements {
            let isMet = await checkRequirement(requirement)
            if requirement.isMandatory && !isMet {
                return false
            }
        }
        
        // Run custom validator
        return await registration.validator()
    }
    
    /// Check if a specific requirement is met
    private func checkRequirement(_ requirement: Requirement) async -> Bool {
        switch requirement.type {
        case .systemFeature(let feature):
            return await SystemFeatures.isAvailable(feature)
            
        case .permission(let permission):
            return await Permissions.isGranted(permission)
            
        case .dependency(let capability):
            return discoveredCapabilities.contains(capability)
            
        case .minimumOSVersion(let version):
            return await OSVersionChecker.isAtLeast(version)
            
        case .hardware(let hardware):
            return await HardwareDetection.isAvailable(hardware)
        }
    }
    
    /// Discover system-level capabilities
    private func discoverSystemCapabilities() async {
        // Camera capability
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus != .denied && cameraStatus != .restricted {
            discoveredCapabilities.insert("system.camera")
        }
        
        // Location capability
        if CLLocationManager.locationServicesEnabled() {
            discoveredCapabilities.insert("system.location")
        }
        
        // Notification capability
        let notificationCenter = UNUserNotificationCenter.current()
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .authorized {
            discoveredCapabilities.insert("system.notifications")
        }
        
        // Network capability
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkAxiomCapabilityCheck")
        monitor.start(queue: queue)
        
        // Check current network state
        if monitor.currentPath.status == .satisfied {
            discoveredCapabilities.insert("system.network")
        }
        monitor.cancel()
        
        // File system capability
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if documentsPath != nil {
            discoveredCapabilities.insert("system.filesystem")
        }
    }
    
    /// Process discovery requests from the queue
    private func processDiscoveryRequests() async {
        for await request in discoveryQueue.stream {
            await handleDiscoveryRequest(request)
        }
    }
    
    /// Handle a specific discovery request
    private func handleDiscoveryRequest(_ request: DiscoveryRequest) async {
        guard let registration = registeredCapabilities[request.identifier] else {
            return
        }
        
        let isAvailable = await validateAxiomCapability(registration)
        let wasAvailable = discoveredCapabilities.contains(request.identifier)
        
        if isAvailable != wasAvailable {
            if isAvailable {
                discoveredCapabilities.insert(request.identifier)
                await notifyAxiomCapabilityDiscovered(request.identifier)
            } else {
                discoveredCapabilities.remove(request.identifier)
                await notifyAxiomCapabilityLost(request.identifier)
            }
        }
    }
    
    /// Notify observers that a capability was discovered
    private func notifyAxiomCapabilityDiscovered(_ identifier: String) async {
        NotificationCenter.default.post(
            name: .capabilityBecameAvailable,
            object: nil,
            userInfo: ["capability": identifier]
        )
    }
    
    /// Notify observers that a capability was lost
    private func notifyAxiomCapabilityLost(_ identifier: String) async {
        NotificationCenter.default.post(
            name: .capabilityBecameUnavailable,
            object: nil,
            userInfo: ["capability": identifier]
        )
    }
}

// MARK: - System Feature Detection

/// System feature detection utilities
private actor SystemFeatures {
    static func isAvailable(_ feature: String) async -> Bool {
        switch feature {
        case "camera":
            return AVCaptureDevice.default(for: .video) != nil
        case "microphone":
            return AVCaptureDevice.default(for: .audio) != nil
        case "location":
            return CLLocationManager.locationServicesEnabled()
        case "notifications":
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            return settings.authorizationStatus != .denied
        case "network":
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "FeatureCheck")
            monitor.start(queue: queue)
            let isConnected = monitor.currentPath.status == .satisfied
            monitor.cancel()
            return isConnected
        default:
            return false
        }
    }
}

// MARK: - Permission Checking

/// Permission checking utilities
private actor Permissions {
    static func isGranted(_ permission: String) async -> Bool {
        switch permission {
        case "camera":
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        case "microphone":
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        case "location":
            let manager = CLLocationManager()
            #if os(macOS)
            return manager.authorizationStatus == .authorizedAlways
            #else
            return manager.authorizationStatus == .authorizedWhenInUse || 
                   manager.authorizationStatus == .authorizedAlways
            #endif
        case "notifications":
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        default:
            return false
        }
    }
}

// MARK: - OS Version Checking

/// OS version checking utilities
private actor OSVersionChecker {
    static func isAtLeast(_ version: String) async -> Bool {
        guard let targetVersion = parseVersion(version) else { return false }
        
        let currentVersion = ProcessInfo.processInfo.operatingSystemVersion
        let current = (currentVersion.majorVersion, currentVersion.minorVersion, currentVersion.patchVersion)
        
        return current.0 > targetVersion.0 ||
               (current.0 == targetVersion.0 && current.1 > targetVersion.1) ||
               (current.0 == targetVersion.0 && current.1 == targetVersion.1 && current.2 >= targetVersion.2)
    }
    
    private static func parseVersion(_ version: String) -> (Int, Int, Int)? {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 1 else { return nil }
        
        let major = components[0]
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        
        return (major, minor, patch)
    }
}

// MARK: - Hardware Detection

/// Hardware detection utilities
private actor HardwareDetection {
    static func isAvailable(_ hardware: String) async -> Bool {
        switch hardware {
        case "gpu":
            return true // Assume GPU is always available on iOS
        case "neural_engine":
            return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 11
        case "lidar":
            // This is a simplified check - would need actual device capability detection
            return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14
        case "face_id":
            // Simplified - would check for actual Face ID hardware
            return ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 11
        case "touch_id":
            // Simplified - would check for actual Touch ID hardware
            return true
        default:
            return false
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let capabilityBecameAvailable = Notification.Name("AxiomCapabilityBecameAvailable")
    static let capabilityBecameUnavailable = Notification.Name("AxiomCapabilityBecameUnavailable")
}

// MARK: - AxiomCapability Metadata

public struct AxiomCapabilityMetadata: Sendable {
    public let name: String?
    public let description: String
    public let version: String
    public let category: String?
    public let documentation: String?
    public let supportedPlatforms: [String]?
    public let minimumOSVersion: String?
    public let tags: Set<String>?
    public let dependencies: [String]?
    
    public init(
        name: String? = nil,
        description: String = "",
        version: String = "1.0.0",
        category: String? = nil,
        documentation: String? = nil,
        supportedPlatforms: [String]? = nil,
        minimumOSVersion: String? = nil,
        tags: Set<String>? = nil,
        dependencies: [String]? = nil
    ) {
        self.name = name
        self.description = description
        self.version = version
        self.category = category
        self.documentation = documentation
        self.supportedPlatforms = supportedPlatforms
        self.minimumOSVersion = minimumOSVersion
        self.tags = tags
        self.dependencies = dependencies
    }
}