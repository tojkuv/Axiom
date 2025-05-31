import Foundation
import Axiom
import XCTest
import SwiftUI

/// AxiomTesting provides comprehensive testing utilities for the Axiom framework
public struct AxiomTesting {
    public init() {}
}

// MARK: - Test Doubles and Mocks

/// Mock capability manager for testing
public actor MockCapabilityManager {
    public private(set) var availableCapabilities: Set<Capability> = []
    public private(set) var validationHistory: [(Capability, Bool)] = []
    public private(set) var configurationCalls: [([Capability])] = []
    
    public init(availableCapabilities: Set<Capability> = Set(Capability.allCases)) {
        self.availableCapabilities = availableCapabilities
    }
    
    public func configure(availableCapabilities: [Capability]) async {
        self.availableCapabilities = Set(availableCapabilities)
        configurationCalls.append(availableCapabilities)
    }
    
    public func validate(_ capability: Capability) async throws {
        let isAvailable = availableCapabilities.contains(capability)
        validationHistory.append((capability, isAvailable))
        
        if !isAvailable {
            throw CapabilityError.unavailable(capability)
        }
    }
    
    public func validateWithContext(_ capability: Capability, context: CapabilityContext) async throws -> Bool {
        let isValid = availableCapabilities.contains(capability)
        validationHistory.append((capability, isValid))
        
        if !isValid {
            throw CapabilityError.unavailable(capability)
        }
        
        return isValid
    }
    
    public func validateWithDegradation(_ capability: Capability, context: CapabilityContext) async -> (isUsable: Bool, fallbackOptions: [String]) {
        let isUsable = availableCapabilities.contains(capability)
        validationHistory.append((capability, isUsable))
        
        return (
            isUsable: isUsable,
            fallbackOptions: isUsable ? [] : ["Manual operation"]
        )
    }
    
    public func addCapability(_ capability: Capability) async {
        availableCapabilities.insert(capability)
    }
    
    public func removeCapability(_ capability: Capability) async {
        availableCapabilities.remove(capability)
    }
    
    public func reset() async {
        validationHistory.removeAll()
        configurationCalls.removeAll()
        availableCapabilities = Set(Capability.allCases)
    }
}

/// Mock performance monitor for testing
public actor MockPerformanceMonitor {
    public private(set) var operationCount: Int = 0
    public private(set) var operationNames: [String] = []
    
    public init() {}
    
    public func recordOperation(_ name: String) async {
        operationCount += 1
        operationNames.append(name)
    }
    
    public func getOperationCount() async -> Int {
        return operationCount
    }
    
    public func getOperationNames() async -> [String] {
        return operationNames
    }
    
    public func reset() async {
        operationCount = 0
        operationNames.removeAll()
    }
}

/// Mock intelligence for testing
public actor MockAxiomIntelligence {
    public private(set) var processedQueries: [String] = []
    public private(set) var detectedPatterns: [DetectedPattern] = []
    public private(set) var generatedDNA: [ComponentID: ArchitecturalDNA] = [:]
    
    public var enabledFeatures: Set<IntelligenceFeature> = []
    public var confidenceThreshold: Double = 0.7
    public var automationLevel: AutomationLevel = .supervised
    public var learningMode: LearningMode = .observation
    public var performanceConfiguration: IntelligencePerformanceConfiguration
    
    public init() {
        self.performanceConfiguration = IntelligencePerformanceConfiguration(
            maxResponseTime: 0.2,
            maxMemoryUsage: 50_000_000,
            maxConcurrentOperations: 5,
            enableCaching: true,
            cacheExpiration: 60
        )
    }
    
    public func processQuery(_ query: String) async throws -> QueryResult {
        processedQueries.append(query)
        
        guard enabledFeatures.contains(.naturalLanguageQueries) else {
            throw IntelligenceError.featureNotEnabled(.naturalLanguageQueries)
        }
        
        return QueryResult(
            query: query,
            intent: .help,
            answer: "Mock response to: \(query)",
            confidence: 0.8,
            data: [:],
            suggestions: ["Try asking about components"],
            executionTime: 0.1,
            respondedAt: Date()
        )
    }
    
    public func getArchitecturalDNA(for componentID: ComponentID) async throws -> ArchitecturalDNA? {
        guard enabledFeatures.contains(.architecturalDNA) else {
            throw IntelligenceError.featureNotEnabled(.architecturalDNA)
        }
        
        return generatedDNA[componentID]
    }
    
    public func detectPatterns() async throws -> [DetectedPattern] {
        guard enabledFeatures.contains(.emergentPatternDetection) else {
            throw IntelligenceError.featureNotEnabled(.emergentPatternDetection)
        }
        
        return detectedPatterns
    }
    
    public func enableFeature(_ feature: IntelligenceFeature) async {
        // Enable dependencies first
        for dependency in feature.dependencies {
            enabledFeatures.insert(dependency)
        }
        enabledFeatures.insert(feature)
    }
    
    public func disableFeature(_ feature: IntelligenceFeature) async {
        enabledFeatures.remove(feature)
        
        // Disable features that depend on this one
        let dependents = IntelligenceFeature.allCases.filter { $0.dependencies.contains(feature) }
        for dependent in dependents {
            enabledFeatures.remove(dependent)
        }
    }
    
    public func setAutomationLevel(_ level: AutomationLevel) async {
        automationLevel = level
    }
    
    public func setLearningMode(_ mode: LearningMode) async {
        learningMode = mode
    }
    
    public func getMetrics() async -> IntelligenceMetrics {
        return IntelligenceMetrics(
            totalOperations: processedQueries.count,
            averageResponseTime: 0.1,
            cacheHitRate: 0.5,
            successfulPredictions: 0,
            predictionAccuracy: 0.0,
            featureMetrics: [:]
        )
    }
    
    public func reset() async {
        processedQueries.removeAll()
        detectedPatterns.removeAll()
        generatedDNA.removeAll()
        enabledFeatures.removeAll()
    }
    
    // Test helpers
    public func addPattern(_ pattern: DetectedPattern) async {
        detectedPatterns.append(pattern)
    }
    
    public func addDNA(_ dna: ArchitecturalDNA, for componentID: ComponentID) async {
        generatedDNA[componentID] = dna
    }
}

// MARK: - Test Data Builders

/// Builder for creating test domain models
public struct TestDomainModelBuilder {
    public static func user(
        id: String = "test-user-1",
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> TestUser {
        return TestUser(id: id, name: name, email: email)
    }
    
    public static func invalidUser(
        id: String = "invalid-user",
        name: String = "",
        email: String = "invalid-email"
    ) -> TestUser {
        return TestUser(id: id, name: name, email: email)
    }
}

/// Test domain model
public struct TestUser: DomainModel {
    public let id: String
    public let name: String
    public let email: String
    
    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    public func validate() -> DomainValidationResult {
        var errors: [String] = []
        
        if name.isEmpty {
            errors.append("Name cannot be empty")
        }
        
        if !email.contains("@") {
            errors.append("Email must contain @")
        }
        
        return DomainValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

/// Builder for creating test clients
public struct TestClientBuilder {
    public static func userClient(
        capabilityManager: MockCapabilityManager? = nil
    ) async -> TestUserClient {
        let manager = capabilityManager ?? MockCapabilityManager()
        let client = TestUserClient(mockCapabilityManager: manager)
        try? await client.initialize()
        return client
    }
    
    public static func analyticsClient(
        capabilityManager: MockCapabilityManager? = nil
    ) async -> TestAnalyticsClient {
        let manager = capabilityManager ?? MockCapabilityManager()
        let client = TestAnalyticsClient(mockCapabilityManager: manager)
        try? await client.initialize()
        return client
    }
}

/// Test domain client
public actor TestUserClient: DomainClient {
    public typealias State = [String: TestUser]
    public typealias DomainModelType = TestUser
    
    private var _state: State = [:]
    private var _stateVersion = StateVersion()
    
    public let mockCapabilities: MockCapabilityManager
    public var stateSnapshot: State { _state }
    
    public init(mockCapabilityManager: MockCapabilityManager) {
        self.mockCapabilities = mockCapabilityManager
    }
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {
        for user in _state.values {
            let validation = user.validate()
            if !validation.isValid {
                throw DomainError.validationFailed(validation)
            }
        }
    }
    
    public func addObserver<T: AxiomContext>(_ context: T) async {}
    public func removeObserver<T: AxiomContext>(_ context: T) async {}
    public func notifyObservers() async {}
    
    public func initialize() async throws {
        try await mockCapabilities.validate(.businessLogic)
        try await validateState()
    }
    
    public func shutdown() async {
        _state.removeAll()
    }
    
    // MARK: DomainClient Implementation
    
    public func create(_ model: TestUser) async throws -> TestUser {
        try await mockCapabilities.validate(.userDefaults)
        
        let validation = model.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        return await updateState { state in
            state[model.id] = model
            return model
        }
    }
    
    public func update(_ model: TestUser) async throws -> TestUser {
        try await mockCapabilities.validate(.userDefaults)
        
        let validation = model.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
        
        return await updateState { state in
            state[model.id] = model
            return model
        }
    }
    
    public func delete(id: String) async throws {
        try await mockCapabilities.validate(.userDefaults)
        
        await updateState { state in
            state.removeValue(forKey: id)
        }
    }
    
    public func find(id: String) async -> TestUser? {
        stateSnapshot[id]
    }
    
    public func query(_ criteria: QueryCriteria<TestUser>) async -> [TestUser] {
        let users = Array(stateSnapshot.values)
        return users.filter(criteria.predicate)
    }
    
    public func validateBusinessRules(_ model: TestUser) async throws {
        let validation = model.validate()
        guard validation.isValid else {
            throw DomainError.validationFailed(validation)
        }
    }
    
    public func applyBusinessLogic(_ operation: BusinessOperation<TestUser>) async throws -> TestUser {
        let user = TestUser(id: "test", name: "Test", email: "test@example.com")
        return try operation.execute(user)
    }
}

/// Test infrastructure client
public actor TestAnalyticsClient: InfrastructureClient {
    public typealias State = [String: Any]
    public typealias DomainModelType = EmptyDomain
    
    private var _state: State = [:]
    private var _stateVersion = StateVersion()
    
    public let mockCapabilities: MockCapabilityManager
    public var stateSnapshot: State { _state }
    
    public init(mockCapabilityManager: MockCapabilityManager) {
        self.mockCapabilities = mockCapabilityManager
    }
    
    public func updateState<T>(_ update: @Sendable (inout State) throws -> T) async rethrows -> T {
        let result = try update(&_state)
        _stateVersion = _stateVersion.incrementMinor()
        await notifyObservers()
        return result
    }
    
    public func validateState() async throws {}
    public func addObserver<T: AxiomContext>(_ context: T) async {}
    public func removeObserver<T: AxiomContext>(_ context: T) async {}
    public func notifyObservers() async {}
    
    public func initialize() async throws {
        try await validateState()
    }
    
    public func shutdown() async {
        _state.removeAll()
    }
    
    // MARK: InfrastructureClient Implementation
    
    public func healthCheck() async -> HealthStatus {
        .healthy
    }
    
    public func configure(_ configuration: Configuration) async throws {
        try await mockCapabilities.validate(.analytics)
        
        await updateState { state in
            state["configuration"] = configuration.settings
        }
    }
}

// MARK: - Testing Utilities

/// Utilities for testing Axiom components
public struct AxiomTestUtilities {
    
    /// Creates a complete test environment with all necessary mocks
    public static func createTestEnvironment() -> TestEnvironment {
        let capabilityManager = MockCapabilityManager()
        let performanceMonitor = MockPerformanceMonitor()
        let intelligence = MockAxiomIntelligence()
        
        return TestEnvironment(
            capabilityManager: capabilityManager,
            performanceMonitor: performanceMonitor,
            intelligence: intelligence
        )
    }
    
    /// Waits for async operations to complete
    public static func waitForAsync(timeout: TimeInterval = 1.0) async throws {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
    }
    
    /// Asserts that an async operation completes within a time limit
    public static func assertCompletes<T>(
        within timeout: TimeInterval = 1.0,
        operation: @escaping () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let start = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(duration, timeout, "Operation took \(duration)s, expected < \(timeout)s", file: file, line: line)
        return result
    }
    
    /// Asserts that two domain models are equivalent
    public static func assertEqual<T: DomainModel & Equatable>(
        _ lhs: T,
        _ rhs: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs, rhs, file: file, line: line)
        XCTAssertEqual(lhs.id, rhs.id, file: file, line: line)
    }
    
    /// Verifies capability validation behavior for test clients
    public static func assertCapabilityValidation(
        mockCapabilities: MockCapabilityManager,
        capability: Capability,
        shouldSucceed: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await mockCapabilities.validate(capability)
            XCTAssertTrue(shouldSucceed, "Expected capability validation to fail", file: file, line: line)
        } catch {
            XCTAssertFalse(shouldSucceed, "Expected capability validation to succeed", file: file, line: line)
        }
    }
    
    /// Creates test architectural DNA
    public static func createTestArchitecturalDNA(
        for componentID: ComponentID,
        category: ComponentCategory = .client
    ) -> TestArchitecturalDNA {
        return TestArchitecturalDNA(
            componentID: componentID,
            purpose: ComponentPurpose(
                category: category,
                role: "Test role",
                domain: "Test domain",
                responsibilities: ["Test responsibility"],
                businessValue: .high
            ),
            constraints: [
                ArchitecturalConstraint(
                    type: .actorSafety,
                    description: "Must use actor for thread safety",
                    rule: .exactly(count: 1)
                )
            ],
            relationships: [],
            requiredCapabilities: [.businessLogic],
            providedCapabilities: [.stateManagement],
            performanceProfile: PerformanceProfile(
                latency: LatencyProfile(typical: 0.010, maximum: 0.100),
                throughput: ThroughputProfile(operationsPerSecond: 1000, peakOperationsPerSecond: 10000, sustainedOperationsPerSecond: 5000),
                memory: MemoryProfile(baselineBytes: 1024, maxBytes: 8192)
            ),
            qualityAttributes: QualityAttributes(reliability: 0.8)
        )
    }
}

/// Complete test environment
public struct TestEnvironment {
    public let capabilityManager: MockCapabilityManager
    public let performanceMonitor: MockPerformanceMonitor
    public let intelligence: MockAxiomIntelligence
    
    public init(
        capabilityManager: MockCapabilityManager,
        performanceMonitor: MockPerformanceMonitor,
        intelligence: MockAxiomIntelligence
    ) {
        self.capabilityManager = capabilityManager
        self.performanceMonitor = performanceMonitor
        self.intelligence = intelligence
    }
    
    /// Resets all mocks to initial state
    public func reset() async {
        await capabilityManager.reset()
        await performanceMonitor.reset()
        await intelligence.reset()
    }
    
    /// Creates test client dependencies
    public func createClientDependencies() async -> TestClientDependencies {
        let userClient = await TestClientBuilder.userClient(capabilityManager: capabilityManager)
        let analyticsClient = await TestClientBuilder.analyticsClient(capabilityManager: capabilityManager)
        
        return TestClientDependencies(
            userClient: userClient,
            analyticsClient: analyticsClient
        )
    }
}

/// Test client dependencies
public struct TestClientDependencies: ClientDependencies {
    public let userClient: TestUserClient
    public let analyticsClient: TestAnalyticsClient
    
    public init() {
        fatalError("Use init(userClient:analyticsClient:)")
    }
    
    public init(userClient: TestUserClient, analyticsClient: TestAnalyticsClient) {
        self.userClient = userClient
        self.analyticsClient = analyticsClient
    }
}

/// Test implementation of ArchitecturalDNA
public struct TestArchitecturalDNA: ArchitecturalDNA {
    public let componentID: ComponentID
    public let purpose: ComponentPurpose
    public let constraints: [ArchitecturalConstraint]
    public let relationships: [ComponentRelationship]
    public let requiredCapabilities: Set<Capability>
    public let providedCapabilities: Set<Capability>
    public let performanceProfile: PerformanceProfile
    public let qualityAttributes: QualityAttributes
    public let architecturalLayer: ArchitecturalLayer = .application
    
    public func validateArchitecturalIntegrity() async throws -> ArchitecturalValidationResult {
        return ArchitecturalValidationResult(
            isValid: true,
            violations: [],
            warnings: [],
            score: 1.0,
            recommendations: []
        )
    }
    
    public func analyzeChangeImpact(_ change: ArchitecturalChange) async -> ChangeImpactAnalysis {
        return ChangeImpactAnalysis(
            change: change,
            impacts: [],
            riskLevel: .low,
            estimatedEffort: .minimal,
            recommendations: [],
            analyzedAt: Date()
        )
    }
    
    public func getEvolutionSuggestions() async -> [EvolutionSuggestion] {
        return []
    }
}

// MARK: - XCTest Extensions

public extension XCTestCase {
    
    /// Sets up a complete Axiom test environment
    func setupAxiomTestEnvironment() -> TestEnvironment {
        return AxiomTestUtilities.createTestEnvironment()
    }
    
    /// Tears down test environment
    func tearDownAxiomTestEnvironment(_ environment: TestEnvironment) async {
        await environment.reset()
    }
    
    /// Convenient test for domain model validation
    func testDomainModelValidation<T: DomainModel>(
        valid: T,
        invalid: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let validResult = valid.validate()
        XCTAssertTrue(validResult.isValid, "Valid model should pass validation", file: file, line: line)
        XCTAssertTrue(validResult.errors.isEmpty, "Valid model should have no errors", file: file, line: line)
        
        let invalidResult = invalid.validate()
        XCTAssertFalse(invalidResult.isValid, "Invalid model should fail validation", file: file, line: line)
        XCTAssertFalse(invalidResult.errors.isEmpty, "Invalid model should have errors", file: file, line: line)
    }
    
    /// Convenient test for user client operations
    func testUserClientOperation(
        client: TestUserClient,
        operation: (TestUserClient) async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation(client)
        } catch {
            XCTFail("Client operation failed: \(error)", file: file, line: line)
        }
    }
    
    /// Convenient test for analytics client operations
    func testAnalyticsClientOperation(
        client: TestAnalyticsClient,
        operation: (TestAnalyticsClient) async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation(client)
        } catch {
            XCTFail("Client operation failed: \(error)", file: file, line: line)
        }
    }
}