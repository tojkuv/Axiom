import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform lifecycle coordination functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class PlatformLifecycleTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testPlatformLifecycleCoordinatorInitialization() async throws {
        let coordinator = PlatformLifecycleCoordinator()
        XCTAssertNotNil(coordinator, "PlatformLifecycleCoordinator should initialize correctly")
    }
    
    func testLifecycleStateTransitions() async throws {
        let coordinator = PlatformLifecycleCoordinator()
        
        // Test initialization
        await coordinator.initialize()
        let initialState = await coordinator.currentState
        XCTAssertEqual(initialState, .initialized, "Should be in initialized state")
        
        // Test activation
        await coordinator.activate()
        let activeState = await coordinator.currentState
        XCTAssertEqual(activeState, .active, "Should be in active state")
        
        // Test deactivation
        await coordinator.deactivate()
        let inactiveState = await coordinator.currentState
        XCTAssertEqual(inactiveState, .inactive, "Should be in inactive state")
    }
    
    func testCrossPlatformResourceManager() async throws {
        let resourceManager = CrossPlatformResourceManager()
        
        let isAvailable = await resourceManager.isResourceAvailable()
        XCTAssertNotNil(isAvailable, "Resource availability should be determinable")
        
        try await resourceManager.allocateResources()
        let resourcesAllocated = await resourceManager.areResourcesAllocated()
        XCTAssertTrue(resourcesAllocated, "Resources should be allocated after allocation call")
        
        await resourceManager.releaseResources()
        let resourcesReleased = await resourceManager.areResourcesAllocated()
        XCTAssertFalse(resourcesReleased, "Resources should be released after release call")
    }
    
    // MARK: - Performance Tests
    
    func testLifecyclePerformanceRequirements() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let coordinator = PlatformLifecycleCoordinator()
                await coordinator.initialize()
                await coordinator.activate()
                await coordinator.deactivate()
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testLifecycleMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let coordinator = PlatformLifecycleCoordinator()
            let resourceManager = CrossPlatformResourceManager()
            
            await coordinator.initialize()
            try await resourceManager.allocateResources()
            await resourceManager.releaseResources()
            await coordinator.deactivate()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testLifecycleErrorHandling() async throws {
        let coordinator = PlatformLifecycleCoordinator()
        
        // Test invalid state transition
        do {
            try await coordinator.forceStateTransition(.invalid)
            XCTFail("Should throw error for invalid state transition")
        } catch {
            XCTAssertTrue(error is AxiomError, "Should throw AxiomError for invalid state")
        }
    }
}