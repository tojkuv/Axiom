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

/// Mock performance monitor for testing that implements full PerformanceMonitoring protocol
public actor MockPerformanceMonitor: PerformanceMonitoring {
    // MARK: - Internal Storage
    
    /// Active operations being tracked
    private var activeOperations: [UUID: MockActiveOperation] = [:]
    
    /// Completed operations organized by category
    private var categoryMetrics: [PerformanceCategory: MockCategoryMetrics] = [:]
    
    /// Performance alerts generated during testing
    private var alerts: [PerformanceAlert] = []
    
    /// Performance configuration for testing
    private let configuration: PerformanceConfiguration
    
    /// Maximum samples per category for memory management
    private let maxSamplesPerCategory: Int
    
    /// Performance thresholds for testing
    private let thresholds: PerformanceThresholds
    
    /// Test-specific operation tracking
    public private(set) var operationCount: Int = 0
    public private(set) var operationNames: [String] = []
    
    // MARK: - Initialization
    
    public init(
        configuration: PerformanceConfiguration = PerformanceConfiguration(),
        maxSamplesPerCategory: Int = 1000
    ) {
        self.configuration = configuration
        self.maxSamplesPerCategory = maxSamplesPerCategory
        self.thresholds = PerformanceThresholds()
        
        // Initialize metrics for all categories
        for category in PerformanceCategory.allCases {
            categoryMetrics[category] = MockCategoryMetrics()
        }
    }
    
    // MARK: - PerformanceMonitoring Protocol Implementation
    
    public func startOperation(_ name: String, category: PerformanceCategory) -> PerformanceToken {
        let token = PerformanceToken(
            id: UUID(),
            operationName: name,
            category: category,
            startTime: CFAbsoluteTimeGetCurrent()
        )
        
        let activeOp = MockActiveOperation(
            token: token,
            startTime: CFAbsoluteTimeGetCurrent(),
            metadata: [:]
        )
        
        activeOperations[token.id] = activeOp
        
        // Update legacy tracking
        operationCount += 1
        operationNames.append(name)
        
        return token
    }
    
    public func endOperation(_ token: PerformanceToken) async {
        await endOperation(token, metadata: [:])
    }
    
    public func endOperation(_ token: PerformanceToken, metadata: [String: Any]) async {
        guard let activeOp = activeOperations.removeValue(forKey: token.id) else {
            return
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - activeOp.startTime
        
        let completedOp = MockCompletedOperation(
            name: token.operationName,
            category: token.category,
            duration: duration,
            startTime: activeOp.startTime,
            endTime: endTime,
            metadata: metadata
        )
        
        // Add to category metrics
        await addCompletedOperation(completedOp)
        
        // Check performance thresholds and generate alerts if needed
        await checkPerformanceThresholds(completedOp)
    }
    
    public func recordMetric(_ metric: PerformanceMetric) async {
        let completedOp = MockCompletedOperation(
            name: metric.name,
            category: metric.category,
            duration: 0.0,
            startTime: metric.timestamp.timeIntervalSinceReferenceDate,
            endTime: metric.timestamp.timeIntervalSinceReferenceDate,
            metadata: [
                "value": metric.value,
                "unit": metric.unit.rawValue,
                "type": "custom_metric"
            ]
        )
        
        await addCompletedOperation(completedOp)
    }
    
    public func getMetrics(for category: PerformanceCategory) async -> PerformanceCategoryMetrics {
        guard let categoryData = categoryMetrics[category] else {
            return PerformanceCategoryMetrics(
                category: category,
                totalOperations: 0,
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                percentile95: 0,
                percentile99: 0,
                operationsPerSecond: 0,
                recentSamples: []
            )
        }
        
        let samples = categoryData.samples
        guard !samples.isEmpty else {
            return PerformanceCategoryMetrics(
                category: category,
                totalOperations: 0,
                averageDuration: 0,
                minDuration: 0,
                maxDuration: 0,
                percentile95: 0,
                percentile99: 0,
                operationsPerSecond: 0,
                recentSamples: []
            )
        }
        
        let durations = samples.map { $0.duration }.sorted()
        let totalOps = samples.count
        let avgDuration = durations.reduce(0, +) / Double(totalOps)
        let minDuration = durations.first ?? 0
        let maxDuration = durations.last ?? 0
        
        let p95Index = Int(Double(totalOps) * 0.95)
        let p99Index = Int(Double(totalOps) * 0.99)
        let percentile95 = p95Index < totalOps ? durations[p95Index] : maxDuration
        let percentile99 = p99Index < totalOps ? durations[p99Index] : maxDuration
        
        // Calculate operations per second over last minute
        let oneMinuteAgo = CFAbsoluteTimeGetCurrent() - 60
        let recentOps = samples.filter { $0.endTime >= oneMinuteAgo }
        let opsPerSecond = Double(recentOps.count) / 60.0
        
        return PerformanceCategoryMetrics(
            category: category,
            totalOperations: totalOps,
            averageDuration: avgDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            percentile95: percentile95,
            percentile99: percentile99,
            operationsPerSecond: opsPerSecond,
            recentSamples: Array(samples.suffix(100)).map { OperationSample(from: $0) }
        )
    }
    
    public func getOverallMetrics() async -> OverallPerformanceMetrics {
        var categoryMetricsDict: [PerformanceCategory: PerformanceCategoryMetrics] = [:]
        
        for category in PerformanceCategory.allCases {
            categoryMetricsDict[category] = await getMetrics(for: category)
        }
        
        let totalOperations = categoryMetricsDict.values.reduce(0) { $0 + $1.totalOperations }
        let totalActiveOperations = activeOperations.count
        
        let memoryUsage = estimateMemoryUsage()
        let healthScore = calculateHealthScore(categoryMetrics: categoryMetricsDict)
        
        return OverallPerformanceMetrics(
            categoryMetrics: categoryMetricsDict,
            totalOperations: totalOperations,
            activeOperations: totalActiveOperations,
            memoryUsage: memoryUsage,
            healthScore: healthScore,
            alertCount: alerts.count,
            uptime: 0.0
        )
    }
    
    public func getPerformanceAlerts() async -> [PerformanceAlert] {
        return Array(alerts.suffix(100))
    }
    
    public func clearMetrics() async {
        categoryMetrics.removeAll()
        alerts.removeAll()
        activeOperations.removeAll()
        operationCount = 0
        operationNames.removeAll()
        
        // Reinitialize metrics for all categories
        for category in PerformanceCategory.allCases {
            categoryMetrics[category] = MockCategoryMetrics()
        }
    }
    
    // MARK: - Legacy Testing Methods
    
    public func recordOperation(_ name: String) async {
        let token = startOperation(name, category: .businessLogic)
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms simulation
        await endOperation(token)
    }
    
    public func getOperationCount() async -> Int {
        return operationCount
    }
    
    public func getOperationNames() async -> [String] {
        return operationNames
    }
    
    public func reset() async {
        await clearMetrics()
    }
    
    // MARK: - Testing-Specific Methods
    
    /// Simulates a slow operation for testing performance alerts
    public func simulateSlowOperation(
        _ name: String, 
        category: PerformanceCategory, 
        duration: TimeInterval
    ) async {
        let token = startOperation(name, category: category)
        
        // Simulate the operation duration
        let nanoseconds = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
        
        await endOperation(token, metadata: ["simulated": true])
    }
    
    /// Simulates high-frequency operations for throughput testing
    public func simulateHighFrequencyOperations(
        _ name: String,
        category: PerformanceCategory,
        count: Int,
        avgDuration: TimeInterval = 0.001
    ) async {
        for i in 0..<count {
            let token = startOperation("\(name)-\(i)", category: category)
            
            // Add some variation to duration
            let variation = Double.random(in: 0.5...1.5)
            let duration = avgDuration * variation
            let nanoseconds = UInt64(duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            
            await endOperation(token)
        }
    }
    
    /// Adds a test alert manually
    public func addTestAlert(_ alert: PerformanceAlert) async {
        alerts.append(alert)
    }
    
    /// Gets specific metrics for testing validation
    public func getTestMetrics() async -> MockTestMetrics {
        return MockTestMetrics(
            totalOperations: operationCount,
            activeOperationsCount: activeOperations.count,
            alertsCount: alerts.count,
            categoriesWithData: categoryMetrics.compactMap { (category, metrics) in
                metrics.samples.isEmpty ? nil : category
            }
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func addCompletedOperation(_ operation: MockCompletedOperation) async {
        guard var categoryData = categoryMetrics[operation.category] else { return }
        
        categoryData.samples.append(operation)
        
        // Enforce sample limit
        if categoryData.samples.count > maxSamplesPerCategory {
            let excess = categoryData.samples.count - maxSamplesPerCategory
            categoryData.samples.removeFirst(excess)
        }
        
        categoryMetrics[operation.category] = categoryData
    }
    
    private func checkPerformanceThresholds(_ operation: MockCompletedOperation) async {
        let threshold = thresholds.threshold(for: operation.category)
        
        // Check duration threshold
        if operation.duration > threshold.maxDuration {
            let alert = PerformanceAlert(
                type: .slowOperation,
                category: operation.category,
                operationName: operation.name,
                threshold: threshold.maxDuration,
                actualValue: operation.duration,
                timestamp: Date(),
                message: "Test operation '\(operation.name)' exceeded duration threshold: \(operation.duration)s > \(threshold.maxDuration)s"
            )
            
            alerts.append(alert)
        }
    }
    
    private func estimateMemoryUsage() -> MemoryUsage {
        let activeOpsMemory = activeOperations.count * MemoryLayout<MockActiveOperation>.size
        let metricsMemory = categoryMetrics.values.reduce(0) { total, categoryData in
            total + (categoryData.samples.count * MemoryLayout<MockCompletedOperation>.size)
        }
        let alertsMemory = alerts.count * MemoryLayout<PerformanceAlert>.size
        
        return MemoryUsage(
            activeOperations: activeOpsMemory,
            historicalMetrics: metricsMemory,
            alerts: alertsMemory,
            totalBytes: activeOpsMemory + metricsMemory + alertsMemory
        )
    }
    
    private func calculateHealthScore(categoryMetrics: [PerformanceCategory: PerformanceCategoryMetrics]) -> Double {
        guard !categoryMetrics.isEmpty else { return 1.0 }
        
        let scores = categoryMetrics.compactMap { (category, metrics) -> Double? in
            guard metrics.totalOperations > 0 else { return nil }
            
            let threshold = thresholds.threshold(for: category)
            
            // Score based on P95 performance vs threshold
            let p95Score = min(1.0, threshold.p95Threshold / max(metrics.percentile95, 0.001))
            
            // Score based on operations per second vs expected throughput
            let throughputScore = min(1.0, metrics.operationsPerSecond / max(threshold.expectedThroughput, 0.001))
            
            // Combined score (weighted average)
            return (p95Score * 0.7) + (throughputScore * 0.3)
        }
        
        guard !scores.isEmpty else { return 1.0 }
        return scores.reduce(0, +) / Double(scores.count)
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

// MARK: - Mock Performance Testing Support Types

/// Mock active operation for testing
private struct MockActiveOperation {
    let token: PerformanceToken
    let startTime: TimeInterval
    let metadata: [String: Any]
}

/// Mock completed operation for testing
private struct MockCompletedOperation {
    let name: String
    let category: PerformanceCategory
    let duration: TimeInterval
    let startTime: TimeInterval
    let endTime: TimeInterval
    let metadata: [String: Any]
}

/// Mock category metrics storage
private struct MockCategoryMetrics {
    var samples: [MockCompletedOperation] = []
}

/// Test metrics summary
public struct MockTestMetrics {
    public let totalOperations: Int
    public let activeOperationsCount: Int
    public let alertsCount: Int
    public let categoriesWithData: [PerformanceCategory]
}

/// Extension to create OperationSample from MockCompletedOperation
fileprivate extension OperationSample {
    init(from operation: MockCompletedOperation) {
        self.name = operation.name
        self.duration = operation.duration
        self.timestamp = Date(timeIntervalSinceReferenceDate: operation.endTime)
    }
}

// MARK: - Performance Benchmark Testing Infrastructure

/// Performance benchmark test suite for comprehensive testing
public struct PerformanceBenchmarkSuite {
    public let name: String
    public let benchmarks: [PerformanceBenchmark]
    public let configuration: BenchmarkConfiguration
    
    public init(name: String, benchmarks: [PerformanceBenchmark], configuration: BenchmarkConfiguration = BenchmarkConfiguration()) {
        self.name = name
        self.benchmarks = benchmarks
        self.configuration = configuration
    }
    
    /// Runs all benchmarks in the suite
    public func runBenchmarks(monitor: MockPerformanceMonitor) async -> BenchmarkSuiteResults {
        var results: [BenchmarkResult] = []
        
        for benchmark in benchmarks {
            let result = await benchmark.run(monitor: monitor, configuration: configuration)
            results.append(result)
        }
        
        return BenchmarkSuiteResults(
            suiteName: name,
            results: results,
            overallScore: calculateOverallScore(results),
            executedAt: Date()
        )
    }
    
    private func calculateOverallScore(_ results: [BenchmarkResult]) -> Double {
        guard !results.isEmpty else { return 0.0 }
        return results.map { $0.score }.reduce(0, +) / Double(results.count)
    }
}

/// Individual performance benchmark
public struct PerformanceBenchmark {
    public let name: String
    public let category: PerformanceCategory
    public let targetLatency: TimeInterval
    public let targetThroughput: Double
    public let operation: (MockPerformanceMonitor) async throws -> Void
    
    public init(
        name: String,
        category: PerformanceCategory,
        targetLatency: TimeInterval,
        targetThroughput: Double,
        operation: @escaping (MockPerformanceMonitor) async throws -> Void
    ) {
        self.name = name
        self.category = category
        self.targetLatency = targetLatency
        self.targetThroughput = targetThroughput
        self.operation = operation
    }
    
    /// Runs the benchmark and returns results
    public func run(monitor: MockPerformanceMonitor, configuration: BenchmarkConfiguration) async -> BenchmarkResult {
        let startTime = Date()
        
        do {
            // Run the benchmark operation
            try await operation(monitor)
            
            // Get metrics for this benchmark's category
            let metrics = await monitor.getMetrics(for: category)
            
            // Calculate score based on how well we met targets
            let latencyScore = targetLatency > 0 ? min(1.0, targetLatency / max(metrics.averageDuration, 0.001)) : 1.0
            let throughputScore = targetThroughput > 0 ? min(1.0, metrics.operationsPerSecond / targetThroughput) : 1.0
            let score = (latencyScore + throughputScore) / 2.0
            
            return BenchmarkResult(
                benchmarkName: name,
                category: category,
                success: true,
                score: score,
                metrics: metrics,
                duration: Date().timeIntervalSince(startTime),
                error: nil
            )
        } catch {
            return BenchmarkResult(
                benchmarkName: name,
                category: category,
                success: false,
                score: 0.0,
                metrics: await monitor.getMetrics(for: category),
                duration: Date().timeIntervalSince(startTime),
                error: error
            )
        }
    }
}

/// Configuration for benchmark execution
public struct BenchmarkConfiguration {
    public let iterations: Int
    public let warmupIterations: Int
    public let timeout: TimeInterval
    public let allowFailures: Bool
    
    public init(
        iterations: Int = 100,
        warmupIterations: Int = 10,
        timeout: TimeInterval = 30.0,
        allowFailures: Bool = false
    ) {
        self.iterations = iterations
        self.warmupIterations = warmupIterations
        self.timeout = timeout
        self.allowFailures = allowFailures
    }
}

/// Result of a benchmark execution
public struct BenchmarkResult {
    public let benchmarkName: String
    public let category: PerformanceCategory
    public let success: Bool
    public let score: Double // 0.0 to 1.0
    public let metrics: PerformanceCategoryMetrics
    public let duration: TimeInterval
    public let error: Error?
    
    public init(
        benchmarkName: String,
        category: PerformanceCategory,
        success: Bool,
        score: Double,
        metrics: PerformanceCategoryMetrics,
        duration: TimeInterval,
        error: Error?
    ) {
        self.benchmarkName = benchmarkName
        self.category = category
        self.success = success
        self.score = score
        self.metrics = metrics
        self.duration = duration
        self.error = error
    }
}

/// Results of a complete benchmark suite execution
public struct BenchmarkSuiteResults {
    public let suiteName: String
    public let results: [BenchmarkResult]
    public let overallScore: Double
    public let executedAt: Date
    
    public var successfulBenchmarks: [BenchmarkResult] {
        results.filter { $0.success }
    }
    
    public var failedBenchmarks: [BenchmarkResult] {
        results.filter { !$0.success }
    }
    
    public var successRate: Double {
        guard !results.isEmpty else { return 0.0 }
        return Double(successfulBenchmarks.count) / Double(results.count)
    }
}

// MARK: - Performance Analysis Tools

/// Performance analysis and reporting tools
public struct PerformanceAnalyzer {
    
    /// Analyzes performance metrics and provides insights
    public static func analyzeMetrics(_ metrics: OverallPerformanceMetrics) -> PerformanceAnalysisReport {
        var insights: [PerformanceInsight] = []
        var recommendations: [String] = []
        
        // Analyze each category
        for (category, categoryMetrics) in metrics.categoryMetrics {
            if categoryMetrics.totalOperations > 0 {
                // Check for performance issues
                if categoryMetrics.percentile95 > 0.1 { // 100ms
                    insights.append(PerformanceInsight(
                        type: .latencyIssue,
                        category: category,
                        severity: .high,
                        description: "High P95 latency detected",
                        value: categoryMetrics.percentile95
                    ))
                    recommendations.append("Optimize \(category.rawValue) operations to reduce latency")
                }
                
                if categoryMetrics.operationsPerSecond < 10 && categoryMetrics.totalOperations > 100 {
                    insights.append(PerformanceInsight(
                        type: .throughputIssue,
                        category: category,
                        severity: .medium,
                        description: "Low throughput detected",
                        value: categoryMetrics.operationsPerSecond
                    ))
                    recommendations.append("Consider optimizing \(category.rawValue) for higher throughput")
                }
            }
        }
        
        // Check memory usage
        if metrics.memoryUsage.totalBytes > 10 * 1024 * 1024 { // 10MB
            insights.append(PerformanceInsight(
                type: .memoryIssue,
                category: .businessLogic,
                severity: .medium,
                description: "High memory usage detected",
                value: Double(metrics.memoryUsage.totalBytes)
            ))
            recommendations.append("Consider implementing memory optimization strategies")
        }
        
        // Calculate overall performance score
        let score = metrics.healthScore
        
        return PerformanceAnalysisReport(
            overallScore: score,
            insights: insights,
            recommendations: recommendations,
            totalOperations: metrics.totalOperations,
            averageLatency: calculateAverageLatency(metrics),
            totalMemoryUsage: metrics.memoryUsage.totalBytes,
            analyzedAt: Date()
        )
    }
    
    /// Compares two sets of performance metrics
    public static func compareMetrics(
        baseline: OverallPerformanceMetrics,
        current: OverallPerformanceMetrics
    ) -> PerformanceComparisonReport {
        var categoryComparisons: [PerformanceCategoryComparison] = []
        
        for category in PerformanceCategory.allCases {
            let baselineMetrics = baseline.categoryMetrics[category]
            let currentMetrics = current.categoryMetrics[category]
            
            if let baseline = baselineMetrics, let current = currentMetrics {
                let comparison = PerformanceCategoryComparison(
                    category: category,
                    latencyChange: calculatePercentageChange(
                        from: baseline.averageDuration,
                        to: current.averageDuration
                    ),
                    throughputChange: calculatePercentageChange(
                        from: baseline.operationsPerSecond,
                        to: current.operationsPerSecond
                    ),
                    p95Change: calculatePercentageChange(
                        from: baseline.percentile95,
                        to: current.percentile95
                    )
                )
                categoryComparisons.append(comparison)
            }
        }
        
        return PerformanceComparisonReport(
            categoryComparisons: categoryComparisons,
            overallLatencyChange: calculatePercentageChange(
                from: calculateAverageLatency(baseline),
                to: calculateAverageLatency(current)
            ),
            memoryUsageChange: calculatePercentageChange(
                from: Double(baseline.memoryUsage.totalBytes),
                to: Double(current.memoryUsage.totalBytes)
            ),
            comparedAt: Date()
        )
    }
    
    private static func calculateAverageLatency(_ metrics: OverallPerformanceMetrics) -> Double {
        let totalDuration = metrics.categoryMetrics.values.reduce(0.0) {
            $0 + ($1.averageDuration * Double($1.totalOperations))
        }
        let totalOperations = metrics.categoryMetrics.values.reduce(0) { $0 + $1.totalOperations }
        return totalOperations > 0 ? totalDuration / Double(totalOperations) : 0.0
    }
    
    private static func calculatePercentageChange(from baseline: Double, to current: Double) -> Double {
        guard baseline > 0 else { return current > 0 ? 100.0 : 0.0 }
        return ((current - baseline) / baseline) * 100.0
    }
}

/// Performance insight from analysis
public struct PerformanceInsight {
    public let type: InsightType
    public let category: PerformanceCategory
    public let severity: Severity
    public let description: String
    public let value: Double
    
    public enum InsightType {
        case latencyIssue
        case throughputIssue
        case memoryIssue
        case alertSpike
    }
    
    public enum Severity {
        case low, medium, high, critical
    }
}

/// Comprehensive performance analysis report
public struct PerformanceAnalysisReport {
    public let overallScore: Double
    public let insights: [PerformanceInsight]
    public let recommendations: [String]
    public let totalOperations: Int
    public let averageLatency: Double
    public let totalMemoryUsage: Int
    public let analyzedAt: Date
}

/// Performance comparison between two measurement periods
public struct PerformanceComparisonReport {
    public let categoryComparisons: [PerformanceCategoryComparison]
    public let overallLatencyChange: Double // Percentage change
    public let memoryUsageChange: Double // Percentage change
    public let comparedAt: Date
}

/// Comparison data for a specific performance category
public struct PerformanceCategoryComparison {
    public let category: PerformanceCategory
    public let latencyChange: Double // Percentage change
    public let throughputChange: Double // Percentage change
    public let p95Change: Double // Percentage change
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
