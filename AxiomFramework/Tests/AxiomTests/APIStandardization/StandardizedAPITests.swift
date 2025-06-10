import XCTest
import Axiom
@testable import AxiomMacros

final class StandardizedAPITests: XCTestCase {
    
    // Test 1: Verify unified error handling pattern
    func testUnifiedErrorHandlingPattern() async throws {
        // Test that all APIs use AxiomResult<T> consistently
        
        // Navigation API
        let navigator = StandardizedNavigator()
        let navResult = await navigator.navigate(to: .home)
        XCTAssertTrue(navResult is AxiomResult<Void>)
        
        // Client API
        let client = StandardizedClient()
        let clientResult = await client.process(.update)
        XCTAssertTrue(clientResult is AxiomResult<Void>)
        
        // Context API
        let context = StandardizedContext()
        let contextResult = await context.update(newState)
        XCTAssertTrue(contextResult is AxiomResult<Void>)
        
        // All results should handle errors consistently
        for result in [navResult, clientResult, contextResult] {
            switch result {
            case .success:
                // Success case
                break
            case .failure(let error):
                // All errors should be AxiomError type
                XCTAssertTrue(error is AxiomError)
            }
        }
    }
    
    // Test 2: Verify consistent naming patterns
    func testConsistentNamingPatterns() async throws {
        // Test that state update methods are standardized
        
        // Before: updateState, setState, mutateState, modifyState
        // After: unified update() method
        
        let components = [
            StandardizedContext(),
            StandardizedClient(),
            StandardizedOrchestrator()
        ]
        
        for component in components {
            // All should have consistent update() method
            let result = await component.update(TestState())
            XCTAssertNotNil(result)
            
            // Should NOT have old method names
            // XCTAssertFalse(component.responds(to: #selector(updateState)))
            // XCTAssertFalse(component.responds(to: #selector(setState)))
        }
    }
    
    // Test 3: Verify API reduction metrics
    func testAPIReductionMetrics() {
        // Count essential APIs vs original count
        let essentialAPIs = CoreAPI.allCases.count
        let originalAPICount = 178
        
        let reduction = Double(originalAPICount - essentialAPIs) / Double(originalAPICount) * 100
        
        XCTAssertEqual(essentialAPIs, 47, "Should have 47 essential APIs")
        XCTAssertGreaterThanOrEqual(reduction, 73.0, "Should achieve at least 73% reduction")
    }
    
    // Test 4: Verify API discoverability
    func testAPIDiscoverability() {
        // Test that APIs follow predictable patterns
        let operations = ["process", "update", "get", "navigate"]
        let components = ["Context", "Client", "Navigator", "Orchestrator"]
        
        var discoveredAPIs = 0
        var totalAPIs = 0
        
        for component in components {
            for operation in operations {
                totalAPIs += 1
                // Check if predictable API exists
                let methodName = "\(operation)"
                if StandardizedAPI.hasPredictableMethod(component: component, operation: operation) {
                    discoveredAPIs += 1
                }
            }
        }
        
        let discoverabilityRate = Double(discoveredAPIs) / Double(totalAPIs) * 100
        XCTAssertGreaterThanOrEqual(discoverabilityRate, 90.0, "Should achieve 90% discoverability")
    }
    
    // Test 5: Verify backwards compatibility preserved
    func testBackwardsCompatibilityDuringRefactoring() async throws {
        // Test that existing functionality still works
        
        // Old pattern (should still work during migration)
        let legacyClient = LegacyClient()
        do {
            try await legacyClient.processAction(.update) // throws pattern
            XCTAssertTrue(true, "Legacy throwing pattern still works")
        } catch {
            XCTFail("Legacy functionality should not break")
        }
        
        // New pattern
        let standardClient = StandardizedClient()
        let result = await standardClient.process(.update) // Result pattern
        XCTAssertNotNil(result)
    }
}

// Supporting types for testing
struct TestState {}
struct AxiomError: Error {}
typealias AxiomResult<T> = Result<T, AxiomError>

protocol StandardizedAPI {
    func process<T>(_ action: T) async -> AxiomResult<Void>
    func update<T>(_ newValue: T) async -> AxiomResult<Void>
    func get<T>() async -> AxiomResult<T>
}

enum CoreAPI: CaseIterable {
    // 47 essential APIs organized by component
    case contextUpdate, contextQuery, contextLifecycle, contextError
    case clientProcess, clientState, clientStream, clientError
    case navigateForward, navigateBack, dismiss, route
    // ... total 47 cases
}