import XCTest
import AxiomTesting
@testable import AxiomPlatform
@testable import AxiomArchitecture

/// Tests for AxiomPlatform event bus functionality
/// 
/// Coverage Requirements:
/// - All public APIs: ✅
/// - Error conditions: ✅  
/// - Performance requirements: ✅
/// - Memory management: ✅
final class FrameworkEventBusTests: XCTestCase {
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - Core Functionality Tests
    
    func testFrameworkEventBusInitialization() async throws {
        let eventBus = FrameworkEventBus()
        XCTAssertNotNil(eventBus, "FrameworkEventBus should initialize correctly")
    }
    
    func testEventPublishingAndSubscription() async throws {
        let eventBus = FrameworkEventBus()
        
        var receivedEvents: [FrameworkEvent] = []
        let subscription = await eventBus.subscribe { event in
            receivedEvents.append(event)
        }
        
        let testEvent = FrameworkEvent.lifecycleChanged(.active)
        await eventBus.publish(testEvent)
        
        // Allow time for event processing
        try await Task.sleep(for: .milliseconds(10))
        
        XCTAssertEqual(receivedEvents.count, 1, "Should receive one event")
        if let receivedEvent = receivedEvents.first {
            XCTAssertEqual(receivedEvent, testEvent, "Should receive the published event")
        }
        
        await eventBus.unsubscribe(subscription)
    }
    
    func testMultipleSubscribers() async throws {
        let eventBus = FrameworkEventBus()
        
        var subscriber1Events: [FrameworkEvent] = []
        var subscriber2Events: [FrameworkEvent] = []
        
        let subscription1 = await eventBus.subscribe { event in
            subscriber1Events.append(event)
        }
        
        let subscription2 = await eventBus.subscribe { event in
            subscriber2Events.append(event)
        }
        
        let testEvent = FrameworkEvent.performanceWarning(.memoryPressure)
        await eventBus.publish(testEvent)
        
        // Allow time for event processing
        try await Task.sleep(for: .milliseconds(10))
        
        XCTAssertEqual(subscriber1Events.count, 1, "Subscriber 1 should receive event")
        XCTAssertEqual(subscriber2Events.count, 1, "Subscriber 2 should receive event")
        
        await eventBus.unsubscribe(subscription1)
        await eventBus.unsubscribe(subscription2)
    }
    
    // MARK: - Performance Tests
    
    func testEventBusPerformanceRequirements() async throws {
        try await TestHelpers.performance.assertPerformanceRequirements(
            operation: {
                let eventBus = FrameworkEventBus()
                
                // Simulate high-frequency event publishing
                for i in 0..<100 {
                    let event = FrameworkEvent.systemEvent(.resourceUpdate)
                    await eventBus.publish(event)
                }
            },
            maxDuration: .milliseconds(100),
            maxMemoryGrowth: 1024 * 1024 // 1MB
        )
    }
    
    // MARK: - Memory Management Tests
    
    func testEventBusMemoryManagement() async throws {
        try await TestHelpers.performance.assertNoMemoryLeaks {
            let eventBus = FrameworkEventBus()
            
            // Create and remove subscriptions
            for _ in 0..<10 {
                let subscription = await eventBus.subscribe { _ in }
                await eventBus.unsubscribe(subscription)
            }
            
            // Publish events
            for i in 0..<50 {
                let event = FrameworkEvent.systemEvent(.resourceUpdate)
                await eventBus.publish(event)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testEventBusErrorHandling() async throws {
        let eventBus = FrameworkEventBus()
        
        // Test subscriber error handling
        let subscription = await eventBus.subscribe { event in
            throw AxiomError.infrastructureError(.serviceUnavailable("Test error"))
        }
        
        let testEvent = FrameworkEvent.errorOccurred(.systemError)
        
        // Publishing should not throw even if subscriber throws
        await eventBus.publish(testEvent)
        
        // Event bus should continue functioning
        let eventCount = await eventBus.getPublishedEventCount()
        XCTAssertEqual(eventCount, 1, "Event should still be published despite subscriber error")
        
        await eventBus.unsubscribe(subscription)
    }
}