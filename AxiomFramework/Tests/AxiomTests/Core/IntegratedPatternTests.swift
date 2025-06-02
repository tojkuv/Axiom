import Testing
import Foundation
import SwiftUI
@testable import Axiom

/// Integration tests for Observer Pattern with Memory Management
/// 
/// Tests the integration of:
/// - Weak reference observer pattern
/// - Configuration-based memory limits
/// - Adaptive memory behavior
/// - Thread-safe operations
@Suite("Integrated Pattern Tests")
struct IntegratedPatternTests {
    
    // MARK: - Test Types
    
    /// State that tracks memory usage
    struct MemoryTrackedState: Sendable {
        var data: [String: Data] = [:]
        var updateCount: Int = 0
        
        var estimatedMemoryUsage: Int {
            data.values.reduce(0) { $0 + $1.count } + MemoryLayout<Self>.size
        }
    }
    
    /// Memory-aware client with observer pattern
    actor MemoryAwareClient: AxiomClient {
        typealias State = MemoryTrackedState
        typealias DomainModelType = EmptyDomain
        
        private var _state: MemoryTrackedState
        private let _capabilities: CapabilityManager
        private let _observers = ObserverCollection()
        private let _memoryManager: MemoryManager
        
        var stateSnapshot: MemoryTrackedState { _state }
        var capabilities: CapabilityManager { _capabilities }
        
        init(memoryConfig: MemoryConfiguration = MemoryConfiguration()) {
            self._state = MemoryTrackedState()
            self._capabilities = CapabilityManager()
            self._memoryManager = MemoryManager(configuration: memoryConfig)
        }
        
        func updateState<T>(_ update: @Sendable (inout MemoryTrackedState) throws -> T) async rethrows -> T {
            let oldMemoryUsage = _state.estimatedMemoryUsage
            let result = try update(&_state)
            let newMemoryUsage = _state.estimatedMemoryUsage
            
            // Update memory tracking
            if newMemoryUsage > oldMemoryUsage {
                let diff = newMemoryUsage - oldMemoryUsage
                try? await _memoryManager.registerUsage(diff)
            } else if newMemoryUsage < oldMemoryUsage {
                let diff = oldMemoryUsage - newMemoryUsage
                await _memoryManager.releaseUsage(diff)
            }
            
            // Notify observers
            await notifyObservers()
            
            return result
        }
        
        func validateState() async throws {}
        
        func addObserver<T: AxiomContext>(_ context: T) async {
            await _observers.add(context)
        }
        
        func removeObserver<T: AxiomContext>(_ context: T) async {
            await _observers.remove(context)
        }
        
        func notifyObservers() async {
            await _observers.notifyAll { context in
                await context.onClientStateChange(self)
            }
        }
        
        func initialize() async throws {}
        func shutdown() async {
            await _observers.removeAll()
        }
        
        // Test helpers
        func getObserverCount() async -> Int {
            await _observers.count
        }
        
        func getMemoryStats() async -> MemoryStats {
            await _memoryManager.getMemoryStats()
        }
        
        func updateMemoryConfiguration(_ config: MemoryConfiguration) async {
            await _memoryManager.updateConfiguration(config)
        }
    }
    
    /// Test context that tracks state changes
    @MainActor
    final class TestTrackingContext: AxiomContext {
        typealias View = EmptyView
        typealias Clients = ClientContainer<MemoryAwareClient>
        
        let clients: ClientContainer<MemoryAwareClient>
        let intelligence: AxiomIntelligence
        var stateChangeCount = 0
        var lastMemoryUsage = 0
        
        init(client: MemoryAwareClient) {
            self.clients = ClientContainer(client)
            self.intelligence = DefaultAxiomIntelligence()
        }
        
        func onAppear() async {}
        func onDisappear() async {}
        
        func onClientStateChange<T: AxiomClient>(_ client: T) async {
            stateChangeCount += 1
            if let memoryClient = client as? MemoryAwareClient {
                lastMemoryUsage = await memoryClient.stateSnapshot.estimatedMemoryUsage
            }
        }
        
        func handleError(_ error: any AxiomError) async {}
        func trackAnalyticsEvent(_ event: String, parameters: [String: Any]) async {}
    }
    
    struct EmptyView: View, AxiomView {
        typealias Context = TestTrackingContext
        let context: TestTrackingContext
        
        var body: some View {
            Text("Test View")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Observer pattern with memory tracking")
    @MainActor
    func testObserverPatternWithMemoryTracking() async throws {
        // Create client with 1MB memory limit
        let memoryConfig = MemoryConfiguration(
            maxMemoryBytes: 1_000_000,
            targetMemoryBytes: 800_000,
            adaptiveBehaviorEnabled: true
        )
        let client = MemoryAwareClient(memoryConfig: memoryConfig)
        let context = TestTrackingContext(client: client)
        
        // Register observer
        await client.addObserver(context)
        
        // Update state with memory tracking
        await client.updateState { state in
            state.data["item1"] = Data(repeating: 0, count: 100_000) // 100KB
            state.updateCount += 1
        }
        
        // Verify observer was notified
        #expect(context.stateChangeCount == 1)
        #expect(context.lastMemoryUsage > 100_000)
        
        // Verify memory was tracked
        let stats = await client.getMemoryStats()
        #expect(stats.currentUsage >= 100_000) // At least the data size
        #expect(stats.usageRatio < 0.2) // Well below limit
    }
    
    @Test("Memory limits with adaptive observer cleanup")
    @MainActor
    func testMemoryLimitsWithAdaptiveObserverCleanup() async throws {
        // Create client with small memory limit
        let memoryConfig = MemoryConfiguration(
            maxMemoryBytes: 500_000, // 500KB
            targetMemoryBytes: 400_000,
            evictionThreshold: 0.8,
            adaptiveBehaviorEnabled: true
        )
        let client = MemoryAwareClient(memoryConfig: memoryConfig)
        
        // Create multiple observers
        var contexts: [TestTrackingContext] = []
        for _ in 0..<5 {
            let context = TestTrackingContext(client: client)
            contexts.append(context)
            await client.addObserver(context)
        }
        
        // Fill memory close to limit
        for i in 0..<10 {
            await client.updateState { state in
                state.data["item\(i)"] = Data(repeating: 0, count: 40_000) // 40KB each
            }
        }
        
        // Verify all observers were notified
        for context in contexts {
            #expect(context.stateChangeCount == 10)
        }
        
        // Verify memory stayed within limits
        let stats = await client.getMemoryStats()
        #expect(stats.currentUsage <= memoryConfig.maxMemoryBytes)
    }
    
    @Test("Weak reference cleanup under memory pressure")
    @MainActor
    func testWeakReferenceCleanupUnderMemoryPressure() async throws {
        let client = MemoryAwareClient()
        
        // Create observers in a scope
        do {
            let context1 = TestTrackingContext(client: client)
            let context2 = TestTrackingContext(client: client)
            await client.addObserver(context1)
            await client.addObserver(context2)
            
            #expect(await client.getObserverCount() == 2)
        }
        // Contexts deallocated here
        
        // Trigger state update to clean up weak references
        await client.updateState { state in
            state.updateCount += 1
        }
        
        // Verify observers were cleaned up
        #expect(await client.getObserverCount() == 0)
    }
    
    @Test("Dynamic memory configuration updates")
    @MainActor
    func testDynamicMemoryConfigurationUpdates() async throws {
        let initialConfig = MemoryConfiguration(
            maxMemoryBytes: 1_000_000,
            adaptiveBehaviorEnabled: false
        )
        let client = MemoryAwareClient(memoryConfig: initialConfig)
        
        // Store data
        await client.updateState { state in
            state.data["large"] = Data(repeating: 0, count: 500_000)
        }
        
        // Update configuration to enable adaptive behavior
        let newConfig = MemoryConfiguration(
            maxMemoryBytes: 2_000_000,
            targetMemoryBytes: 1_500_000,
            adaptiveBehaviorEnabled: true
        )
        await client.updateMemoryConfiguration(newConfig)
        
        // Add more data
        await client.updateState { state in
            state.data["large2"] = Data(repeating: 0, count: 800_000)
        }
        
        // Verify new configuration is active
        let stats = await client.getMemoryStats()
        #expect(stats.maxMemory == 2_000_000)
    }
    
    @Test("Concurrent observer and memory operations")
    @MainActor
    func testConcurrentObserverAndMemoryOperations() async throws {
        let client = MemoryAwareClient()
        let contexts = (0..<10).map { _ in TestTrackingContext(client: client) }
        
        // Register observers concurrently
        await withTaskGroup(of: Void.self) { group in
            for context in contexts {
                group.addTask {
                    await client.addObserver(context)
                }
            }
        }
        
        // Update state concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    await client.updateState { state in
                        state.data["concurrent\(i)"] = Data(repeating: 0, count: 10_000)
                    }
                }
            }
        }
        
        // Verify all observers received notifications
        for context in contexts {
            #expect(context.stateChangeCount == 20)
        }
        
        // Verify memory tracking is consistent
        let stats = await client.getMemoryStats()
        #expect(stats.currentUsage > 0)
    }
    
    @Test("Performance with memory management overhead")
    @MainActor
    func testPerformanceWithMemoryManagementOverhead() async throws {
        let client = MemoryAwareClient()
        let context = TestTrackingContext(client: client)
        await client.addObserver(context)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform many small updates
        for i in 0..<100 {
            await client.updateState { state in
                state.data["perf\(i)"] = Data(repeating: 0, count: 1000)
                state.updateCount += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Verify performance is acceptable
        #expect(duration < 0.5) // Should complete within 500ms
        
        // Verify all updates were tracked
        #expect(context.stateChangeCount == 100)
        
        let stats = await client.getMemoryStats()
        print("📊 Integrated Performance:")
        print("   Updates: 100")
        print("   Duration: \(String(format: "%.3f", duration)) seconds")
        print("   Updates/sec: \(String(format: "%.0f", 100.0 / duration))")
        print("   Memory usage: \(stats.currentUsage) bytes")
    }
}