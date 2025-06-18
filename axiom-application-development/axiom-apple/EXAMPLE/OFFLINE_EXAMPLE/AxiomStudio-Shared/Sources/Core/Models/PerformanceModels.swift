import Foundation

public struct MemoryUsage: Codable, Equatable, Hashable, Sendable {
    public let totalMemory: UInt64
    public let usedMemory: UInt64
    public let freeMemory: UInt64
    public let appMemoryUsage: UInt64
    public let memoryPressure: MemoryPressureLevel
    public let timestamp: Date
    
    public init(
        totalMemory: UInt64 = 0,
        usedMemory: UInt64 = 0,
        freeMemory: UInt64 = 0,
        appMemoryUsage: UInt64 = 0,
        memoryPressure: MemoryPressureLevel = .normal,
        timestamp: Date = Date()
    ) {
        self.totalMemory = totalMemory
        self.usedMemory = usedMemory
        self.freeMemory = freeMemory
        self.appMemoryUsage = appMemoryUsage
        self.memoryPressure = memoryPressure
        self.timestamp = timestamp
    }
    
    public var usagePercentage: Double {
        guard totalMemory > 0 else { return 0 }
        return Double(usedMemory) / Double(totalMemory) * 100
    }
    
    public var appUsagePercentage: Double {
        guard totalMemory > 0 else { return 0 }
        return Double(appMemoryUsage) / Double(totalMemory) * 100
    }
}

public enum MemoryPressureLevel: String, CaseIterable, Codable, Hashable, Sendable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct PerformanceMetric: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let metricType: PerformanceMetricType
    public let value: Double
    public let unit: String
    public let timestamp: Date
    public let context: String?
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        metricType: PerformanceMetricType,
        value: Double,
        unit: String,
        timestamp: Date = Date(),
        context: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.metricType = metricType
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.context = context
        self.metadata = metadata
    }
}

public enum PerformanceMetricType: String, CaseIterable, Codable, Hashable, Sendable {
    case cpuUsage = "cpuUsage"
    case memoryUsage = "memoryUsage"
    case diskUsage = "diskUsage"
    case networkLatency = "networkLatency"
    case frameRate = "frameRate"
    case appLaunchTime = "appLaunchTime"
    case taskExecutionTime = "taskExecutionTime"
    case stateUpdateTime = "stateUpdateTime"
    case capabilityActivationTime = "capabilityActivationTime"
    case batteryLevel = "batteryLevel"
    case batteryUsage = "batteryUsage"
    
    public var displayName: String {
        switch self {
        case .cpuUsage: return "CPU Usage"
        case .memoryUsage: return "Memory Usage"
        case .diskUsage: return "Disk Usage"
        case .networkLatency: return "Network Latency"
        case .frameRate: return "Frame Rate"
        case .appLaunchTime: return "App Launch Time"
        case .taskExecutionTime: return "Task Execution Time"
        case .stateUpdateTime: return "State Update Time"
        case .capabilityActivationTime: return "Capability Activation Time"
        case .batteryLevel: return "Battery Level"
        case .batteryUsage: return "Battery Usage"
        }
    }
}

public struct CapabilityStatus: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let capabilityName: String
    public let status: CapabilityState
    public let isAvailable: Bool
    public let lastActivated: Date?
    public let lastDeactivated: Date?
    public let activationCount: Int
    public let errorCount: Int
    public let averageActivationTime: TimeInterval?
    public let permissions: [PermissionStatus]
    
    public init(
        id: UUID = UUID(),
        capabilityName: String,
        status: CapabilityState = .inactive,
        isAvailable: Bool = true,
        lastActivated: Date? = nil,
        lastDeactivated: Date? = nil,
        activationCount: Int = 0,
        errorCount: Int = 0,
        averageActivationTime: TimeInterval? = nil,
        permissions: [PermissionStatus] = []
    ) {
        self.id = id
        self.capabilityName = capabilityName
        self.status = status
        self.isAvailable = isAvailable
        self.lastActivated = lastActivated
        self.lastDeactivated = lastDeactivated
        self.activationCount = activationCount
        self.errorCount = errorCount
        self.averageActivationTime = averageActivationTime
        self.permissions = permissions
    }
}

public enum CapabilityState: String, CaseIterable, Codable, Hashable, Sendable {
    case inactive = "inactive"
    case activating = "activating"
    case active = "active"
    case deactivating = "deactivating"
    case error = "error"
    case unavailable = "unavailable"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct PermissionStatus: Codable, Equatable, Hashable, Sendable {
    public let permissionType: PermissionType
    public let status: PermissionState
    public let lastRequested: Date?
    public let lastGranted: Date?
    public let lastDenied: Date?
    
    public init(
        permissionType: PermissionType,
        status: PermissionState,
        lastRequested: Date? = nil,
        lastGranted: Date? = nil,
        lastDenied: Date? = nil
    ) {
        self.permissionType = permissionType
        self.status = status
        self.lastRequested = lastRequested
        self.lastGranted = lastGranted
        self.lastDenied = lastDenied
    }
}

public enum PermissionType: String, CaseIterable, Codable, Hashable, Sendable {
    case calendar = "calendar"
    case contacts = "contacts"
    case location = "location"
    case health = "health"
    case photos = "photos"
    case microphone = "microphone"
    case camera = "camera"
    case notifications = "notifications"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public enum PermissionState: String, CaseIterable, Codable, Hashable, Sendable {
    case notDetermined = "notDetermined"
    case denied = "denied"
    case restricted = "restricted"
    case authorized = "authorized"
    case provisional = "provisional"
    
    public var displayName: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        }
    }
}

public struct BatteryImpact: Codable, Equatable, Hashable, Sendable {
    public let level: BatteryImpactLevel
    public let energyUsage: Double
    public let timestamp: Date
    public let duration: TimeInterval
    public let activities: [BatteryActivity]
    
    public init(
        level: BatteryImpactLevel,
        energyUsage: Double,
        timestamp: Date = Date(),
        duration: TimeInterval,
        activities: [BatteryActivity] = []
    ) {
        self.level = level
        self.energyUsage = energyUsage
        self.timestamp = timestamp
        self.duration = duration
        self.activities = activities
    }
}

public enum BatteryImpactLevel: String, CaseIterable, Codable, Hashable, Sendable {
    case minimal = "minimal"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct BatteryActivity: Codable, Equatable, Hashable, Sendable {
    public let activityType: BatteryActivityType
    public let energyUsage: Double
    public let duration: TimeInterval
    
    public init(activityType: BatteryActivityType, energyUsage: Double, duration: TimeInterval) {
        self.activityType = activityType
        self.energyUsage = energyUsage
        self.duration = duration
    }
}

public enum BatteryActivityType: String, CaseIterable, Codable, Hashable, Sendable {
    case location = "location"
    case processing = "processing"
    case display = "display"
    case network = "network"
    case storage = "storage"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

public struct ThermalState: Codable, Equatable, Hashable, Sendable {
    public let level: ThermalLevel
    public let timestamp: Date
    public let throttled: Bool
    
    public init(level: ThermalLevel, timestamp: Date = Date(), throttled: Bool = false) {
        self.level = level
        self.timestamp = timestamp
        self.throttled = throttled
    }
}

public enum ThermalLevel: String, CaseIterable, Codable, Hashable, Sendable {
    case nominal = "nominal"
    case fair = "fair"
    case serious = "serious"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}