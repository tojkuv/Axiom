import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
#if canImport(WatchKit)
import WatchKit
#endif

public enum PlatformProfile: Sendable {
    case iOS(memoryLimit: Int)
    case macOS(memoryLimit: Int)
    case watchOS(memoryLimit: Int)
    case tvOS(memoryLimit: Int)
    case unknown(memoryLimit: Int)
}

public enum ResourceType: Hashable, Sendable {
    case memory
    case networkConnections
    case fileHandles
    case threads
    case timers
    case backgroundTasks
}

public struct ResourceQuota: Sendable {
    public let limit: Int
    public let warning: Int
    public let critical: Int
    
    public init(limit: Int, warning: Int, critical: Int? = nil) {
        self.limit = limit
        self.warning = warning
        self.critical = critical ?? Int(Double(limit) * 0.9)
    }
}

public actor CrossPlatformResourceManager {
    public static let shared = CrossPlatformResourceManager()
    
    private let platformProfile: PlatformProfile
    private var resourceQuotas: [ResourceType: ResourceQuota] = [:]
    private var activeResources: [ResourceType: Int] = [:]
    private var resourceObservers: [ResourceObserver] = []
    
    private init() {
        #if os(iOS)
        let totalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        self.platformProfile = .iOS(memoryLimit: min(totalMemory / 2, 1_000_000_000))
        #elseif os(macOS)
        let totalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        self.platformProfile = .macOS(memoryLimit: min(totalMemory / 4, 4_000_000_000))
        #elseif os(watchOS)
        self.platformProfile = .watchOS(memoryLimit: 200_000_000)
        #elseif os(tvOS)
        let totalMemory = Int(ProcessInfo.processInfo.physicalMemory)
        self.platformProfile = .tvOS(memoryLimit: min(totalMemory / 3, 2_000_000_000))
        #else
        self.platformProfile = .unknown(memoryLimit: 100_000_000)
        #endif
        
        Task {
            await setupPlatformQuotas()
        }
    }
    
    private func setupPlatformQuotas() async {
        switch platformProfile {
        case .watchOS(let memoryLimit):
            resourceQuotas[.memory] = ResourceQuota(limit: memoryLimit, warning: Int(Double(memoryLimit) * 0.75))
            resourceQuotas[.networkConnections] = ResourceQuota(limit: 2, warning: 1)
            resourceQuotas[.fileHandles] = ResourceQuota(limit: 20, warning: 15)
            resourceQuotas[.threads] = ResourceQuota(limit: 4, warning: 3)
            resourceQuotas[.timers] = ResourceQuota(limit: 5, warning: 4)
            resourceQuotas[.backgroundTasks] = ResourceQuota(limit: 1, warning: 1)
            
        case .iOS(let memoryLimit):
            resourceQuotas[.memory] = ResourceQuota(limit: memoryLimit, warning: Int(Double(memoryLimit) * 0.8))
            resourceQuotas[.networkConnections] = ResourceQuota(limit: 10, warning: 8)
            resourceQuotas[.fileHandles] = ResourceQuota(limit: 100, warning: 80)
            resourceQuotas[.threads] = ResourceQuota(limit: 32, warning: 25)
            resourceQuotas[.timers] = ResourceQuota(limit: 20, warning: 15)
            resourceQuotas[.backgroundTasks] = ResourceQuota(limit: 3, warning: 2)
            
        case .macOS(let memoryLimit):
            resourceQuotas[.memory] = ResourceQuota(limit: memoryLimit, warning: Int(Double(memoryLimit) * 0.85))
            resourceQuotas[.networkConnections] = ResourceQuota(limit: 50, warning: 40)
            resourceQuotas[.fileHandles] = ResourceQuota(limit: 1000, warning: 800)
            resourceQuotas[.threads] = ResourceQuota(limit: 64, warning: 50)
            resourceQuotas[.timers] = ResourceQuota(limit: 100, warning: 80)
            resourceQuotas[.backgroundTasks] = ResourceQuota(limit: 10, warning: 8)
            
        case .tvOS(let memoryLimit):
            resourceQuotas[.memory] = ResourceQuota(limit: memoryLimit, warning: Int(Double(memoryLimit) * 0.8))
            resourceQuotas[.networkConnections] = ResourceQuota(limit: 20, warning: 15)
            resourceQuotas[.fileHandles] = ResourceQuota(limit: 200, warning: 150)
            resourceQuotas[.threads] = ResourceQuota(limit: 16, warning: 12)
            resourceQuotas[.timers] = ResourceQuota(limit: 30, warning: 25)
            resourceQuotas[.backgroundTasks] = ResourceQuota(limit: 5, warning: 4)
            
        case .unknown(let memoryLimit):
            resourceQuotas[.memory] = ResourceQuota(limit: memoryLimit, warning: Int(Double(memoryLimit) * 0.7))
            resourceQuotas[.networkConnections] = ResourceQuota(limit: 5, warning: 4)
            resourceQuotas[.fileHandles] = ResourceQuota(limit: 50, warning: 40)
            resourceQuotas[.threads] = ResourceQuota(limit: 8, warning: 6)
            resourceQuotas[.timers] = ResourceQuota(limit: 10, warning: 8)
            resourceQuotas[.backgroundTasks] = ResourceQuota(limit: 2, warning: 1)
        }
        
        initializeActiveResources()
    }
    
    private func initializeActiveResources() {
        for resourceType in ResourceType.allCases {
            activeResources[resourceType] = 0
        }
    }
    
    public func requestResource(_ type: ResourceType, count: Int = 1) async throws -> ResourceAllocation {
        let currentUsage = activeResources[type] ?? 0
        let newUsage = currentUsage + count
        
        guard let quota = resourceQuotas[type] else {
            throw ResourceError.quotaNotConfigured(type)
        }
        
        if newUsage > quota.limit {
            throw ResourceError.quotaExceeded(type, requested: newUsage, limit: quota.limit)
        }
        
        activeResources[type] = newUsage
        
        if newUsage >= quota.critical {
            await notifyResourceObservers(.critical(type, usage: newUsage, limit: quota.limit))
        } else if newUsage >= quota.warning {
            await notifyResourceObservers(.warning(type, usage: newUsage, limit: quota.limit))
        }
        
        return ResourceAllocation(type: type, count: count, manager: self)
    }
    
    public func releaseResource(_ type: ResourceType, count: Int = 1) async {
        let currentUsage = activeResources[type] ?? 0
        let newUsage = max(0, currentUsage - count)
        activeResources[type] = newUsage
        
        await notifyResourceObservers(.released(type, count: count, remainingUsage: newUsage))
    }
    
    public func getCurrentUsage(_ type: ResourceType) -> Int {
        activeResources[type] ?? 0
    }
    
    public func getQuota(_ type: ResourceType) -> ResourceQuota? {
        resourceQuotas[type]
    }
    
    public func getResourceUsageReport() async -> ResourceUsageReport {
        var usageDetails: [ResourceType: ResourceUsageDetail] = [:]
        
        for type in ResourceType.allCases {
            let usage = activeResources[type] ?? 0
            let quota = resourceQuotas[type]
            
            usageDetails[type] = ResourceUsageDetail(
                current: usage,
                quota: quota,
                utilizationPercentage: quota.map { Double(usage) / Double($0.limit) } ?? 0.0
            )
        }
        
        return ResourceUsageReport(
            platform: platformProfile,
            resourceDetails: usageDetails,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
    }
    
    public func addResourceObserver(_ observer: ResourceObserver) {
        resourceObservers.append(observer)
    }
    
    public func removeResourceObserver(_ observer: ResourceObserver) {
        resourceObservers.removeAll { $0.id == observer.id }
    }
    
    private func notifyResourceObservers(_ event: ResourceEvent) async {
        let activeObservers = resourceObservers.compactMap { $0.callback }
        
        for observer in activeObservers {
            await observer(event)
        }
        
        resourceObservers.removeAll { $0.callback == nil }
        
        await FrameworkEventBus.shared.post(.resourceCleanup(resourceType: "\(event)"))
    }
    
    public func optimizeForPlatform() async {
        let memoryUsage = await SystemMetrics.getDetailedMemoryUsage()
        
        switch platformProfile {
        case .watchOS:
            if memoryUsage.usagePercentage > 0.8 {
                _ = await EmergencyMemoryManager.shared.forceMemoryReclaim(severity: .aggressive)
            }
            
        case .iOS:
            if memoryUsage.usagePercentage > 0.75 {
                _ = await EmergencyMemoryManager.shared.forceMemoryReclaim(severity: .mild)
            }
            
        case .macOS:
            // More relaxed memory management for macOS
            if memoryUsage.usagePercentage > 0.9 {
                _ = await EmergencyMemoryManager.shared.forceMemoryReclaim(severity: .mild)
            }
            
        case .tvOS:
            if memoryUsage.usagePercentage > 0.8 {
                _ = await EmergencyMemoryManager.shared.forceMemoryReclaim(severity: .aggressive)
            }
            
        case .unknown:
            if memoryUsage.usagePercentage > 0.7 {
                _ = await EmergencyMemoryManager.shared.forceMemoryReclaim(severity: .aggressive)
            }
        }
    }
}

public enum ResourceError: Error, Sendable {
    case quotaExceeded(ResourceType, requested: Int, limit: Int)
    case quotaNotConfigured(ResourceType)
    case allocationFailed(ResourceType, reason: String)
}

public enum ResourceEvent: Sendable {
    case warning(ResourceType, usage: Int, limit: Int)
    case critical(ResourceType, usage: Int, limit: Int)
    case released(ResourceType, count: Int, remainingUsage: Int)
}

public struct ResourceAllocation: Sendable {
    public let type: ResourceType
    public let count: Int
    private let manager: CrossPlatformResourceManager
    
    init(type: ResourceType, count: Int, manager: CrossPlatformResourceManager) {
        self.type = type
        self.count = count
        self.manager = manager
    }
    
    public func release() async {
        await manager.releaseResource(type, count: count)
    }
}

public struct ResourceUsageDetail: Sendable {
    public let current: Int
    public let quota: ResourceQuota?
    public let utilizationPercentage: Double
    
    public var isNearLimit: Bool {
        guard let quota = quota else { return false }
        return current >= quota.warning
    }
    
    public var isCritical: Bool {
        guard let quota = quota else { return false }
        return current >= quota.critical
    }
}

public struct ResourceUsageReport: Sendable {
    public let platform: PlatformProfile
    public let resourceDetails: [ResourceType: ResourceUsageDetail]
    public let timestamp: CFAbsoluteTime
    
    public var criticalResources: [ResourceType] {
        resourceDetails.compactMap { key, value in
            value.isCritical ? key : nil
        }
    }
    
    public var resourcesNearLimit: [ResourceType] {
        resourceDetails.compactMap { key, value in
            value.isNearLimit ? key : nil
        }
    }
}

public struct ResourceObserver {
    public let id = UUID()
    public weak var callbackHolder: AnyObject?
    public let callback: (@Sendable (ResourceEvent) async -> Void)?
    
    public init(callback: @escaping @Sendable (ResourceEvent) async -> Void) {
        let holder = CallbackHolder(callback: callback)
        self.callbackHolder = holder
        self.callback = callback
    }
}

private final class CallbackHolder {
    let callback: @Sendable (ResourceEvent) async -> Void
    
    init(callback: @escaping @Sendable (ResourceEvent) async -> Void) {
        self.callback = callback
    }
}

extension ResourceType: CaseIterable {
    public static var allCases: [ResourceType] {
        [.memory, .networkConnections, .fileHandles, .threads, .timers, .backgroundTasks]
    }
}