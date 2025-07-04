import Foundation
import AxiomCore
import SwiftUI
import CoreData
import CoreML
import AVFoundation
import Photos
import Network
import UserNotifications

// MARK: - Domain Capability Foundation

/// Base protocol for domain-specific capabilities with enhanced functionality
public protocol DomainCapability: AxiomExtendedCapability {
    associatedtype ConfigurationType: AxiomCapabilityConfiguration
    associatedtype ResourceType: AxiomCapabilityResource
    
    /// Configuration for this capability
    var configuration: ConfigurationType { get async }
    
    /// Resources managed by this capability
    var resources: ResourceType { get async }
    
    /// Environment this capability is running in
    var environment: AxiomCapabilityEnvironment { get async }
    
    /// Update configuration at runtime
    func updateConfiguration(_ configuration: ConfigurationType) async throws
    
    /// Handle environment changes
    func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async
}

/// Configuration protocol for capabilities
public protocol AxiomCapabilityConfiguration: Codable, Sendable {
    /// Whether this configuration is valid
    var isValid: Bool { get }
    
    /// Merge with another configuration
    func merged(with other: Self) -> Self
    
    /// Environment-specific adjustments
    func adjusted(for environment: AxiomCapabilityEnvironment) -> Self
}

/// Resource protocol for capability resource management
public protocol AxiomCapabilityResource: Sendable {
    /// Current resource usage
    var currentUsage: ResourceUsage { get async }
    
    /// Maximum allowed usage
    var maxUsage: ResourceUsage { get }
    
    /// Release resources
    func release() async
    
    /// Check if resources are available
    func isAvailable() async -> Bool
}

/// Resource usage tracking
public struct ResourceUsage: Codable, Sendable {
    public let memory: Int // bytes
    public let cpu: Double // percentage
    public let bandwidth: Int // bytes per second
    public let storage: Int // bytes
    
    public init(memory: Int = 0, cpu: Double = 0, bandwidth: Int = 0, storage: Int = 0) {
        self.memory = memory
        self.cpu = cpu
        self.bandwidth = bandwidth
        self.storage = storage
    }
    
    /// Check if this usage exceeds another usage
    public func exceeds(_ other: ResourceUsage) -> Bool {
        return memory > other.memory ||
               cpu > other.cpu ||
               bandwidth > other.bandwidth ||
               storage > other.storage
    }
}

/// Environment information for capabilities
public struct AxiomCapabilityEnvironment: Codable, Sendable, Hashable {
    public let isDebug: Bool
    public let isLowPowerMode: Bool
    public let hasNetworkConnection: Bool
    public let deviceClass: DeviceClass
    public let osVersion: String
    
    public init(
        isDebug: Bool = false,
        isLowPowerMode: Bool = false,
        hasNetworkConnection: Bool = true,
        deviceClass: DeviceClass = .phone,
        osVersion: String = "17.0"
    ) {
        self.isDebug = isDebug
        self.isLowPowerMode = isLowPowerMode
        self.hasNetworkConnection = hasNetworkConnection
        self.deviceClass = deviceClass
        self.osVersion = osVersion
    }
    
    // Predefined environment configurations
    public static let testing = AxiomCapabilityEnvironment(isDebug: true)
    public static let development = AxiomCapabilityEnvironment(isDebug: true)
    public static let staging = AxiomCapabilityEnvironment(isDebug: false)
    public static let production = AxiomCapabilityEnvironment(isDebug: false)
    public static let preview = AxiomCapabilityEnvironment(isDebug: true)
    
    // Computed property for backwards compatibility with enum-like usage
    public var rawValue: String {
        switch self {
        case Self.testing: return "testing"
        case Self.development: return "development"
        case Self.staging: return "staging"
        case Self.production: return "production"
        case Self.preview: return "preview"
        default: return "custom"
        }
    }
}

/// Device classification for capability optimization
public enum DeviceClass: String, Codable, CaseIterable, Sendable {
    case phone
    case tablet
    case desktop
    case watch
    case tv
    
    public var memoryCapacity: Int {
        switch self {
        case .phone: return 8 * 1024 * 1024 * 1024 // 8GB
        case .tablet: return 16 * 1024 * 1024 * 1024 // 16GB  
        case .desktop: return 32 * 1024 * 1024 * 1024 // 32GB
        case .watch: return 1 * 1024 * 1024 * 1024 // 1GB
        case .tv: return 4 * 1024 * 1024 * 1024 // 4GB
        }
    }
}

// MARK: - Core Data Capability Registration

/// Extension for registering Core Data persistence capability
extension AxiomCapabilityRegistry {
    
    /// Register Core Data persistence capability
    public func registerCoreDataPersistence() async throws {
        // Note: CoreDataPersistenceCapability implementation removed for MVP
        throw AxiomError.capabilityError(.unavailable("Core Data persistence capability not implemented in MVP"))
    }
}