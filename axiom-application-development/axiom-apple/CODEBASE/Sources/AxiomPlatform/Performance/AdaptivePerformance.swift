import Foundation
import AxiomCore
#if canImport(UIKit)
import UIKit
#endif

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
        let deviceInfo = await MainActor.run { DeviceInfoMonitor.current }
        let processInfo = ProcessInfo.processInfo
        
        return DeviceProfile(
            deviceModel: await deviceInfo.model,
            processorSpeed: await deviceInfo.processorSpeed,
            memorySize: await deviceInfo.memorySize,
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
        
        // Apply SLA adjustments - commented out as PerformanceMonitor needs to be implemented
        // await PerformanceMonitor.shared.adjustSLA(multiplier: settings.slaMultiplier)
        
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
        
        // Apply emergency SLA multiplier - commented out as PerformanceMonitor needs to be implemented
        // await PerformanceMonitor.shared.adjustSLA(multiplier: 3.0)
        
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
        
        init(value: T, cost: Int, lastAccessed: Date, accessCount: Int) {
            self.value = value
            self.cost = cost
            self.lastAccessed = lastAccessed
            self.accessCount = accessCount
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
}

// MARK: - UIKit Integration

#if canImport(UIKit)
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

// MARK: - SLA Management System

/// Service Level Agreement for performance targets
public enum PerformanceSLA: String, CaseIterable, Sendable {
    case aggressive = "aggressive"
    case balanced = "balanced"
    case conservative = "conservative"
    
    public var name: String {
        switch self {
        case .aggressive:
            return "Aggressive"
        case .balanced:
            return "Balanced"
        case .conservative:
            return "Conservative"
        }
    }
    
    public var targetResponseTime: TimeInterval {
        switch self {
        case .aggressive: return 0.016 // 60fps target
        case .balanced: return 0.033   // 30fps target
        case .conservative: return 0.066 // 15fps target
        }
    }
    
    public var maxCPUUsage: Double {
        switch self {
        case .aggressive: return 0.8
        case .balanced: return 0.6
        case .conservative: return 0.4
        }
    }
    
    public var maxMemoryUsage: Double {
        switch self {
        case .aggressive: return 0.8
        case .balanced: return 0.6
        case .conservative: return 0.4
        }
    }
    
    public var maxErrorRate: Double {
        switch self {
        case .aggressive: return 0.05 // 5%
        case .balanced: return 0.02   // 2%
        case .conservative: return 0.01 // 1%
        }
    }
    
    public var budgetAdjustmentFactor: Double {
        switch self {
        case .aggressive: return 1.5
        case .balanced: return 1.0
        case .conservative: return 0.7
        }
    }
}

/// Metrics for tracking SLA achievement
public struct SLAAchievementMetrics: Sendable {
    public let sla: PerformanceSLA
    public let responseTime: TimeInterval
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let errorRate: Double
    public let timestamp: Date
    public let achievementRate: Double
    
    public init(sla: PerformanceSLA, responseTime: TimeInterval, cpuUsage: Double, memoryUsage: Double, errorRate: Double) {
        self.sla = sla
        self.responseTime = responseTime
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.errorRate = errorRate
        self.timestamp = Date()
        
        // Calculate achievement rate as percentage of targets met
        var targetsAchieved = 0
        let totalTargets = 4
        
        if responseTime <= sla.targetResponseTime { targetsAchieved += 1 }
        if cpuUsage <= sla.maxCPUUsage { targetsAchieved += 1 }
        if memoryUsage <= sla.maxMemoryUsage { targetsAchieved += 1 }
        if errorRate <= sla.maxErrorRate { targetsAchieved += 1 }
        
        self.achievementRate = Double(targetsAchieved) / Double(totalTargets)
    }
}

/// SLA monitoring and management system
public actor SLAManager {
    public static let shared = SLAManager()
    
    private var currentSLA: PerformanceSLA = .balanced
    private var achievementHistory: [SLAAchievementMetrics] = []
    private var activeMonitors: [PerformanceMonitor] = []
    private let logger = CategoryLogger.logger(for: .performance)
    private let maxHistorySize = 100
    
    private init() {}
    
    /// Set the target SLA
    public func setSLA(_ sla: PerformanceSLA) async {
        let previousSLA = currentSLA
        currentSLA = sla
        
        logger.info("SLA changed from \(previousSLA.name) to \(sla.name)")
        
        // Validate SLA achievability
        await validateSLAAchievability(sla)
        
        // Update performance budgets
        await recalculatePerformanceBudgets(from: previousSLA, to: sla)
        
        // Update active monitors
        await updateActiveMonitors(newSLA: sla)
        
        // Send telemetry
        await Telemetry.shared.send(
            TelemetryPerformanceAlert(
                type: .slaAdjustment,
                message: "SLA adjusted to \(sla.name)",
                value: sla.budgetAdjustmentFactor,
                threshold: 1.0
            )
        )
    }
    
    /// Get the current SLA
    public func getCurrentSLA() -> PerformanceSLA {
        return currentSLA
    }
    
    /// Record SLA achievement metrics
    public func recordMetrics(
        responseTime: TimeInterval,
        cpuUsage: Double,
        memoryUsage: Double,
        errorRate: Double
    ) async {
        let metrics = SLAAchievementMetrics(
            sla: currentSLA,
            responseTime: responseTime,
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            errorRate: errorRate
        )
        
        achievementHistory.append(metrics)
        
        // Keep history size bounded
        if achievementHistory.count > maxHistorySize {
            achievementHistory.removeFirst(achievementHistory.count - maxHistorySize)
        }
        
        // Check for auto-adjustment needs
        await evaluateAutoAdjustment(metrics)
        
        // Log achievement if below threshold
        if metrics.achievementRate < 0.8 {
            logger.warning("SLA achievement rate: \(String(format: "%.1f", metrics.achievementRate * 100))% (target: 80%+)")
        }
    }
    
    /// Register a performance monitor for SLA updates
    public func registerMonitor(_ monitor: PerformanceMonitor) {
        activeMonitors.append(monitor)
    }
    
    /// Adjust SLA based on performance conditions
    public func adjustSLA(newSLA: PerformanceSLA) async {
        await setSLA(newSLA)
    }
    
    /// Get recent achievement history
    public func getAchievementHistory(last: Int = 10) -> [SLAAchievementMetrics] {
        return Array(achievementHistory.suffix(last))
    }
    
    /// Evaluate if automatic SLA adjustment is needed
    private func evaluateAutoAdjustment(_ metrics: SLAAchievementMetrics) async {
        let recentMetrics = getAchievementHistory(last: 5)
        
        // Only auto-adjust if we have sufficient data
        guard recentMetrics.count >= 3 else { return }
        
        let avgAchievementRate = recentMetrics.map { $0.achievementRate }.reduce(0, +) / Double(recentMetrics.count)
        
        // If consistently underperforming, consider more conservative SLA
        if avgAchievementRate < 0.8 && currentSLA != .conservative {
            logger.warning("Auto-adjusting to conservative SLA due to low achievement rate: \(String(format: "%.1f", avgAchievementRate * 100))%")
            await adjustSLA(newSLA: .conservative)
        }
        // If consistently overperforming, consider more aggressive SLA
        else if avgAchievementRate > 0.98 && currentSLA != .aggressive {
            logger.info("Auto-adjusting to aggressive SLA due to high achievement rate: \(String(format: "%.1f", avgAchievementRate * 100))%")
            await adjustSLA(newSLA: .aggressive)
        }
    }
    
    /// Recalculate performance budgets based on SLA change
    private func recalculatePerformanceBudgets(from previousSLA: PerformanceSLA, to newSLA: PerformanceSLA) async {
        let budgetManager = PerformanceBudgetManager.shared
        
        // Calculate adjustment ratio
        let adjustmentRatio = newSLA.budgetAdjustmentFactor / previousSLA.budgetAdjustmentFactor
        
        logger.info("Recalculating performance budgets with adjustment ratio: \(String(format: "%.2f", adjustmentRatio))")
        
        do {
            // Get current device profile to determine performance class
            let deviceInfo = await MainActor.run { DeviceInfoMonitor.current }
            let deviceProfile = DeviceProfile(
                deviceModel: await deviceInfo.model,
                processorSpeed: await deviceInfo.processorSpeed,
                memorySize: await deviceInfo.memorySize,
                thermalState: await deviceInfo.thermalState,
                batteryLevel: await getBatteryLevel(),
                isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
            )
            
            // Adjust performance class based on new SLA
            let adjustedPerformanceClass = getAdjustedPerformanceClass(
                baseClass: deviceProfile.performanceClass,
                sla: newSLA
            )
            
            // Reconfigure budgets for the adjusted performance class
            try await budgetManager.configureBudgetsForPerformanceClass(adjustedPerformanceClass)
            
            logger.info("Performance budgets recalculated for \(adjustedPerformanceClass) performance class")
        } catch {
            logger.error("Failed to recalculate performance budgets: \(error.localizedDescription)")
        }
    }
    
    /// Update active monitors with new SLA thresholds
    private func updateActiveMonitors(newSLA: PerformanceSLA) async {
        for monitor in activeMonitors {
            await monitor.updateThresholds(
                responseTime: newSLA.targetResponseTime,
                cpuUsage: newSLA.maxCPUUsage,
                memoryUsage: newSLA.maxMemoryUsage,
                errorRate: newSLA.maxErrorRate
            )
        }
        
        logger.info("Updated \(activeMonitors.count) active monitors with new SLA thresholds")
    }
    
    /// Validate SLA achievability against current device capabilities
    private func validateSLAAchievability(_ sla: PerformanceSLA) async {
        let deviceInfo = await MainActor.run { DeviceInfoMonitor.current }
        let memoryPressure = await deviceInfo.currentMemoryPressure
        let thermalState = await deviceInfo.thermalState
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        var warnings: [String] = []
        
        // Check if device is under stress
        if memoryPressure > 0.8 {
            warnings.append("High memory pressure (\(String(format: "%.1f", memoryPressure * 100))%) may prevent SLA achievement")
        }
        
        if thermalState == .serious || thermalState == .critical {
            warnings.append("Thermal throttling (\(thermalState)) may prevent SLA achievement")
        }
        
        if isLowPowerMode {
            warnings.append("Low power mode enabled, SLA targets may not be achievable")
        }
        
        // Check if SLA targets are realistic for device
        let deviceProfile = DeviceProfile(
            deviceModel: await deviceInfo.model,
            processorSpeed: await deviceInfo.processorSpeed,
            memorySize: await deviceInfo.memorySize,
            thermalState: thermalState,
            batteryLevel: await getBatteryLevel(),
            isLowPowerMode: isLowPowerMode
        )
        
        if deviceProfile.performanceClass == .low && sla == .aggressive {
            warnings.append("Aggressive SLA may not be achievable on low-performance device")
        }
        
        if !warnings.isEmpty {
            let warningMessage = "SLA achievability warnings: " + warnings.joined(separator: "; ")
            logger.warning(warningMessage)
            
            await Telemetry.shared.send(
                TelemetryPerformanceAlert(
                    type: .slaAdjustment,
                    message: warningMessage
                )
            )
        } else {
            logger.info("SLA \(sla.name) appears achievable on current device")
        }
    }
    
    /// Get adjusted performance class based on SLA requirements
    private func getAdjustedPerformanceClass(baseClass: PerformanceClass, sla: PerformanceSLA) -> PerformanceClass {
        switch (baseClass, sla) {
        case (.high, .conservative):
            return .medium // Reduce performance class for conservative SLA
        case (.low, .aggressive):
            return .medium // Increase performance class for aggressive SLA
        default:
            return baseClass // Keep base class for balanced or appropriate SLA
        }
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
}

// MARK: - Performance Monitor SLA Integration

extension PerformanceMonitor {
    /// Update monitoring thresholds based on SLA
    public func updateThresholds(
        responseTime: TimeInterval,
        cpuUsage: Double,
        memoryUsage: Double,
        errorRate: Double
    ) async {
        // Implementation would update internal monitoring thresholds
        // For now, log the threshold updates
        let logger = CategoryLogger.logger(for: .performance)
        logger.info("Updated monitoring thresholds - Response: \(String(format: "%.1f", responseTime * 1000))ms, CPU: \(String(format: "%.1f", cpuUsage * 100))%, Memory: \(String(format: "%.1f", memoryUsage * 100))%, Error: \(String(format: "%.1f", errorRate * 100))%")
    }
}