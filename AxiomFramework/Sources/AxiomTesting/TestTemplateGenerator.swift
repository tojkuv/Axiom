import Foundation
@testable import Axiom

/// Automatic test template generation for Axiom components
public struct TestTemplateGenerator {
    
    // MARK: - Context Test Generation
    
    /// Generate test code for a context type
    public static func generateContextTests<C: Context>(
        for contextType: C.Type,
        scenarios: [TestScenarioDefinition<C>],
        template: TestTemplate? = nil
    ) -> String where C.Client: Client {
        let template = template ?? TestTemplate.default
        let className = String(describing: contextType).replacingOccurrences(of: ".", with: "")
        
        var code = """
        \(template.imports.map { "import \($0)" }.joined(separator: "\n"))
        \(template.testableImports.map { "@testable import \($0)" }.joined(separator: "\n"))
        
        final class \(className)Tests: \(template.baseClass) {
        """
        
        // Add setUp if provided
        if !template.setUp.isEmpty {
            code += """
            
            
                override func setUp() async throws {
                    \(template.setUp.split(separator: "\n").map { "        \($0)" }.joined(separator: "\n"))
                }
            """
        }
        
        // Add tearDown if provided
        if !template.tearDown.isEmpty {
            code += """
            
            
                override func tearDown() async throws {
                    \(template.tearDown.split(separator: "\n").map { "        \($0)" }.joined(separator: "\n"))
                }
            """
        }
        
        // Generate test methods
        for scenario in scenarios {
            code += generateTestMethod(for: scenario, contextType: contextType)
        }
        
        code += "\n}"
        
        return code
    }
    
    // MARK: - Client Test Generation
    
    /// Generate test code for a client type
    public static func generateClientTests<C: Client>(
        for clientType: C.Type,
        actions: [C.ActionType]
    ) -> String {
        let className = String(describing: clientType).replacingOccurrences(of: ".", with: "")
        
        var code = """
        import XCTest
        @testable import Axiom
        
        final class \(className)Tests: XCTestCase {
            
            private var client: \(String(describing: clientType))!
            
            override func setUp() async throws {
                await super.setUp()
                // Initialize client with default state
                // client = \(String(describing: clientType))(initialState: .init())
            }
            
            override func tearDown() async throws {
                client = nil
                await super.tearDown()
            }
        """
        
        // Generate test for each action
        for action in actions {
            let actionName = sanitizeActionName(String(describing: action))
            code += """
            
            
                func testProcess\(actionName)() async throws {
                    // Arrange
                    let initialState = await client.state
                    
                    // Act
                    try await client.process(.\(actionName.lowercased()))
                    
                    // Assert
                    let newState = await client.state
                    XCTAssertNotEqual(initialState, newState)
                    
                    // Verify state stream
                    var stateUpdates: [\(String(describing: C.StateType.self))] = []
                    for await state in client.stateStream {
                        stateUpdates.append(state)
                        if stateUpdates.count >= 2 { break }
                    }
                    
                    XCTAssertEqual(stateUpdates.count, 2)
                }
            """
        }
        
        code += "\n}"
        
        return code
    }
    
    // MARK: - Integration Test Generation
    
    /// Generate integration tests for orchestrator flows
    public static func generateIntegrationTests<O>(
        for orchestratorType: O.Type,
        flows: [NavigationFlow]
    ) -> String {
        let className = String(describing: orchestratorType).replacingOccurrences(of: ".", with: "")
        
        var code = """
        import XCTest
        @testable import Axiom
        
        final class \(className)IntegrationTests: XCTestCase {
            
            private var orchestrator: \(String(describing: orchestratorType))!
            
            override func setUp() async throws {
                await super.setUp()
                // Initialize orchestrator
                // orchestrator = \(String(describing: orchestratorType))()
            }
        """
        
        // Generate test for each flow
        for flow in flows {
            let flowName = flow.name.capitalizeFirst()
            code += """
            
            
                func test\(flowName)Flow() async throws {
                    // Execute flow steps
            """
            
            for (index, step) in flow.steps.enumerated() {
                switch step {
                case .navigate(let route):
                    code += """
                    
                        // Step \(index + 1): Navigate
                        await orchestrator.navigate(to: .\(String(describing: route).lowercased()))
                    """
                case .performAction(let action):
                    code += """
                    
                        // Step \(index + 1): Perform action
                        await orchestrator.performAction("\(action)")
                    """
                case .validateState:
                    code += """
                    
                        // Step \(index + 1): Validate state
                        let isValid = await orchestrator.validateCurrentState()
                        XCTAssertTrue(isValid)
                    """
                }
            }
            
            code += "\n    }"
        }
        
        code += "\n}"
        
        return code
    }
    
    // MARK: - Performance Test Generation
    
    /// Generate performance tests for a client
    public static func generatePerformanceTests<C: Client>(
        for clientType: C.Type,
        operations: [PerformanceOperation]
    ) -> String {
        let className = String(describing: clientType).replacingOccurrences(of: ".", with: "")
        
        var code = """
        import XCTest
        @testable import Axiom
        
        final class \(className)PerformanceTests: XCTestCase {
        """
        
        for operation in operations {
            let testName = operation.name.capitalizeFirst()
            code += """
            
            
                func test\(testName)Performance() async throws {
                    // Setup
                    \(operation.setup)
                    
                    // Measure
                    measure {
                        Task {
                            for _ in 0..<\(operation.iterations) {
                                \(operation.operation)
                            }
                        }
                    }
                }
            """
        }
        
        code += "\n}"
        
        return code
    }
    
    // MARK: - Mock Generation
    
    /// Generate mock implementation for a protocol
    public static func generateMock<C: Client>(for config: MockConfiguration<C>) -> String {
        let clientName = String(describing: config.type).replacingOccurrences(of: ".", with: "")
        
        var code = """
        import Foundation
        @testable import Axiom
        
        class Mock\(clientName): \(clientName) {
            
            // Call tracking
            var processCallCount = 0
            var processCallArguments: [\(String(describing: C.ActionType.self))] = []
            
            // Configured behaviors
            private var behaviors: [String: Any] = [:]
            
            override func process(_ action: \(String(describing: C.ActionType.self))) async throws {
                processCallCount += 1
                processCallArguments.append(action)
                
                // Apply configured behaviors
                switch action {
        """
        
        // Add behavior cases
        for behavior in config.behaviors {
            switch behavior {
            case .returnError(let action, let error):
                let actionCase = String(describing: action)
                code += """
                
                        case .\(actionCase):
                            throw \(String(describing: error))
                """
            case .delay(let action, let duration):
                let actionCase = String(describing: action)
                code += """
                
                        case .\(actionCase):
                            try await Task.sleep(for: .\(String(describing: duration)))
                            try await super.process(action)
                """
            case .customBehavior(let action, _):
                let actionCase = String(describing: action)
                code += """
                
                        case .\(actionCase):
                            // Custom behavior implementation
                            if let behavior = behaviors["\(actionCase)"] as? () async throws -> Void {
                                try await behavior()
                            }
                """
            }
        }
        
        code += """
        
                default:
                    try await super.process(action)
                }
            }
            
            // Reset mock
            func reset() {
                processCallCount = 0
                processCallArguments.removeAll()
                behaviors.removeAll()
            }
        }
        """
        
        return code
    }
    
    // MARK: - Test Suite Generation
    
    /// Generate a complete test suite for a type
    public static func generateTestSuite<T>(for config: TestSuiteConfiguration<T>) -> TestSuite {
        var files: [TestSuite.TestFile] = []
        
        // Generate unit tests
        if config.includeUnitTests {
            let unitTestContent = generateUnitTests(for: config)
            files.append(TestSuite.TestFile(
                name: "\(String(describing: config.targetType))Tests.swift",
                content: unitTestContent
            ))
        }
        
        // Generate integration tests
        if config.includeIntegrationTests {
            let integrationTestContent = generateIntegrationTestsForSuite(for: config)
            files.append(TestSuite.TestFile(
                name: "\(String(describing: config.targetType))IntegrationTests.swift",
                content: integrationTestContent
            ))
        }
        
        // Generate performance tests
        if config.includePerformanceTests {
            let performanceTestContent = generatePerformanceTestsForSuite(for: config)
            files.append(TestSuite.TestFile(
                name: "\(String(describing: config.targetType))PerformanceTests.swift",
                content: performanceTestContent
            ))
        }
        
        return TestSuite(files: files)
    }
    
    // MARK: - Private Helpers
    
    private static func generateTestMethod<C: Context>(
        for scenario: TestScenarioDefinition<C>,
        contextType: C.Type
    ) -> String where C.Client: Client {
        """
        
        
            func test\(scenario.name.capitalizeFirst())() async throws {
                let scenario = TestScenario(\(String(describing: contextType)).self)
                    .given(initialState: /* initial state */)
        \(scenario.actions.map { "        .when(/* \(String(describing: $0)) */)" }.joined(separator: "\n"))
        \(scenario.assertions.enumerated().map { "        .then(stateContains: { /* assertion \($0.offset + 1) */ _ in true })" }.joined(separator: "\n"))
                
                try await scenario.execute()
            }
        """
    }
    
    private static func sanitizeActionName(_ action: String) -> String {
        // Remove special characters and capitalize
        let cleaned = action
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        return cleaned.isEmpty ? "Action" : cleaned.capitalizeFirst()
    }
    
    private static func generateUnitTests<T>(for config: TestSuiteConfiguration<T>) -> String {
        let typeName = String(describing: config.targetType)
        
        var content = """
        import XCTest
        @testable import Axiom
        
        final class \(typeName)Tests: XCTestCase {
        """
        
        // Add custom scenarios
        for (index, scenario) in config.customScenarios.enumerated() {
            if let contextScenario = scenario as? TestScenarioDefinition<Context> {
                content += """
                
                
                    func test\(contextScenario.name.capitalizeFirst())() async throws {
                        // Generated test for custom scenario \(index + 1)
                        // Implementation based on scenario definition
                    }
                """
            }
        }
        
        content += "\n}"
        
        return content
    }
    
    private static func generateIntegrationTestsForSuite<T>(for config: TestSuiteConfiguration<T>) -> String {
        """
        import XCTest
        @testable import Axiom
        
        final class \(String(describing: config.targetType))IntegrationTests: XCTestCase {
            
            func testIntegrationFlow() async throws {
                // Generated integration test
                XCTAssertTrue(true)
            }
        }
        """
    }
    
    private static func generatePerformanceTestsForSuite<T>(for config: TestSuiteConfiguration<T>) -> String {
        """
        import XCTest
        @testable import Axiom
        
        final class \(String(describing: config.targetType))PerformanceTests: XCTestCase {
            
            func testPerformance() async throws {
                measure {
                    // Generated performance test
                }
            }
        }
        """
    }
}

// MARK: - String Extensions

private extension String {
    func capitalizeFirst() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
}

// MARK: - Default Templates

public extension TestTemplate {
    static let `default` = TestTemplate(
        imports: ["Foundation", "XCTest"],
        testableImports: ["Axiom"],
        baseClass: "XCTestCase",
        setUp: "await super.setUp()",
        tearDown: "await super.tearDown()"
    )
    
    static let combine = TestTemplate(
        imports: ["Foundation", "XCTest", "Combine"],
        testableImports: ["Axiom"],
        baseClass: "XCTestCase",
        setUp: "await super.setUp()",
        tearDown: "await super.tearDown()"
    )
}

// MARK: - Test Template Errors

public enum TestTemplateError: Error, LocalizedError {
    case invalidContextType
    case invalidClientType
    case generationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidContextType:
            return "Invalid context type for test generation"
        case .invalidClientType:
            return "Invalid client type for test generation"
        case .generationFailed(let reason):
            return "Test generation failed: \(reason)"
        }
    }
}