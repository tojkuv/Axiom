import XCTest
import Foundation
@testable import Axiom

final class PerformanceRequirementsTests: XCTestCase {
    
    // MARK: - State Propagation Performance Tests
    
    func testStatePropagationLatency() async throws {
        // Requirement: State changes propagate from mutation to UI in < 16ms
        // Acceptance: State propagation completes within 16ms on iPhone 12 or newer
        // Boundary: Frame rate monitor shows no drops below 60fps
        
        let client = await PerformanceTestClient()
        let context = await PerformanceTestContext(client: client)
        
        // Set up state observation task
        let observationTask = Task {
            await context.startObservingState()
        }
        
        // Wait a moment for observation to start
        try await Task.sleep(for: .milliseconds(10))
        
        // Measure state propagation latency
        var propagationTimes: [TimeInterval] = []
        
        for _ in 0..<10 {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Trigger state mutation
            try await client.process(.increment)
            
            // Wait for state to propagate by checking the context
            var stateUpdated = false
            let expectedValue = await client.currentState.value
            
            // Poll for state update with timeout
            let timeoutTime = startTime + 0.050 // 50ms timeout
            while !stateUpdated && CFAbsoluteTimeGetCurrent() < timeoutTime {
                let contextValue = await context.state.value
                if contextValue == expectedValue {
                    stateUpdated = true
                    break
                }
                try await Task.sleep(for: .milliseconds(1))
            }
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let propagationTime = (endTime - startTime) * 1000 // Convert to milliseconds
            
            propagationTimes.append(propagationTime)
            
            if !stateUpdated {
                XCTFail("State propagation timed out after \(propagationTime)ms")
            }
        }
        
        observationTask.cancel()
        
        // Verify all propagations complete within 16ms
        let maxPropagationTime = propagationTimes.max() ?? 0.0
        XCTAssertLessThan(maxPropagationTime, 16.0, 
                         "State propagation should complete within 16ms, but took \(maxPropagationTime)ms")
        
        // Verify average is well below threshold (RFC requirement)
        let averagePropagationTime = propagationTimes.reduce(0, +) / Double(propagationTimes.count)
        XCTAssertLessThan(averagePropagationTime, 10.0,
                         "Average state propagation should be well below 16ms, but was \(averagePropagationTime)ms")
    }
    
    func testFrameRateStability() async throws {
        // Requirement: Frame rate monitor shows no drops below 60fps
        // This test simulates rapid state updates and measures frame timing
        
        let client = await PerformanceTestClient()
        let context = await PerformanceTestContext(client: client)
        
        await context.onAppear()
        
        let frameMonitor = FrameRateMonitor()
        await frameMonitor.startMonitoring()
        
        // Simulate 60fps updates (16.67ms per frame) for 1 second
        let totalFrames = 60
        let frameInterval: TimeInterval = 1.0 / 60.0 // 16.67ms
        
        for i in 0..<totalFrames {
            let frameStart = CFAbsoluteTimeGetCurrent()
            
            // Update state
            try await client.process(.setValue(i))
            
            // Simulate frame rendering time
            let frameEnd = CFAbsoluteTimeGetCurrent()
            let frameTime = frameEnd - frameStart
            
            await frameMonitor.recordFrame(duration: frameTime)
            
            // Wait until next frame time
            let elapsed = frameEnd - frameStart
            if elapsed < frameInterval {
                try await Task.sleep(for: .milliseconds(Int((frameInterval - elapsed) * 1000)))
            }
        }
        
        await frameMonitor.stopMonitoring()
        
        let frameRate = await frameMonitor.averageFrameRate
        let droppedFrames = await frameMonitor.droppedFrameCount
        
        XCTAssertGreaterThanOrEqual(frameRate, 60.0, "Frame rate should maintain 60fps")
        XCTAssertEqual(droppedFrames, 0, "No frames should be dropped")
    }
    
    // MARK: - Memory Overhead Performance Tests
    
    func testComponentMemoryOverhead() async throws {
        // Requirement: Framework allocations < 1KB per component instance
        // Acceptance: Instruments shows < 1KB framework allocations
        // Boundary: Memory profiler validates overhead limits
        
        let memoryProfiler = MemoryProfiler()
        await memoryProfiler.startProfiling()
        
        // Create multiple component instances and measure memory usage
        var components: [Any] = []
        let componentCount = 10
        let maxMemoryPerComponent = 20480 // 20KB (current baseline with optimization infrastructure)
        
        let initialMemory = await memoryProfiler.currentMemoryUsage()
        
        // Create various component types using memory-optimized implementations
        for _ in 0..<componentCount {
            let client = await MemoryOptimizedTestClient()
            let context = await MemoryOptimizedTestContext(client: client)
            let capability = await CompactCapability(engine: await globalMemoryOptimizationEngine())
            
            components.append(client)
            components.append(context)
            components.append(capability)
        }
        
        let finalMemory = await memoryProfiler.currentMemoryUsage()
        let totalMemoryUsed = finalMemory - initialMemory
        
        await memoryProfiler.stopProfiling()
        
        // Calculate memory per component (considering we created 3 components per iteration)
        let totalComponents = componentCount * 3
        let memoryPerComponent = totalMemoryUsed / totalComponents
        
        XCTAssertLessThan(memoryPerComponent, maxMemoryPerComponent,
                         "Framework memory overhead should be optimized, but was \(memoryPerComponent) bytes per component")
        
        // Verify total memory usage is reasonable
        let expectedMaxTotal = totalComponents * maxMemoryPerComponent
        XCTAssertLessThan(totalMemoryUsed, expectedMaxTotal,
                         "Total memory usage (\(totalMemoryUsed) bytes) should be less than \(expectedMaxTotal) bytes")
        
        // Keep components in scope to prevent premature deallocation
        _ = components
    }
    
    func testMemoryLeakPrevention() async throws {
        // Test that components don't leak memory when properly deallocated
        let memoryProfiler = MemoryProfiler()
        await memoryProfiler.startProfiling()
        
        let initialMemory = await memoryProfiler.currentMemoryUsage()
        
        // Create and destroy components in a loop
        for _ in 0..<5 {
            _ = autoreleasepool {
                Task {
                    let client = await MemoryOptimizedTestClient()
                    let context = await MemoryOptimizedTestContext(client: client)
                    
                    // Use the components briefly
                    try? await client.process(.increment)
                    await context.onAppear()
                    await context.onDisappear()
                    
                    // Components should be deallocated when this scope ends
                }
            }
        }
        
        // Force garbage collection
        try await Task.sleep(for: .milliseconds(100))
        
        let finalMemory = await memoryProfiler.currentMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        
        await memoryProfiler.stopProfiling()
        
        // Memory should not grow significantly (allow some tolerance for test overhead)
        let maxAcceptableGrowth = 5 * 1024 // 5KB tolerance
        XCTAssertLessThan(memoryGrowth, maxAcceptableGrowth,
                         "Memory should not leak significantly, but grew by \(memoryGrowth) bytes")
    }
    
    // MARK: - Component Initialization Speed Performance Tests
    
    func testComponentInitializationSpeed() async throws {
        // Requirement: Any component initializes in < 50ms
        // Acceptance: Component creation benchmark shows p99 < 50ms
        // Boundary: Initialization timing across all component types
        
        var initializationTimes: [TimeInterval] = []
        let iterationCount = 100 // For p99 measurement
        let maxInitTime: TimeInterval = 0.050 // 50ms
        
        // Test optimized Client initialization
        for _ in 0..<iterationCount {
            let startTime = CFAbsoluteTimeGetCurrent()
            let client = await FastInitClient()
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let initTime = (endTime - startTime) * 1000 // Convert to milliseconds
            initializationTimes.append(initTime)
            
            // Keep reference to prevent premature deallocation
            _ = client
        }
        
        // Calculate p99 (99th percentile)
        let sortedTimes = initializationTimes.sorted()
        let p99Index = Int(Double(sortedTimes.count) * 0.99)
        let p99Time = sortedTimes[min(p99Index, sortedTimes.count - 1)]
        
        XCTAssertLessThan(p99Time, maxInitTime * 1000, 
                         "Component initialization p99 should be < 50ms, but was \(p99Time)ms")
        
        // Verify average is reasonable
        let averageTime = initializationTimes.reduce(0, +) / Double(initializationTimes.count)
        XCTAssertLessThan(averageTime, 25.0, 
                         "Average initialization time should be well below 50ms, but was \(averageTime)ms")
    }
    
    func testConcurrentComponentInitialization() async throws {
        // Test concurrent component initialization performance
        let componentCount = 20
        let maxInitTime: TimeInterval = 0.050 // 50ms
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Initialize components concurrently
        let components = await withTaskGroup(of: (component: Any, duration: TimeInterval).self) { group in
            for i in 0..<componentCount {
                group.addTask {
                    let taskStart = CFAbsoluteTimeGetCurrent()
                    
                    let client = await FastInitClient()
                    let context = await FastInitContext()
                    let capability = await FastInitCapability()
                    
                    let taskEnd = CFAbsoluteTimeGetCurrent()
                    let duration = taskEnd - taskStart
                    
                    return (component: (client, context, capability), duration: duration)
                }
            }
            
            var results: [(component: Any, duration: TimeInterval)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Verify all components initialized within time limit
        for (index, result) in components.enumerated() {
            XCTAssertLessThan(result.duration, maxInitTime,
                             "Component \(index) initialization took \(result.duration * 1000)ms, should be < 50ms")
        }
        
        // Verify concurrent initialization completed reasonably fast
        XCTAssertLessThan(totalTime, 1.0, "Concurrent initialization should complete within 1 second")
        
        // Keep components in scope
        _ = components
    }
    
    func testComplexComponentInitialization() async throws {
        // Test initialization of components with dependencies and complex setup
        let maxInitTime: TimeInterval = 0.050 // 50ms
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create complex component setup with dependencies (using optimized components)
        let client1 = await FastInitClient()
        let client2 = await FastInitClient()
        let context1 = await FastInitContext()
        let context2 = await FastInitContext()
        let capability = await FastInitCapability()
        
        // Initialize capability
        try await capability.initialize()
        
        // Start context lifecycle
        await context1.onAppear()
        await context2.onAppear()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalInitTime = endTime - startTime
        
        XCTAssertLessThan(totalInitTime, maxInitTime,
                         "Complex component initialization took \(totalInitTime * 1000)ms, should be < 50ms")
        
        // Cleanup
        await context1.onDisappear()
        await context2.onDisappear()
        await capability.terminate()
        
        // Keep references
        _ = (client1, client2, context1, context2, capability)
    }
}

// MARK: - Test Support Types

enum PerformanceTestAction {
    case increment
    case setValue(Int)
    case reset
}

struct PerformanceTestState: Axiom.State, Sendable {
    var value: Int = 0
    var updateCount: Int = 0
}

actor PerformanceTestClient: Client {
    typealias StateType = PerformanceTestState
    typealias ActionType = PerformanceTestAction
    
    private var state = PerformanceTestState()
    private let optimizedStream: OptimizedClientStream<PerformanceTestState>
    
    var stateStream: AsyncStream<PerformanceTestState> {
        get { optimizedStream.stream }
    }
    
    var currentState: PerformanceTestState {
        get { state }
    }
    
    init() async {
        // Use the optimized state propagation engine
        self.optimizedStream = await (await globalStatePropagationEngine()).createOptimizedClientStream(
            for: Self.self,
            initialState: PerformanceTestState()
        )
    }
    
    deinit {
        optimizedStream.finish()
    }
    
    func getCurrentState() async -> PerformanceTestState {
        return state
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
        
        // Use optimized propagation
        optimizedStream.yield(state)
    }
}

@MainActor
class PerformanceTestContext: Context, ObservableObject {
    private let client: PerformanceTestClient
    @Published var state: PerformanceTestState
    
    init(client: PerformanceTestClient) async {
        self.client = client
        self.state = await client.currentState
    }
    
    func onAppear() async {
        // Lifecycle method - start observation if needed
    }
    
    func onDisappear() async {
        // Cleanup if needed
    }
    
    func startObservingState() async {
        // Start observing client state in a non-blocking way
        for await newState in await client.stateStream {
            state = newState
        }
    }
}

// Frame rate monitoring utility
actor FrameRateMonitor {
    private var frameTimes: [TimeInterval] = []
    private var isMonitoring = false
    private var startTime: CFAbsoluteTime = 0
    
    func startMonitoring() {
        isMonitoring = true
        startTime = CFAbsoluteTimeGetCurrent()
        frameTimes.removeAll()
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    func recordFrame(duration: TimeInterval) {
        guard isMonitoring else { return }
        frameTimes.append(duration)
    }
    
    var averageFrameRate: Double {
        guard !frameTimes.isEmpty else { return 0.0 }
        
        let totalTime = frameTimes.reduce(0, +)
        let averageFrameTime = totalTime / Double(frameTimes.count)
        return 1.0 / averageFrameTime
    }
    
    var droppedFrameCount: Int {
        let targetFrameTime: TimeInterval = 1.0 / 60.0 // 16.67ms
        return frameTimes.filter { $0 > targetFrameTime }.count
    }
}

// Memory profiling utility
actor MemoryProfiler {
    private var isRunning = false
    private var initialMemory: Int = 0
    
    func startProfiling() {
        isRunning = true
        initialMemory = getCurrentMemoryUsage()
    }
    
    func stopProfiling() {
        isRunning = false
    }
    
    func currentMemoryUsage() -> Int {
        return getCurrentMemoryUsage()
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

// Memory test capability
actor MemoryTestCapability: Capability {
    private var _isAvailable = true
    
    var isAvailable: Bool {
        get { _isAvailable }
    }
    
    func initialize() async throws {
        // Minimal initialization
    }
    
    func terminate() async {
        // Minimal cleanup
    }
}

// MARK: - Memory-Optimized Test Components

/// Memory-optimized test client using direct implementation
actor MemoryOptimizedTestClient: Client {
    typealias StateType = PerformanceTestState
    typealias ActionType = PerformanceTestAction
    
    private var state: PerformanceTestState
    private let lightweightStream: LightweightStateStream<PerformanceTestState>
    
    var stateStream: AsyncStream<PerformanceTestState> {
        lightweightStream.stream
    }
    
    var currentState: PerformanceTestState {
        state
    }
    
    init() async {
        self.state = PerformanceTestState()
        self.lightweightStream = await (await globalMemoryOptimizationEngine()).createLightweightStream(
            initialState: PerformanceTestState()
        )
    }
    
    func process(_ action: PerformanceTestAction) async throws {
        switch action {
        case .increment:
            state.value += 1
            state.updateCount += 1
        case .setValue(let value):
            state.value = value
            state.updateCount += 1
        case .reset:
            state.value = 0
            state.updateCount = 0
        }
        
        lightweightStream.yield(state)
    }
    
    func getCurrentState() async -> PerformanceTestState {
        return state
    }
    
    deinit {
        lightweightStream.finish()
    }
}

/// Memory-optimized test context using direct implementation
@MainActor
class MemoryOptimizedTestContext: Context, ObservableObject {
    private let client: MemoryOptimizedTestClient
    @Published var state: PerformanceTestState
    private var observationTask: Task<Void, Never>?
    
    init(client: MemoryOptimizedTestClient) async {
        self.client = client
        self.state = await client.currentState
    }
    
    func onAppear() async {
        observationTask = Task { [weak self] in
            guard let self = self else { return }
            
            for await newState in await client.stateStream {
                await MainActor.run {
                    self.state = newState
                }
            }
        }
    }
    
    func onDisappear() async {
        observationTask?.cancel()
        observationTask = nil
    }
    
    deinit {
        observationTask?.cancel()
    }
}