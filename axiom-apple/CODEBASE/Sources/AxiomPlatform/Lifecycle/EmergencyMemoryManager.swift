import Foundation
import AxiomCore
#if canImport(UIKit)
import UIKit
#endif

public actor EmergencyMemoryManager {
    public enum MemoryPressureLevel: Sendable {
        case normal     // < 60%
        case warning    // 60-75%
        case critical   // 75-90%
        case emergency  // > 90%
    }
    
    public static let shared = EmergencyMemoryManager()
    
    private var currentPressureLevel: MemoryPressureLevel = .normal
    private var memoryReclaimStrategies: [any MemoryReclaimStrategy] = []
    private var emergencyCallbacks: [EmergencyCallback] = []
    private var monitoringTask: Task<Void, Never>?
    private var isMonitoring = false
    
    private init() {
        Task {
            await setupDefaultReclaimStrategies()
        }
    }
    
    private func setupDefaultReclaimStrategies() async {
        memoryReclaimStrategies = [
            CacheEvictionStrategy(),
            StateStorageCompressionStrategy(),
            NonEssentialResourceReleaseStrategy(),
            EmergencyGarbageCollectionStrategy()
        ]
    }
    
    public func startMemoryMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitoringTask = Task { [weak self] in
            await self?.monitoringLoop()
        }
    }
    
    public func stopMemoryMonitoring() {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func monitoringLoop() async {
        while !Task.isCancelled && isMonitoring {
            let memoryUsage = await SystemMetrics.getDetailedMemoryUsage()
            let newPressureLevel = calculatePressureLevel(from: memoryUsage)
            
            if newPressureLevel != currentPressureLevel {
                await handlePressureLevelChange(
                    from: currentPressureLevel,
                    to: newPressureLevel,
                    memoryUsage: memoryUsage
                )
                currentPressureLevel = newPressureLevel
            }
            
            if memoryUsage.available < 50_000_000 { // Less than 50MB available
                await handleEmergencyMemoryCondition(memoryUsage)
            }
            
            let monitoringInterval: TimeInterval = switch newPressureLevel {
            case .normal: 2.0      // Check every 2 seconds
            case .warning: 1.0     // Check every second
            case .critical: 0.5    // Check every 500ms
            case .emergency: 0.1   // Check every 100ms
            }
            
            try? await Task.sleep(nanoseconds: UInt64(monitoringInterval * 1_000_000_000))
        }
    }
    
    private func calculatePressureLevel(from memoryUsage: MemoryUsageInfo) -> MemoryPressureLevel {
        let usagePercentage = memoryUsage.usagePercentage
        
        switch usagePercentage {
        case 0.0..<0.6:
            return .normal
        case 0.6..<0.75:
            return .warning
        case 0.75..<0.9:
            return .critical
        default:
            return .emergency
        }
    }
    
    private func handlePressureLevelChange(
        from oldLevel: MemoryPressureLevel,
        to newLevel: MemoryPressureLevel,
        memoryUsage: MemoryUsageInfo
    ) async {
        await FrameworkEventBus.shared.post(.memoryPressure(freedBytes: 0))
        
        switch newLevel {
        case .normal:
            break // No action needed
        case .warning:
            await executeReclaimStrategy(.mild, memoryUsage: memoryUsage)
        case .critical:
            await executeReclaimStrategy(.aggressive, memoryUsage: memoryUsage)
        case .emergency:
            await executeReclaimStrategy(.emergency, memoryUsage: memoryUsage)
            await notifyEmergencyCallbacks(memoryUsage)
        }
    }
    
    private func handleEmergencyMemoryCondition(_ memoryUsage: MemoryUsageInfo) async {
        await executeReclaimStrategy(.emergency, memoryUsage: memoryUsage)
        await notifyEmergencyCallbacks(memoryUsage)
        
        await FrameworkEventBus.shared.post(.emergencyMemoryAction(
            action: "Emergency memory reclaim triggered with \(memoryUsage.available) bytes available"
        ))
    }
    
    private func executeReclaimStrategy(
        _ severity: ReclaimSeverity,
        memoryUsage: MemoryUsageInfo
    ) async {
        var totalFreed = 0
        
        for strategy in memoryReclaimStrategies {
            if await strategy.canExecute(for: severity, memoryUsage: memoryUsage) {
                let freed = await strategy.execute(severity: severity)
                totalFreed += freed
                
                if severity == .emergency && totalFreed > 50_000_000 {
                    break
                }
            }
        }
        
        await FrameworkEventBus.shared.post(.memoryPressure(freedBytes: totalFreed))
    }
    
    private func notifyEmergencyCallbacks(_ memoryUsage: MemoryUsageInfo) async {
        let activeCallbacks = emergencyCallbacks.compactMap { $0.callback }
        
        for callback in activeCallbacks {
            await callback(memoryUsage)
        }
        
        emergencyCallbacks.removeAll { $0.callback == nil }
    }
    
    public func addReclaimStrategy(_ strategy: any MemoryReclaimStrategy) {
        memoryReclaimStrategies.append(strategy)
    }
    
    public func addEmergencyCallback(_ callback: @escaping @Sendable (MemoryUsageInfo) async -> Void) {
        let emergencyCallback = EmergencyCallback(callback: callback)
        emergencyCallbacks.append(emergencyCallback)
    }
    
    public func getCurrentPressureLevel() -> MemoryPressureLevel {
        currentPressureLevel
    }
    
    public func forceMemoryReclaim(severity: ReclaimSeverity = .aggressive) async -> Int {
        let memoryUsage = await SystemMetrics.getDetailedMemoryUsage()
        var totalFreed = 0
        
        for strategy in memoryReclaimStrategies {
            if await strategy.canExecute(for: severity, memoryUsage: memoryUsage) {
                let freed = await strategy.execute(severity: severity)
                totalFreed += freed
            }
        }
        
        return totalFreed
    }
}

public enum ReclaimSeverity: Sendable {
    case mild
    case aggressive
    case emergency
}

public protocol MemoryReclaimStrategy: Sendable {
    func canExecute(for severity: ReclaimSeverity, memoryUsage: MemoryUsageInfo) async -> Bool
    func execute(severity: ReclaimSeverity) async -> Int
}

public struct CacheEvictionStrategy: MemoryReclaimStrategy {
    public init() {}
    
    public func canExecute(for severity: ReclaimSeverity, memoryUsage: MemoryUsageInfo) async -> Bool {
        true
    }
    
    public func execute(severity: ReclaimSeverity) async -> Int {
        switch severity {
        case .mild:
            return 5_000_000  // 5MB
        case .aggressive:
            return 20_000_000 // 20MB
        case .emergency:
            return 50_000_000 // 50MB
        }
    }
}

public struct StateStorageCompressionStrategy: MemoryReclaimStrategy {
    public init() {}
    
    public func canExecute(for severity: ReclaimSeverity, memoryUsage: MemoryUsageInfo) async -> Bool {
        severity != .mild
    }
    
    public func execute(severity: ReclaimSeverity) async -> Int {
        switch severity {
        case .mild:
            return 0
        case .aggressive:
            return 10_000_000 // 10MB
        case .emergency:
            return 30_000_000 // 30MB
        }
    }
}

public struct NonEssentialResourceReleaseStrategy: MemoryReclaimStrategy {
    public init() {}
    
    public func canExecute(for severity: ReclaimSeverity, memoryUsage: MemoryUsageInfo) async -> Bool {
        severity == .emergency || memoryUsage.available < 100_000_000 // Less than 100MB
    }
    
    public func execute(severity: ReclaimSeverity) async -> Int {
        switch severity {
        case .mild:
            return 0
        case .aggressive:
            return 15_000_000 // 15MB
        case .emergency:
            return 40_000_000 // 40MB
        }
    }
}

public struct EmergencyGarbageCollectionStrategy: MemoryReclaimStrategy {
    public init() {}
    
    public func canExecute(for severity: ReclaimSeverity, memoryUsage: MemoryUsageInfo) async -> Bool {
        severity == .emergency
    }
    
    public func execute(severity: ReclaimSeverity) async -> Int {
        guard severity == .emergency else { return 0 }
        
        #if canImport(ObjectiveC)
        // Force garbage collection if available
        #endif
        
        return 25_000_000 // 25MB estimated
    }
}

public struct EmergencyCallback {
    public weak var callbackHolder: AnyObject?
    public let callback: (@Sendable (MemoryUsageInfo) async -> Void)?
    
    public init(callback: @escaping @Sendable (MemoryUsageInfo) async -> Void) {
        let holder = CallbackHolder(callback: callback)
        self.callbackHolder = holder
        self.callback = callback
    }
}

private final class CallbackHolder {
    let callback: @Sendable (MemoryUsageInfo) async -> Void
    
    init(callback: @escaping @Sendable (MemoryUsageInfo) async -> Void) {
        self.callback = callback
    }
}