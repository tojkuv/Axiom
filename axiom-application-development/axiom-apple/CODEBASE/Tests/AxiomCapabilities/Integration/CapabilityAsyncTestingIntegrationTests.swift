import XCTest
import AxiomCore
import AxiomCapabilities
import AxiomTesting

// Mock capability that simulates macro-generated code
actor MockNetworkCapability: ExtendedCapability {
    private var _state: CapabilityState = .unknown
    private var stateStreamContinuation: AsyncStream<CapabilityState>.Continuation?
    
    public var state: CapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<CapabilityState> {
        get async {
            AsyncStream { continuation in
                self.stateStreamContinuation = continuation
                continuation.yield(_state)
            }
        }
    }
    
    public var isAvailable: Bool {
        get async { await state == .available }
    }
    
    public func activate() async throws {
        await transitionTo(.initializing)
        try await Task.sleep(for: .milliseconds(50))
        await transitionTo(.available)
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    public func isSupported() async -> Bool {
        return true
    }
    
    public func requestPermission() async throws {
        // Network doesn't require permission
    }
    
    public var activationTimeout: Duration {
        get async { .milliseconds(10) }
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        // Store timeout if needed
    }
    
    private func transitionTo(_ newState: CapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
    
    // Domain-specific functionality
    func fetchData(from url: URL) async throws -> Data {
        guard await isAvailable else {
            throw CapabilityError.notAvailable
        }
        return Data("test data".utf8)
    }
}

// Mock context for testing
@MainActor
class MockTaskContext: ObservableObject {
    @Published var tasks: [String] = []
    @Published var isLoading = false
    
    func loadTasks() async {
        isLoading = true
        try? await Task.sleep(for: .milliseconds(100))
        isLoading = false
    }
    
    func addTask(_ task: String) async {
        tasks.append(task)
    }
}

final class CapabilityAsyncTestingIntegrationTests: XCTestCase {
    
    // Test 1: Verify capability works with CapabilityTestScenario
    func testCapabilityWithAsyncTestScenario() async throws {
        // Use async testing utilities to test the capability
        let scenario = CapabilityTestScenario(MockNetworkCapability.self)
        
        let result = try await scenario
            .when { capability in
                try await capability.activate()
            }
            .then { capability in
                await capability.state == AxiomCapabilityState.available
            }
        
        XCTAssertTrue(result)
    }
    
    // Test 2: Verify capability lifecycle testing with AsyncStreamTester
    func testCapabilityLifecycleWithAsyncStreamTester() async throws {
        let capability = MockNetworkCapability()
        let stream = await capability.stateStream
        let streamTester = AsyncStreamTester(stream)
        
        // Test state transitions in background
        Task {
            try await capability.activate()
            try await Task.sleep(for: .milliseconds(100))
            await capability.deactivate()
        }
        
        // Verify state stream emits correct sequence
        try await streamTester.expectValues([
            AxiomCapabilityState.unknown,
            AxiomCapabilityState.initializing,
            AxiomCapabilityState.available,
            AxiomCapabilityState.terminating,
            AxiomCapabilityState.unavailable
        ])
    }
    
    // Test 3: Verify context testing works with new utilities
    func testContextWithAsyncTestScenario() async throws {
        let scenario = ContextTestScenario(MockTaskContext.self)
        
        let result = try await scenario
            .when { context in
                await context.loadTasks()
            }
            .then { context in
                context.isLoading == false && context.tasks.isEmpty
            }
            .and { context in
                await context.addTask("Test Task")
            }
            .then { context in
                context.tasks.count == 1 && context.tasks.first == "Test Task"
            }
        
        XCTAssertTrue(result)
    }
    
    // Test 4: Verify parallel testing with timeout handling
    func testParallelCapabilityTesting() async throws {
        let cap1 = MockNetworkCapability()
        let cap2 = MockNetworkCapability()
        
        // Test both capabilities in parallel using expectAsync
        async let result1 = expectAsync(timeout: .seconds(2)) {
            try await cap1.activate()
            return await cap1.isAvailable
        }
        
        async let result2 = expectAsync(timeout: .seconds(2)) {
            try await cap2.activate()
            let data = try await cap2.fetchData(from: URL(string: "https://test.com")!)
            return data.count > 0
        }
        
        let results = try await (result1, result2)
        XCTAssertTrue(results.0)
        XCTAssertTrue(results.1)
    }
    
    // Test 5: Verify error handling in test scenarios
    func testErrorHandlingInTestScenarios() async throws {
        let scenario = CapabilityTestScenario(MockNetworkCapability.self)
        
        do {
            _ = try await scenario
                .when(timeout: .milliseconds(10)) { capability in
                    // This should timeout
                    try await Task.sleep(for: .seconds(1))
                }
                .then { _ in
                    false // Should not reach here
                }
            
            XCTFail("Expected timeout error")
        } catch AsyncTestError.timeout(_) {
            // Expected
        }
    }
}