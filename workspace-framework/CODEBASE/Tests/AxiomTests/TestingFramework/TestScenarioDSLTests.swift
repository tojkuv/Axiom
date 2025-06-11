import XCTest
import AxiomTesting
@testable import Axiom

final class TestScenarioDSLTests: XCTestCase {
    
    func testBasicTestScenarioStructure() async throws {
        // This test validates the basic DSL structure works
        var setupCalled = false
        var actionCalled = false
        var assertionCalled = false
        
        try await TestScenario {
            Given {
                setupCalled = true
                return TestContext()
            }
            When { (context: TestContext) in
                actionCalled = true
                context.value = 42
            }
            Then { (context: TestContext) in
                assertionCalled = true
                XCTAssertEqual(context.value, 42)
            }
        }.run()
        
        XCTAssertTrue(setupCalled, "Given block should be called")
        XCTAssertTrue(actionCalled, "When block should be called")
        XCTAssertTrue(assertionCalled, "Then block should be called")
    }
    
    func testAsyncStateObservation() async throws {
        // This test validates async state observation with ThenEventually
        try await TestScenario {
            Given {
                MockAsyncClient()
            }
            When { (client: MockAsyncClient) in
                // This triggers an async state change
                await client.process(.updateValue(100))
            }
            ThenEventually(timeout: .seconds(2)) { (client: MockAsyncClient) async in
                // Should automatically wait for the state to update
                await client.state.value == 100
            }
        }.run()
    }
    
    func testMultipleWhenThenSteps() async throws {
        // Test that multiple When/Then steps work correctly
        try await TestScenario {
            Given {
                TestCounter()
            }
            When { (counter: TestCounter) in
                counter.increment()
            }
            Then { (counter: TestCounter) in
                XCTAssertEqual(counter.value, 1)
            }
            When { (counter: TestCounter) in
                counter.increment()
                counter.increment()
            }
            Then { (counter: TestCounter) in
                XCTAssertEqual(counter.value, 3)
            }
        }.run()
    }
    
    func testErrorHandling() async throws {
        // Test that errors are properly propagated
        do {
            try await TestScenario {
                Given {
                    ErrorThrowingContext()
                }
                When { (context: ErrorThrowingContext) in
                    try context.performFailingOperation()
                }
                Then { _ in
                    XCTFail("Should not reach here")
                }
            }.run()
            
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }
    
    func testTimeoutBehavior() async throws {
        // Test that ThenEventually properly times out
        do {
            try await TestScenario {
                Given {
                    SlowUpdatingClient()
                }
                When { (client: SlowUpdatingClient) in
                    await client.startSlowUpdate()
                }
                ThenEventually(timeout: .milliseconds(100)) { (client: SlowUpdatingClient) async in
                    // This will never be true within timeout
                    await client.isComplete
                }
            }.run()
            
            XCTFail("Expected timeout error")
        } catch TestScenarioError.conditionTimeout {
            // Expected timeout
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Helpers

private class TestContext {
    var value: Int = 0
}

private class TestCounter {
    private(set) var value: Int = 0
    
    func increment() {
        value += 1
    }
}

private actor MockAsyncClient {
    private(set) var state = State(value: 0)
    
    struct State {
        let value: Int
    }
    
    func process(_ action: Action) async {
        switch action {
        case .updateValue(let newValue):
            // Simulate async delay
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            state = State(value: newValue)
        }
    }
    
    enum Action {
        case updateValue(Int)
    }
}

private class ErrorThrowingContext {
    struct TestError: Error {}
    
    func performFailingOperation() throws {
        throw TestError()
    }
}

private actor SlowUpdatingClient {
    private(set) var isComplete = false
    
    func startSlowUpdate() async {
        Task {
            // This takes longer than our test timeout
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            isComplete = true
        }
    }
}