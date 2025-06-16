import Testing
import AxiomTesting
@testable import AxiomApple

/// WORKER-05 TDD Tests for Capability Protocol Framework
/// Following RED→GREEN→REFACTOR cycles as per CB-SESSION-001
final class Worker05CapabilityFrameworkTests {
    
    // MARK: - Core Capability Protocol Tests (REQUIREMENTS-W-05-001)
    
    @Test("Capability activation and availability check")
    func testCapabilityActivationAndAvailability() async throws {
        let capability = TestCapability()
        
        // Initially not available
        let initialAvailability = await capability.isAvailable
        #expect(initialAvailability == false)
        
        // After activation should be available
        try await capability.activate()
        let finalAvailability = await capability.isAvailable
        #expect(finalAvailability == true)
    }
    
    @Test("Capability state transitions under 10ms")
    func testCapabilityStateTransitionTiming() async throws {
        let capability = StandardCapability()
        
        let startTime = ContinuousClock.now
        
        // Test state transitions
        try await capability.activate()
        await capability.transitionTo(.restricted)
        await capability.transitionTo(.available)
        await capability.deactivate()
        
        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .milliseconds(10))
    }
    
    @Test("Extended capability state observation")
    func testExtendedCapabilityStateObservation() async throws {
        let capability = ObservableTestCapability()
        var observedStates: [CapabilityState] = []
        
        let task = Task {
            for await state in await capability.stateStream {
                observedStates.append(state)
                if observedStates.count >= 3 { break }
            }
        }
        
        try await capability.activate()
        await capability.transitionTo(.restricted)
        await capability.deactivate()
        
        await task.value
        #expect(observedStates == [.available, .restricted, .unavailable])
    }
    
    @Test("Capability error handling")
    func testCapabilityErrorHandling() async throws {
        let capability = FailingTestCapability()
        
        await #expect(throws: CapabilityError.self) {
            try await capability.activate()
        }
        
        let isAvailable = await capability.isAvailable
        #expect(isAvailable == false)
    }
    
    @Test("Capability manager registration and lifecycle")
    func testCapabilityManagerLifecycle() async throws {
        let manager = DefaultCapabilityManager()
        let capability1 = TestCapability()
        let capability2 = TestCapability()
        
        // Register capabilities
        await manager.register(capability1, for: "test1")
        await manager.register(capability2, for: "test2")
        
        // Initialize all
        await manager.initializeAll()
        
        // Verify activation
        let retrieved1 = await manager.capability(for: "test1", as: TestCapability.self)
        let retrieved2 = await manager.capability(for: "test2", as: TestCapability.self)
        
        let available1 = await retrieved1?.isAvailable ?? false
        let available2 = await retrieved2?.isAvailable ?? false
        
        #expect(available1 == true)
        #expect(available2 == true)
        
        // Terminate all
        await manager.terminateAll()
        
        let finalAvailable1 = await retrieved1?.isAvailable ?? true
        let finalAvailable2 = await retrieved2?.isAvailable ?? true
        
        #expect(finalAvailable1 == false)
        #expect(finalAvailable2 == false)
    }
}

// MARK: - Test Support Types

/// Test capability for basic lifecycle testing
actor TestCapability: AxiomCapability {
    private var _isAvailable: Bool = false
    
    var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    func activate() async throws {
        _isAvailable = true
    }
    
    func deactivate() async {
        _isAvailable = false
    }
}

/// Test capability that demonstrates state observation
actor ObservableTestCapability: AxiomExtendedCapability {
    private var _state: CapabilityState = .unknown
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    var isAvailable: Bool {
        get async { _state == .available }
    }
    
    var state: CapabilityState {
        get async { _state }
    }
    
    var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                Task {
                    await setStreamContinuation(continuation)
                    continuation.yield(await _state)
                }
            }
        }
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<CapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    func activate() async throws {
        await transitionTo(.available)
    }
    
    func deactivate() async {
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    func isSupported() async -> Bool {
        return true
    }
    
    func requestPermission() async throws {
        // Test implementation - always grants permission
    }
}

/// Test capability that fails activation
actor FailingTestCapability: AxiomCapability {
    private var _isAvailable: Bool = false
    
    var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    func activate() async throws {
        throw CapabilityError.initializationFailed("Test failure")
    }
    
    func deactivate() async {
        _isAvailable = false
    }
}