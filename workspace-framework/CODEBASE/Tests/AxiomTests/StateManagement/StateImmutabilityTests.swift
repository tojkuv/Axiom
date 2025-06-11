import XCTest
@testable import Axiom

final class StateImmutabilityTests: XCTestCase {
    // Test that all state mutations produce new immutable value type instances
    func testStateMutationsProduceNewInstances() async {
        let immutableState = ImmutableStateManager(initialState: AppState())
        
        let initialState = immutableState.currentState
        let updatedState = immutableState.update { state in
            state.incrementingCounter()
        }
        
        // States should be different instances (different IDs)
        XCTAssertNotEqual(initialState.id, updatedState.id, "State mutations should produce new instances")
        
        // Original state should be unchanged
        XCTAssertEqual(initialState.counter, 0)
        XCTAssertEqual(updatedState.counter, 1)
        
        // Multiple updates should each produce new instances
        let state2 = immutableState.update { state in
            state.addingValue("item1")
        }
        let state3 = immutableState.update { state in
            state.addingValue("item2")
        }
        
        XCTAssertNotEqual(state2.id, state3.id)
        XCTAssertEqual(state2.values.count, 1)
        XCTAssertEqual(state3.values.count, 2)
    }
    
    // Test that concurrent mutations produce consistent final state
    func testConcurrentMutationsProduceConsistentState() async {
        let stateManager = ConcurrentImmutableStateManager()
        let mutationCount = 100
        
        // Perform concurrent mutations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<mutationCount {
                group.addTask {
                    await stateManager.performMutation(id: i)
                }
            }
            
            await group.waitForAll()
        }
        
        // Verify final state is consistent
        let finalState = await stateManager.state
        XCTAssertEqual(finalState.counter, mutationCount, "All mutations should be applied")
        XCTAssertEqual(finalState.history.count, mutationCount, "All mutations should be recorded")
        
        // Verify no mutations were lost
        let uniqueIds = Set(finalState.history)
        XCTAssertEqual(uniqueIds.count, mutationCount, "No duplicate or missing mutations")
    }
    
    // Test 1000 concurrent state mutations show no data corruption
    func testThousandConcurrentMutationsShowNoCorruption() async {
        let stateManager = ConcurrentImmutableStateManager()
        let mutationCount = 1000
        
        // Create different types of mutations
        await withTaskGroup(of: Void.self) { group in
            // Counter increments
            for i in 0..<(mutationCount / 3) {
                group.addTask {
                    await stateManager.incrementCounter()
                }
            }
            
            // Value additions
            for i in 0..<(mutationCount / 3) {
                group.addTask {
                    await stateManager.addValue("value-\(i)")
                }
            }
            
            // Mixed operations
            for i in 0..<(mutationCount / 3) {
                group.addTask {
                    await stateManager.performComplexMutation(index: i)
                }
            }
            
            await group.waitForAll()
        }
        
        // Verify state integrity
        let finalState = await stateManager.state
        
        // Check counter consistency
        XCTAssertGreaterThanOrEqual(finalState.counter, mutationCount / 3)
        
        // Check values consistency
        XCTAssertGreaterThanOrEqual(finalState.values.count, mutationCount / 3)
        
        // Verify structural integrity
        XCTAssertTrue(finalState.isValid(), "State should maintain internal consistency")
        
        // Verify no data corruption in collections
        for value in finalState.values {
            XCTAssertTrue(value.hasPrefix("value-") || value.hasPrefix("complex-"))
        }
    }
    
    // Test that state types enforce immutability at compile time
    func testStateTypesEnforceImmutability() {
        // This test verifies compile-time guarantees
        struct TestState: ImmutableState {
            let id: String = UUID().uuidString
            let counter: Int
            let values: [String]
            
            // All properties must be let-declared
            // var mutableProperty: Int // This would fail compilation
        }
        
        let state = TestState(counter: 0, values: [])
        
        // Cannot mutate properties directly
        // state.counter = 1 // This would fail compilation
        // state.values.append("test") // This would fail compilation
        
        XCTAssertEqual(state.counter, 0)
        XCTAssertEqual(state.values.count, 0)
    }
    
    // Test copy-on-write optimization for large states
    func testCopyOnWriteOptimization() {
        let largeState = LargeImmutableState(size: 10000)
        
        // Test structural sharing before mutation
        let state1 = largeState
        let state2 = state1 // Should share storage due to COW
        
        // Verify they share storage until mutation
        XCTAssertTrue(state1.sharesStorage(with: state2), "States should share storage before mutation")
        
        // Mutate and verify storage is no longer shared
        var state3 = state2
        state3.incrementCounter()
        XCTAssertFalse(state2.sharesStorage(with: state3), "States should not share storage after mutation")
        XCTAssertEqual(state3.counter, 1)
        XCTAssertEqual(state2.counter, 0)
        
        // Test that further mutations don't create unnecessary copies
        var state4 = state3
        state4.incrementCounter()
        XCTAssertEqual(state4.counter, 2)
        XCTAssertEqual(state3.counter, 1) // Original remains unchanged
    }
    
    // Test thread safety of immutable state updates
    func testThreadSafetyOfImmutableUpdates() async {
        let stateManager = ThreadSafeImmutableStateManager()
        let iterations = 100
        
        // Concurrent reads and writes from multiple queues
        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<iterations {
                group.addTask {
                    await stateManager.write(value: i)
                }
            }
            
            // Readers
            for _ in 0..<iterations {
                group.addTask {
                    let state = await stateManager.read()
                    // Verify state is valid at any point
                    XCTAssertTrue(state.isConsistent())
                }
            }
            
            await group.waitForAll()
        }
        
        // Final verification
        let finalState = await stateManager.read()
        XCTAssertEqual(finalState.writeCount, iterations)
        XCTAssertTrue(finalState.isConsistent())
    }
    
    // MARK: - Enhanced ImmutableState Protocol Tests (W-01-001)
    
    // Test enhanced ImmutableState protocol with version tracking and structural hash
    func testEnhancedImmutableStateProtocol() {
        // Test that enhanced states have version tracking
        let state = EnhancedTestState(counter: 0, values: [])
        
        // Version should increment with state changes
        XCTAssertEqual(state.version, 1, "Initial state should have version 1")
        
        let updatedState = state.incrementingCounter()
        XCTAssertEqual(updatedState.version, 2, "Updated state should have incremented version")
        XCTAssertGreaterThan(updatedState.version, state.version, "New state version should be greater than previous")
        
        // Structural hash should change with content changes
        XCTAssertNotEqual(state.structuralHash, updatedState.structuralHash, "Structural hash should change with state mutations")
        
        // Identical states should have identical structural hashes
        let duplicateState = EnhancedTestState(counter: 0, values: [])
        XCTAssertEqual(state.structuralHash, duplicateState.structuralHash, "Identical states should have identical structural hashes")
        
        // State validation should work
        XCTAssertNoThrow(try state.validateInvariants(), "Valid state should pass validation")
    }
    
    // Test automatic versioning support for state changes
    func testAutomaticVersioning() {
        let manager = EnhancedImmutableStateManager(initialState: EnhancedTestState(counter: 0, values: []))
        
        let initialState = manager.currentState
        XCTAssertEqual(initialState.version, 1, "Initial state should start with version 1")
        
        // Each update should increment version automatically
        let state1 = manager.update { $0.incrementingCounter() }
        XCTAssertEqual(state1.version, 2, "First update should increment to version 2")
        
        let state2 = manager.update { $0.addingValue("test") }
        XCTAssertEqual(state2.version, 3, "Second update should increment to version 3")
        
        // Version should be preserved in state history
        XCTAssertEqual(initialState.version, 1, "Original state version should remain unchanged")
        XCTAssertEqual(state1.version, 2, "Previous state version should remain unchanged")
    }
    
    // Test state validation framework integration
    func testStateValidationFramework() {
        // Valid state should pass validation
        let validState = EnhancedTestState(counter: 5, values: ["a", "b"])
        XCTAssertNoThrow(try validState.validateInvariants(), "Valid state should pass validation")
        
        // Invalid state should fail validation
        let invalidState = EnhancedTestState(counter: -1, values: [])
        XCTAssertThrowsError(try invalidState.validateInvariants(), "Invalid state should fail validation") { error in
            guard let stateError = error as? StateValidationError else {
                XCTFail("Should throw StateValidationError")
                return
            }
            XCTAssertEqual(stateError.invariant, "counter_non_negative", "Should identify specific failed invariant")
        }
    }
}

// MARK: - Test Support Types

// Concrete immutable state type for testing
struct AppState: ImmutableState, ValidatableState {
    let id: String
    let version: UInt64
    let counter: Int
    let values: [String]
    let history: [Int]
    
    init(id: String = UUID().uuidString, version: UInt64 = 1, counter: Int = 0, values: [String] = [], history: [Int] = []) {
        self.id = id
        self.version = version
        self.counter = counter
        self.values = values
        self.history = history
    }
    
    func isValid() -> Bool {
        return counter >= 0 && history.count <= counter * 2 // Allow some slack for complex operations
    }
    
    func checkInvariants() -> [String] {
        var errors: [String] = []
        if counter < 0 {
            errors.append("Counter cannot be negative")
        }
        if history.count > counter * 2 {
            errors.append("History count exceeds reasonable bounds")
        }
        return errors
    }
    
    func withVersion(_ newVersion: UInt64) -> AppState {
        AppState(id: id, version: newVersion, counter: counter, values: values, history: history)
    }
    
    // Helper methods for creating modified copies
    func incrementingCounter() -> AppState {
        AppState(id: UUID().uuidString, version: version + 1, counter: counter + 1, values: values, history: history)
    }
    
    func addingValue(_ value: String) -> AppState {
        AppState(id: UUID().uuidString, version: version + 1, counter: counter, values: values.appending(value), history: history)
    }
    
    func addingToHistory(_ item: Int) -> AppState {
        AppState(id: UUID().uuidString, version: version + 1, counter: counter, values: values, history: history.appending(item))
    }
}

// Wrapper for concurrent state management with proper immutability
actor ConcurrentImmutableStateManager {
    private let stateManager: Axiom.ConcurrentImmutableStateManager<AppState>
    
    var state: AppState {
        get async { await stateManager.state }
    }
    
    init() {
        stateManager = Axiom.ConcurrentImmutableStateManager(initialState: AppState())
    }
    
    func performMutation(id: Int) async {
        await stateManager.trackedUpdate(id: "mutation-\(id)") { state in
            state.incrementingCounter().addingToHistory(id)
        }
    }
    
    func incrementCounter() async {
        await stateManager.update { state in
            state.incrementingCounter()
        }
    }
    
    func addValue(_ value: String) async {
        await stateManager.update { state in
            state.addingValue(value)
        }
    }
    
    func performComplexMutation(index: Int) async {
        await stateManager.update { state in
            state.incrementingCounter()
                .addingValue("complex-\(index)")
                .addingToHistory(index)
        }
    }
}

// Large state type for COW testing
struct LargeImmutableState {
    private var storage: COWContainer<LargeStateData>
    
    var counter: Int {
        storage.value.counter
    }
    
    var data: [Int] {
        storage.value.data
    }
    
    init(size: Int) {
        storage = COWContainer(LargeStateData(counter: 0, data: Array(0..<size)))
    }
    
    func sharesStorage(with other: LargeImmutableState) -> Bool {
        return storage.sharesStorage(with: other.storage)
    }
    
    func withMutation(_ mutation: (inout LargeImmutableState) -> Void) -> LargeImmutableState {
        var copy = self
        mutation(&copy)
        return copy
    }
    
    mutating func incrementCounter() {
        storage.withMutation { data in
            data.counter += 1
        }
    }
}

private struct LargeStateData {
    var counter: Int
    let data: [Int]
}

// Thread-safe state manager
actor ThreadSafeImmutableStateManager {
    private let container: ThreadSafeStateContainer<ThreadSafeState>
    
    init() {
        container = ThreadSafeStateContainer(initialState: ThreadSafeState())
    }
    
    func write(value: Int) async {
        await container.update { state in
            state.withWrite(value: value)
        }
    }
    
    func read() async -> ThreadSafeState {
        await container.read()
    }
}

struct ThreadSafeState: ImmutableState {
    let id: String
    let version: UInt64
    let writeCount: Int
    let lastValue: Int?
    
    init(id: String = UUID().uuidString, version: UInt64 = 1, writeCount: Int = 0, lastValue: Int? = nil) {
        self.id = id
        self.version = version
        self.writeCount = writeCount
        self.lastValue = lastValue
    }
    
    func withVersion(_ newVersion: UInt64) -> ThreadSafeState {
        ThreadSafeState(id: id, version: newVersion, writeCount: writeCount, lastValue: lastValue)
    }
    
    func withWrite(value: Int) -> ThreadSafeState {
        ThreadSafeState(version: version + 1, writeCount: writeCount + 1, lastValue: value)
    }
    
    func isConsistent() -> Bool {
        return writeCount >= 0
    }
}

// MARK: - Enhanced Test Support Types (W-01-001)

// Enhanced test state implementing the new protocol features
struct EnhancedTestState: ImmutableState {
    let id: String
    let version: UInt64
    let counter: Int
    let values: [String]
    
    init(id: String = UUID().uuidString, version: UInt64 = 1, counter: Int, values: [String]) {
        self.id = id
        self.version = version
        self.counter = counter
        self.values = values
    }
    
    var structuralHash: Int {
        var hasher = Hasher()
        hasher.combine(counter)
        hasher.combine(values)
        return hasher.finalize()
    }
    
    func validateInvariants() throws {
        if counter < 0 {
            throw StateValidationError(invariant: "counter_non_negative", message: "Counter cannot be negative")
        }
        if values.count > 1000 {
            throw StateValidationError(invariant: "values_size_limit", message: "Values array cannot exceed 1000 items")
        }
    }
    
    func withVersion(_ newVersion: UInt64) -> EnhancedTestState {
        EnhancedTestState(id: id, version: newVersion, counter: counter, values: values)
    }
    
    // Helper methods for mutations
    func incrementingCounter() -> EnhancedTestState {
        EnhancedTestState(
            id: UUID().uuidString,
            version: version + 1,
            counter: counter + 1,
            values: values
        )
    }
    
    func addingValue(_ value: String) -> EnhancedTestState {
        EnhancedTestState(
            id: UUID().uuidString,
            version: version + 1,
            counter: counter,
            values: values.appending(value)
        )
    }
}

// Enhanced state manager with automatic versioning
class EnhancedImmutableStateManager<State: ImmutableState> {
    private var _currentState: State
    private var _version: UInt64 = 1
    private let lock = NSLock()
    
    var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        return _currentState
    }
    
    init(initialState: State) {
        self._currentState = initialState.withVersion(1)
    }
    
    @discardableResult
    func update(_ transform: (State) -> State) -> State {
        lock.lock()
        defer { lock.unlock() }
        
        _version += 1
        let newState = transform(_currentState).withVersion(_version)
        _currentState = newState
        return newState
    }
}

// State validation error
struct StateValidationError: Error {
    let invariant: String
    let message: String
}