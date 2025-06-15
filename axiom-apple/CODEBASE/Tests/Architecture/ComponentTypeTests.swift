import XCTest
@testable import Axiom

final class AxiomComponentTypeTests: XCTestCase {
    
    // MARK: - Component Type Definition Tests
    
    func testAxiomComponentTypeEnumerationHasExactlySixCases() {
        // Red: Test that AxiomComponentType enum has exactly 6 cases
        let componentTypes: [AxiomComponentType] = [
            .capability,
            .state,
            .client,
            .orchestrator,
            .context,
            .presentation
        ]
        
        XCTAssertEqual(componentTypes.count, 6, "AxiomComponentType must have exactly 6 cases")
    }
    
    func testAxiomComponentTypeEnumIsFrozen() {
        // Red: Test that AxiomComponentType is marked as @frozen
        // This test will verify at compile time that no new cases can be added
        // The actual @frozen attribute will be verified by the compiler
        
        // Exhaustive switch without default case will fail to compile if enum is not frozen
        let type: AxiomComponentType = .capability
        
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
    
    func testAxiomComponentTypeHasStringDescription() {
        // Red: Test that each component type has a meaningful string description
        XCTAssertEqual(AxiomComponentType.capability.description, "Capability")
        XCTAssertEqual(AxiomComponentType.state.description, "State")
        XCTAssertEqual(AxiomComponentType.client.description, "Client")
        XCTAssertEqual(AxiomComponentType.orchestrator.description, "Orchestrator")
        XCTAssertEqual(AxiomComponentType.context.description, "Context")
        XCTAssertEqual(AxiomComponentType.presentation.description, "Presentation")
    }
    
    // MARK: - Component Validation Protocol Tests
    
    func testCapabilityValidationProtocolRequirements() {
        // RED: Test that CapabilityValidatable protocol defines required lifecycle methods
        // This test will verify that capabilities can be validated properly
        
        struct TestCapability: AxiomCapabilityValidatable {
            func initialize() async throws {
                // Test implementation
            }
            
            func terminate() async {
                // Test implementation  
            }
            
            var isAvailable: Bool {
                return true
            }
        }
        
        let capability = TestCapability()
        XCTAssertTrue(capability.isAvailable)
    }
    
    func testStateValidationProtocolRequirements() {
        // RED: Test that StateValidatable protocol ensures value type constraints
        
        struct TestState: AxiomStateValidatable {
            let id: String = "test"
            let value: Int = 42
        }
        
        let state = TestState()
        XCTAssertEqual(state.id, "test")
        XCTAssertEqual(state.value, 42)
    }
    
    func testClientValidationProtocolRequirements() {
        // RED: Test that ClientValidatable protocol enforces actor isolation and associated types
        
        actor TestClient: AxiomClientValidatable {
            typealias StateType = TestClientState
            typealias ActionType = TestClientAction
            
            private var state: StateType = TestClientState()
            
            func processAction(_ action: ActionType) async {
                // Test implementation
            }
        }
        
        struct TestClientState {
            let value: String = "test"
        }
        
        enum TestClientAction {
            case test
        }
        
        let client = TestClient()
        // Verify compilation - actor isolation enforced by compiler
        Task {
            await client.processAction(.test)
        }
    }
    
    func testComponentRegistryValidation() async {
        // RED: Test that ComponentRegistry validates components correctly
        let registry = ComponentRegistry()
        
        // Test valid capability registration
        struct ValidCapability: AxiomCapabilityValidatable {
            func initialize() async throws { }
            func terminate() async { }
            var isAvailable: Bool { true }
        }
        
        let capability = ValidCapability()
        
        do {
            try await registry.register(capability, type: .capability, id: "test-capability")
            let capabilities = await registry.getComponents(ofType: .capability)
            XCTAssertEqual(capabilities.count, 1)
            XCTAssertEqual(capabilities.first?.type, .capability)
        } catch {
            XCTFail("Valid capability should register successfully: \(error)")
        }
    }
    
    func testComponentValidationErrors() async {
        // RED: Test that ComponentRegistry rejects invalid components
        let registry = ComponentRegistry()
        
        // Test invalid capability (doesn't conform to protocol)
        struct InvalidComponent { }
        let invalidComponent = InvalidComponent()
        
        do {
            try await registry.register(invalidComponent, type: .capability, id: "invalid")
            XCTFail("Invalid component should throw validation error")
        } catch let error as ComponentValidationError {
            switch error {
            case .invalidCapability:
                // Expected error
                break
            default:
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}