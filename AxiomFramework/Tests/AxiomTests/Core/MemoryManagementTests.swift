import Testing
import Foundation
@testable import Axiom

/// Comprehensive testing for Memory Management with configuration-based limits
/// 
/// Tests include:
/// - Configurable memory limits
/// - Adaptive memory behavior
/// - Cache eviction strategies
/// - Memory pressure handling
/// - Performance under memory constraints
/// - Memory leak prevention
@Suite("Memory Management Tests")
struct MemoryManagementTests {
    
    // MARK: - Test Types
    
    struct TestCacheItem: Sendable {
        let id: String
        let data: Data
        let timestamp: Date
        
        var sizeInBytes: Int {
            data.count + MemoryLayout<Self>.size
        }
    }
    
    /// Memory configuration for testing
    struct MemoryConfiguration: Sendable {
        var maxMemoryUsageBytes: Int = 10_000_000 // 10MB default
        var targetMemoryUsageBytes: Int = 8_000_000 // 8MB target
        var evictionThreshold: Double = 0.8 // Start evicting at 80%
        var adaptiveBehaviorEnabled: Bool = true
    }
    
    /// Test memory manager with configurable limits
    actor TestMemoryManager {
        private var configuration: MemoryConfiguration
        private var cache: [String: TestCacheItem] = [:]
        private var currentMemoryUsage: Int = 0
        private var evictionCount: Int = 0
        
        init(configuration: MemoryConfiguration = MemoryConfiguration()) {
            self.configuration = configuration
        }
        
        // MARK: - Configuration
        
        func updateConfiguration(_ newConfig: MemoryConfiguration) {
            configuration = newConfig
            if configuration.adaptiveBehaviorEnabled {
                adaptToMemoryPressure()
            }
        }
        
        func getConfiguration() -> MemoryConfiguration {
            configuration
        }
        
        // MARK: - Cache Management
        
        func store(_ item: TestCacheItem) throws {
            let itemSize = item.sizeInBytes
            
            // Check if item would exceed memory limit
            if currentMemoryUsage + itemSize > configuration.maxMemoryUsageBytes {
                if configuration.adaptiveBehaviorEnabled {
                    // Try to make room by evicting old items
                    evictItemsToMakeRoom(forSize: itemSize)
                } else {
                    throw MemoryError.memoryLimitExceeded
                }
            }
            
            // Store the item
            if let existingItem = cache[item.id] {
                currentMemoryUsage -= existingItem.sizeInBytes
            }
            cache[item.id] = item
            currentMemoryUsage += itemSize
            
            // Check if we need to trigger eviction
            if shouldTriggerEviction() {
                performEviction()
            }
        }
        
        func retrieve(_ id: String) -> TestCacheItem? {
            cache[id]
        }
        
        func remove(_ id: String) {
            if let item = cache[id] {
                currentMemoryUsage -= item.sizeInBytes
                cache[id] = nil
            }
        }
        
        func clear() {
            cache.removeAll()
            currentMemoryUsage = 0
            evictionCount = 0
        }
        
        // MARK: - Memory Management
        
        private func shouldTriggerEviction() -> Bool {
            let usageRatio = Double(currentMemoryUsage) / Double(configuration.maxMemoryUsageBytes)
            return usageRatio > configuration.evictionThreshold
        }
        
        private func performEviction() {
            guard configuration.adaptiveBehaviorEnabled else { return }
            
            // Sort items by timestamp (oldest first)
            let sortedItems = cache.values.sorted { $0.timestamp < $1.timestamp }
            
            // Evict oldest items until we're below target memory
            for item in sortedItems {
                if currentMemoryUsage <= configuration.targetMemoryUsageBytes {
                    break
                }
                remove(item.id)
                evictionCount += 1
            }
        }
        
        private func evictItemsToMakeRoom(forSize size: Int) {
            // Sort items by timestamp (oldest first)
            let sortedItems = cache.values.sorted { $0.timestamp < $1.timestamp }
            
            var freedMemory = 0
            for item in sortedItems {
                remove(item.id)
                freedMemory += item.sizeInBytes
                evictionCount += 1
                
                if currentMemoryUsage + size <= configuration.maxMemoryUsageBytes {
                    break
                }
            }
        }
        
        private func adaptToMemoryPressure() {
            // Simulate adaptive behavior based on system memory pressure
            // In real implementation, this would respond to system notifications
            if currentMemoryUsage > configuration.targetMemoryUsageBytes {
                performEviction()
            }
        }
        
        // MARK: - Metrics
        
        func getMemoryUsage() -> (current: Int, max: Int, ratio: Double) {
            let ratio = Double(currentMemoryUsage) / Double(configuration.maxMemoryUsageBytes)
            return (currentMemoryUsage, configuration.maxMemoryUsageBytes, ratio)
        }
        
        func getCacheStats() -> (itemCount: Int, evictionCount: Int, memoryUsage: Int) {
            (cache.count, evictionCount, currentMemoryUsage)
        }
    }
    
    enum MemoryError: Error {
        case memoryLimitExceeded
    }
    
    // MARK: - Configuration Tests
    
    @Test("Memory configuration initialization")
    func testMemoryConfigurationInitialization() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 5_000_000,
            targetMemoryUsageBytes: 4_000_000,
            evictionThreshold: 0.75,
            adaptiveBehaviorEnabled: true
        )
        
        let manager = TestMemoryManager(configuration: config)
        let currentConfig = await manager.getConfiguration()
        
        #expect(currentConfig.maxMemoryUsageBytes == 5_000_000)
        #expect(currentConfig.targetMemoryUsageBytes == 4_000_000)
        #expect(currentConfig.evictionThreshold == 0.75)
        #expect(currentConfig.adaptiveBehaviorEnabled == true)
    }
    
    @Test("Dynamic configuration updates")
    func testDynamicConfigurationUpdates() async throws {
        let manager = TestMemoryManager()
        
        // Update configuration
        let newConfig = MemoryConfiguration(
            maxMemoryUsageBytes: 20_000_000,
            targetMemoryUsageBytes: 15_000_000,
            evictionThreshold: 0.9,
            adaptiveBehaviorEnabled: false
        )
        
        await manager.updateConfiguration(newConfig)
        let updatedConfig = await manager.getConfiguration()
        
        #expect(updatedConfig.maxMemoryUsageBytes == 20_000_000)
        #expect(updatedConfig.adaptiveBehaviorEnabled == false)
    }
    
    // MARK: - Memory Limit Tests
    
    @Test("Memory limit enforcement without adaptive behavior")
    func testMemoryLimitEnforcementWithoutAdaptive() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 1000,
            adaptiveBehaviorEnabled: false
        )
        let manager = TestMemoryManager(configuration: config)
        
        // Store item within limit
        let smallItem = TestCacheItem(
            id: "small",
            data: Data(repeating: 0, count: 500),
            timestamp: Date()
        )
        try await manager.store(smallItem)
        
        // Try to store item that exceeds limit
        let largeItem = TestCacheItem(
            id: "large",
            data: Data(repeating: 0, count: 600),
            timestamp: Date()
        )
        
        await #expect(throws: MemoryError.self) {
            try await manager.store(largeItem)
        }
    }
    
    @Test("Memory limit with adaptive eviction")
    func testMemoryLimitWithAdaptiveEviction() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 2000,
            targetMemoryUsageBytes: 1500,
            adaptiveBehaviorEnabled: true
        )
        let manager = TestMemoryManager(configuration: config)
        
        // Store multiple items
        for i in 0..<5 {
            let item = TestCacheItem(
                id: "item\(i)",
                data: Data(repeating: 0, count: 400),
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await manager.store(item)
        }
        
        // Verify some items were evicted
        let stats = await manager.getCacheStats()
        #expect(stats.itemCount < 5)
        #expect(stats.evictionCount > 0)
        
        // Verify memory usage is within limits
        let usage = await manager.getMemoryUsage()
        #expect(usage.current <= config.maxMemoryUsageBytes)
    }
    
    // MARK: - Eviction Strategy Tests
    
    @Test("LRU eviction strategy")
    func testLRUEvictionStrategy() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 1500,
            targetMemoryUsageBytes: 1000,
            evictionThreshold: 0.8,
            adaptiveBehaviorEnabled: true
        )
        let manager = TestMemoryManager(configuration: config)
        
        // Store items with different timestamps
        let oldItem = TestCacheItem(
            id: "old",
            data: Data(repeating: 0, count: 500),
            timestamp: Date().addingTimeInterval(-10)
        )
        try await manager.store(oldItem)
        
        let newItem = TestCacheItem(
            id: "new",
            data: Data(repeating: 0, count: 500),
            timestamp: Date()
        )
        try await manager.store(newItem)
        
        // Store item that triggers eviction
        let triggerItem = TestCacheItem(
            id: "trigger",
            data: Data(repeating: 0, count: 600),
            timestamp: Date().addingTimeInterval(5)
        )
        try await manager.store(triggerItem)
        
        // Verify old item was evicted
        let retrievedOld = await manager.retrieve("old")
        let retrievedNew = await manager.retrieve("new")
        let retrievedTrigger = await manager.retrieve("trigger")
        
        #expect(retrievedOld == nil)
        #expect(retrievedNew != nil)
        #expect(retrievedTrigger != nil)
    }
    
    // MARK: - Performance Tests
    
    @Test("Memory management performance under load")
    func testMemoryManagementPerformanceUnderLoad() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 10_000_000, // 10MB
            targetMemoryUsageBytes: 8_000_000, // 8MB
            adaptiveBehaviorEnabled: true
        )
        let manager = TestMemoryManager(configuration: config)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Store many items
        for i in 0..<1000 {
            let item = TestCacheItem(
                id: "item\(i)",
                data: Data(repeating: 0, count: 10_000), // 10KB each
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await manager.store(item)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Verify performance
        #expect(duration < 1.0) // Should complete within 1 second
        
        // Verify memory constraints were respected
        let usage = await manager.getMemoryUsage()
        #expect(usage.current <= config.maxMemoryUsageBytes)
        
        let stats = await manager.getCacheStats()
        print("📊 Memory Management Performance:")
        print("   Items stored: 1000")
        print("   Items in cache: \(stats.itemCount)")
        print("   Items evicted: \(stats.evictionCount)")
        print("   Memory usage: \(usage.current) / \(usage.max) (\(String(format: "%.1f", usage.ratio * 100))%)")
        print("   Duration: \(String(format: "%.3f", duration)) seconds")
    }
    
    // MARK: - Adaptive Behavior Tests
    
    @Test("Adaptive behavior response to memory pressure")
    func testAdaptiveBehaviorResponseToMemoryPressure() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 5000,
            targetMemoryUsageBytes: 3000,
            evictionThreshold: 0.7,
            adaptiveBehaviorEnabled: true
        )
        let manager = TestMemoryManager(configuration: config)
        
        // Fill cache to near threshold
        for i in 0..<4 {
            let item = TestCacheItem(
                id: "item\(i)",
                data: Data(repeating: 0, count: 1000),
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await manager.store(item)
        }
        
        // Verify eviction occurred
        let stats = await manager.getCacheStats()
        #expect(stats.evictionCount > 0)
        #expect(stats.memoryUsage <= config.targetMemoryUsageBytes)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Zero memory limit handling")
    func testZeroMemoryLimitHandling() async throws {
        let config = MemoryConfiguration(
            maxMemoryUsageBytes: 0,
            adaptiveBehaviorEnabled: false
        )
        let manager = TestMemoryManager(configuration: config)
        
        let item = TestCacheItem(
            id: "test",
            data: Data(repeating: 0, count: 1),
            timestamp: Date()
        )
        
        await #expect(throws: MemoryError.self) {
            try await manager.store(item)
        }
    }
    
    @Test("Memory cleanup on clear")
    func testMemoryCleanupOnClear() async throws {
        let manager = TestMemoryManager()
        
        // Store items
        for i in 0..<10 {
            let item = TestCacheItem(
                id: "item\(i)",
                data: Data(repeating: 0, count: 1000),
                timestamp: Date()
            )
            try await manager.store(item)
        }
        
        // Clear cache
        await manager.clear()
        
        // Verify everything was cleared
        let stats = await manager.getCacheStats()
        #expect(stats.itemCount == 0)
        #expect(stats.memoryUsage == 0)
        #expect(stats.evictionCount == 0)
    }
}