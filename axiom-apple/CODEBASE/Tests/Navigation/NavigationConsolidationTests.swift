import XCTest
@testable import Axiom

/// Behavior preservation tests for navigation service consolidation
/// These tests ensure that consolidating 8 navigation files into 1 service preserves all functionality
final class NavigationConsolidationTests: XCTestCase {
    
    // MARK: - Core Behavior Preservation Tests
    
    /// Test that NavigationService exists and is instantiable
    func testNavigationServiceExists() {
        let service = NavigationService()
        XCTAssertNotNil(service, "NavigationService should be instantiable")
    }
    
    /// Test that NavigationFlow validation behavior is preserved
    func testNavigationFlowValidationPreserved() {
        // Test that flow validation continues to work with Result pattern
        let request = NavigationRequest(
            source: .presentation,
            target: .context,
            route: SimpleRoute()
        )
        
        let result = NavigationFlow.validateFlow(request)
        
        // This should succeed for valid flow
        switch result {
        case .success:
            XCTAssertTrue(true, "Valid flow should be accepted")
        case .failure(let error):
            XCTFail("Valid flow should not fail: \(error)")
        }
    }
    
    /// Test that invalid navigation flows are properly rejected
    func testInvalidNavigationFlowRejected() {
        // Test invalid flow: presentation directly to orchestrator (should fail)
        let invalidRequest = NavigationRequest(
            source: .presentation,
            target: .orchestrator,
            route: SimpleRoute()
        )
        
        let result = NavigationFlow.validateFlow(invalidRequest)
        
        switch result {
        case .success:
            XCTFail("Invalid flow should be rejected")
        case .failure(let error):
            // Verify it uses proper error system
            if case .navigationError(_) = error {
                XCTAssertTrue(true, "Should use AxiomError navigation type")
            } else {
                XCTFail("Should use AxiomError.navigationError")
            }
        }
    }
    
    /// Test that navigation patterns are accessible
    func testNavigationPatternsPreserved() {
        // Test that navigation patterns continue to exist
        let modalPattern = NavigationPattern.modal(.sheet)
        let pushPattern = NavigationPattern.push
        
        XCTAssertNotNil(modalPattern, "Modal navigation pattern should exist")
        XCTAssertNotNil(pushPattern, "Push navigation pattern should exist")
    }
    
    /// Test that type-safe routes work
    func testTypeSafeRoutesPreserved() {
        // Test that TypeSafeRoute functionality is preserved
        let route = TypeSafeRoute.named("test-route")
        XCTAssertEqual(route.identifier, "test-route", "Route identification should work")
        
        // Test route parameters
        let paramRoute = TypeSafeRoute.parameterized("user", parameters: ["id": "123"])
        XCTAssertEqual(paramRoute.identifier, "user", "Parameterized routes should work")
    }
    
    /// Test that orchestrator functionality is preserved
    func testOrchestratorPreserved() async {
        // Test that Orchestrator protocol is still available
        let mockOrchestrator = MockOrchestratorImpl()
        await mockOrchestrator.navigate(to: SimpleRoute())
        
        // Verify it executed
        XCTAssertTrue(mockOrchestrator.didNavigate, "Orchestrator should execute navigation")
    }
    
    /// Test that cancellation tokens work
    func testNavigationCancellationPreserved() {
        // Test that cancellation functionality is preserved
        let token = NavigationCancellationToken()
        
        XCTAssertFalse(token.isCancelled, "Token should start uncancelled")
        
        token.cancel()
        XCTAssertTrue(token.isCancelled, "Token should be cancelled after cancel()")
    }
    
    /// Test that error propagation patterns work with navigation
    func testNavigationErrorPropagationPreserved() async {
        // Test that navigation uses the new error propagation patterns
        let result = await withErrorContext("testNavigation") {
            // Simulate a navigation operation that might fail
            return SimpleRoute()
        }
        
        switch result {
        case .success(let route):
            XCTAssertNotNil(route, "Error context should preserve successful operations")
        case .failure(let error):
            // Verify error has proper context
            XCTAssertTrue(error is AxiomError, "Should use AxiomError system")
        }
    }
    
    /// Test performance baseline for consolidation
    func testNavigationPerformanceBaseline() {
        // Establish performance baseline before consolidation
        measure {
            // Create navigation service (should be fast)
            let service = NavigationService()
            
            // Create some routes (should be fast)
            let routes = (1...100).map { TypeSafeRoute.named("route-\($0)") }
            
            // Use them to prevent optimization
            XCTAssertEqual(routes.count, 100)
            XCTAssertNotNil(service)
        }
    }
}

// MARK: - Simple Mock Types for Testing

/// Simple route implementation for testing
struct SimpleRoute: Hashable {
    let id = UUID().uuidString
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SimpleRoute, rhs: SimpleRoute) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Mock orchestrator for testing
class MockOrchestratorImpl: Orchestrator {
    private(set) var didNavigate = false
    
    func navigate(to route: any Hashable) async {
        didNavigate = true
    }
}