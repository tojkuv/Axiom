import Foundation

// MARK: - Capability Enumeration

/// All available capabilities in the Axiom framework
public enum Capability: String, CaseIterable, Sendable, Codable {
    // MARK: Data Access
    case network = "network"
    case storage = "storage"
    case keychain = "keychain"
    case userDefaults = "userDefaults"
    case fileSystem = "fileSystem"
    case database = "database"
    case cache = "cache"
    
    // MARK: System Services
    case location = "location"
    case camera = "camera"
    case microphone = "microphone"
    case photos = "photos"
    case contacts = "contacts"
    case calendar = "calendar"
    case notifications = "notifications"
    case biometrics = "biometrics"
    case healthKit = "healthKit"
    
    // MARK: Cross-Cutting Concerns
    case analytics = "analytics"
    case logging = "logging"
    case errorReporting = "errorReporting"
    case performanceMonitoring = "performanceMonitoring"
    case remoteConfig = "remoteConfig"
    
    // MARK: Application Services
    case navigation = "navigation"
    case stateManagement = "stateManagement"
    case businessLogic = "businessLogic"
    case backgroundProcessing = "backgroundProcessing"
    case deepLinking = "deepLinking"
    case sharing = "sharing"
    
    // MARK: Development & Testing
    case debugging = "debugging"
    case testing = "testing"
    case mocking = "mocking"
    case simulation = "simulation"
}

// MARK: - Capability Domain

/// Groups capabilities into logical domains
public enum CapabilityDomain: String, CaseIterable, Sendable, Codable {
    case dataAccess = "dataAccess"
    case systemServices = "systemServices"
    case crossCutting = "crossCutting"
    case application = "application"
    case development = "development"
    
    /// Returns all capabilities in this domain
    public var capabilities: Set<Capability> {
        switch self {
        case .dataAccess:
            return [.network, .storage, .keychain, .userDefaults, .fileSystem, .database, .cache]
            
        case .systemServices:
            return [.location, .camera, .microphone, .photos, .contacts, .calendar, .notifications, .biometrics, .healthKit]
            
        case .crossCutting:
            return [.analytics, .logging, .errorReporting, .performanceMonitoring, .remoteConfig]
            
        case .application:
            return [.navigation, .stateManagement, .businessLogic, .backgroundProcessing, .deepLinking, .sharing]
            
        case .development:
            return [.debugging, .testing, .mocking, .simulation]
        }
    }
    
    /// Checks if a capability belongs to this domain
    public func contains(_ capability: Capability) -> Bool {
        capabilities.contains(capability)
    }
}

// MARK: - Capability Requirements

/// Describes the requirements for a capability
public struct CapabilityRequirement: Sendable, Codable {
    public let capability: Capability
    public let required: Bool
    public let reason: String?
    public let alternatives: [Capability]
    
    public init(
        capability: Capability,
        required: Bool = true,
        reason: String? = nil,
        alternatives: [Capability] = []
    ) {
        self.capability = capability
        self.required = required
        self.reason = reason
        self.alternatives = alternatives
    }
}

// MARK: - Capability Metadata

extension Capability {
    /// Human-readable name for the capability
    public var displayName: String {
        switch self {
        case .network: return "Network Access"
        case .storage: return "Local Storage"
        case .keychain: return "Keychain Access"
        case .userDefaults: return "User Defaults"
        case .fileSystem: return "File System"
        case .database: return "Database"
        case .cache: return "Cache Storage"
        case .location: return "Location Services"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .photos: return "Photo Library"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .notifications: return "Notifications"
        case .biometrics: return "Biometric Authentication"
        case .healthKit: return "HealthKit"
        case .analytics: return "Analytics"
        case .logging: return "Logging"
        case .errorReporting: return "Error Reporting"
        case .performanceMonitoring: return "Performance Monitoring"
        case .remoteConfig: return "Remote Configuration"
        case .navigation: return "Navigation"
        case .stateManagement: return "State Management"
        case .businessLogic: return "Business Logic"
        case .backgroundProcessing: return "Background Processing"
        case .deepLinking: return "Deep Linking"
        case .sharing: return "Sharing"
        case .debugging: return "Debugging"
        case .testing: return "Testing"
        case .mocking: return "Mocking"
        case .simulation: return "Simulation"
        }
    }
    
    /// Description of what this capability enables
    public var capabilityDescription: String {
        switch self {
        case .network: return "Allows network requests and API communication"
        case .storage: return "Enables local data persistence"
        case .keychain: return "Secure storage for sensitive data"
        case .userDefaults: return "Simple key-value storage for preferences"
        case .fileSystem: return "Direct file system access"
        case .database: return "Database operations (Core Data, SQLite)"
        case .cache: return "Temporary data caching"
        case .location: return "Access to device location"
        case .camera: return "Camera access for photos/video"
        case .microphone: return "Audio recording capabilities"
        case .photos: return "Access to photo library"
        case .contacts: return "Read/write contact information"
        case .calendar: return "Calendar event management"
        case .notifications: return "Local and push notifications"
        case .biometrics: return "Face ID/Touch ID authentication"
        case .healthKit: return "Health data access"
        case .analytics: return "User behavior tracking"
        case .logging: return "Application logging"
        case .errorReporting: return "Crash and error reporting"
        case .performanceMonitoring: return "Performance metrics collection"
        case .remoteConfig: return "Remote configuration updates"
        case .navigation: return "App navigation control"
        case .stateManagement: return "Application state management"
        case .businessLogic: return "Core business operations"
        case .backgroundProcessing: return "Background task execution"
        case .deepLinking: return "URL scheme handling"
        case .sharing: return "Share sheet and activity items"
        case .debugging: return "Debug tools and utilities"
        case .testing: return "Testing framework access"
        case .mocking: return "Mock data generation"
        case .simulation: return "Environment simulation"
        }
    }
    
    /// The domain this capability belongs to
    public var domain: CapabilityDomain {
        for domain in CapabilityDomain.allCases {
            if domain.contains(self) {
                return domain
            }
        }
        preconditionFailure("Capability \(self) not assigned to any domain - assign capability to a domain first")
    }
    
    /// Whether this capability requires user permission
    public var requiresUserPermission: Bool {
        switch self {
        case .location, .camera, .microphone, .photos, .contacts, .calendar, .notifications, .biometrics, .healthKit:
            return true
        default:
            return false
        }
    }
    
    /// Whether this capability is available in all environments
    public var isAlwaysAvailable: Bool {
        switch self {
        case .stateManagement, .businessLogic, .logging, .debugging:
            return true
        default:
            return false
        }
    }
}

// MARK: - Capability Extensions

extension Capability: Comparable {
    public static func < (lhs: Capability, rhs: Capability) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}