import XCTest
@testable import Axiom

final class CapabilityProtocolTests: XCTestCase {
    // Test that capability mock can transition through all states in < 10ms
    func testCapabilityLifecycleTransitions() async throws {
        let capability = MockCapability()
        
        let startTime = Date()
        
        // Test initial state
        let initialAvailability = await capability.isAvailable
        XCTAssertFalse(initialAvailability, "Capability should start unavailable")
        
        // Test initialization
        try await capability.activate()
        let afterInit = await capability.isAvailable
        XCTAssertTrue(afterInit, "Capability should be available after initialization")
        
        // Test state transitions
        await capability.transitionTo(.restricted)
        let restricted = await capability.currentState
        XCTAssertEqual(restricted, .restricted)
        
        await capability.transitionTo(.unavailable)
        let unavailable = await capability.currentState
        XCTAssertEqual(unavailable, .unavailable)
        
        await capability.transitionTo(.unknown)
        let unknown = await capability.currentState
        XCTAssertEqual(unknown, .unknown)
        
        // Test termination
        await capability.deactivate()
        let afterTerminate = await capability.isAvailable
        XCTAssertFalse(afterTerminate, "Capability should be unavailable after termination")
        
        let elapsed = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
        XCTAssertLessThan(elapsed, 10, "All transitions should complete in < 10ms")
    }
    
    // Test that all capability states are handled correctly
    func testCapabilityStatesIncludeAllRequired() async {
        let capability = MockCapability()
        
        // Test all required states exist
        let states: [CapabilityState] = [.available, .unavailable, .restricted, .unknown]
        
        for state in states {
            await capability.transitionTo(state)
            let currentState = await capability.currentState
            XCTAssertEqual(currentState, state, "Capability should support \(state) state")
        }
    }
    
    // Test lifecycle method error handling
    func testCapabilityInitializationFailure() async {
        let capability = FailingCapability()
        
        do {
            try await capability.activate()
            XCTFail("Initialization should have thrown an error")
        } catch {
            // Expected error
            XCTAssertTrue(error is CapabilityError)
        }
        
        // Verify capability remains unavailable after failed initialization
        let isAvailable = await capability.isAvailable
        XCTAssertFalse(isAvailable, "Capability should remain unavailable after failed initialization")
    }
    
    // Test concurrent access to capability state
    func testConcurrentCapabilityAccess() async {
        let capability = MockCapability()
        try? await capability.activate()
        
        // Perform concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Multiple readers
            for _ in 0..<10 {
                group.addTask {
                    let _ = await capability.isAvailable
                }
            }
            
            // State transitions
            group.addTask {
                await capability.transitionTo(.restricted)
            }
            
            group.addTask {
                await capability.transitionTo(.available)
            }
            
            await group.waitForAll()
        }
        
        // Verify capability is in a valid state
        let finalState = await capability.currentState
        XCTAssertTrue([.available, .restricted].contains(finalState), "Capability should be in a valid state after concurrent access")
    }
    
    // Test capability cleanup on termination
    func testCapabilityTerminationCleanup() async throws {
        let capability = ResourceCapability()
        
        // Initialize and allocate resources
        try await capability.activate()
        await capability.allocateResources()
        
        let resourcesBeforeTermination = await capability.activeResources
        XCTAssertGreaterThan(resourcesBeforeTermination, 0, "Should have active resources")
        
        // Terminate
        await capability.deactivate()
        
        // Verify cleanup
        let resourcesAfterTermination = await capability.activeResources
        XCTAssertEqual(resourcesAfterTermination, 0, "All resources should be cleaned up after termination")
        
        let state = await capability.currentState
        XCTAssertEqual(state, .unavailable, "Capability should be unavailable after termination")
    }
    
    // Test capability state observation
    func testCapabilityStateObservation() async throws {
        let capability = ObservableCapability()
        var observedStates: [CapabilityState] = []
        
        // Set up observation
        let task = Task {
            for await state in await capability.stateStream {
                observedStates.append(state)
                if observedStates.count >= 4 {
                    break
                }
            }
        }
        
        // Perform state transitions
        try await capability.activate()
        await capability.transitionTo(.restricted)
        await capability.transitionTo(.available)
        await capability.deactivate()
        
        // Wait for observations
        await task.value
        
        // Verify all transitions were observed
        XCTAssertEqual(observedStates.count, 4)
        XCTAssertEqual(observedStates, [.available, .restricted, .available, .unavailable])
    }
}

// MARK: - Test Support Types

// Basic mock capability
actor MockCapability: AxiomCapability {
    private(set) var currentState: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        currentState = .available
    }
    
    func deactivate() async {
        currentState = .unavailable
    }
    
    func transitionTo(_ state: CapabilityState) {
        currentState = state
    }
}

// Capability that fails initialization
actor FailingCapability: AxiomCapability {
    private(set) var currentState: CapabilityState = .unavailable
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        throw CapabilityError.initializationFailed("Test failure")
    }
    
    func deactivate() async {
        currentState = .unavailable
    }
}

// Capability with resource management
actor ResourceCapability: AxiomCapability {
    private(set) var currentState: CapabilityState = .unavailable
    private(set) var activeResources: Int = 0
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    func activate() async throws {
        currentState = .available
    }
    
    func deactivate() async {
        // Clean up resources
        activeResources = 0
        currentState = .unavailable
    }
    
    func allocateResources() {
        guard currentState == .available else { return }
        activeResources += 5
    }
}

// Observable capability with state stream
actor ObservableCapability: AxiomCapability {
    private(set) var currentState: CapabilityState = .unavailable
    private var continuation: AsyncStream<CapabilityState>.Continuation?
    
    var isAvailable: Bool {
        currentState == .available
    }
    
    var stateStream: AsyncStream<CapabilityState> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func activate() async throws {
        transitionTo(.available)
    }
    
    func deactivate() async {
        transitionTo(.unavailable)
        continuation?.finish()
    }
    
    func transitionTo(_ state: CapabilityState) {
        currentState = state
        continuation?.yield(state)
    }
}