import Foundation

// MARK: - Testing Analyzer System

/// Component analyzer for test generation and validation
public actor TestingAnalyzer {
    
    // MARK: - Properties
    
    /// Test pattern repository for common scenarios
    private let patternRepository: TestPatternRepository
    
    /// Test history for pattern analysis
    private var testHistory: [TestExecutionRecord] = []
    
    /// Component usage statistics
    private var componentStats: [String: ComponentStatistics] = [:]
    
    // MARK: - Initialization
    
    public init() {
        self.patternRepository = TestPatternRepository()
    }
    
    // MARK: - Test Generation
    
    /// Generates test scenarios for a component based on its structure
    public func generateTestScenarios(for component: TestableComponent) async -> [TestScenario] {
        var scenarios: [TestScenario] = []
        
        // Generate unit tests for public methods
        scenarios.append(contentsOf: await generateMethodTests(for: component))
        
        // Generate property tests
        scenarios.append(contentsOf: await generatePropertyTests(for: component))
        
        // Generate edge case tests based on parameter types
        scenarios.append(contentsOf: await generateEdgeCaseTests(for: component))
        
        // Generate integration tests if component has dependencies
        if !component.dependencies.isEmpty {
            scenarios.append(contentsOf: await generateIntegrationTests(for: component))
        }
        
        // Generate concurrency tests for actor-based components
        if component.isActor {
            scenarios.append(contentsOf: await generateConcurrencyTests(for: component))
        }
        
        return scenarios
    }
    
    /// Analyzes test coverage for given scenarios
    public func analyzeTestCoverage(scenarios: [TestScenario], for component: TestableComponent) async -> CoverageAnalysis {
        let methodsCovered = Set(scenarios.compactMap { scenario in
            scenario.targetMethod
        })
        
        let propertiesCovered = Set(scenarios.compactMap { scenario in
            scenario.targetProperty
        })
        
        let methodCoverage = Double(methodsCovered.count) / Double(max(1, component.methods.count))
        let propertyCoverage = Double(propertiesCovered.count) / Double(max(1, component.properties.count))
        let overallCoverage = (methodCoverage + propertyCoverage) / 2.0
        
        var gaps: [CoverageGap] = []
        
        // Identify uncovered methods
        for method in component.methods {
            if !methodsCovered.contains(method.name) {
                gaps.append(CoverageGap(
                    type: .method,
                    identifier: method.name,
                    severity: method.isPublic ? .high : .medium
                ))
            }
        }
        
        // Identify uncovered properties
        for property in component.properties {
            if !propertiesCovered.contains(property.name) {
                gaps.append(CoverageGap(
                    type: .property,
                    identifier: property.name,
                    severity: property.isPublic ? .medium : .low
                ))
            }
        }
        
        return CoverageAnalysis(
            overallCoverage: overallCoverage,
            methodCoverage: methodCoverage,
            propertyCoverage: propertyCoverage,
            gaps: gaps
        )
    }
    
    /// Records test execution results for analysis
    public func recordTestExecution(_ record: TestExecutionRecord) async {
        testHistory.append(record)
        
        // Update component statistics
        if var stats = componentStats[record.componentId] {
            stats.totalExecutions += 1
            if record.success {
                stats.successfulExecutions += 1
            } else {
                stats.failedExecutions += 1
            }
            stats.averageExecutionTime = (stats.averageExecutionTime * Double(stats.totalExecutions - 1) + record.executionTime) / Double(stats.totalExecutions)
            componentStats[record.componentId] = stats
        } else {
            componentStats[record.componentId] = ComponentStatistics(
                componentId: record.componentId,
                totalExecutions: 1,
                successfulExecutions: record.success ? 1 : 0,
                failedExecutions: record.success ? 0 : 1,
                averageExecutionTime: record.executionTime
            )
        }
        
        // Maintain reasonable history size
        if testHistory.count > 10000 {
            testHistory.removeFirst(5000)
        }
    }
    
    /// Gets test recommendations based on code changes
    public func getTestRecommendations(for changes: [CodeChange]) async -> [TestRecommendation] {
        var recommendations: [TestRecommendation] = []
        
        for change in changes {
            // Recommend unit tests for method changes
            if change.type == .methodModification {
                recommendations.append(TestRecommendation(
                    type: .unit,
                    target: change.identifier,
                    priority: .high,
                    reason: "Method '\(change.identifier)' was modified"
                ))
            }
            
            // Recommend integration tests for interface changes
            if change.type == .interfaceChange {
                recommendations.append(TestRecommendation(
                    type: .integration,
                    target: change.identifier,
                    priority: .high,
                    reason: "Interface change affects dependent components"
                ))
            }
            
            // Recommend regression tests for bug fixes
            if change.type == .bugFix {
                recommendations.append(TestRecommendation(
                    type: .regression,
                    target: change.identifier,
                    priority: .medium,
                    reason: "Ensure bug fix doesn't regress"
                ))
            }
        }
        
        return recommendations
    }
    
    /// Analyzes test failures to identify patterns
    public func analyzeTestFailures(_ failures: [TestFailure]) async -> [FailureAnalysis] {
        var analyses: [FailureAnalysis] = []
        
        // Group failures by component
        let failuresByComponent = Dictionary(grouping: failures) { $0.componentId }
        
        for (componentId, componentFailures) in failuresByComponent {
            let stats = componentStats[componentId]
            let failureRate = stats.map { Double($0.failedExecutions) / Double($0.totalExecutions) } ?? 0.0
            
            // Identify common failure patterns
            let errorMessages = componentFailures.map { $0.errorMessage }
            let commonErrors = findCommonPatterns(in: errorMessages)
            
            let analysis = FailureAnalysis(
                componentId: componentId,
                failureCount: componentFailures.count,
                failureRate: failureRate,
                commonPatterns: commonErrors,
                recommendations: generateFailureRecommendations(
                    failures: componentFailures,
                    patterns: commonErrors
                )
            )
            
            analyses.append(analysis)
        }
        
        return analyses
    }
    
    // MARK: - Private Implementation
    
    private func generateMethodTests(for component: TestableComponent) async -> [TestScenario] {
        component.methods.compactMap { method in
            guard method.isPublic else { return nil }
            
            let implementation = patternRepository.getMethodTestPattern(
                methodName: method.name,
                parameters: method.parameters,
                returnType: method.returnType
            )
            
            return TestScenario(
                name: "test\(method.name.capitalizedFirstLetter())",
                type: .unit,
                targetMethod: method.name,
                targetProperty: nil,
                priority: .high,
                implementation: implementation
            )
        }
    }
    
    private func generatePropertyTests(for component: TestableComponent) async -> [TestScenario] {
        component.properties.compactMap { property in
            guard property.isPublic else { return nil }
            
            let implementation = patternRepository.getPropertyTestPattern(
                propertyName: property.name,
                propertyType: property.type,
                isReadOnly: property.isReadOnly
            )
            
            return TestScenario(
                name: "test\(property.name.capitalizedFirstLetter())Property",
                type: .unit,
                targetMethod: nil,
                targetProperty: property.name,
                priority: .medium,
                implementation: implementation
            )
        }
    }
    
    private func generateEdgeCaseTests(for component: TestableComponent) async -> [TestScenario] {
        var scenarios: [TestScenario] = []
        
        for method in component.methods where method.isPublic {
            // Generate edge cases based on parameter types
            for (index, param) in method.parameters.enumerated() {
                if let edgeCases = getEdgeCasesForType(param.type) {
                    for edgeCase in edgeCases {
                        let implementation = patternRepository.getEdgeCaseTestPattern(
                            methodName: method.name,
                            parameterIndex: index,
                            edgeCase: edgeCase
                        )
                        
                        scenarios.append(TestScenario(
                            name: "test\(method.name.capitalizedFirstLetter())_\(edgeCase.identifier)",
                            type: .edgeCase,
                            targetMethod: method.name,
                            targetProperty: nil,
                            priority: .medium,
                            implementation: implementation
                        ))
                    }
                }
            }
        }
        
        return scenarios
    }
    
    private func generateIntegrationTests(for component: TestableComponent) async -> [TestScenario] {
        component.dependencies.map { dependency in
            let implementation = patternRepository.getIntegrationTestPattern(
                componentName: component.name,
                dependencyName: dependency.name
            )
            
            return TestScenario(
                name: "testIntegrationWith\(dependency.name)",
                type: .integration,
                targetMethod: nil,
                targetProperty: nil,
                priority: .high,
                implementation: implementation
            )
        }
    }
    
    private func generateConcurrencyTests(for component: TestableComponent) async -> [TestScenario] {
        var scenarios: [TestScenario] = []
        
        // Test concurrent access to methods
        let concurrentMethods = component.methods.filter { $0.isPublic && !$0.isIsolated }
        for method in concurrentMethods {
            let implementation = patternRepository.getConcurrencyTestPattern(
                componentName: component.name,
                methodName: method.name
            )
            
            scenarios.append(TestScenario(
                name: "testConcurrent\(method.name.capitalizedFirstLetter())",
                type: .concurrency,
                targetMethod: method.name,
                targetProperty: nil,
                priority: .critical,
                implementation: implementation
            ))
        }
        
        return scenarios
    }
    
    private func getEdgeCasesForType(_ type: String) -> [EdgeCase]? {
        switch type {
        case "Int", "Int32", "Int64":
            return [
                EdgeCase(identifier: "zero", value: "0"),
                EdgeCase(identifier: "negative", value: "-1"),
                EdgeCase(identifier: "maxValue", value: "\(type).max")
            ]
        case "String":
            return [
                EdgeCase(identifier: "empty", value: "\"\""),
                EdgeCase(identifier: "unicode", value: "\"🎯💯\""),
                EdgeCase(identifier: "veryLong", value: "String(repeating: \"a\", count: 10000)")
            ]
        case "Array", "[String]", "[Int]":
            return [
                EdgeCase(identifier: "empty", value: "[]"),
                EdgeCase(identifier: "single", value: "[testValue]"),
                EdgeCase(identifier: "large", value: "Array(repeating: testValue, count: 1000)")
            ]
        default:
            return nil
        }
    }
    
    private func findCommonPatterns(in messages: [String]) -> [String] {
        var patternCounts: [String: Int] = [:]
        
        // Simple pattern extraction based on common keywords
        let keywords = ["nil", "crash", "timeout", "assertion", "precondition", "index", "bounds"]
        
        for message in messages {
            for keyword in keywords {
                if message.lowercased().contains(keyword) {
                    patternCounts[keyword, default: 0] += 1
                }
            }
        }
        
        // Return patterns that appear in more than 30% of failures
        let threshold = Int(Double(messages.count) * 0.3)
        return patternCounts.compactMap { key, count in
            count >= threshold ? key : nil
        }
    }
    
    private func generateFailureRecommendations(failures: [TestFailure], patterns: [String]) -> [String] {
        var recommendations: [String] = []
        
        if patterns.contains("nil") {
            recommendations.append("Add nil checks and optional unwrapping validation")
        }
        
        if patterns.contains("timeout") {
            recommendations.append("Increase timeout values or optimize performance")
        }
        
        if patterns.contains("index") || patterns.contains("bounds") {
            recommendations.append("Add bounds checking for array/collection access")
        }
        
        if patterns.contains("assertion") || patterns.contains("precondition") {
            recommendations.append("Review and validate preconditions")
        }
        
        if failures.count > 5 {
            recommendations.append("Consider breaking down complex tests into smaller units")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

/// Component representation for testing
public struct TestableComponent: Sendable {
    public let name: String
    public let isActor: Bool
    public let methods: [ComponentMethod]
    public let properties: [ComponentProperty]
    public let dependencies: [ComponentDependency]
}

/// Method representation
public struct ComponentMethod: Sendable {
    public let name: String
    public let parameters: [MethodParameter]
    public let returnType: String
    public let isPublic: Bool
    public let isIsolated: Bool
}

/// Method parameter
public struct MethodParameter: Sendable {
    public let name: String
    public let type: String
}

/// Property representation
public struct ComponentProperty: Sendable {
    public let name: String
    public let type: String
    public let isPublic: Bool
    public let isReadOnly: Bool
}

/// Component dependency
public struct ComponentDependency: Sendable {
    public let name: String
    public let type: String
}

/// Test scenario
public struct TestScenario: Sendable {
    public let name: String
    public let type: TestType
    public let targetMethod: String?
    public let targetProperty: String?
    public let priority: TestPriority
    public let implementation: String
}

/// Test execution record
public struct TestExecutionRecord: Sendable {
    public let testId: String
    public let componentId: String
    public let success: Bool
    public let executionTime: TimeInterval
    public let timestamp: Date
}

/// Component statistics
public struct ComponentStatistics: Sendable {
    public let componentId: String
    public var totalExecutions: Int
    public var successfulExecutions: Int
    public var failedExecutions: Int
    public var averageExecutionTime: TimeInterval
}

/// Coverage analysis
public struct CoverageAnalysis: Sendable {
    public let overallCoverage: Double
    public let methodCoverage: Double
    public let propertyCoverage: Double
    public let gaps: [CoverageGap]
}

/// Coverage gap
public struct CoverageGap: Sendable {
    public let type: CoverageType
    public let identifier: String
    public let severity: CoverageSeverity
}

/// Code change
public struct CodeChange: Sendable {
    public let identifier: String
    public let type: TestChangeType
    public let filePath: String
}

/// Test recommendation
public struct TestRecommendation: Sendable {
    public let type: TestType
    public let target: String
    public let priority: TestPriority
    public let reason: String
}

/// Test failure
public struct TestFailure: Sendable {
    public let testId: String
    public let componentId: String
    public let errorMessage: String
    public let timestamp: Date
}

/// Failure analysis
public struct FailureAnalysis: Sendable {
    public let componentId: String
    public let failureCount: Int
    public let failureRate: Double
    public let commonPatterns: [String]
    public let recommendations: [String]
}

/// Edge case
public struct EdgeCase: Sendable {
    public let identifier: String
    public let value: String
}

// MARK: - Enums

public enum TestType: String, Sendable {
    case unit
    case integration
    case edgeCase
    case concurrency
    case regression
}

public enum TestPriority: String, Sendable {
    case low
    case medium
    case high
    case critical
}

public enum CoverageType: String, Sendable {
    case method
    case property
}

public enum CoverageSeverity: String, Sendable {
    case low
    case medium
    case high
}

public enum TestChangeType: String, Sendable {
    case methodModification
    case interfaceChange
    case bugFix
    case refactoring
}

public enum EstimatedEffort: String, CaseIterable, Sendable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case xlarge = "xlarge"
}

public enum ComplexityLevel: String, Sendable {
    case low
    case medium
    case high
    case critical
}

// MARK: - Test Pattern Repository

/// Repository of common test patterns
private struct TestPatternRepository {
    
    func getMethodTestPattern(methodName: String, parameters: [MethodParameter], returnType: String) -> String {
        var pattern = """
        func test\(methodName.capitalizedFirstLetter())() async throws {
            // Arrange
            let sut = await createSystemUnderTest()
        """
        
        if !parameters.isEmpty {
            pattern += "\n"
            for param in parameters {
                pattern += "    let \(param.name) = create\(param.type)()\n"
            }
        }
        
        pattern += "\n    // Act\n"
        
        if returnType != "Void" {
            pattern += "    let result = "
        } else {
            pattern += "    "
        }
        
        pattern += "await sut.\(methodName)("
        pattern += parameters.map { "\($0.name): \($0.name)" }.joined(separator: ", ")
        pattern += ")\n"
        
        pattern += "\n    // Assert\n"
        
        if returnType != "Void" {
            pattern += "    #expect(result != nil)\n"
        } else {
            pattern += "    // Verify expected behavior\n"
        }
        
        pattern += "}"
        
        return pattern
    }
    
    func getPropertyTestPattern(propertyName: String, propertyType: String, isReadOnly: Bool) -> String {
        if isReadOnly {
            return """
            func test\(propertyName.capitalizedFirstLetter())Property() async throws {
                // Arrange
                let sut = await createSystemUnderTest()
                
                // Act
                let value = await sut.\(propertyName)
                
                // Assert
                #expect(value != nil)
            }
            """
        } else {
            return """
            func test\(propertyName.capitalizedFirstLetter())Property() async throws {
                // Arrange
                let sut = await createSystemUnderTest()
                let newValue = create\(propertyType)()
                
                // Act
                await sut.\(propertyName) = newValue
                let retrievedValue = await sut.\(propertyName)
                
                // Assert
                #expect(retrievedValue == newValue)
            }
            """
        }
    }
    
    func getEdgeCaseTestPattern(methodName: String, parameterIndex: Int, edgeCase: EdgeCase) -> String {
        return """
        func test\(methodName.capitalizedFirstLetter())_\(edgeCase.identifier)() async throws {
            // Arrange
            let sut = await createSystemUnderTest()
            let edgeCaseValue = \(edgeCase.value)
            
            // Act & Assert
            await #expect(throws: Never.self) {
                _ = await sut.\(methodName)(value: edgeCaseValue)
            }
        }
        """
    }
    
    func getIntegrationTestPattern(componentName: String, dependencyName: String) -> String {
        return """
        func testIntegrationWith\(dependencyName)() async throws {
            // Arrange
            let dependency = await create\(dependencyName)()
            let sut = await create\(componentName)(dependency: dependency)
            
            // Act
            // Test interaction between components
            
            // Assert
            // Verify integration behavior
        }
        """
    }
    
    func getConcurrencyTestPattern(componentName: String, methodName: String) -> String {
        return """
        func testConcurrent\(methodName.capitalizedFirstLetter())() async throws {
            // Arrange
            let sut = await createSystemUnderTest()
            let iterations = 100
            
            // Act
            await withTaskGroup(of: Void.self) { group in
                for i in 0..<iterations {
                    group.addTask {
                        await sut.\(methodName)(value: i)
                    }
                }
            }
            
            // Assert
            // Verify thread-safe behavior
        }
        """
    }
}

// MARK: - String Extension

private extension String {
    func capitalizedFirstLetter() -> String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
}