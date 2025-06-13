import XCTest
@testable import Axiom

/// Tests for the state mutation DSL
final class MutationDSLTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct TestState: State, Equatable {
        var id: String = UUID().uuidString
        var value: String = ""
        var count: Int = 0
        var items: [String] = []
        var settings: Settings = Settings()
        
        struct Settings: Equatable {
            var isEnabled: Bool = false
            var threshold: Int = 10
        }
    }
    
    enum TestAction {
        case updateValue(String)
        case increment
        case addItem(String)
        case updateSettings(TestState.Settings)
    }
    
    final actor TestClient: BaseClient<TestState, TestAction>, Client {
        typealias StateType = TestState
        typealias ActionType = TestAction
        
        init() {
            super.init(initialState: TestState())
        }
        
        func process(_ action: TestAction) async throws {
            switch action {
            case .updateValue(let value):
                await mutate { state in
                    state.value = value
                }
            case .increment:
                await mutate { state in
                    state.count += 1
                }
            case .addItem(let item):
                await mutate { state in
                    state.items.append(item)
                }
            case .updateSettings(let settings):
                await mutate { state in
                    state.settings = settings
                }
            }
        }
    }
    
    // MARK: - Mutation DSL Tests
    
    func testMutationDSLSimplePropertyUpdate() async throws {
        let client = TestClient()
        
        // This should fail - mutate method doesn't exist yet
        let result = await client.mutate { state in
            state.value = "updated"
            state.count = 42
            return state.count
        }
        
        XCTAssertEqual(result, 42)
        XCTAssertEqual(await client.state.value, "updated")
        XCTAssertEqual(await client.state.count, 42)
    }
    
    func testMutationDSLArrayModification() async throws {
        let client = TestClient()
        
        // Test array mutation
        await client.mutate { state in
            state.items.append("item1")
            state.items.append("item2")
            state.items.remove(at: 0)
        }
        
        XCTAssertEqual(await client.state.items, ["item2"])
    }
    
    func testMutationDSLNestedPropertyUpdate() async throws {
        let client = TestClient()
        
        // Test nested property mutation
        await client.mutate { state in
            state.settings.isEnabled = true
            state.settings.threshold = 100
        }
        
        XCTAssertTrue(await client.state.settings.isEnabled)
        XCTAssertEqual(await client.state.settings.threshold, 100)
    }
    
    func testMutationDSLAsyncOperations() async throws {
        let client = TestClient()
        
        // Test async mutation
        let fetchedValue = await client.mutateAsync { state in
            // Simulate async operation
            try await Task.sleep(nanoseconds: 100_000) // 0.1ms
            state.value = "async-updated"
            return state.value
        }
        
        XCTAssertEqual(fetchedValue, "async-updated")
        XCTAssertEqual(await client.state.value, "async-updated")
    }
    
    func testMutationDSLImmutabilityPreservation() async throws {
        let client = TestClient()
        let initialState = await client.state
        
        // Perform mutation
        await client.mutate { state in
            state.count = 999
        }
        
        // Original state should be unchanged
        XCTAssertEqual(initialState.count, 0)
        XCTAssertEqual(await client.state.count, 999)
    }
    
    func testMutationDSLErrorHandling() async throws {
        let client = TestClient()
        
        // Test error propagation in mutation
        do {
            try await client.mutateAsync { state in
                state.value = "error-test"
                throw TestError.simulatedError
            }
            XCTFail("Should have thrown error")
        } catch {
            // State should not be updated on error
            XCTAssertEqual(await client.state.value, "")
        }
    }
    
    // MARK: - StateStreamBuilder Tests
    
    func testStateStreamBuilderBasicUsage() async throws {
        let initialState = TestState(value: "initial", count: 10)
        
        // This should fail - StateStreamBuilder doesn't exist yet
        let stream = StateStreamBuilder(initialState: initialState)
            .withBufferSize(50)
            .build()
        
        var receivedStates: [TestState] = []
        
        Task {
            for await state in stream {
                receivedStates.append(state)
                if receivedStates.count >= 1 {
                    break
                }
            }
        }
        
        // Give async task time to receive initial state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates.first?.value, "initial")
        XCTAssertEqual(receivedStates.first?.count, 10)
    }
    
    // MARK: - StateValidator Tests
    
    func testStateValidatorValidation() async throws {
        let state = TestState(value: "test", count: -1)
        
        // This should fail - StateValidator doesn't exist yet
        let rules: [StateValidationRule<TestState>] = [
            StateValidationRule { state in
                guard state.count >= 0 else {
                    throw ValidationError.invalidCount
                }
            }
        ]
        
        do {
            try StateValidator.validate(state, using: rules)
            XCTFail("Should have failed validation")
        } catch ValidationError.invalidCount {
            // Expected
        }
    }
    
    func testStateValidatorDiff() async throws {
        let before = TestState(value: "before", count: 1, items: ["a", "b"])
        let after = TestState(value: "after", count: 2, items: ["a", "b", "c"])
        
        // This should fail - StateValidator doesn't exist yet
        let diff = StateValidator.diff(before, after)
        
        XCTAssertTrue(diff.hasChanges)
        XCTAssertEqual(diff.changedProperties.count, 3) // value, count, items
    }
    
    // MARK: - Helper Types
    
    enum TestError: Error {
        case simulatedError
    }
    
    enum ValidationError: Error {
        case invalidCount
    }
    
    // MARK: - REQUIREMENTS-W-01-003: Enhanced Mutation DSL Tests (RED Phase)
    
    func testEnhancedMutationOperators() async throws {
        let client = TestClient()
        
        // Enhanced collection mutation operators
        await client.mutate { state in
            // Array enhancements
            state.items.upsert("item1", id: "item1")
            state.items.update(id: "item1") { item in
                item = "updated_item1" 
            }
            state.items.removeAll(ids: ["item1"])
            
            // Enhanced property updates
            state.value.append(" suffix")
            state.count.increment(by: 5)
        }
        
        XCTAssertEqual(await client.state.items.count, 0)
        XCTAssertEqual(await client.state.value, " suffix")
        XCTAssertEqual(await client.state.count, 5)
    }
    
    func testTransactionalMutations() async throws {
        let client = TestClient()
        
        // Transaction should either complete fully or rollback completely
        let result = try await client.transaction { transaction in
            transaction.update(\.value, to: "transactional")
            transaction.update(\.count, to: 100)
            transaction.transform(\.items) { items in
                items.append("tx_item")
            }
            return "transaction_result"
        }
        
        XCTAssertEqual(result, "transaction_result")
        XCTAssertEqual(await client.state.value, "transactional")
        XCTAssertEqual(await client.state.count, 100)
        XCTAssertEqual(await client.state.items, ["tx_item"])
    }
    
    func testTransactionRollback() async throws {
        let client = TestClient()
        
        // Set initial state
        await client.mutate { state in
            state.value = "initial"
            state.count = 1
        }
        
        // Transaction that should rollback on validation failure
        do {
            try await client.transaction { transaction in
                transaction.update(\.value, to: "should_rollback")
                transaction.update(\.count, to: -1) // Invalid count
                
                // This should trigger validation failure
                transaction.validate { state in
                    guard state.count >= 0 else {
                        throw ValidationError.invalidCount
                    }
                }
            }
            XCTFail("Transaction should have failed")
        } catch {
            // State should remain unchanged after rollback
            XCTAssertEqual(await client.state.value, "initial")
            XCTAssertEqual(await client.state.count, 1)
        }
    }
    
    func testBatchMutationOptimization() async throws {
        let client = TestClient()
        
        // Batch mutations should be coalesced for performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await client.batchMutate([
            { state in state.count += 1 },
            { state in state.count += 2 },
            { state in state.count += 3 },
            { state in state.items.append("batch1") },
            { state in state.items.append("batch2") }
        ])
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Batch should complete efficiently
        XCTAssertLessThan(duration, 0.001) // < 1ms
        XCTAssertEqual(await client.state.count, 6)
        XCTAssertEqual(await client.state.items, ["batch1", "batch2"])
    }
    
    func testValidatedMutations() async throws {
        let client = TestClient()
        
        // Successful validated mutation
        let validationRules: [StateValidationRule<TestState>] = [
            StateValidationRule { state in
                guard state.count >= 0 else {
                    throw ValidationError.invalidCount
                }
            }
        ]
        
        try await client.validatedMutate({ state in
            state.count = 5
            state.value = "validated"
        }, validations: validationRules)
        
        XCTAssertEqual(await client.state.count, 5)
        XCTAssertEqual(await client.state.value, "validated")
        
        // Failed validated mutation
        do {
            try await client.validatedMutate({ state in
                state.count = -1 // Should fail validation
            }, validations: validationRules)
            XCTFail("Should have failed validation")
        } catch {
            // State should remain unchanged
            XCTAssertEqual(await client.state.count, 5)
        }
    }
    
    func testMutationDebugging() async throws {
        let client = TestClient()
        
        // Debug mutation with tracing
        let (result, diff, duration, _) = try MutationDebugger.trace({ state in
            state.value = "debugged"
            state.count = 42
            return "debug_result"
        }, on: await client.state)
        
        XCTAssertEqual(result, "debug_result")
        XCTAssertTrue(diff.hasChanges())
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 0.001) // Should be very fast
    }
    
    func testMutationProfiling() async throws {
        let profiler = MutationProfiler<TestState>()
        let client = TestClient()
        
        // Profile multiple mutations
        try await profiler.profile(name: "simple_update") { state in
            state.value = "profiled"
        } on: await client.state
        
        try await profiler.profile(name: "complex_update") { state in
            state.items = Array(0..<100).map { "item_\($0)" }
            state.count = state.items.count
        } on: await client.state
        
        let report = await profiler.report()
        XCTAssertEqual(report.profiles.count, 2)
        XCTAssertTrue(report.profiles.contains { $0.name == "simple_update" })
        XCTAssertTrue(report.profiles.contains { $0.name == "complex_update" })
    }
    
    func testUndoRedoFunctionality() async throws {
        let undoManager = UndoManager<TestState>(maxHistory: 10)
        let client = TestClient()
        
        // Record initial state
        await undoManager.recordSnapshot(await client.state)
        
        // Make some changes
        await client.mutate { state in
            state.value = "change1"
            state.count = 1
        }
        await undoManager.recordSnapshot(await client.state)
        
        await client.mutate { state in
            state.value = "change2"
            state.count = 2
        }
        await undoManager.recordSnapshot(await client.state)
        
        // Test undo
        if let undoState = await undoManager.undo() {
            XCTAssertEqual(undoState.value, "change1")
            XCTAssertEqual(undoState.count, 1)
        } else {
            XCTFail("Undo should return previous state")
        }
        
        // Test redo
        if let redoState = await undoManager.redo() {
            XCTAssertEqual(redoState.value, "change2")
            XCTAssertEqual(redoState.count, 2)
        } else {
            XCTFail("Redo should return next state")
        }
    }
    
    func testMutablePropertyWrapper() async throws {
        let client = TestClient()
        
        // Mutable property wrapper for elegant mutations
        @Mutable var state = await client.state
        
        // Should provide mutation operators
        state.update { s in
            s.value = "mutable_wrapper"
            s.count = 999
        }
        
        // The wrapper should update the underlying client
        XCTAssertEqual(state.value, "mutable_wrapper")
        XCTAssertEqual(state.count, 999)
    }
    
    func testCollectionMutationExtensions() async throws {
        // Test enhanced array operations
        var items: [IdentifiableItem] = []
        
        let item1 = IdentifiableItem(id: "1", name: "Item 1")
        let item2 = IdentifiableItem(id: "2", name: "Item 2")
        
        // Test upsert
        let upserted = items.upsert(item1)
        XCTAssertEqual(upserted.name, "Item 1")
        XCTAssertEqual(items.count, 1)
        
        // Test update by ID
        let updateSuccess = items.update(id: "1") { item in
            item.name = "Updated Item 1"
        }
        XCTAssertTrue(updateSuccess)
        XCTAssertEqual(items.first?.name, "Updated Item 1")
        
        // Test remove by IDs
        items.append(item2)
        items.removeAll(ids: ["1", "2"])
        XCTAssertTrue(items.isEmpty)
    }
    
    func testDictionaryMutationExtensions() async throws {
        var settings: [String: Any] = [:]
        
        // Test update with default
        let updatedValue = settings.update(key: "count", default: 0) { value in
            if let count = value as? Int {
                value = count + 1
            }
        }
        
        XCTAssertNotNil(updatedValue)
        XCTAssertEqual(settings["count"] as? Int, 1)
        
        // Test merge with combining
        let other = ["count": 5, "name": "test"]
        settings.merge(other) { existing, new in
            return new // Use new value for conflicts
        }
        
        XCTAssertEqual(settings["count"] as? Int, 5)
        XCTAssertEqual(settings["name"] as? String, "test")
    }
    
    func testBatchMutationCoordinator() async throws {
        let initialState = TestState()
        let coordinator = BatchMutationCoordinator<TestState>(initialState: initialState)
        
        // Enqueue multiple mutations that should be coalesced
        await coordinator.enqueue { state in state.count += 1 }
        await coordinator.enqueue { state in state.count += 2 }
        await coordinator.enqueue { state in state.value = "coalesced" }
        
        // Process batch immediately
        let finalState = try await coordinator.processBatchImmediately()
        
        // Final state should reflect all coalesced mutations
        XCTAssertEqual(finalState.count, 3)
        XCTAssertEqual(finalState.value, "coalesced")
    }
    
    // MARK: - Supporting Types for Enhanced Tests
    
    struct IdentifiableItem: Identifiable, Equatable {
        let id: String
        var name: String
    }
    
    struct MutationProfile {
        let name: String
        let duration: TimeInterval
        let memoryDelta: Int
    }
    
    struct MutationReport {
        let profiles: [MutationProfile]
    }
}