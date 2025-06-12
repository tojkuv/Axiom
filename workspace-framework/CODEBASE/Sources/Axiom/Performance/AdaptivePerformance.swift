import Foundation

// MARK: - Adaptive Performance Types

public struct DeviceProfile: Sendable {
    public let deviceModel: String
    public let processorSpeed: Double
    public let memorySize: Int64
    public let thermalState: ProcessInfo.ThermalState
    public let batteryLevel: Float
    public let isLowPowerMode: Bool
    public let timestamp: Date
    
    public var performanceClass: PerformanceClass {
        // Classify device performance capability
        if processorSpeed > 2.5 && memorySize > 4_000_000_000 {
            return .high
        } else if processorSpeed > 1.5 && memorySize > 2_000_000_000 {
            return .medium
        } else {
            return .low
        }
    }
    
    public var isThrottled: Bool {
        return thermalState == .critical || thermalState == .serious || isLowPowerMode || batteryLevel < 0.2
    }
    
    public init(deviceModel: String, processorSpeed: Double, memorySize: Int64, thermalState: ProcessInfo.ThermalState, batteryLevel: Float, isLowPowerMode: Bool) {
        self.deviceModel = deviceModel
        self.processorSpeed = processorSpeed
        self.memorySize = memorySize
        self.thermalState = thermalState
        self.batteryLevel = batteryLevel
        self.isLowPowerMode = isLowPowerMode
        self.timestamp = Date()
    }
}

public enum PerformanceFeature: String, CaseIterable, Sendable {
    case advancedAnimations = "advancedAnimations"
    case realtimeSync = "realtimeSync"
    case aggressiveCaching = "aggressiveCaching"
    case backgroundProcessing = "backgroundProcessing"
    case preloading = "preloading"
    case complexRendering = "complexRendering"
    
    public var description: String {
        switch self {
        case .advancedAnimations:
            return "Advanced UI animations and transitions"
        case .realtimeSync:
            return "Real-time data synchronization"
        case .aggressiveCaching:
            return "Aggressive memory and disk caching"
        case .backgroundProcessing:
            return "Background task processing"
        case .preloading:
            return "Content preloading and prefetching"
        case .complexRendering:
            return "Complex rendering operations"
        }
    }
}

public enum CacheSize: Sendable {
    case small, medium, large, unlimited
    
    public var byteLimit: Int {
        switch self {
        case .small: return 10_000_000 // 10MB
        case .medium: return 50_000_000 // 50MB
        case .large: return 100_000_000 // 100MB
        case .unlimited: return Int.max
        }
    }
    
    public var itemLimit: Int {
        switch self {
        case .small: return 100
        case .medium: return 500
        case .large: return 1000
        case .unlimited: return Int.max
        }
    }
}

public struct OptimizationSettings: Sendable {
    public let enabledFeatures: Set<PerformanceFeature>
    public let cacheSize: CacheSize
    public let slaMultiplier: Double
    public let maxConcurrentOperations: Int
    public let refreshInterval: TimeInterval
    
    public init(enabledFeatures: Set<PerformanceFeature>, cacheSize: CacheSize, slaMultiplier: Double, maxConcurrentOperations: Int, refreshInterval: TimeInterval) {
        self.enabledFeatures = enabledFeatures
        self.cacheSize = cacheSize
        self.slaMultiplier = slaMultiplier
        self.maxConcurrentOperations = maxConcurrentOperations
        self.refreshInterval = refreshInterval
    }
    
    public static let highPerformance = OptimizationSettings(
        enabledFeatures: Set(PerformanceFeature.allCases),
        cacheSize: .large,
        slaMultiplier: 1.0,
        maxConcurrentOperations: 10,
        refreshInterval: 0.1
    )
    
    public static let balanced = OptimizationSettings(
        enabledFeatures: [.realtimeSync, .aggressiveCaching, .preloading],
        cacheSize: .medium,
        slaMultiplier: 1.5,
        maxConcurrentOperations: 5,
        refreshInterval: 0.5
    )
    
    public static let conservative = OptimizationSettings(
        enabledFeatures: [.aggressiveCaching],
        cacheSize: .small,
        slaMultiplier: 2.0,
        maxConcurrentOperations: 2,
        refreshInterval: 1.0
    )
}

// MARK: - Adaptive Performance Optimizer

/// Automatically adapts performance settings based on device capabilities and current state
public actor AdaptivePerformanceOptimizer {
    public static let shared = AdaptivePerformanceOptimizer()
    
    private var deviceProfile: DeviceProfile?
    private var currentSettings: OptimizationSettings = .balanced
    private var enabledFeatures: Set<PerformanceFeature> = []
    private var cacheSize: CacheSize = .medium
    private var monitoringTask: Task<Void, Never>?
    private let logger = CategoryLogger.logger(for: .performance)
    
    private init() {}
    
    /// Start adaptive optimization
    public func startOptimization() async {
        logger.info("Starting adaptive performance optimization")
        
        // Initial device profiling
        deviceProfile = await profileDevice()
        await adjustPerformanceSettings()
        
        // Start continuous monitoring
        monitoringTask = Task {
            await continuousOptimization()
        }
    }
    
    /// Stop adaptive optimization
    public func stopOptimization() {
        monitoringTask?.cancel()
        monitoringTask = nil
        logger.info("Stopped adaptive performance optimization")
    }
    
    /// Get current device profile
    public func getCurrentProfile() -> DeviceProfile? {
        return deviceProfile
    }
    
    /// Get current optimization settings
    public func getCurrentSettings() -> OptimizationSettings {
        return currentSettings
    }
    
    /// Manually set optimization level
    public func setOptimizationLevel(_ level: OptimizationLevel) async {
        switch level {
        case .maximum:
            currentSettings = .highPerformance
        case .balanced:
            currentSettings = .balanced
        case .battery:
            currentSettings = .conservative
        }
        
        await applySettings(currentSettings)
        logger.info("Manual optimization level set to: \(level)")
    }
    
    /// Check if a feature is currently enabled
    public func isFeatureEnabled(_ feature: PerformanceFeature) -> Bool {
        return enabledFeatures.contains(feature)
    }
    
    /// Force refresh device profile and adjust settings
    public func refreshAndOptimize() async {
        deviceProfile = await profileDevice()
        await adjustPerformanceSettings()
    }
    
    // MARK: - Private Implementation
    
    private func profileDevice() async -> DeviceProfile {
        let deviceInfo = DeviceInfo.current
        let processInfo = ProcessInfo.processInfo
        
        return DeviceProfile(
            deviceModel: deviceInfo.model,
            processorSpeed: deviceInfo.processorSpeed,
            memorySize: deviceInfo.memorySize,
            thermalState: processInfo.thermalState,
            batteryLevel: await getBatteryLevel(),
            isLowPowerMode: processInfo.isLowPowerModeEnabled
        )
    }
    
    private func getBatteryLevel() async -> Float {
        #if canImport(UIKit)
        return await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = true
            return UIDevice.current.batteryLevel
        }
        #else
        return 1.0 // Default for non-iOS platforms
        #endif
    }
    
    private func adjustPerformanceSettings() async {
        guard let profile = deviceProfile else { return }
        
        let newSettings: OptimizationSettings
        
        if profile.isThrottled {
            // Device is throttled - use conservative settings
            newSettings = .conservative
            logger.info("Device is throttled (thermal: \(profile.thermalState), battery: \(profile.batteryLevel), lowPower: \(profile.isLowPowerMode)) - using conservative settings")
        } else {
            // Adapt based on performance class
            switch profile.performanceClass {
            case .high:
                newSettings = .highPerformance
            case .medium:
                newSettings = .balanced
            case .low:
                newSettings = .conservative
            }
        }
        
        currentSettings = newSettings
        await applySettings(newSettings)
        
        logger.info("Performance settings adapted for \(profile.performanceClass) device")
    }
    
    private func applySettings(_ settings: OptimizationSettings) async {
        // Update enabled features
        enabledFeatures = settings.enabledFeatures
        
        // Update cache size
        cacheSize = settings.cacheSize
        
        // Apply SLA adjustments
        await PerformanceMonitor.shared.adjustSLA(multiplier: settings.slaMultiplier)
        
        // Configure budget manager for performance class
        do {
            try await PerformanceBudgetManager.shared.configureBudgetsForPerformanceClass(
                deviceProfile?.performanceClass ?? .medium
            )
        } catch {
            logger.error("Failed to configure budgets: \(error)")
        }
        
        // Log feature changes
        let enabledFeatureNames = settings.enabledFeatures.map(\.rawValue).joined(separator: ", ")
        logger.info("Applied settings - Features: [\(enabledFeatureNames)], Cache: \(settings.cacheSize), SLA: \(settings.slaMultiplier)x")
    }
    
    private func continuousOptimization() async {
        while !Task.isCancelled {
            do {
                // Re-profile device
                let newProfile = await profileDevice()
                let oldProfile = deviceProfile
                deviceProfile = newProfile
                
                // Check if significant changes occurred
                if let old = oldProfile, shouldAdjustSettings(from: old, to: newProfile) {
                    await adjustPerformanceSettings()
                }
                
                // Monitor for thermal throttling
                if newProfile.thermalState == .critical {
                    await handleCriticalThermalState()
                }
                
                // Check memory pressure
                await checkMemoryPressure()
                
                // Sleep before next check
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
            } catch {
                if !Task.isCancelled {
                    logger.error("Error in continuous optimization: \(error)")
                    try? await Task.sleep(nanoseconds: 60_000_000_000) // 1 minute retry
                }
            }
        }
    }
    
    private func shouldAdjustSettings(from oldProfile: DeviceProfile, to newProfile: DeviceProfile) -> Bool {
        // Check for significant state changes
        return oldProfile.thermalState != newProfile.thermalState ||
               oldProfile.isLowPowerMode != newProfile.isLowPowerMode ||
               abs(oldProfile.batteryLevel - newProfile.batteryLevel) > 0.2 ||
               oldProfile.performanceClass != newProfile.performanceClass
    }
    
    private func handleCriticalThermalState() async {
        logger.warning("Critical thermal state detected - applying emergency throttling")
        
        // Disable expensive features immediately
        enabledFeatures.removeAll()
        
        // Reduce cache size
        cacheSize = .small
        
        // Apply emergency SLA multiplier
        await PerformanceMonitor.shared.adjustSLA(multiplier: 3.0)
        
        // Clear performance budgets to prevent further load
        await PerformanceBudgetManager.shared.resetAllBudgets()
    }
    
    private func checkMemoryPressure() async {
        let memoryUsage = getCurrentMemoryUsage()
        let memoryPressure = memoryUsage / Double(deviceProfile?.memorySize ?? 1)
        
        if memoryPressure > 0.8 {
            logger.warning("High memory pressure detected: \(String(format: "%.1f", memoryPressure * 100))%")
            
            // Reduce cache size if not already at minimum
            if cacheSize != .small {
                cacheSize = .small
                logger.info("Reduced cache size due to memory pressure")
            }
            
            // Disable memory-intensive features
            enabledFeatures.remove(.aggressiveCaching)
            enabledFeatures.remove(.preloading)
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size)
        } else {
            return 0.0
        }
    }
}

// MARK: - SLA Adjustment Extension

extension PerformanceMonitor {
    /// Adjust SLA threshold based on device performance
    public func adjustSLA(multiplier: Double) async {
        // This would adjust the internal SLA threshold
        // For now, we'll just log the adjustment
        let logger = CategoryLogger.logger(for: .performance)
        logger.info("SLA threshold adjusted by \(multiplier)x for device performance")
    }
}

// MARK: - Optimization Level

public enum OptimizationLevel: String, CaseIterable, Sendable {
    case maximum = "maximum"
    case balanced = "balanced"
    case battery = "battery"
    
    public var description: String {
        switch self {
        case .maximum:
            return "Maximum Performance"
        case .balanced:
            return "Balanced"
        case .battery:
            return "Battery Optimized"
        }
    }
}

// MARK: - Adaptive Cache

/// Cache that adapts its behavior based on device performance
public actor AdaptiveCache<Key: Hashable, Value> {
    private var storage: [Key: CacheEntry<Value>] = [:]
    private let optimizer = AdaptivePerformanceOptimizer.shared
    private let logger = CategoryLogger.logger(for: .performance)
    
    private struct CacheEntry<T> {
        let value: T
        let cost: Int
        let lastAccessed: Date
        let accessCount: Int
        
        init(value: T, cost: Int) {
            self.value = value
            self.cost = cost
            self.lastAccessed = Date()
            self.accessCount = 1
        }
        
        func accessed() -> CacheEntry<T> {
            return CacheEntry(value: value, cost: cost, lastAccessed: Date(), accessCount: accessCount + 1)
        }
    }
    
    public init() {}
    
    /// Set value with adaptive cache management
    public func setValue(_ value: Value, forKey key: Key, cost: Int = 1) async {
        let settings = await optimizer.getCurrentSettings()
        let maxSize = settings.cacheSize.itemLimit
        
        // Remove existing entry if present
        if storage[key] != nil {
            storage.removeValue(forKey: key)
        }
        
        // Check if we need to evict items
        if storage.count >= maxSize {
            await evictItems(toMakeRoom: 1, maxSize: maxSize)
        }
        
        storage[key] = CacheEntry(value: value, cost: cost)
    }
    
    /// Get value with access tracking
    public func getValue(forKey key: Key) -> Value? {
        guard let entry = storage[key] else { return nil }
        
        // Update access information
        storage[key] = entry.accessed()
        
        return entry.value
    }
    
    /// Remove value
    public func removeValue(forKey key: Key) {
        storage.removeValue(forKey: key)
    }
    
    /// Clear all cached values
    public func removeAll() {
        storage.removeAll()
        logger.debug("Adaptive cache cleared")
    }
    
    /// Get cache statistics
    public func getStatistics() -> (count: Int, totalCost: Int, hitRate: Double) {
        let count = storage.count
        let totalCost = storage.values.reduce(0) { $0 + $1.cost }
        let totalAccesses = storage.values.reduce(0) { $0 + $1.accessCount }
        let hitRate = totalAccesses > count ? Double(totalAccesses - count) / Double(totalAccesses) : 0.0
        
        return (count, totalCost, hitRate)
    }
    
    // MARK: - Private Helpers
    
    private func evictItems(toMakeRoom roomNeeded: Int, maxSize: Int) async {
        let itemsToRemove = max(roomNeeded, maxSize / 10) // Remove at least 10% when evicting
        
        // Sort by access pattern - least recently used and least accessed first
        let sortedEntries = storage.sorted { lhs, rhs in
            if lhs.value.accessCount != rhs.value.accessCount {
                return lhs.value.accessCount < rhs.value.accessCount
            }
            return lhs.value.lastAccessed < rhs.value.lastAccessed
        }
        
        let keysToRemove = Array(sortedEntries.prefix(itemsToRemove).map(\.key))
        
        for key in keysToRemove {
            storage.removeValue(forKey: key)
        }
        
        logger.debug("Evicted \(keysToRemove.count) items from adaptive cache")
    }
}

// MARK: - Performance Class Extension

extension PerformanceClass {
    var slaMultiplier: Double {
        switch self {
        case .high: return 1.0
        case .medium: return 1.5
        case .low: return 2.0
        }
    }
    
    var cacheSize: CacheSize {
        switch self {
        case .high: return .large
        case .medium: return .medium
        case .low: return .small
        }
    }
    
    var budgetMultiplier: Double {
        switch self {
        case .high: return 1.0
        case .medium: return 1.5
        case .low: return 2.0
        }
    }
}

// MARK: - UIKit Integration

#if canImport(UIKit)
import UIKit

extension AdaptivePerformanceOptimizer {
    /// Configure optimization based on app lifecycle events
    public func configureForAppLifecycle() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.handleAppBackground()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.handleAppForeground()
            }
        }
    }
    
    private func handleAppBackground() async {
        logger.info("App entered background - reducing performance features")
        enabledFeatures.remove(.realtimeSync)
        enabledFeatures.remove(.advancedAnimations)
    }
    
    private func handleAppForeground() async {
        logger.info("App entered foreground - restoring performance features")
        await refreshAndOptimize()
    }
}
#endif