import XCTest
@testable import Axiom

/// Tests for the Intelligence System Caching Architecture
/// Phase 3 Milestone 1: Caching Architecture Implementation
final class IntelligenceCachingTests: XCTestCase {
    
    private var intelligenceCache: IntelligenceCache!
    private var queryCache: QueryResultCache!
    
    override func setUp() async throws {
        try await super.setUp()
        intelligenceCache = IntelligenceCache(
            configuration: CacheConfiguration(
                maxSize: 100,
                ttl: 300.0, // 5 minutes
                evictionPolicy: .lru
            )
        )
        queryCache = QueryResultCache(
            configuration: CacheConfiguration(
                maxSize: 50,
                ttl: 180.0, // 3 minutes
                evictionPolicy: .lru
            )
        )
    }
    
    override func tearDown() async throws {
        await intelligenceCache.clearAll()
        await queryCache.clearAll()
        intelligenceCache = nil
        queryCache = nil
        try await super.tearDown()
    }
    
    // MARK: - Component Cache Tests
    
    func testComponentCaching() async throws {
        // Test component caching with TTL policies
        let componentID = ComponentID("test-component")
        let cachedComponent = CachedComponent(
            id: componentID,
            name: "TestComponent",
            type: "Actor",
            cachedAt: Date(),
            data: ["test": "data"]
        )
        
        // Cache the component
        await intelligenceCache.cacheComponent(cachedComponent, for: componentID)
        
        // Retrieve from cache
        let retrieved = await intelligenceCache.cachedComponent(for: componentID)
        XCTAssertNotNil(retrieved, "Component should be cached")
        XCTAssertEqual(retrieved?.id, componentID, "Component ID should match")
        XCTAssertEqual(retrieved?.name, "TestComponent", "Component name should match")
    }
    
    func testComponentCacheTTLExpiration() async throws {
        // Test TTL expiration for component cache
        let componentID = ComponentID("expiring-component")
        let cachedComponent = CachedComponent(
            id: componentID,
            name: "ExpiringComponent", 
            type: "Context",
            cachedAt: Date().addingTimeInterval(-400), // Expired (> 300s TTL)
            data: ["expired": "data"]
        )
        
        await intelligenceCache.cacheComponent(cachedComponent, for: componentID)
        
        // This should trigger expiration cleanup
        await intelligenceCache.invalidateExpiredEntries()
        
        let retrieved = await intelligenceCache.cachedComponent(for: componentID)
        XCTAssertNil(retrieved, "Expired component should be removed from cache")
    }
    
    func testComponentCacheLRUEviction() async throws {
        // Test LRU eviction policy
        let config = CacheConfiguration(maxSize: 2, ttl: 300.0, evictionPolicy: .lru)
        let cache = IntelligenceCache(configuration: config)
        
        // Add components up to max capacity
        let comp1 = CachedComponent(id: ComponentID("comp1"), name: "Component1", type: "Actor", cachedAt: Date(), data: [:])
        let comp2 = CachedComponent(id: ComponentID("comp2"), name: "Component2", type: "Context", cachedAt: Date(), data: [:])
        
        await cache.cacheComponent(comp1, for: comp1.id)
        await cache.cacheComponent(comp2, for: comp2.id)
        
        // Add third component, should evict least recently used
        let comp3 = CachedComponent(id: ComponentID("comp3"), name: "Component3", type: "Client", cachedAt: Date(), data: [:])
        await cache.cacheComponent(comp3, for: comp3.id)
        
        // comp1 should be evicted (LRU)
        let retrieved1 = await cache.cachedComponent(for: comp1.id)
        let retrieved2 = await cache.cachedComponent(for: comp2.id)
        let retrieved3 = await cache.cachedComponent(for: comp3.id)
        
        XCTAssertNil(retrieved1, "LRU component should be evicted")
        XCTAssertNotNil(retrieved2, "Recent component should remain")
        XCTAssertNotNil(retrieved3, "Newest component should be cached")
    }
    
    // MARK: - Query Result Cache Tests
    
    func testQueryResultCaching() async throws {
        // Test query result caching with invalidation
        let query = "test query"
        let queryResult = QueryResult(
            wasSuccessful: true,
            responseTime: 0.05,
            resultCount: 5,
            userSatisfaction: 0.9
        )
        let cachedResult = CachedQueryResult(
            query: query,
            result: queryResult,
            cachedAt: Date(),
            hitCount: 1
        )
        
        await queryCache.cacheResult(cachedResult, for: query)
        
        let retrieved = await queryCache.cachedResult(for: query)
        XCTAssertNotNil(retrieved, "Query result should be cached")
        XCTAssertEqual(retrieved?.query, query, "Query should match")
        XCTAssertEqual(retrieved?.result.wasSuccessful, true, "Result should match")
    }
    
    func testQueryCacheInvalidation() async throws {
        // Test cache invalidation strategies
        let query = "invalidation test"
        let queryResult = QueryResult(wasSuccessful: true, responseTime: 0.1, resultCount: 3, userSatisfaction: 0.8)
        let cachedResult = CachedQueryResult(query: query, result: queryResult, cachedAt: Date(), hitCount: 1)
        
        await queryCache.cacheResult(cachedResult, for: query)
        
        // Invalidate by pattern
        await queryCache.invalidateByPattern("invalidation*")
        
        let retrieved = await queryCache.cachedResult(for: query)
        XCTAssertNil(retrieved, "Query should be invalidated by pattern")
    }
    
    func testQueryCacheHitCountTracking() async throws {
        // Test hit count tracking for query cache
        let query = "popular query"
        let queryResult = QueryResult(wasSuccessful: true, responseTime: 0.02, resultCount: 10, userSatisfaction: 0.95)
        let cachedResult = CachedQueryResult(query: query, result: queryResult, cachedAt: Date(), hitCount: 1)
        
        await queryCache.cacheResult(cachedResult, for: query)
        
        // Access multiple times
        _ = await queryCache.cachedResult(for: query)
        _ = await queryCache.cachedResult(for: query)
        _ = await queryCache.cachedResult(for: query)
        
        let final = await queryCache.cachedResult(for: query)
        XCTAssertEqual(final?.hitCount, 5, "Hit count should be tracked correctly")
    }
    
    // MARK: - Memory Management Tests
    
    func testCacheMemoryEfficiency() async throws {
        // Test memory usage tracking and efficiency
        let initialMemory = await intelligenceCache.getMemoryUsage()
        
        // Add multiple components
        for i in 0..<10 {
            let component = CachedComponent(
                id: ComponentID("component-\(i)"),
                name: "Component\(i)",
                type: "TestType",
                cachedAt: Date(),
                data: ["index": "\(i)", "large_data": String(repeating: "x", count: 1000)]
            )
            await intelligenceCache.cacheComponent(component, for: component.id)
        }
        
        let memoryAfterCaching = await intelligenceCache.getMemoryUsage()
        XCTAssertGreaterThan(memoryAfterCaching, initialMemory, "Memory usage should increase with cached data")
        
        // Clear cache and verify memory cleanup
        await intelligenceCache.clearAll()
        let memoryAfterClearing = await intelligenceCache.getMemoryUsage()
        XCTAssertLessThanOrEqual(memoryAfterClearing, initialMemory + 1000, "Memory should be freed after clearing cache")
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() async throws {
        // Test thread-safe concurrent access
        let concurrentTasks = 20
        let componentsPerTask = 5
        
        await withTaskGroup(of: Void.self) { group in
            for taskID in 0..<concurrentTasks {
                group.addTask {
                    for componentIndex in 0..<componentsPerTask {
                        let component = CachedComponent(
                            id: ComponentID("task-\(taskID)-comp-\(componentIndex)"),
                            name: "ConcurrentComponent\(taskID)-\(componentIndex)",
                            type: "ConcurrentType",
                            cachedAt: Date(),
                            data: ["task": "\(taskID)", "component": "\(componentIndex)"]
                        )
                        await self.intelligenceCache.cacheComponent(component, for: component.id)
                        
                        // Also test retrieval
                        _ = await self.intelligenceCache.cachedComponent(for: component.id)
                    }
                }
            }
        }
        
        // Verify all components were cached correctly
        let totalComponents = concurrentTasks * componentsPerTask
        let cacheSize = await intelligenceCache.getCacheSize()
        XCTAssertEqual(cacheSize, totalComponents, "All components should be cached despite concurrent access")
    }
    
    // MARK: - Performance Tests
    
    func testCachePerformance() async throws {
        // Test cache operation performance
        let startTime = Date()
        let testIterations = 1000
        
        // Performance test for caching operations
        for i in 0..<testIterations {
            let component = CachedComponent(
                id: ComponentID("perf-comp-\(i)"),
                name: "PerfComponent\(i)",
                type: "PerfType",
                cachedAt: Date(),
                data: ["iteration": "\(i)"]
            )
            await intelligenceCache.cacheComponent(component, for: component.id)
        }
        
        let cachingDuration = Date().timeIntervalSince(startTime)
        
        // Performance test for retrieval operations
        let retrievalStartTime = Date()
        for i in 0..<testIterations {
            _ = await intelligenceCache.cachedComponent(for: ComponentID("perf-comp-\(i)"))
        }
        let retrievalDuration = Date().timeIntervalSince(retrievalStartTime)
        
        // Verify performance targets
        let avgCachingTime = cachingDuration / Double(testIterations)
        let avgRetrievalTime = retrievalDuration / Double(testIterations)
        
        XCTAssertLessThan(avgCachingTime, 0.001, "Average caching time should be < 1ms")
        XCTAssertLessThan(avgRetrievalTime, 0.0005, "Average retrieval time should be < 0.5ms")
        
        print("📊 Cache Performance Metrics:")
        print("   Caching: \(String(format: "%.4f", avgCachingTime * 1000))ms avg")
        print("   Retrieval: \(String(format: "%.4f", avgRetrievalTime * 1000))ms avg")
    }
    
    // MARK: - Cache Configuration Tests
    
    func testCacheConfiguration() async throws {
        // Test cache configuration and behavior
        let config = CacheConfiguration(
            maxSize: 5,
            ttl: 60.0, // 1 minute
            evictionPolicy: .lru,
            memoryThreshold: 1024 * 1024 // 1MB
        )
        
        let cache = IntelligenceCache(configuration: config)
        
        let maxSize = await cache.getMaxSize()
        let ttl = await cache.getTTL()
        
        XCTAssertEqual(maxSize, 5, "Max size should match configuration")
        XCTAssertEqual(ttl, 60.0, "TTL should match configuration")
    }
}