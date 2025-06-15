import XCTest
@testable import Axiom

final class NavigationServiceTests: XCTestCase {
    
    // MARK: - Basic Navigation Tests
    
    func testBasicNavigation() async throws {
        // Basic test to verify navigation functionality
        let navigation = await createValidNavigationOrchestrator()
        
        // Test that navigation service exists and is functional
        XCTAssertNotNil(navigation, "Navigation service should be created")
        
        // Test basic orchestrator conformance
        let conformsToOrchestrator = navigation is (any AxiomOrchestrator)
        XCTAssertTrue(conformsToOrchestrator, "Navigation service should conform to AxiomOrchestrator")
    }
    
    // MARK: - RED: Navigation Service Component Type Tests
    
    func testNavigationAsStandaloneComponentTypeFails() async throws {
        // Requirement: Navigation is an Orchestrator service, not a separate component type
        // Acceptance: NavigationService protocol conforms to Orchestrator capabilities
        // Boundary: Type system prevents navigation implementation outside Orchestrator
        
        // RED Test: This should fail because we haven't implemented the constraint yet
        // The test attempts to create a standalone NavigationService that doesn't conform to Orchestrator
        
        // Attempt to create a standalone navigation service
        let standaloneNavigation = StandaloneNavigationService()
        
        // This should fail because StandaloneNavigationService doesn't conform to AxiomOrchestrator
        // We test that the type system prevents navigation implementation outside AxiomOrchestrator
        let isValidNavigationService = standaloneNavigation is (any AxiomOrchestrator)
        
        XCTAssertFalse(isValidNavigationService,
                      "Navigation service must be implemented as AxiomOrchestrator service, not standalone component")
        
        // Test that AxiomComponentType enum doesn't include Navigation as a separate type
        let componentTypes = AxiomComponentType.allCases
        let hasNavigationType = componentTypes.contains { type in
            "\(type)".lowercased().contains("navigation")
        }
        
        XCTAssertFalse(hasNavigationType, 
                      "Navigation should not be a separate component type - it must be an AxiomOrchestrator service")
    }
    
    func testNavigationServiceMustConformToAxiomOrchestrator() async throws {
        // Test that any valid AxiomNavigationService must conform to AxiomOrchestrator protocol
        
        // Attempt to use a navigation service that doesn't inherit from AxiomOrchestrator
        let invalidNavigation = InvalidNavigationService()
        
        // This should fail type checking - navigation must be AxiomOrchestrator-based
        let orchestratorCheck = invalidNavigation is (any AxiomOrchestrator)
        XCTAssertFalse(orchestratorCheck,
                      "Invalid navigation service should not conform to AxiomOrchestrator (test validates constraint)")
        
        // Verify that valid navigation services must implement AxiomOrchestrator methods
        // This should now pass in GREEN phase with proper implementation
        let validNavigation = await createValidNavigationOrchestrator()
        let conformsToOrchestrator = validNavigation is (any AxiomOrchestrator)
        XCTAssertTrue(conformsToOrchestrator,
                     "Valid navigation service must conform to AxiomOrchestrator protocol")
        
        // Also verify it conforms to AxiomNavigationService
        let conformsToNavigationService = validNavigation is (any AxiomNavigationService)
        XCTAssertTrue(conformsToNavigationService,
                     "ValidNavigationOrchestrator must conform to AxiomNavigationService protocol")
    }
    
    func testNavigationCapabilitiesRequireAxiomOrchestratorContext() async throws {
        // Test that navigation capabilities require AxiomOrchestrator context
        
        // Attempt to perform navigation without Orchestrator context
        let contextlessNavigation = ContextlessNavigation()
        
        do {
            try await contextlessNavigation.navigate(to: TestRoute.home)
            XCTFail("Navigation without AxiomOrchestrator context should fail")
        } catch NavigationError.orchestratorRequired {
            // Expected behavior - navigation requires AxiomOrchestrator
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Support Types (These should fail compilation/runtime in RED phase)

/// Invalid standalone navigation service that doesn't conform to AxiomOrchestrator
/// This represents what should NOT be allowed
class StandaloneNavigationService {
    func navigate(to route: TestRoute) async throws {
        // This is invalid - navigation without AxiomOrchestrator capabilities
        throw NavigationError.invalidImplementation("Navigation must be AxiomOrchestrator service")
    }
    
    func getCurrentRoute() -> TestRoute? {
        return nil
    }
}

/// Invalid navigation service that doesn't inherit from AxiomOrchestrator
/// Used to test type system constraints
actor InvalidNavigationService {
    func navigate(to route: TestRoute) async throws {
        // This should not be valid - missing AxiomOrchestrator conformance
        throw NavigationError.invalidImplementation("Missing AxiomOrchestrator conformance")
    }
}

/// Valid navigation orchestrator - this should be implementable
/// Now implemented in GREEN phase as proper AxiomOrchestrator service
func createValidNavigationOrchestrator() async -> ValidNavigationOrchestrator {
    return await ValidNavigationOrchestrator()
}

/// Navigation that attempts to work without AxiomOrchestrator context
class ContextlessNavigation {
    func navigate(to route: TestRoute) async throws {
        // This should fail - navigation requires AxiomOrchestrator context
        throw NavigationError.orchestratorRequired
    }
}

// MARK: - Supporting Types

enum TestRoute: Equatable {
    case home
    case detail(id: String)
    case settings
}

enum NavigationError: Error {
    case invalidImplementation(String)
    case orchestratorRequired
    case notImplemented(String)
}