import Testing
import AxiomTesting
@testable import AxiomApple

/// WORKER-05 TDD Tests for Timeout Management Features
/// Following RED→GREEN→REFACTOR cycles as per CB-SESSION-002
final class Worker05TimeoutManagementTests {
    
    // MARK: - Timeout Management Tests (REQUIREMENTS-W-05-001 Completion)
    
    @Test("Capability activation with custom timeout")
    func testCapabilityActivationWithCustomTimeout() async throws {
        let capability = DelayedTestCapability(activationDelay: .milliseconds(5))
        
        // Should succeed with sufficient timeout
        try await capability.activate(timeout: .milliseconds(20))
        let isAvailable = await capability.isAvailable
        #expect(isAvailable == true)
    }
    
    @Test("Capability activation timeout failure")
    func testCapabilityActivationTimeoutFailure() async throws {
        let capability = DelayedTestCapability(activationDelay: .milliseconds(50))
        
        // Should fail with insufficient timeout
        await #expect(throws: CapabilityError.self) {
            try await capability.activate(timeout: .milliseconds(10))
        }
    }
    
    @Test("Capability default timeout is 10ms")
    func testCapabilityDefaultTimeout() async throws {
        #expect(Capability.transitionTimeout == .milliseconds(10))
    }
    
    @Test("ExtendedCapability timeout configuration")
    func testExtendedCapabilityTimeoutConfiguration() async throws {
        let capability = ConfigurableTimeoutCapability()
        
        // Configure custom timeout
        await capability.setActivationTimeout(.milliseconds(25))
        let timeout = await capability.activationTimeout
        #expect(timeout == .milliseconds(25))
    }
    
    @Test("StandardCapability respects configured timeout")
    func testStandardCapabilityTimeoutConfiguration() async throws {
        let capability = DelayedStandardCapability(activationDelay: .milliseconds(15))
        
        // Configure timeout
        await capability.setActivationTimeout(.milliseconds(30))
        
        // Should succeed with configured timeout
        try await capability.activate()
        let isAvailable = await capability.isAvailable
        #expect(isAvailable == true)
    }
    
    @Test("Timeout error provides clear messaging")
    func testTimeoutErrorMessaging() async throws {
        let capability = DelayedTestCapability(activationDelay: .milliseconds(100))
        
        do {
            try await capability.activate(timeout: .milliseconds(5))
            #expect(Bool(false), "Should have thrown timeout error")
        } catch let error as CapabilityError {
            if case .initializationFailed(let message) = error {
                #expect(message.contains("timed out"))
                #expect(message.contains("5"))
            } else {
                #expect(Bool(false), "Wrong error type")
            }
        }
    }
    
    @Test("Concurrent activation attempts with timeout")
    func testConcurrentActivationWithTimeout() async throws {
        let capability = DelayedTestCapability(activationDelay: .milliseconds(8))
        
        // Start multiple activation attempts
        async let result1: () = capability.activate(timeout: .milliseconds(15))
        async let result2: () = capability.activate(timeout: .milliseconds(15))
        async let result3: () = capability.activate(timeout: .milliseconds(15))
        
        // All should complete successfully (or be ignored if already activating)
        try await result1
        try await result2  
        try await result3
        
        let isAvailable = await capability.isAvailable
        #expect(isAvailable == true)
    }
}

// MARK: - Test Support Types for Timeout Management

/// Test capability that simulates activation delays
actor DelayedTestCapability: Capability {
    private var _isAvailable: Bool = false
    private let activationDelay: Duration
    private var activationTask: Task<Void, Error>?
    
    init(activationDelay: Duration) {
        self.activationDelay = activationDelay
    }
    
    var isAvailable: Bool {
        get async { _isAvailable }
    }
    
    func activate() async throws {
        // Prevent concurrent activation
        guard activationTask == nil else { return }
        
        activationTask = Task {
            try await Task.sleep(for: activationDelay)
            _isAvailable = true
        }
        
        try await activationTask?.value
    }
    
    func deactivate() async {
        activationTask?.cancel()
        activationTask = nil
        _isAvailable = false
    }
}

/// Test capability with configurable timeout
actor ConfigurableTimeoutCapability: ExtendedCapability {
    private var _isAvailable: Bool = false
    private var _state: CapabilityState = .unknown
    private var _activationTimeout: Duration = .milliseconds(10)
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
    
    var activationTimeout: Duration {
        get async { _activationTimeout }
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
    
    func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
}

/// Test implementation of StandardCapability with delayed activation
actor DelayedStandardCapability: StandardCapability {
    private let activationDelay: Duration
    
    init(activationDelay: Duration) {
        self.activationDelay = activationDelay
        super.init()
    }
    
    override func activate() async throws {
        try await Task.sleep(for: activationDelay)
        try await super.activate()
    }
}