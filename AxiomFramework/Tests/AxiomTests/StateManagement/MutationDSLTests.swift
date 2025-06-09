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
}