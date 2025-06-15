import XCTest
@testable import Axiom

final class DependencyRulesTests: XCTestCase {
    
    // MARK: - Dependency Rules Tests
    
    func testComponentDependencyRulesAreDefined() {
        // Red: Test that each component type has defined dependency rules
        
        // Test Capability dependencies
        let capabilityDependencies = DependencyRules.allowedDependencies(for: .capability)
        XCTAssertNotNil(capabilityDependencies, "Capability must have defined dependency rules")
        XCTAssertTrue(capabilityDependencies.contains(.capability), "Capabilities can depend on other capabilities")
        
        // Test State dependencies
        let stateDependencies = DependencyRules.allowedDependencies(for: .state)
        XCTAssertNotNil(stateDependencies, "State must have defined dependency rules")
        XCTAssertTrue(stateDependencies.isEmpty, "States cannot depend on any component type")
        
        // Test Client dependencies  
        let clientDependencies = DependencyRules.allowedDependencies(for: .client)
        XCTAssertNotNil(clientDependencies, "Client must have defined dependency rules")
        XCTAssertTrue(clientDependencies.contains(.capability), "Clients can depend on capabilities")
        XCTAssertFalse(clientDependencies.contains(.client), "Clients cannot depend on other clients")
        
        // Test Context dependencies
        let contextDependencies = DependencyRules.allowedDependencies(for: .context)
        XCTAssertNotNil(contextDependencies, "Context must have defined dependency rules")
        XCTAssertTrue(contextDependencies.contains(.client), "Contexts can depend on clients")
        XCTAssertTrue(contextDependencies.contains(.context), "Contexts can depend on downstream contexts")
        XCTAssertFalse(contextDependencies.contains(.capability), "Contexts cannot directly depend on capabilities")
        
        // Test Orchestrator dependencies
        let orchestratorDependencies = DependencyRules.allowedDependencies(for: .orchestrator)
        XCTAssertNotNil(orchestratorDependencies, "Orchestrator must have defined dependency rules")
        XCTAssertTrue(orchestratorDependencies.contains(.context), "Orchestrator can depend on contexts")
        
        // Test Presentation dependencies
        let presentationDependencies = DependencyRules.allowedDependencies(for: .presentation)
        XCTAssertNotNil(presentationDependencies, "Presentation must have defined dependency rules")
        XCTAssertTrue(presentationDependencies.contains(.context), "Presentations can depend on contexts")
        XCTAssertEqual(presentationDependencies.count, 1, "Presentations can only depend on contexts")
    }
    
    func testDependencyValidation() {
        // Red: Test that dependency validation works correctly
        
        // Valid dependencies
        XCTAssertTrue(DependencyRules.isValidDependency(from: .client, to: .capability))
        XCTAssertTrue(DependencyRules.isValidDependency(from: .context, to: .client))
        XCTAssertTrue(DependencyRules.isValidDependency(from: .orchestrator, to: .context))
        XCTAssertTrue(DependencyRules.isValidDependency(from: .presentation, to: .context))
        XCTAssertTrue(DependencyRules.isValidDependency(from: .capability, to: .capability))
        
        // Invalid dependencies
        XCTAssertFalse(DependencyRules.isValidDependency(from: .client, to: .client))
        XCTAssertFalse(DependencyRules.isValidDependency(from: .context, to: .capability))
        XCTAssertFalse(DependencyRules.isValidDependency(from: .state, to: .client))
        XCTAssertFalse(DependencyRules.isValidDependency(from: .presentation, to: .client))
        XCTAssertFalse(DependencyRules.isValidDependency(from: .capability, to: .context))
    }
    
    func testDependencyErrorMessages() {
        // Red: Test that clear error messages are provided for invalid dependencies
        
        let error1 = DependencyRules.dependencyError(from: .client, to: .client)
        XCTAssertEqual(error1, "Client cannot depend on Client: Clients must be isolated from each other")
        
        let error2 = DependencyRules.dependencyError(from: .context, to: .capability)
        XCTAssertEqual(error2, "Context cannot depend on Capability: Contexts can only depend on Clients and downstream Contexts")
        
        let error3 = DependencyRules.dependencyError(from: .state, to: .client)
        XCTAssertEqual(error3, "State cannot depend on Client: States must be pure value types with no dependencies")
    }
    
    // MARK: - Performance Tests
    
    func testDependencyValidationPerformance() {
        // Test that dependency validation has O(1) complexity
        measure {
            for _ in 0..<10000 {
                _ = DependencyRules.isValidDependency(from: .client, to: .capability)
                _ = DependencyRules.isValidDependency(from: .context, to: .client)
                _ = DependencyRules.isValidDependency(from: .presentation, to: .context)
            }
        }
    }
    
    func testAllowedDependenciesPerformance() {
        // Test that allowed dependencies lookup has O(1) complexity
        measure {
            for _ in 0..<10000 {
                _ = DependencyRules.allowedDependencies(for: .client)
                _ = DependencyRules.allowedDependencies(for: .context)
                _ = DependencyRules.allowedDependencies(for: .presentation)
            }
        }
    }
    
    // MARK: - Graph Analysis Tests
    
    func testDependencyGraphIsAcyclic() {
        // Test that the default dependency rules form a DAG
        let dependencies: [Axiom.ComponentType: Set<Axiom.ComponentType>] = [
            .capability: [.capability],
            .state: [],
            .client: [.capability],
            .orchestrator: [.context],
            .context: [.client, .context],
            .presentation: [.context]
        ]
        
        XCTAssertTrue(DependencyRules.isAcyclicGraph(dependencies))
    }
    
    func testCyclicGraphDetection() {
        // Test that cycles are properly detected
        let cyclicDependencies: [Axiom.ComponentType: Set<Axiom.ComponentType>] = [
            .client: [.context],
            .context: [.orchestrator],
            .orchestrator: [.client]  // Creates a cycle
        ]
        
        XCTAssertFalse(DependencyRules.isAcyclicGraph(cyclicDependencies))
    }
    
    func testTopologicalSort() {
        // Test topological sorting of dependency graph
        let dependencies: [Axiom.ComponentType: Set<Axiom.ComponentType>] = [
            .presentation: [.context],
            .context: [.client],
            .client: [.capability],
            .capability: []
        ]
        
        let sorted = DependencyRules.topologicalSort(dependencies)
        XCTAssertNotNil(sorted)
        
        // Verify that dependencies come after their dependents in the sorted order
        if let sortedArray = sorted {
            let indexMap = Dictionary(uniqueKeysWithValues: sortedArray.enumerated().map { ($0.element, $0.offset) })
            
            for (source, targets) in dependencies {
                for target in targets {
                    if let sourceIndex = indexMap[source], let targetIndex = indexMap[target] {
                        XCTAssertLessThan(targetIndex, sourceIndex,
                                           "\(target) should come before \(source) in topological order")
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Dependency Rules Tests
    
    func testSelfDependencyPrevention() {
        // RED: Test that self-dependencies are properly detected and prevented
        let selfDependencies: [ComponentType: Set<ComponentType>] = [
            .client: [.client]  // Self-dependency
        ]
        
        let result = DependencyRules.validateDependencyGraph(selfDependencies)
        XCTAssertFalse(result.isValid, "Self-dependencies should be invalid")
        XCTAssertTrue(result.violations.contains { $0.violationType == .selfDependency }, 
                     "Should detect self-dependency violation")
    }
    
    func testCycleDetectionWithPath() {
        // RED: Test that cycles are detected with full path information
        let cyclicDependencies: [ComponentType: Set<ComponentType>] = [
            .client: [.context],
            .context: [.orchestrator],
            .orchestrator: [.client]  // Creates cycle: client → context → orchestrator → client
        ]
        
        let result = DependencyRules.validateDependencyGraph(cyclicDependencies)
        XCTAssertFalse(result.isValid, "Cyclic dependencies should be invalid")
        XCTAssertTrue(result.violations.contains { $0.violationType == .cyclicDependency }, 
                     "Should detect cyclic dependency")
        
        // Verify cycle path is provided
        let cycleViolation = result.violations.first { $0.violationType == .cyclicDependency }
        XCTAssertNotNil(cycleViolation?.cyclePath, "Cycle violation should include path information")
    }
    
    func testRuntimeDependencyRegistration() {
        // RED: Test that runtime dependency registration validates rules
        let validator = DependencyRules.RuntimeValidator()
        
        // Valid registration
        let validResult = validator.registerDependency(from: .client, to: .capability, context: "TestValidation")
        XCTAssertTrue(validResult.isSuccess, "Valid dependency should register successfully")
        
        // Invalid registration
        let invalidResult = validator.registerDependency(from: .client, to: .client, context: "TestValidation")
        XCTAssertFalse(invalidResult.isSuccess, "Invalid dependency should fail registration")
        XCTAssertEqual(invalidResult.error?.violationType, .isolationViolation, "Should detect isolation violation")
    }
    
    func testDAGCompositionValidation() {
        // RED: Test DAG validation for specific component hierarchies
        
        // Valid capability composition
        let validCapabilities: [ComponentType: Set<ComponentType>] = [
            .capability: [.capability]  // Capabilities can compose with other capabilities
        ]
        
        let capabilityResult = DependencyRules.validateDAGComposition(validCapabilities, componentType: .capability)
        XCTAssertTrue(capabilityResult.isValid, "Valid capability composition should pass")
        
        // Valid context hierarchy
        let validContexts: [ComponentType: Set<ComponentType>] = [
            .context: [.client, .context]  // Contexts can depend on clients and downstream contexts
        ]
        
        let contextResult = DependencyRules.validateDAGComposition(validContexts, componentType: .context)
        XCTAssertTrue(contextResult.isValid, "Valid context hierarchy should pass")
    }
    
    func testBuildTimeValidationGeneration() {
        // RED: Test that build-time validation code can be generated
        let validationCode = DependencyRules.generateBuildTimeValidation()
        
        XCTAssertFalse(validationCode.isEmpty, "Should generate build-time validation code")
        XCTAssertTrue(validationCode.contains("#error"), "Should contain compile-time error directives")
        XCTAssertTrue(validationCode.contains("canImport"), "Should use canImport for conditional compilation")
    }
    
    func testDependencyViolationDetailedErrors() {
        // RED: Test that detailed error information is provided for violations
        let violations: [ComponentType: Set<ComponentType>] = [
            .state: [.client],      // State cannot depend on anything
            .client: [.client],     // Client isolation violation
            .presentation: [.capability]  // Presentation can only depend on context
        ]
        
        let result = DependencyRules.validateDependencyGraph(violations)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.violations.count, 3, "Should detect all three violations")
        
        // Check specific violation types
        let violationTypes = Set(result.violations.map { $0.violationType })
        XCTAssertTrue(violationTypes.contains(.stateViolation))
        XCTAssertTrue(violationTypes.contains(.isolationViolation))
        XCTAssertTrue(violationTypes.contains(.presentationViolation))
    }
    
    func testPerformanceValidationThresholds() {
        // RED: Test that validation meets performance requirements (< 0.1ms per check)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform 1000 validation checks
        for _ in 0..<1000 {
            _ = DependencyRules.isValidDependency(from: .client, to: .capability)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let timePerCheck = timeElapsed / 1000.0
        
        XCTAssertLessThan(timePerCheck, 0.0001, "Each validation check should take less than 0.1ms")
    }
}