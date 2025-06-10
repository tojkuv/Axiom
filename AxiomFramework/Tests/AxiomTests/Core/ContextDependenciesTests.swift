import XCTest
@testable import Axiom

final class ContextDependenciesTests: XCTestCase {
    
    // MARK: - Requirement: Context can ONLY depend on Clients and downstream Contexts
    
    func testContextCannotAccessCapabilitiesDirectly() throws {
        // Contexts should NOT be able to depend on Capabilities directly
        let validator = ContextDependencyValidator()
        
        // Test case 1: Context trying to access a Capability
        let result1 = validator.validate(
            source: .context,
            target: .capability
        )
        XCTAssertFalse(result1.isValid, "Context should not be able to depend on Capability")
        XCTAssertEqual(result1.violations.count, 1)
        XCTAssertEqual(result1.violations.first?.rule, .contextCannotAccessCapability)
        
        // Test case 2: Context with valid Client dependency
        let result2 = validator.validate(
            source: .context,
            target: .client
        )
        XCTAssertTrue(result2.isValid, "Context should be able to depend on Client")
        XCTAssertTrue(result2.violations.isEmpty)
        
        // Test case 3: Context with valid downstream Context dependency
        let result3 = validator.validate(
            source: .context,
            target: .context
        )
        XCTAssertTrue(result3.isValid, "Context should be able to depend on downstream Context")
        XCTAssertTrue(result3.violations.isEmpty)
    }
    
    func testContextDependencyValidationWithNames() throws {
        // Test with specific component names
        var moduleValidator = ModuleDependencyValidator()
        
        // Add a Context -> Capability dependency (should be invalid)
        moduleValidator.addDependency(
            from: ModuleDependencyValidator.Module(name: "UserProfileContext", type: .context),
            to: ModuleDependencyValidator.Module(name: "LocationCapability", type: .capability)
        )
        
        let violations = moduleValidator.validateDependencies()
        XCTAssertFalse(violations.isEmpty, "Should detect Context -> Capability violation")
        XCTAssertTrue(violations.contains { $0.contains("UserProfileContext") && $0.contains("LocationCapability") })
    }
    
    func testContextCannotCreateCircularDependencies() throws {
        var moduleValidator = ModuleDependencyValidator()
        
        // Create a circular dependency: A -> B -> C -> A
        moduleValidator.addDependency(
            from: ModuleDependencyValidator.Module(name: "ContextA", type: .context),
            to: ModuleDependencyValidator.Module(name: "ContextB", type: .context)
        )
        moduleValidator.addDependency(
            from: ModuleDependencyValidator.Module(name: "ContextB", type: .context),
            to: ModuleDependencyValidator.Module(name: "ContextC", type: .context)
        )
        moduleValidator.addDependency(
            from: ModuleDependencyValidator.Module(name: "ContextC", type: .context),
            to: ModuleDependencyValidator.Module(name: "ContextA", type: .context)
        )
        
        let violations = moduleValidator.validateDependencies()
        XCTAssertFalse(violations.isEmpty, "Should find violations")
        XCTAssertTrue(violations.contains { $0.contains("circular") || $0.contains("cycle") || $0.contains("Circular") },
                     "Should detect circular dependency")
    }
    
    func testStaticAnalysisDetectsInvalidImports() throws {
        // Test import validation
        let importValidator = ImportValidator()
        
        let contextFileImports = """
        import Foundation
        import SwiftUI
        import Axiom
        import LocationCapability  // This should be invalid for a Context
        """
        
        let violations = importValidator.validateImports(
            contextFileImports,
            forComponentType: .context,
            componentName: "UserProfileContext"
        )
        
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations.first?.contains("LocationCapability") ?? false)
    }
    
    func testContextDependencyBoundaryConditions() throws {
        var moduleValidator = ModuleDependencyValidator()
        
        // Create 10 contexts in a valid dependency chain
        for i in 0..<9 {
            moduleValidator.addDependency(
                from: ModuleDependencyValidator.Module(name: "Context\(i+1)", type: .context),
                to: ModuleDependencyValidator.Module(name: "Context\(i)", type: .context)
            )
        }
        
        // Also add some valid Client dependencies
        for i in 0..<5 {
            moduleValidator.addDependency(
                from: ModuleDependencyValidator.Module(name: "Context\(i)", type: .context),
                to: ModuleDependencyValidator.Module(name: "Client\(i)", type: .client)
            )
        }
        
        let violations = moduleValidator.validateDependencies()
        XCTAssertTrue(violations.isEmpty, "Valid dependency chain should have no violations")
        
        // Verify zero Capability -> Context edges
        let edges = moduleValidator.getDependencyEdges()
        let invalidEdges = edges.filter { edge in
            edge.sourceType == .context && edge.targetType == .capability
        }
        XCTAssertEqual(invalidEdges.count, 0, "Should have zero Context -> Capability edges")
    }
    
    func testBuildScriptValidation() throws {
        // This simulates what a build script would do
        let buildValidator = BuildDependencyValidator()
        
        // Simulate scanning a Context module
        let contextModule = BuildDependencyValidator.ScannedModule(
            name: "UserProfileContext",
            type: .context,
            imports: ["Foundation", "SwiftUI", "UserClient", "ObservableContext"],
            dependencies: ["UserClient", "ObservableContext"]
        )
        
        let errors = buildValidator.validateModule(contextModule)
        XCTAssertTrue(errors.isEmpty, "Valid Context module should pass validation")
        
        // Now test with invalid dependency
        let invalidContextModule = BuildDependencyValidator.ScannedModule(
            name: "InvalidContext", 
            type: .context,
            imports: ["Foundation", "LocationCapability"],
            dependencies: ["LocationCapability"]
        )
        
        let errors2 = buildValidator.validateModule(invalidContextModule)
        XCTAssertFalse(errors2.isEmpty, "Context with Capability dependency should fail")
        XCTAssertTrue(errors2.first?.contains("cannot depend on Capability") ?? false)
    }
}