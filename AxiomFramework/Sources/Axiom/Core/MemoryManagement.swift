import Foundation

// MARK: - Memory Configuration

/// Configuration for memory management with adaptive behavior
public struct MemoryConfiguration: Sendable {
    /// Maximum memory usage in bytes
    public var maxMemoryBytes: Int
    
    /// Target memory usage for normal operation
    public var targetMemoryBytes: Int
    
    /// Threshold ratio (0.0-1.0) at which to start eviction
    public var evictionThreshold: Double
    
    /// Enable adaptive behavior based on memory pressure
    public var adaptiveBehaviorEnabled: Bool
    
    /// Memory pressure response strategy
    public var pressureStrategy: MemoryPressureStrategy
    
    public init(
        maxMemoryBytes: Int = 50_000_000, // 50MB default
        targetMemoryBytes: Int = 40_000_000, // 40MB target
        evictionThreshold: Double = 0.8,
        adaptiveBehaviorEnabled: Bool = true,
        pressureStrategy: MemoryPressureStrategy = .automatic
    ) {
        self.maxMemoryBytes = maxMemoryBytes
        self.targetMemoryBytes = targetMemoryBytes
        self.evictionThreshold = evictionThreshold
        self.adaptiveBehaviorEnabled = adaptiveBehaviorEnabled
        self.pressureStrategy = pressureStrategy
    }
}

/// Memory pressure response strategies
public enum MemoryPressureStrategy: String, Sendable, CaseIterable {
    case automatic // System decides based on conditions
    case aggressive // Evict more items sooner
    case conservative // Keep items longer
    case disabled // No automatic eviction
}

// MARK: - Memory Managed Protocol

/// Protocol for types that can report their memory usage
public protocol MemoryManaged {
    /// Calculate the approximate memory footprint in bytes
    var memoryFootprint: Int { get }
}

// MARK: - Memory Manager

/// Thread-safe memory manager with configurable limits and adaptive behavior
public actor MemoryManager {
    private var configuration: MemoryConfiguration
    private var currentUsage: Int = 0
    private var evictionHandlers: [(String) -> Void] = []
    
    // Metrics
    private var totalEvictions: Int = 0
    private var lastEvictionTime: Date?
    
    public init(configuration: MemoryConfiguration = MemoryConfiguration()) {
        self.configuration = configuration
    }
    
    // MARK: - Configuration Management
    
    /// Update the memory configuration
    public func updateConfiguration(_ newConfig: MemoryConfiguration) {
        configuration = newConfig
        if configuration.adaptiveBehaviorEnabled {
            Task { await checkMemoryPressure() }
        }
    }
    
    /// Get current configuration
    public func getConfiguration() -> MemoryConfiguration {
        configuration
    }
    
    // MARK: - Memory Tracking
    
    /// Register memory usage
    public func registerUsage(_ bytes: Int) throws {
        guard bytes >= 0 else {
            throw MemoryError.invalidMemorySize
        }
        
        let newUsage = currentUsage + bytes
        
        // Check if we would exceed limit
        if newUsage > configuration.maxMemoryBytes && !configuration.adaptiveBehaviorEnabled {
            throw MemoryError.memoryLimitExceeded(
                requested: bytes,
                available: configuration.maxMemoryBytes - currentUsage
            )
        }
        
        currentUsage = newUsage
        
        // Check if we need to trigger eviction
        if shouldTriggerEviction() {
            Task { await performEviction() }
        }
    }
    
    /// Release memory usage
    public func releaseUsage(_ bytes: Int) {
        currentUsage = max(0, currentUsage - bytes)
    }
    
    /// Get current memory statistics
    public func getMemoryStats() -> MemoryStats {
        MemoryStats(
            currentUsage: currentUsage,
            maxMemory: configuration.maxMemoryBytes,
            targetMemory: configuration.targetMemoryBytes,
            usageRatio: Double(currentUsage) / Double(configuration.maxMemoryBytes),
            totalEvictions: totalEvictions,
            lastEvictionTime: lastEvictionTime
        )
    }
    
    // MARK: - Eviction Management
    
    /// Add an eviction handler
    public func addEvictionHandler(_ handler: @escaping (String) -> Void) {
        evictionHandlers.append(handler)
    }
    
    /// Check if eviction should be triggered
    private func shouldTriggerEviction() -> Bool {
        guard configuration.adaptiveBehaviorEnabled else { return false }
        
        let usageRatio = Double(currentUsage) / Double(configuration.maxMemoryBytes)
        return usageRatio > configuration.evictionThreshold
    }
    
    /// Perform memory eviction based on strategy
    private func performEviction() async {
        guard configuration.adaptiveBehaviorEnabled else { return }
        
        let targetBytes = configuration.targetMemoryBytes
        let bytesToFree = currentUsage - targetBytes
        
        guard bytesToFree > 0 else { return }
        
        // Notify eviction handlers
        let evictionId = UUID().uuidString
        for handler in evictionHandlers {
            handler(evictionId)
        }
        
        totalEvictions += 1
        lastEvictionTime = Date()
    }
    
    /// Check system memory pressure and adapt
    private func checkMemoryPressure() async {
        // In a real implementation, this would check system memory pressure
        // For now, we just check our own usage
        if shouldTriggerEviction() {
            await performEviction()
        }
    }
    
    // MARK: - Cleanup
    
    /// Reset all memory tracking
    public func reset() {
        currentUsage = 0
        totalEvictions = 0
        lastEvictionTime = nil
        evictionHandlers.removeAll()
    }
}

// MARK: - Memory Statistics

/// Memory usage statistics
public struct MemoryStats: Sendable {
    public let currentUsage: Int
    public let maxMemory: Int
    public let targetMemory: Int
    public let usageRatio: Double
    public let totalEvictions: Int
    public let lastEvictionTime: Date?
    
    /// Memory usage as percentage string
    public var usagePercentage: String {
        String(format: "%.1f%%", usageRatio * 100)
    }
    
    /// Available memory in bytes
    public var availableMemory: Int {
        maxMemory - currentUsage
    }
}

// MARK: - Memory Errors

/// Errors related to memory management
public enum MemoryError: Error, LocalizedError {
    case memoryLimitExceeded(requested: Int, available: Int)
    case invalidMemorySize
    case evictionFailed(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .memoryLimitExceeded(let requested, let available):
            return "Memory limit exceeded. Requested: \(requested) bytes, Available: \(available) bytes"
        case .invalidMemorySize:
            return "Invalid memory size specified"
        case .evictionFailed(let reason):
            return "Memory eviction failed: \(reason)"
        }
    }
}

// MARK: - Global Memory Manager

/// Global memory manager for framework-wide memory management
public actor GlobalMemoryManager {
    public static let shared = GlobalMemoryManager()
    
    private let memoryManager: MemoryManager
    
    private init() {
        self.memoryManager = MemoryManager()
    }
    
    /// Get the global memory manager
    public func getManager() -> MemoryManager {
        memoryManager
    }
    
    /// Update global memory configuration
    public func updateConfiguration(_ config: MemoryConfiguration) async {
        await memoryManager.updateConfiguration(config)
    }
    
    /// Get current memory statistics
    public func getStats() async -> MemoryStats {
        await memoryManager.getMemoryStats()
    }
}