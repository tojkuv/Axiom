import XCTest
@testable import Axiom

final class UnidirectionalFlowTests: XCTestCase {
    
    // Test that reverse dependencies fail at compile time
    func testReverseDependenciesFail() {
        // Test Capability → Client (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .capability, to: .client), 
                       "Capability should not depend on Client")
        
        // Test Client → Context (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .client, to: .context),
                       "Client should not depend on Context")
        
        // Test Context → Orchestrator (reverse) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .context, to: .orchestrator),
                       "Context should not depend on Orchestrator")
        
        // Test State → Client (reverse from owner) fails
        XCTAssertFalse(UnidirectionalFlow.validate(from: .state, to: .client),
                       "State should not depend on Client")
        
        // Test Presentation → Context (reverse from binding) fails  
        XCTAssertFalse(UnidirectionalFlow.validate(from: .presentation, to: .context),
                       "Presentation should not have explicit dependency on Context")
    }
    
    // Test that forward dependencies are allowed
    func testForwardDependenciesAllowed() {
        // Test Orchestrator → Context is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .orchestrator, to: .context),
                      "Orchestrator should be able to depend on Context")
        
        // Test Context → Client is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .context, to: .client),
                      "Context should be able to depend on Client")
        
        // Test Client → Capability is allowed
        XCTAssertTrue(UnidirectionalFlow.validate(from: .client, to: .capability),
                      "Client should be able to depend on Capability")
    }
    
    // Test that the dependency flow is strictly unidirectional
    func testStrictUnidirectionalFlow() {
        let flowOrder: [ComponentType] = [.orchestrator, .context, .client, .capability]
        
        // Verify each component can only depend on downstream components
        for (index, component) in flowOrder.enumerated() {
            // Check dependencies on upstream components fail
            for upstreamIndex in 0..<index {
                let upstreamComponent = flowOrder[upstreamIndex]
                XCTAssertFalse(UnidirectionalFlow.validate(from: component, to: upstreamComponent),
                             "\(component) should not depend on upstream \(upstreamComponent)")
            }
            
            // Check dependencies on downstream components pass
            for downstreamIndex in (index + 1)..<flowOrder.count {
                let downstreamComponent = flowOrder[downstreamIndex]
                XCTAssertTrue(UnidirectionalFlow.validate(from: component, to: downstreamComponent),
                            "\(component) should be able to depend on downstream \(downstreamComponent)")
            }
        }
    }
    
    // MARK: - Enhanced Unidirectional Flow Validation Tests
    
    func testDependencyValidatableProtocol() {
        // RED: Test that components can declare their type for validation
        
        struct TestCapability: DependencyValidatable {
            static var componentType: ComponentType { .capability }
        }
        
        struct TestClient: DependencyValidatable {
            static var componentType: ComponentType { .client }
        }
        
        // Test protocol-based validation
        let capabilityValidation = TestClient.validateDependency(on: TestCapability.self)
        XCTAssertNotNil(capabilityValidation, "Client should be able to depend on Capability")
        
        // Test invalid dependency should fail
        XCTAssertThrowsError(try TestCapability.validateDependency(on: TestClient.self)) { error in
            XCTAssertTrue(error is UnidirectionalFlowError, "Should throw UnidirectionalFlowError")
        }
    }
    
    func testValidationTokenSystem() {
        // RED: Test that validation tokens are generated for valid dependencies
        let tokenResult = UnidirectionalFlow.generateValidationToken(from: .client, to: .capability)
        
        XCTAssertTrue(tokenResult.isValid, "Valid dependency should generate token")
        XCTAssertNotNil(tokenResult.token, "Valid dependency should have validation token")
        
        // Test invalid dependency doesn't generate token
        let invalidTokenResult = UnidirectionalFlow.generateValidationToken(from: .capability, to: .client)
        XCTAssertFalse(invalidTokenResult.isValid, "Invalid dependency should not generate token")
        XCTAssertNil(invalidTokenResult.token, "Invalid dependency should not have token")
        XCTAssertNotNil(invalidTokenResult.error, "Invalid dependency should have error")
    }
    
    func testRuntimeDependencyAnalyzer() {
        // RED: Test comprehensive runtime dependency analysis
        let analyzer = UnidirectionalFlow.DependencyAnalyzer()
        
        // Test valid dependency graph
        let validDependencies: [ComponentType: Set<ComponentType>] = [
            .orchestrator: [.context],
            .context: [.client],
            .client: [.capability]
        ]
        
        let validResult = analyzer.analyzeDependencyGraph(validDependencies)
        XCTAssertTrue(validResult.isValid, "Valid unidirectional graph should pass analysis")
        XCTAssertTrue(validResult.violations.isEmpty, "Valid graph should have no violations")
        XCTAssertNotNil(validResult.topologicalOrder, "Valid graph should have topological order")
        
        // Test invalid dependency graph with reverse flow
        let invalidDependencies: [ComponentType: Set<ComponentType>] = [
            .capability: [.client],  // Reverse dependency
            .client: [.context],     // Reverse dependency
            .context: [.orchestrator] // Reverse dependency
        ]
        
        let invalidResult = analyzer.analyzeDependencyGraph(invalidDependencies)
        XCTAssertFalse(invalidResult.isValid, "Invalid graph with reverse dependencies should fail")
        XCTAssertFalse(invalidResult.violations.isEmpty, "Invalid graph should have violations")
        XCTAssertEqual(invalidResult.violations.count, 3, "Should detect all three reverse dependencies")
    }
    
    func testCycleDetectionWithVisualization() {
        // RED: Test cycle detection with path visualization
        let analyzer = UnidirectionalFlow.DependencyAnalyzer()
        
        // Create cyclic dependency graph
        let cyclicDependencies: [ComponentType: Set<ComponentType>] = [
            .client: [.context],
            .context: [.orchestrator],
            .orchestrator: [.client]  // Creates cycle
        ]
        
        let result = analyzer.analyzeDependencyGraph(cyclicDependencies)
        XCTAssertFalse(result.isValid, "Cyclic graph should be invalid")
        
        // Check cycle detection
        let cycleViolations = result.violations.filter { $0.violationType == .cyclicDependency }
        XCTAssertFalse(cycleViolations.isEmpty, "Should detect cyclic dependency")
        
        // Check path visualization
        let cycleViolation = cycleViolations.first!
        XCTAssertNotNil(cycleViolation.cyclePath, "Cycle violation should include path")
        XCTAssertGreaterThanOrEqual(cycleViolation.cyclePath!.count, 3, "Cycle path should include at least 3 components")
    }
    
    func testTopologicalSortingForInitialization() {
        // RED: Test topological sorting for component initialization order
        let analyzer = UnidirectionalFlow.DependencyAnalyzer()
        
        let dependencies: [ComponentType: Set<ComponentType>] = [
            .orchestrator: [.context],
            .context: [.client],
            .client: [.capability]
        ]
        
        let result = analyzer.analyzeDependencyGraph(dependencies)
        XCTAssertTrue(result.isValid, "Valid dependency graph should pass")
        XCTAssertNotNil(result.topologicalOrder, "Should provide topological order")
        
        let order = result.topologicalOrder!
        
        // Verify correct initialization order (dependencies first)
        let capabilityIndex = order.firstIndex(of: .capability)!
        let clientIndex = order.firstIndex(of: .client)!
        let contextIndex = order.firstIndex(of: .context)!
        let orchestratorIndex = order.firstIndex(of: .orchestrator)!
        
        XCTAssertLessThan(capabilityIndex, clientIndex, "Capability should be initialized before Client")
        XCTAssertLessThan(clientIndex, contextIndex, "Client should be initialized before Context")
        XCTAssertLessThan(contextIndex, orchestratorIndex, "Context should be initialized before Orchestrator")
    }
    
    func testPerformanceOptimization() {
        // RED: Test that validation meets performance requirements (< 1ms)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform 10000 validation checks
        for _ in 0..<10000 {
            _ = UnidirectionalFlow.validate(from: .client, to: .capability)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let timePerCheck = timeElapsed / 10000.0
        
        XCTAssertLessThan(timePerCheck, 0.001, "Each validation check should take less than 1ms")
    }
    
    func testBuildScriptIntegration() {
        // RED: Test that build script integration code can be generated
        let buildScript = UnidirectionalFlow.generateBuildScriptValidation()
        
        XCTAssertFalse(buildScript.isEmpty, "Should generate build script validation")
        XCTAssertTrue(buildScript.contains("#error"), "Should contain compile-time error directives")
        XCTAssertTrue(buildScript.contains("canImport"), "Should use canImport for module validation")
        XCTAssertTrue(buildScript.contains("UnidirectionalFlow"), "Should reference flow validation")
    }
    
    func testSpecialCaseValidation() {
        // RED: Test special case validation (Client-State, Context-Presentation)
        
        // Test Client-State ownership
        let clientStateResult = UnidirectionalFlow.validateSpecialCase(from: .client, to: .state, caseType: .ownership)
        XCTAssertTrue(clientStateResult.isValid, "Client should own State")
        XCTAssertEqual(clientStateResult.caseType, .ownership, "Should identify as ownership case")
        
        // Test invalid State-Client reverse ownership
        let stateClientResult = UnidirectionalFlow.validateSpecialCase(from: .state, to: .client, caseType: .ownership)
        XCTAssertFalse(stateClientResult.isValid, "State cannot depend on Client")
        
        // Test Context-Presentation binding
        let contextPresentationResult = UnidirectionalFlow.validateSpecialCase(from: .context, to: .presentation, caseType: .binding)
        XCTAssertTrue(contextPresentationResult.isValid, "Context should bind to Presentation")
        XCTAssertEqual(contextPresentationResult.caseType, .binding, "Should identify as binding case")
        
        // Test invalid Presentation-Context reverse binding
        let presentationContextResult = UnidirectionalFlow.validateSpecialCase(from: .presentation, to: .context, caseType: .binding)
        XCTAssertFalse(presentationContextResult.isValid, "Presentation cannot directly depend on Context")
    }
}
