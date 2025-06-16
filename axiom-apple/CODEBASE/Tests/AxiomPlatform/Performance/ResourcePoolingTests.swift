import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform resource pooling functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ResourcePoolingTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testResourcePoolInitialization() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 10, factory: TestResource.create)
        XCTAssertNotNil(pool, "ResourcePool should initialize correctly")
        
        let maxSize = await pool.getMaxSize()
        XCTAssertEqual(maxSize, 10, "Should set correct max size")
        
        let currentSize = await pool.getCurrentSize()
        XCTAssertEqual(currentSize, 0, "Should start with empty pool")
    }
    
    func testResourceAcquisitionAndRelease() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 5, factory: TestResource.create)
        
        // Acquire resource
        let resource = await pool.acquireResource()
        XCTAssertNotNil(resource, "Should acquire resource from pool")
        
        let activeCount = await pool.getActiveResourceCount()
        XCTAssertEqual(activeCount, 1, "Should have 1 active resource")
        
        // Release resource
        await pool.releaseResource(resource)
        
        let activeCountAfterRelease = await pool.getActiveResourceCount()
        XCTAssertEqual(activeCountAfterRelease, 0, "Should have 0 active resources after release")
        
        let poolSize = await pool.getCurrentSize()
        XCTAssertEqual(poolSize, 1, "Should have 1 resource in pool after release")
    }
    
    func testResourcePoolLimits() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 2, factory: TestResource.create)
        
        // Acquire up to max capacity
        let resource1 = await pool.acquireResource()
        let resource2 = await pool.acquireResource()
        
        let activeCount = await pool.getActiveResourceCount()
        XCTAssertEqual(activeCount, 2, "Should have 2 active resources")
        
        // Try to acquire beyond capacity
        let resource3 = await pool.tryAcquireResource(timeout: .milliseconds(100))
        XCTAssertNil(resource3, "Should not acquire resource beyond capacity")
        
        // Release one resource
        await pool.releaseResource(resource1)
        
        // Should now be able to acquire
        let resource4 = await pool.acquireResource()
        XCTAssertNotNil(resource4, "Should acquire resource after one is released")
        
        // Clean up
        await pool.releaseResource(resource2)
        await pool.releaseResource(resource4)
    }
    
    func testResourcePoolValidation() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 3, factory: TestResource.create)
        
        let resource = await pool.acquireResource()
        
        // Simulate resource becoming invalid
        resource.invalidate()
        
        // Release invalid resource
        await pool.releaseResource(resource)
        
        // Pool should not retain invalid resources
        let poolSize = await pool.getCurrentSize()
        XCTAssertEqual(poolSize, 0, "Should not retain invalid resources")
        
        // Acquiring new resource should create fresh one
        let newResource = await pool.acquireResource()
        XCTAssertTrue(newResource.isValid, "New resource should be valid")
        
        await pool.releaseResource(newResource)
    }
    
    func testResourcePoolEviction() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 2, 
                                            factory: TestResource.create,
                                            evictionPolicy: .leastRecentlyUsed)
        
        // Fill pool
        let resource1 = await pool.acquireResource()
        await pool.releaseResource(resource1)
        
        let resource2 = await pool.acquireResource()
        await pool.releaseResource(resource2)
        
        // Pool should be at capacity
        let poolSize = await pool.getCurrentSize()
        XCTAssertEqual(poolSize, 2, "Pool should be at capacity")
        
        // Use resource1 again to make it more recently used
        let reusedResource1 = await pool.acquireResource()
        XCTAssertEqual(reusedResource1.id, resource1.id, "Should reuse resource1")
        await pool.releaseResource(reusedResource1)
        
        // Add new resource, should evict resource2 (least recently used)
        let resource3 = await pool.acquireResource()
        await pool.releaseResource(resource3)
        
        // Verify resource2 was evicted
        let resource4 = await pool.acquireResource()
        XCTAssertNotEqual(resource4.id, resource2.id, "Resource2 should have been evicted")
        
        await pool.releaseResource(resource4)
    }
    
    // MARK: - Performance Tests
    
    func testResourcePoolPerformance() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let pool = ResourcePool<TestResource>(maxSize: 20, factory: TestResource.create)
                
                // Test rapid acquire/release cycles
                for _ in 0..<100 {
                    let resource = await pool.acquireResource()
                    
                    // Simulate work with resource
                    resource.performWork()
                    
                    await pool.releaseResource(resource)
                }
            },
            maxDuration: .milliseconds(200),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    func testConcurrentResourceAccess() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 10, factory: TestResource.create)
        
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                // Simulate concurrent access
                await withTaskGroup(of: Void.self) { group in
                    for i in 0..<50 {
                        group.addTask {
                            let resource = await pool.acquireResource()
                            
                            // Simulate work
                            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                            resource.performWork()
                            
                            await pool.releaseResource(resource)
                        }
                    }
                }
            },
            maxDuration: .seconds(1),
            maxMemoryGrowth: 2 * 1024 * 1024 // 2MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testResourcePoolMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let pool = ResourcePool<TestResource>(maxSize: 5, factory: TestResource.create)
            
            // Simulate resource lifecycle
            for i in 0..<20 {
                let resource = await pool.acquireResource()
                resource.performWork()
                
                if i % 3 == 0 {
                    // Occasionally invalidate resources to test cleanup
                    resource.invalidate()
                }
                
                await pool.releaseResource(resource)
            }
            
            await pool.drainPool()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testResourcePoolErrorHandling() async throws {
        let pool = ResourcePool<TestResource>(maxSize: 2, factory: TestResource.create)
        
        // Test double release
        let resource = await pool.acquireResource()
        await pool.releaseResource(resource)
        
        do {
            try await pool.releaseResourceStrict(resource)
            XCTFail("Should throw error for double release")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for double release")
        }
        
        // Test factory failure
        let failingPool = ResourcePool<TestResource>(maxSize: 2) {
            throw AxiomError.resourceCreationFailed
        }
        
        do {
            _ = try await failingPool.acquireResourceStrict()
            XCTFail("Should throw error when factory fails")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should propagate factory error")
        }
    }
}

// MARK: - Test Helper Classes

private class TestResource {
    let id: UUID = UUID()
    private var valid: Bool = true
    
    var isValid: Bool { valid }
    
    static func create() -> TestResource {
        return TestResource()
    }
    
    func performWork() {
        // Simulate work
        Thread.sleep(forTimeInterval: 0.001) // 1ms
    }
    
    func invalidate() {
        valid = false
    }
}