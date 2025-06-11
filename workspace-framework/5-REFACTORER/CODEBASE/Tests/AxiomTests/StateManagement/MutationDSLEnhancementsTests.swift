import XCTest
@testable import Axiom

/// Tests for REQUIREMENTS-W-01-003: Mutation DSL Enhancements
final class MutationDSLEnhancementsTests: XCTestCase {
    
    // MARK: - Test Types
    
    struct TestItem: Identifiable, Equatable {
        let id: String
        var name: String
        var value: Int
    }
    
    struct TestState: State, Equatable {
        var id: String = UUID().uuidString
        var items: [TestItem] = []
        var dict: [String: Int] = [:]
        var count: Int = 0
        var value: String = ""
    }
    
    enum TestAction: Action {
        case update
    }
    
    final actor TestClient: BaseClient<TestState, TestAction>, ObservableClient {
        typealias S = TestState
        
        init() {
            super.init(initialState: TestState())
        }
        
        func process(_ action: TestAction) async throws {
            // No-op for testing
        }
    }
    
    // MARK: - RED Phase Tests
    
    func testEnhancedTransactionTypedKeyPaths() async throws {
        let client = TestClient()
        
        // Test transaction with typed keyPath operations
        let result = try await client.transaction { transaction in
            // Typed update operations
            transaction.update(\.count, to: 42)
            transaction.update(\.value, to: "transacted")
            
            // Transform operations
            transaction.transform(\.items) { items in
                var newItems = items
                newItems.append(TestItem(id: "1", name: "Item 1", value: 100))
                return newItems
            }
            
            // Conditional operations
            transaction.updateIf({ $0.count > 40 }, \.value, to: "high_count")
            
            return transaction.operationCount
        }
        
        XCTAssertEqual(result, 4)
        XCTAssertEqual(await client.state.count, 42)
        XCTAssertEqual(await client.state.value, "high_count")
        XCTAssertEqual(await client.state.items.count, 1)
    }
    
    func testTransactionRollbackOnError() async throws {
        let client = TestClient()
        
        // Set initial state
        await client.mutate { state in
            state.value = "initial"
            state.count = 10
        }
        
        // Transaction that should rollback on validation failure
        do {
            try await client.transaction { transaction in
                transaction.update(\.value, to: "should_rollback")
                transaction.update(\.count, to: -1) // Will fail validation
                
                // Add validation that will fail
                transaction.validate { state in
                    guard state.count >= 0 else {
                        throw AxiomError.validationError(.invalidInput("count", "must be non-negative"))
                    }
                }
            }
            XCTFail("Transaction should have failed")
        } catch {
            // State should remain unchanged after rollback
            XCTAssertEqual(await client.state.value, "initial")
            XCTAssertEqual(await client.state.count, 10)
        }
    }
    
    func testBatchMutationCoalescing() async throws {
        let client = TestClient()
        
        // Test batch mutations are applied efficiently
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try await client.batchMutate([
            { state in state.count += 1 },
            { state in state.count += 2 },
            { state in state.count += 3 },
            { state in state.items.append(TestItem(id: "1", name: "Batch 1", value: 1)) },
            { state in state.items.append(TestItem(id: "2", name: "Batch 2", value: 2)) }
        ])
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Batch should complete efficiently
        XCTAssertLessThan(duration, 0.01) // < 10ms
        XCTAssertEqual(await client.state.count, 6)
        XCTAssertEqual(await client.state.items.count, 2)
    }
    
    func testCollectionMutationOperators() async throws {
        let client = TestClient()
        
        // Test enhanced collection operators
        await client.mutate { state in
            // Add initial items
            state.items = [
                TestItem(id: "1", name: "Item 1", value: 10),
                TestItem(id: "2", name: "Item 2", value: 20)
            ]
        }
        
        // Test update by ID
        await client.mutate { state in
            let updated = state.items.update(id: "1") { item in
                item.name = "Updated Item 1"
                item.value = 15
            }
            XCTAssertTrue(updated)
        }
        
        // Verify update
        let items = await client.state.items
        XCTAssertEqual(items.first?.name, "Updated Item 1")
        XCTAssertEqual(items.first?.value, 15)
        
        // Test upsert
        await client.mutate { state in
            let newItem = TestItem(id: "3", name: "Item 3", value: 30)
            _ = state.items.upsert(newItem)
            
            // Update existing item via upsert
            let updatedItem = TestItem(id: "1", name: "Upserted Item 1", value: 100)
            _ = state.items.upsert(updatedItem)
        }
        
        // Verify upsert
        let finalItems = await client.state.items
        XCTAssertEqual(finalItems.count, 3)
        XCTAssertEqual(finalItems.first(where: { $0.id == "1" })?.name, "Upserted Item 1")
        XCTAssertEqual(finalItems.first(where: { $0.id == "3" })?.name, "Item 3")
        
        // Test removeAll by IDs
        await client.mutate { state in
            state.items.removeAll(ids: ["1", "3"])
        }
        
        let remainingItems = await client.state.items
        XCTAssertEqual(remainingItems.count, 1)
        XCTAssertEqual(remainingItems.first?.id, "2")
    }
    
    func testDictionaryMutationOperators() async throws {
        let client = TestClient()
        
        // Test dictionary update with default
        await client.mutate { state in
            _ = state.dict.update(key: "counter", default: 0) { value in
                value += 1
            }
        }
        
        XCTAssertEqual(await client.state.dict["counter"], 1)
        
        // Test merge
        await client.mutate { state in
            let otherDict = ["counter": 5, "newKey": 10]
            state.dict.merge(otherDict) { _, new in new }
        }
        
        let finalDict = await client.state.dict
        XCTAssertEqual(finalDict["counter"], 5)
        XCTAssertEqual(finalDict["newKey"], 10)
    }
    
    func testValidatedMutations() async throws {
        let client = TestClient()
        
        // Define validation rules
        let validationRules: [StateValidationRule<TestState>] = [
            StateValidationRule(description: "Count must be non-negative") { state in
                guard state.count >= 0 else {
                    throw AxiomError.validationError(.invalidInput("count", "must be non-negative"))
                }
            },
            StateValidationRule(description: "Value must not be empty") { state in
                guard !state.value.isEmpty else {
                    throw AxiomError.validationError(.invalidInput("value", "must not be empty"))
                }
            }
        ]
        
        // Successful validated mutation
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
        let initialState = TestState(count: 0, value: "initial")
        
        // Debug mutation with tracing
        let (result, diff, duration, memoryDelta) = try MutationDebugger.trace({ state in
            state.value = "debugged"
            state.count = 42
            return state.count
        }, on: initialState, logLevel: .detailed)
        
        XCTAssertEqual(result, 42)
        XCTAssertTrue(diff.hasChanges())
        XCTAssertGreaterThan(duration, 0)
        XCTAssertLessThan(duration, 0.001) // Should be very fast
        XCTAssertEqual(diff.after.value, "debugged")
        XCTAssertEqual(diff.after.count, 42)
        XCTAssertGreaterThanOrEqual(memoryDelta, 0) // Memory delta tracked
    }
    
    func testUndoRedoSupport() async throws {
        let undoManager = UndoManager<TestState>(maxHistory: 10)
        let client = TestClient()
        
        // Record initial state
        await undoManager.recordSnapshot(await client.state)
        
        // Make changes and record snapshots
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
    
    func testTransactionConditionalTransform() async throws {
        let client = TestClient()
        
        // Set initial state
        await client.mutate { state in
            state.count = 50
            state.value = "initial"
            state.items = [TestItem(id: "1", name: "Item", value: 10)]
        }
        
        // Test conditional transform
        try await client.transaction { transaction in
            // This should execute since count > 40
            transaction.transformIf({ $0.count > 40 }, \.value) { value in
                return value.uppercased()
            }
            
            // This should not execute since count < 100
            transaction.transformIf({ $0.count > 100 }, \.items) { items in
                var newItems = items
                newItems.append(TestItem(id: "2", name: "Should not appear", value: 20))
                return newItems
            }
        }
        
        XCTAssertEqual(await client.state.value, "INITIAL")
        XCTAssertEqual(await client.state.items.count, 1) // Should not have added item
    }
    
    func testEnhancedPropertyMutationOperators() async throws {
        let client = TestClient()
        
        // Test string mutations
        await client.mutate { state in
            state.value = "hello"
            state.value.append(" world")
            state.value.prepend("Say: ")
            state.value.replaceAll("world", with: "Swift")
        }
        
        XCTAssertEqual(await client.state.value, "Say: hello Swift")
        
        // Test int mutations
        await client.mutate { state in
            state.count = 10
            state.count.increment(by: 5)
            state.count.decrement(by: 3)
            state.count.multiply(by: 2)
        }
        
        XCTAssertEqual(await client.state.count, 24) // (10 + 5 - 3) * 2
    }
    
    func testEnhancedArrayMutationOperators() async throws {
        let client = TestClient()
        
        // Set initial state with duplicates
        await client.mutate { state in
            state.items = [
                TestItem(id: "1", name: "Item 1", value: 10),
                TestItem(id: "2", name: "Item 2", value: 20),
                TestItem(id: "3", name: "Item 3", value: 30),
                TestItem(id: "2", name: "Item 2", value: 20), // Duplicate
                TestItem(id: "4", name: "Item 4", value: 40)
            ]
        }
        
        // Test remove duplicates
        await client.mutate { state in
            state.items.removeDuplicates()
        }
        
        var items = await client.state.items
        XCTAssertEqual(items.count, 4) // One duplicate removed
        
        // Test removeFirst/removeLast with predicate
        await client.mutate { state in
            _ = state.items.removeFirst { $0.value < 30 }
            _ = state.items.removeLast { $0.value > 20 }
        }
        
        items = await client.state.items
        XCTAssertEqual(items.count, 2)
        
        // Test move operation
        await client.mutate { state in
            state.items = [
                TestItem(id: "A", name: "A", value: 1),
                TestItem(id: "B", name: "B", value: 2),
                TestItem(id: "C", name: "C", value: 3)
            ]
            state.items.move(from: 0, to: 2)
        }
        
        items = await client.state.items
        XCTAssertEqual(items.map { $0.id }, ["B", "C", "A"])
    }
    
    func testSetMutationOperators() async throws {
        struct SetState: State, Equatable {
            var id = UUID().uuidString
            var tags: Set<String> = []
            var active = false
        }
        
        actor SetClient: BaseClient<SetState, TestAction>, ObservableClient {
            typealias S = SetState
            
            init() {
                super.init(initialState: SetState())
            }
            
            func process(_ action: TestAction) async throws {}
        }
        
        let client = SetClient()
        
        // Test toggle membership
        await client.mutate { state in
            _ = state.tags.toggle("swift") // Add
            _ = state.tags.toggle("ios") // Add
            let wasPresent = state.tags.toggle("swift") // Remove
            XCTAssertFalse(wasPresent)
        }
        
        XCTAssertEqual(await client.state.tags, ["ios"])
        
        // Test insert multiple
        await client.mutate { state in
            state.tags.insert(contentsOf: ["swiftui", "combine", "async"])
        }
        
        XCTAssertEqual(await client.state.tags.count, 4)
        
        // Test bool toggle
        await client.mutate { state in
            state.active.toggle()
        }
        
        XCTAssertTrue(await client.state.active)
    }
}