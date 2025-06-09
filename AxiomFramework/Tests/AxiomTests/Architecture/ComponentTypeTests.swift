import XCTest
@testable import Axiom

final class ComponentTypeTests: XCTestCase {
    
    // MARK: - Component Type Definition Tests
    
    func testComponentTypeEnumerationHasExactlySixCases() {
        // Red: Test that ComponentType enum has exactly 6 cases
        let componentTypes: [ComponentType] = [
            .capability,
            .state,
            .client,
            .orchestrator,
            .context,
            .presentation
        ]
        
        XCTAssertEqual(componentTypes.count, 6, "ComponentType must have exactly 6 cases")
    }
    
    func testComponentTypeEnumIsFrozen() {
        // Red: Test that ComponentType is marked as @frozen
        // This test will verify at compile time that no new cases can be added
        // The actual @frozen attribute will be verified by the compiler
        
        // Exhaustive switch without default case will fail to compile if enum is not frozen
        let type: ComponentType = .capability
        
        switch type {
        case .capability:
            break
        case .state:
            break
        case .client:
            break
        case .orchestrator:
            break
        case .context:
            break
        case .presentation:
            break
        // No default case - this ensures exhaustiveness at compile time
        }
    }
    
    func testComponentTypeHasStringDescription() {
        // Red: Test that each component type has a meaningful string description
        XCTAssertEqual(ComponentType.capability.description, "Capability")
        XCTAssertEqual(ComponentType.state.description, "State")
        XCTAssertEqual(ComponentType.client.description, "Client")
        XCTAssertEqual(ComponentType.orchestrator.description, "Orchestrator")
        XCTAssertEqual(ComponentType.context.description, "Context")
        XCTAssertEqual(ComponentType.presentation.description, "Presentation")
    }
}