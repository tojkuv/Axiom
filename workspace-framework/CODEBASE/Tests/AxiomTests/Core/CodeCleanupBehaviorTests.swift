import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Behavior preservation tests for code cleanup refactoring
/// These tests ensure no functionality is lost during dead code removal
final class CodeCleanupBehaviorTests: XCTestCase {
    
    // MARK: - Error Handling Behavior Preservation
    
    func testErrorHandlingBehaviorPreserved() async throws {
        // Test that essential error handling functionality still works after cleanup
        let contextError = AxiomError.contextError(.lifecycleError("test"))
        XCTAssertEqual(contextError.localizedDescription, "Context Error: Lifecycle error: test")
        
        let clientError = AxiomError.clientError(.timeout(duration: 1.0))
        XCTAssertEqual(clientError.localizedDescription, "Client Error: Operation timed out after 1.0 seconds")
        
        let navigationError = AxiomError.navigationError(.invalidRoute("test"))
        XCTAssertEqual(navigationError.localizedDescription, "Navigation Error: Invalid route: test")
        
        // Verify recovery strategies work
        XCTAssertEqual(contextError.recoveryStrategy, .propagate)
        XCTAssertEqual(clientError.recoveryStrategy, .userPrompt(message: "Operation failed"))
    }
    
    func testAxiomErrorInitializationBehaviorPreserved() async throws {
        // Test error creation from generic errors still works
        let genericError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        let axiomError = AxiomError(from: genericError)
        
        // Should be converted to context error with unknown handling
        if case .contextError(.lifecycleError(let message)) = axiomError {
            XCTAssertTrue(message.contains("Unknown error"))
        } else {
            XCTFail("Error conversion behavior changed")
        }
    }
    
    // MARK: - Presentation Context Binding Behavior
    
    func testPresentationContextBindingCoreWorksBefore() async throws {
        // Test that presentation context binding works before cleanup
        let manager = PresentationBindingManager.shared
        
        // Count should be accessible
        let initialCount = await manager.debugBindingCount()
        XCTAssertGreaterThanOrEqual(initialCount, 0)
        
        // Binding functionality should work
        let mockClient = MockPresentationClient()
        await manager.bind(context: mockClient, to: "test-presentation")
        
        let newCount = await manager.debugBindingCount()
        XCTAssertEqual(newCount, initialCount + 1)
    }
    
    // MARK: - Launch Action Behavior
    
    func testLaunchActionBehaviorPreserved() async throws {
        // Test that launch actions work properly with URL parsing
        let launchAction = LaunchAction.deepLink(url: URL(string: "test://example")!)
        
        // Should have a valid URL
        if case .deepLink(let url) = launchAction {
            XCTAssertEqual(url.scheme, "test")
            XCTAssertEqual(url.host, "example")
        } else {
            XCTFail("Launch action behavior changed")
        }
    }
    
    // MARK: - Mutation DSL Behavior
    
    func testMutationDSLBehaviorPreserved() async throws {
        // Test that implemented mutation functionality works
        let client = TestObservableClient(initialState: TestState(value: 0))
        
        // Test that implemented mutation methods work
        await client.mutate { state in
            state.value = 42
        }
        
        let finalState = await client.state
        XCTAssertEqual(finalState.value, 42)
    }
    
    // MARK: - Framework Size Baseline
    
    func testFrameworkSizeBaseline() throws {
        // Record current file sizes before cleanup
        let errorHandlingPath = "/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/Sources/Axiom/ErrorHandling.swift"
        let errorHandlingContent = try String(contentsOfFile: errorHandlingPath)
        let errorHandlingLines = errorHandlingContent.components(separatedBy: .newlines).count
        
        // Should be around 599 lines before cleanup
        XCTAssertGreaterThan(errorHandlingLines, 590, "ErrorHandling.swift baseline size")
        
        let presentationBindingPath = "/Users/tojkuv/Documents/GitHub/axiom-apple/workspace-framework/AxiomFramework/Sources/Axiom/PresentationContextBinding.swift"
        let presentationContent = try String(contentsOfFile: presentationBindingPath)
        
        // Should contain resetForTesting before cleanup
        XCTAssertTrue(presentationContent.contains("resetForTesting"), "resetForTesting should exist before cleanup")
    }
}

// MARK: - Test Support Types

private struct TestState: State, Equatable {
    var value: Int
}

private actor TestObservableClient: ObservableClient<TestState, TestAction> {
    typealias StateType = TestState
    typealias ActionType = TestAction
    
    override init(initialState: TestState) {
        super.init(initialState: initialState)
    }
    
    override func process(_ action: TestAction) async throws {
        switch action {
        case .setValue(let newValue):
            await updateState(TestState(value: newValue))
        }
    }
}

private enum TestAction {
    case setValue(Int)
}

private actor MockPresentationClient: Context {
    let contextId = "mock-context"
    var dependencies: ContextDependencies = ContextDependencies()
}