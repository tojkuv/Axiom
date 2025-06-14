import Foundation
@testable import Axiom

/// Stub implementation of TestTemplateGenerator for compilation
public struct TestTemplateGenerator {
    
    public static func generateMock(for config: MockConfiguration) -> String {
        return "// Mock generation stub"
    }
    
    public static func generateTestSuite(for config: TestSuiteConfiguration) -> String {
        return "// Test suite generation stub"
    }
    
    public static func generateContextTests<StateType, ActionType>(
        for contextType: Any.Type,
        scenarios: [TestScenarioDefinition<StateType, ActionType>],
        includePerformanceTests: Bool = false
    ) -> String {
        return "// Context test generation stub"
    }
    
    public static func generateContextTests(
        for contextType: Any.Type,
        operations: [String]
    ) -> String {
        return "// Context test generation stub"
    }
}

public struct MockConfiguration {
    public let targetType: Any.Type
    public let operations: [String]
    
    public init(targetType: Any.Type, operations: [String]) {
        self.targetType = targetType
        self.operations = operations
    }
}

public struct TestSuiteConfiguration {
    public let targetType: Any.Type
    public let includeUnitTests: Bool
    public let includeIntegrationTests: Bool
    public let includePerformanceTests: Bool
    
    public init(targetType: Any.Type, includeUnitTests: Bool, includeIntegrationTests: Bool, includePerformanceTests: Bool) {
        self.targetType = targetType
        self.includeUnitTests = includeUnitTests
        self.includeIntegrationTests = includeIntegrationTests
        self.includePerformanceTests = includePerformanceTests
    }
}

public struct TestScenarioDefinition<StateType, ActionType> {
    public let name: String
    public let given: StateType
    public let actions: [ActionType]
    public let assertions: [(StateType) -> Bool]
    
    public init(name: String, given: StateType, actions: [ActionType], assertions: [(StateType) -> Bool]) {
        self.name = name
        self.given = given
        self.actions = actions
        self.assertions = assertions
    }
}