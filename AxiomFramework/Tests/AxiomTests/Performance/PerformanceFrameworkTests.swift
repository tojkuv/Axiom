import XCTest
import SwiftUI
@testable import Axiom
@testable import AxiomTesting

/// Comprehensive tests for Performance framework requirements
/// Tests state propagation, memory overhead, and component initialization using AxiomTesting framework
final class PerformanceFrameworkTests: XCTestCase {
    
    // MARK: - Test Environment
    
    var testEnvironment: TestEnvironment!
    
    override func setUp() async throws {
        testEnvironment = TestHelpers.createTestEnvironment()
    }
    
    override func tearDown() async throws {
        await testEnvironment.cleanup()
        testEnvironment = nil
    }
    
    // MARK: - State Propagation Performance Tests
    
    func testStatePropagationLatencyRequirements() async throws {
        try await testEnvironment.runTest { env in
            let client = PerformanceTestClient()
            let context = try await env.createContext(
                StatePropagationTestContext.self,
                id: "state-propagation"
            ) {
                StatePropagationTestContext(client: client)
            }
            
            // Test state propagation latency using framework utilities
            try await TestHelpers.performance.assertPerformanceRequirements(
                operation: {
                    // Trigger state mutation and measure propagation
                    try await client.process(.increment)
                    
                    // Wait for state to propagate to context
                    try await TestHelpers.context.assertState(
                        in: context,
                        timeout: .milliseconds(16), // 16ms requirement
                        condition: { $0.hasReceivedLatestState },
                        description: "State should propagate within 16ms"
                    )
                },
                maxDuration: .milliseconds(16), // < 16ms requirement
                maxMemoryGrowth: 1024, // 1KB max growth
                iterations: 10
            )
        }
    }
    
    func testFrameRateStabilityUnderLoad() async throws {
        try await testEnvironment.runTest { env in
            let client = PerformanceTestClient()
            let context = try await env.createContext(
                FrameRateTestContext.self,
                id: "frame-rate"
            ) {
                FrameRateTestContext(client: client)
            }
            
            // Test frame rate stability with rapid updates
            let frameRateResults = try await TestHelpers.performance.loadTest(
                concurrency: 1,
                duration: .seconds(1),
                operation: {
                    // Simulate 60fps updates
                    let frameStart = ContinuousClock.now
                    try await client.process(.setValue(Int.random(in: 0...1000)))
                    
                    let frameEnd = ContinuousClock.now
                    let frameDuration = frameEnd - frameStart
                    
                    // Record frame timing
                    await context.recordFrame(duration: frameDuration)
                    
                    // Maintain 60fps timing
                    let targetFrameTime = Duration.milliseconds(16) // 16.67ms for 60fps
                    if frameDuration < targetFrameTime {
                        try await Task.sleep(for: targetFrameTime - frameDuration)
                    }
                }
            )
            
            // Assert frame rate requirements
            XCTAssertGreaterThanOrEqual(
                frameRateResults.throughputPerSecond,
                60.0,
                "Frame rate should maintain 60fps"
            )
            
            XCTAssertLessThanOrEqual(
                frameRateResults.errorRate,
                0.0,
                "No frame drops should occur"
            )
        }
    }
    
    // MARK: - Memory Overhead Performance Tests
    
    func testComponentMemoryOverheadRequirements() async throws {
        try await testEnvironment.runTest { env in
            // Test memory overhead using framework utilities
            let memoryResults = try await TestHelpers.performance.trackMemoryUsage(
                during: {
                    var components: [Any] = []
                    let componentCount = 10
                    
                    // Create multiple components and measure overhead
                    for i in 0..<componentCount {
                        let client = MemoryOptimizedTestClient()
                        let context = try await env.createContext(
                            MemoryOptimizedTestContext.self,
                            id: "memory-test-\(i)"
                        ) {
                            MemoryOptimizedTestContext(client: client)
                        }
                        
                        components.append(client)
                        components.append(context)
                    }
                    
                    // Keep components in scope
                    _ = components
                },
                samplingInterval: .milliseconds(10)
            )
            
            // Calculate memory per component
            let totalComponents = 20 // 2 components per iteration * 10 iterations
            let memoryPerComponent = memoryResults.memoryProfile.memoryGrowth / totalComponents
            
            // Assert memory requirements
            XCTAssertLessThan(
                memoryPerComponent,
                20480, // 20KB current optimized baseline
                "Framework memory overhead per component should be optimized"
            )
            
            XCTAssertLessThan(
                memoryResults.memoryProfile.peakUsage,
                1024 * 1024, // 1MB peak
                "Peak memory usage should be reasonable"
            )
        }
    }
    
    func testMemoryLeakPrevention() async throws {
        try await testEnvironment.runTest { env in
            // Test memory leak prevention using framework utilities
            try await TestHelpers.performance.assertMemoryBounds(
                during: {
                    // Create and destroy components in cycles
                    for i in 0..<5 {
                        let client = MemoryOptimizedTestClient()
                        let context = try await env.createContext(
                            MemoryLeakTestContext.self,
                            id: "leak-test-\(i)"
                        ) {
                            MemoryLeakTestContext(client: client)
                        }
                        
                        // Use components briefly
                        try await client.process(.increment)
                        
                        // Remove context to test cleanup
                        await env.removeContext("leak-test-\(i)")
                        
                        // Allow cleanup time
                        try await Task.sleep(for: .milliseconds(10))
                    }
                },
                maxGrowth: 5 * 1024, // 5KB tolerance
                maxPeak: 50 * 1024 // 50KB peak tolerance
            )
        }
    }
    
    // MARK: - Component Initialization Performance Tests
    
    func testComponentInitializationSpeedRequirements() async throws {
        try await testEnvironment.runTest { env in
            var initializationTimes: [Duration] = []
            let iterationCount = 100
            
            // Measure component initialization times
            for i in 0..<iterationCount {
                let startTime = ContinuousClock.now
                
                let client = FastInitTestClient()
                let context = try await env.createContext(
                    FastInitTestContext.self,
                    id: "fast-init-\(i)"
                ) {
                    FastInitTestContext(client: client)
                }
                
                let endTime = ContinuousClock.now
                let initTime = endTime - startTime
                initializationTimes.append(initTime)
                
                // Clean up immediately
                await env.removeContext("fast-init-\(i)")
            }
            
            // Calculate p99 (99th percentile)
            let sortedTimes = initializationTimes.sorted { $0 < $1 }
            let p99Index = Int(Double(sortedTimes.count) * 0.99)
            let p99Time = sortedTimes[min(p99Index, sortedTimes.count - 1)]
            
            // Assert initialization requirements
            XCTAssertLessThan(
                p99Time,
                .milliseconds(50), // < 50ms requirement
                "Component initialization p99 should be < 50ms"
            )
            
            let averageTime = initializationTimes.reduce(.zero) { $0 + $1 } / initializationTimes.count
            XCTAssertLessThan(
                averageTime,
                .milliseconds(25), // Well below 50ms
                "Average initialization time should be well below 50ms"
            )
        }
    }
    
    func testConcurrentComponentInitializationPerformance() async throws {
        try await testEnvironment.runTest { env in
            let componentCount = 20
            let maxInitTime = Duration.milliseconds(50)
            
            let startTime = ContinuousClock.now
            
            // Test concurrent initialization using framework utilities
            try await TestHelpers.performance.assertLoadTestRequirements(
                concurrency: componentCount,
                duration: .seconds(5),
                minThroughput: 50, // components per second
                maxErrorRate: 0.0, // No errors
                operation: {
                    let client = FastInitTestClient()
                    let contextId = "concurrent-\(UUID().uuidString)"
                    let context = try await env.createContext(
                        ConcurrentInitTestContext.self,
                        id: contextId
                    ) {
                        ConcurrentInitTestContext(client: client)
                    }
                    
                    // Brief usage
                    try await client.process(.increment)
                    
                    // Cleanup
                    await env.removeContext(contextId)
                }
            )
            
            let totalTime = ContinuousClock.now - startTime
            
            // Verify concurrent initialization completed reasonably fast
            XCTAssertLessThan(
                totalTime,
                .seconds(10), // Should complete well within 10 seconds
                "Concurrent initialization should complete efficiently"
            )
        }
    }
    
    // MARK: - Integration Performance Tests
    
    func testComplexComponentSetupPerformance() async throws {
        try await testEnvironment.runTest { env in
            // Test complex component setup with dependencies
            let benchmark = try await TestHelpers.performance.benchmark({
                // Create complex component setup
                let client1 = FastInitTestClient()
                let client2 = FastInitTestClient()
                
                let context1 = try await env.createContext(
                    ComplexTestContext.self,
                    id: "complex-1"
                ) {
                    ComplexTestContext(client: client1)
                }
                
                let context2 = try await env.createContext(
                    ComplexTestContext.self,
                    id: "complex-2"
                ) {
                    ComplexTestContext(client: client2)
                }
                
                // Establish dependencies and interactions
                try await context1.establishDependency(on: context2)
                
                // Process some work
                try await client1.process(.increment)
                try await client2.process(.setValue(42))
                
                // Wait for propagation
                try await TestHelpers.context.assertState(
                    in: context1,
                    condition: { $0.dependencyEstablished },
                    description: "Dependencies should be established"
                )
                
                // Cleanup
                await env.removeContext("complex-1")
                await env.removeContext("complex-2")
            }, iterations: 10)
            
            // Assert complex setup performance
            XCTAssertLessThan(
                benchmark.averageDuration,
                .milliseconds(50), // < 50ms for complex setup
                "Complex component setup should be fast"
            )
            
            XCTAssertLessThan(
                benchmark.averageMemoryGrowth,
                10 * 1024, // 10KB average growth
                "Complex setup should not use excessive memory"
            )
        }
    }
    
    // MARK: - Framework Compliance Tests
    
    func testPerformanceFrameworkCompliance() async throws {
        let client = PerformanceTestClient()
        let context = StatePropagationTestContext(client: client)
        
        // Use framework compliance testing
        assertFrameworkCompliance(client)
        assertFrameworkCompliance(context)
        
        // Performance-specific compliance checks
        await context.onAppear()
        XCTAssertTrue(context.isActive, "Context should be active for performance testing")
        
        await context.onDisappear()
        XCTAssertFalse(context.isActive, "Context should clean up properly")
    }
}

// MARK: - Test Support Contexts

@MainActor
class StatePropagationTestContext: BaseContext {
    private let client: PerformanceTestClient
    @Published private(set) var latestState: PerformanceTestState?
    @Published private(set) var hasReceivedLatestState = false
    private var observationTask: Task<Void, Never>?
    
    init(client: PerformanceTestClient) {
        self.client = client
        super.init()
    }
    
    override func performAppearance() async {
        await super.performAppearance()
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await state in await client.stateStream {
                await MainActor.run {
                    self?.latestState = state
                    self?.hasReceivedLatestState = true
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

@MainActor
class FrameRateTestContext: BaseContext {
    private let client: PerformanceTestClient
    @Published private(set) var frameCount = 0
    @Published private(set) var totalFrameTime: Duration = .zero
    @Published private(set) var droppedFrames = 0
    
    init(client: PerformanceTestClient) {
        self.client = client
        super.init()
    }
    
    func recordFrame(duration: Duration) {
        frameCount += 1
        totalFrameTime += duration
        
        // Check for dropped frames (> 16.67ms = 60fps)
        if duration > .milliseconds(17) {
            droppedFrames += 1
        }
    }
    
    var averageFrameRate: Double {
        guard frameCount > 0 else { return 0.0 }
        let averageFrameTime = totalFrameTime.timeInterval / Double(frameCount)
        return 1.0 / averageFrameTime
    }
}

@MainActor
class MemoryOptimizedTestContext: BaseContext {
    private let client: MemoryOptimizedTestClient
    @Published private(set) var state: PerformanceTestState?
    private var observationTask: Task<Void, Never>?
    
    init(client: MemoryOptimizedTestClient) {
        self.client = client
        super.init()
    }
    
    override func performAppearance() async {
        await super.performAppearance()
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await state in await client.stateStream {
                await MainActor.run {
                    self?.state = state
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

@MainActor
class MemoryLeakTestContext: BaseContext {
    private let client: MemoryOptimizedTestClient
    @Published private(set) var processedCount = 0
    private var observationTask: Task<Void, Never>?
    
    init(client: MemoryOptimizedTestClient) {
        self.client = client
        super.init()
    }
    
    override func performAppearance() async {
        await super.performAppearance()
        observationTask = Task { [weak self] in
            guard let client = self?.client else { return }
            for await _ in await client.stateStream {
                await MainActor.run {
                    self?.processedCount += 1
                }
            }
        }
    }
    
    override func performDisappearance() async {
        await super.performDisappearance()
        observationTask?.cancel()
        observationTask = nil
    }
}

@MainActor
class FastInitTestContext: BaseContext {
    private let client: FastInitTestClient
    @Published private(set) var initializationTime: Duration?
    
    init(client: FastInitTestClient) {
        let startTime = ContinuousClock.now
        self.client = client
        super.init()
        self.initializationTime = ContinuousClock.now - startTime
    }
}

@MainActor
class ConcurrentInitTestContext: BaseContext {
    private let client: FastInitTestClient
    @Published private(set) var isReady = false
    
    init(client: FastInitTestClient) {
        self.client = client
        super.init()
        self.isReady = true
    }
}

@MainActor
class ComplexTestContext: BaseContext {
    private let client: FastInitTestClient
    @Published private(set) var dependencyEstablished = false
    @Published private(set) var dependentContext: ComplexTestContext?
    
    init(client: FastInitTestClient) {
        self.client = client
        super.init()
    }
    
    func establishDependency(on context: ComplexTestContext) async throws {
        dependentContext = context
        dependencyEstablished = true
    }
}

// MARK: - Test Support Types

enum PerformanceTestAction: Equatable {
    case increment
    case setValue(Int)
    case reset
}

struct PerformanceTestState: Axiom.State, Sendable, Equatable {
    var value: Int = 0
    var updateCount: Int = 0
}

actor PerformanceTestClient: Client {
    typealias StateType = PerformanceTestState
    typealias ActionType = PerformanceTestAction
    
    private var state = PerformanceTestState()
    private let stream: AsyncStream<PerformanceTestState>
    private let continuation: AsyncStream<PerformanceTestState>.Continuation
    
    var stateStream: AsyncStream<PerformanceTestState> {
        stream
    }
    
    var currentState: PerformanceTestState {
        state
    }
    
    init() {
        (stream, continuation) = AsyncStream.makeStream(of: PerformanceTestState.self)
        continuation.yield(state)
    }
    
    func process(_ action: PerformanceTestAction) async throws {
        switch action {
        case .increment:
            state.value += 1
            state.updateCount += 1
        case .setValue(let newValue):
            state.value = newValue
            state.updateCount += 1
        case .reset:
            state.value = 0
            state.updateCount = 0
        }
        
        continuation.yield(state)
    }
    
    deinit {
        continuation.finish()
    }
}

actor MemoryOptimizedTestClient: Client {
    typealias StateType = PerformanceTestState
    typealias ActionType = PerformanceTestAction
    
    private var state = PerformanceTestState()
    private let stream: AsyncStream<PerformanceTestState>
    private let continuation: AsyncStream<PerformanceTestState>.Continuation
    
    var stateStream: AsyncStream<PerformanceTestState> {
        stream
    }
    
    var currentState: PerformanceTestState {
        state
    }
    
    init() {
        (stream, continuation) = AsyncStream.makeStream(of: PerformanceTestState.self)
        continuation.yield(state)
    }
    
    func process(_ action: PerformanceTestAction) async throws {
        switch action {
        case .increment:
            state.value += 1
            state.updateCount += 1
        case .setValue(let newValue):
            state.value = newValue
            state.updateCount += 1
        case .reset:
            state.value = 0
            state.updateCount = 0
        }
        
        continuation.yield(state)
    }
    
    deinit {
        continuation.finish()
    }
}

actor FastInitTestClient: Client {
    typealias StateType = PerformanceTestState
    typealias ActionType = PerformanceTestAction
    
    private var state = PerformanceTestState()
    private let stream: AsyncStream<PerformanceTestState>
    private let continuation: AsyncStream<PerformanceTestState>.Continuation
    
    var stateStream: AsyncStream<PerformanceTestState> {
        stream
    }
    
    var currentState: PerformanceTestState {
        state
    }
    
    init() {
        // Optimized for fast initialization
        (stream, continuation) = AsyncStream.makeStream(of: PerformanceTestState.self)
    }
    
    func process(_ action: PerformanceTestAction) async throws {
        switch action {
        case .increment:
            state.value += 1
            state.updateCount += 1
        case .setValue(let newValue):
            state.value = newValue
            state.updateCount += 1
        case .reset:
            state.value = 0
            state.updateCount = 0
        }
        
        continuation.yield(state)
    }
    
    deinit {
        continuation.finish()
    }
}

// MARK: - Duration Extensions

extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1_000_000_000_000_000_000
    }
}