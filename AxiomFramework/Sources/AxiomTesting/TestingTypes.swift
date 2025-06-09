import Foundation
@testable import Axiom

// MARK: - Test Scenario Definition

/// Definition of a test scenario for code generation
public struct TestScenarioDefinition<C: Context> where C.Client: Client {
    public let name: String
    public let given: C.Client.StateType
    public let actions: [C.Client.ActionType]
    public let assertions: [(C.Client.StateType) -> Bool]
    
    public init(
        name: String,
        given: C.Client.StateType,
        actions: [C.Client.ActionType],
        assertions: [(C.Client.StateType) -> Bool]
    ) {
        self.name = name
        self.given = given
        self.actions = actions
        self.assertions = assertions
    }
}

// MARK: - Navigation Flow

/// Represents a navigation flow for testing
public struct NavigationFlow {
    public let name: String
    public let steps: [FlowStep]
    
    public init(name: String, steps: [FlowStep]) {
        self.name = name
        self.steps = steps
    }
    
    public enum FlowStep {
        case navigate(to: Route)
        case performAction(String)
        case validateState((Any) -> Bool)
    }
}

// MARK: - Performance Operation

/// Represents a performance test operation
public struct PerformanceOperation {
    public let name: String
    public let setup: String
    public let operation: String
    public let iterations: Int
    
    public init(
        name: String,
        setup: String,
        operation: String,
        iterations: Int
    ) {
        self.name = name
        self.setup = setup
        self.operation = operation
        self.iterations = iterations
    }
}

// MARK: - Mock Configuration

/// Configuration for generating mocks
public struct MockConfiguration<C: Client> {
    public let type: C.Type
    public let behaviors: [MockBehavior<C>]
    
    public init(type: C.Type, behaviors: [MockBehavior<C>]) {
        self.type = type
        self.behaviors = behaviors
    }
}

/// Mock behavior specification
public enum MockBehavior<C: Client> {
    case returnError(for: C.ActionType, error: Error)
    case delay(for: C.ActionType, duration: Duration)
    case customBehavior(for: C.ActionType, handler: (C.ActionType) async throws -> Void)
}

// MARK: - Test Suite Configuration

/// Configuration for generating a complete test suite
public struct TestSuiteConfiguration<T> {
    public let targetType: T.Type
    public let includeUnitTests: Bool
    public let includeIntegrationTests: Bool
    public let includePerformanceTests: Bool
    public let customScenarios: [Any]
    
    public init(
        targetType: T.Type,
        includeUnitTests: Bool = true,
        includeIntegrationTests: Bool = true,
        includePerformanceTests: Bool = true,
        customScenarios: [Any] = []
    ) {
        self.targetType = targetType
        self.includeUnitTests = includeUnitTests
        self.includeIntegrationTests = includeIntegrationTests
        self.includePerformanceTests = includePerformanceTests
        self.customScenarios = customScenarios
    }
}

// MARK: - Test Suite

/// Generated test suite with multiple files
public struct TestSuite {
    public let files: [TestFile]
    
    public init(files: [TestFile]) {
        self.files = files
    }
    
    public struct TestFile {
        public let name: String
        public let content: String
        
        public init(name: String, content: String) {
            self.name = name
            self.content = content
        }
    }
}

// MARK: - Test Template

/// Template for customizing generated tests
public struct TestTemplate {
    public let imports: [String]
    public let testableImports: [String]
    public let baseClass: String
    public let setUp: String
    public let tearDown: String
    
    public init(
        imports: [String] = ["Foundation", "XCTest"],
        testableImports: [String] = ["Axiom"],
        baseClass: String = "XCTestCase",
        setUp: String = "",
        tearDown: String = ""
    ) {
        self.imports = imports
        self.testableImports = testableImports
        self.baseClass = baseClass
        self.setUp = setUp
        self.tearDown = tearDown
    }
}

// MARK: - Default Orchestrator

/// Default orchestrator for testing
public struct DefaultOrchestrator {
    public init() {}
    
    public func navigate(to route: Route) async {
        // Default navigation implementation
    }
    
    public func performAction(_ action: String) async {
        // Default action implementation
    }
    
    public func validateCurrentState() async -> Bool {
        // Default validation
        return true
    }
}