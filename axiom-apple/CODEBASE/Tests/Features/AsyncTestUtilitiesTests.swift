import XCTest
@testable import Axiom
@testable import AxiomTesting

final class AsyncTestUtilitiesTests: XCTestCase {
    
    // Test data structures
    struct TestState: State, Equatable {
        let count: Int
    }
    
    enum TestAction: Equatable {
        case increment
        case decrement
        case setValue(Int)
    }
    
    // MARK: - State Collection Tests
    
    func testCollectStatesUtility() async throws {
        // Given: A mock client
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Collecting states while processing actions
        let states = try await AsyncTestHelpers.collectStates(
            from: client,
            count: 3
        ) { client in
            await client.setState(TestState(count: 1))
            await client.setState(TestState(count: 2))
            await client.setState(TestState(count: 3))
        }
        
        // Then: All states should be collected
        XCTAssertEqual(states.count, 3)
        XCTAssertEqual(states[0].count, 0) // Initial state
        XCTAssertEqual(states[1].count, 1)
        XCTAssertEqual(states[2].count, 2)
    }
    
    func testCollectStatesTimeout() async throws {
        // Given: A mock client that doesn't produce enough states
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Trying to collect more states than produced
        do {
            _ = try await AsyncTestHelpers.collectStates(
                from: client,
                count: 5,
                timeout: .milliseconds(100)
            ) { client in
                await client.setState(TestState(count: 1))
                await client.setState(TestState(count: 2))
                // Only 3 states total (including initial), but we want 5
            }
            XCTFail("Should have thrown timeout error")
        } catch let error as AsyncTestError {
            // Then: Should throw timeout error
            if case .timeout(let message) = error {
                XCTAssertTrue(message.contains("3 of 5"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Wait For State Tests
    
    func testWaitForStateCondition() async throws {
        // Given: A mock client
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Waiting for a specific state
        Task {
            try await Task.sleep(for: .milliseconds(50))
            await client.setState(TestState(count: 5))
            await client.setState(TestState(count: 10))
        }
        
        let foundState = try await AsyncTestHelpers.waitForState(
            in: client,
            timeout: .seconds(1)
        ) { state in
            state.count == 10
        }
        
        // Then: Should find the matching state
        XCTAssertEqual(foundState.count, 10)
    }
    
    func testWaitForStateTimeout() async throws {
        // Given: A mock client
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Waiting for a state that never arrives
        do {
            _ = try await AsyncTestHelpers.waitForState(
                in: client,
                timeout: .milliseconds(100)
            ) { state in
                state.count == 999 // Never happens
            }
            XCTFail("Should have thrown timeout error")
        } catch let error as AsyncTestError {
            // Then: Should throw timeout error
            if case .timeout = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - State Sequence Tests
    
    func testAssertStateSequence() async throws {
        // Given: A mock client
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Asserting a sequence of states
        try await AsyncTestHelpers.assertStateSequence(
            from: client,
            timeout: .seconds(1),
            sequence: [
                { $0.count == 0 }, // Initial
                { $0.count == 1 },
                { $0.count == 2 },
                { $0.count == 3 }
            ]
        ) { client in
            await client.setState(TestState(count: 1))
            await client.setState(TestState(count: 2))
            await client.setState(TestState(count: 3))
        }
        
        // Test passes if no error thrown
    }
    
    func testAssertStateSequenceIncomplete() async throws {
        // Given: A mock client
        let client = AxiomTesting.MockClient<TestState, TestAction>(initialState: TestState(count: 0))
        
        // When: Sequence is not completed
        do {
            try await AsyncTestHelpers.assertStateSequence(
                from: client,
                timeout: .milliseconds(100),
                sequence: [
                    { $0.count == 0 },
                    { $0.count == 1 },
                    { $0.count == 999 } // Never happens
                ]
            ) { client in
                await client.setState(TestState(count: 1))
            }
            XCTFail("Should have thrown sequence incomplete error")
        } catch let error as AsyncTestError {
            // Then: Should throw sequence incomplete error
            if case .sequenceIncomplete(let message) = error {
                XCTAssertTrue(message.contains("2 of 3"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - Action Recording Tests
    
    func testActionRecording() async throws {
        // Given: An action recorder
        let recorder = ActionRecorder<TestAction>()
        
        // When: Recording actions
        await recorder.record(.increment)
        await recorder.record(.setValue(42))
        await recorder.record(.decrement)
        
        // Then: Should have recorded all actions
        await recorder.assertCount(3)
        await recorder.assertSequence([.increment, .setValue(42), .decrement])
    }
    
    func testActionRecorderReset() async throws {
        // Given: An action recorder with some actions
        let recorder = ActionRecorder<TestAction>()
        await recorder.record(.increment)
        await recorder.record(.decrement)
        
        // When: Resetting the recorder
        await recorder.reset()
        
        // Then: Should have no actions
        await recorder.assertCount(0)
    }
    
    // MARK: - Timing Utility Tests
    
    func testWaitUntilCondition() async throws {
        // Given: A changing condition
        var conditionMet = false
        
        Task {
            try await Task.sleep(for: .milliseconds(50))
            conditionMet = true
        }
        
        // When: Waiting for the condition
        try await TimingHelpers.waitUntil(
            timeout: .seconds(1),
            pollingInterval: .milliseconds(10)
        ) {
            conditionMet
        }
        
        // Then: Should complete without error
        XCTAssertTrue(conditionMet)
    }
    
    func testWaitUntilTimeout() async throws {
        // Given: A condition that never becomes true
        let condition = { false }
        
        // When: Waiting for the condition
        do {
            try await TimingHelpers.waitUntil(
                timeout: .milliseconds(100),
                pollingInterval: .milliseconds(10)
            ) {
                condition()
            }
            XCTFail("Should have thrown timeout error")
        } catch let error as AsyncTestError {
            // Then: Should throw timeout error
            if case .timeout = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testEventuallyAssertion() async throws {
        // Given: A value that changes over time
        var value = 0
        
        Task {
            for i in 1...5 {
                try await Task.sleep(for: .milliseconds(20))
                value = i
            }
        }
        
        // When: Using eventually to assert
        try await TimingHelpers.eventually(
            within: .seconds(1),
            pollingInterval: .milliseconds(10)
        ) {
            if value != 5 {
                throw AsyncTestError.timeout("Value not yet 5")
            }
        }
        
        // Test passes if no error thrown
    }
    
    func testEventuallyAssertionFails() async throws {
        // Given: A value that never reaches expected state
        let value = 0
        
        // When: Using eventually with impossible assertion
        do {
            try await TimingHelpers.eventually(
                within: .milliseconds(100),
                pollingInterval: .milliseconds(10)
            ) {
                if value != 999 {
                    throw AsyncTestError.timeout("Value is not 999")
                }
            }
            XCTFail("Should have thrown eventually failed error")
        } catch let error as AsyncTestError {
            // Then: Should throw eventually failed error
            if case .eventuallyFailed = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    // MARK: - XCTest Extension Tests
    
    func testRunAsyncTestWithTimeout() async throws {
        // Given: A test that completes in time
        try await runAsyncTest(timeout: .seconds(1)) {
            try await Task.sleep(for: .milliseconds(50))
            // Test completes successfully
        }
        
        // Test passes if no error thrown
    }
    
    func testRunAsyncTestTimeout() async throws {
        // Given: A test that takes too long
        do {
            try await runAsyncTest(timeout: .milliseconds(100)) {
                try await Task.sleep(for: .seconds(1))
            }
            XCTFail("Should have thrown timeout error")
        } catch let error as AsyncTestError {
            // Then: Should throw timeout error
            if case .timeout = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
}