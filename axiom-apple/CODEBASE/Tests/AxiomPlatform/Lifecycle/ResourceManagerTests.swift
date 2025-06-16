import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform resource management functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class ResourceManagerTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testEmergencyMemoryManagerInitialization() async throws {
        let memoryManager = EmergencyMemoryManager()
        XCTAssertNotNil(memoryManager, "EmergencyMemoryManager should initialize correctly")
    }
    
    func testMemoryWarningHandling() async throws {
        let memoryManager = EmergencyMemoryManager()
        
        // Simulate memory warning
        await memoryManager.handleMemoryWarning()
        
        let memoryCleared = await memoryManager.wasMemoryCleared()
        XCTAssertTrue(memoryCleared, "Memory should be cleared after warning")
    }
    
    func testResourceAllocationTracking() async throws {
        let resourceManager = CrossPlatformResourceManager()
        
        let initialCount = await resourceManager.getAllocatedResourceCount()
        XCTAssertEqual(initialCount, 0, "Should start with no allocated resources")
        
        try await resourceManager.allocateResource("test-resource")
        let afterAllocation = await resourceManager.getAllocatedResourceCount()
        XCTAssertEqual(afterAllocation, 1, "Should have one allocated resource")
        
        await resourceManager.releaseResource("test-resource")
        let afterRelease = await resourceManager.getAllocatedResourceCount()
        XCTAssertEqual(afterRelease, 0, "Should have no allocated resources after release")
    }
    
    // MARK: - Performance Tests
    
    func testResourceManagerPerformanceRequirements() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let memoryManager = EmergencyMemoryManager()
                await memoryManager.handleMemoryWarning()
            },
            maxDuration: .milliseconds(50),
            maxMemoryGrowth: 512 * 1024 // 512KB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testResourceManagerMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let memoryManager = EmergencyMemoryManager()
            let resourceManager = CrossPlatformResourceManager()
            
            // Simulate resource lifecycle
            try await resourceManager.allocateResource("leak-test")
            await memoryManager.handleMemoryWarning()
            await resourceManager.releaseResource("leak-test")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testResourceManagerErrorHandling() async throws {
        let resourceManager = CrossPlatformResourceManager()
        
        // Test allocation failure
        do {
            try await resourceManager.allocateResource("")
            XCTFail("Should throw error for empty resource name")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid resource name")
        }
        
        // Test double release
        try await resourceManager.allocateResource("double-release-test")
        await resourceManager.releaseResource("double-release-test")
        
        // Second release should handle gracefully
        await resourceManager.releaseResource("double-release-test")
        
        let count = await resourceManager.getAllocatedResourceCount()
        XCTAssertEqual(count, 0, "Should handle double release gracefully")
    }
}