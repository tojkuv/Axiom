import Foundation

// MARK: - Axiom Intelligence Protocol

/// Unified intelligence interface for all Axiom intelligence capabilities
/// This protocol provides a central configuration and access point for the 8 breakthrough intelligence systems
public protocol AxiomIntelligence: Actor {
    /// Currently enabled intelligence features
    var enabledFeatures: Set<IntelligenceFeature> { get }
    
    /// Confidence threshold for automated actions (0.0 - 1.0)
    var confidenceThreshold: Double { get }
    
    /// Level of automation for intelligence operations
    var automationLevel: AutomationLevel { get }
    
    /// Learning mode for continuous improvement
    var learningMode: LearningMode { get }
    
    /// Performance configuration for intelligence operations
    var performanceConfiguration: IntelligencePerformanceConfiguration { get }
    
    /// Enable an intelligence feature
    func enableFeature(_ feature: IntelligenceFeature) async
    
    /// Disable an intelligence feature
    func disableFeature(_ feature: IntelligenceFeature) async
    
    /// Update automation level
    func setAutomationLevel(_ level: AutomationLevel) async
    
    /// Update learning mode
    func setLearningMode(_ mode: LearningMode) async
    
    /// Get current intelligence metrics
    func getMetrics() async -> IntelligenceMetrics
    
    /// Reset intelligence state and learning
    func reset() async
}

// MARK: - Intelligence Feature Types

/// The 8 breakthrough intelligence features of Axiom
public enum IntelligenceFeature: String, CaseIterable, Sendable {
    case architecturalDNA = "architectural_dna"
    case intentDrivenEvolution = "intent_driven_evolution"
    case naturalLanguageQueries = "natural_language_queries"
    case selfOptimizingPerformance = "self_optimizing_performance"
    case constraintPropagation = "constraint_propagation"
    case emergentPatternDetection = "emergent_pattern_detection"
    case temporalDevelopmentWorkflows = "temporal_development_workflows"
    case predictiveArchitectureIntelligence = "predictive_architecture_intelligence"
    
    /// Human-readable name for the feature
    public var displayName: String {
        switch self {
        case .architecturalDNA:
            return "Architectural DNA"
        case .intentDrivenEvolution:
            return "Intent-Driven Evolution"
        case .naturalLanguageQueries:
            return "Natural Language Queries"
        case .selfOptimizingPerformance:
            return "Self-Optimizing Performance"
        case .constraintPropagation:
            return "Constraint Propagation"
        case .emergentPatternDetection:
            return "Emergent Pattern Detection"
        case .temporalDevelopmentWorkflows:
            return "Temporal Development Workflows"
        case .predictiveArchitectureIntelligence:
            return "Predictive Architecture Intelligence"
        }
    }
    
    /// Description of what this feature provides
    public var description: String {
        switch self {
        case .architecturalDNA:
            return "Complete component introspection and self-documentation"
        case .intentDrivenEvolution:
            return "Predictive architecture evolution based on business intent"
        case .naturalLanguageQueries:
            return "Explore architecture in plain English"
        case .selfOptimizingPerformance:
            return "Continuous learning and automatic optimization"
        case .constraintPropagation:
            return "Automatic business rule compliance"
        case .emergentPatternDetection:
            return "Learning and codifying new patterns"
        case .temporalDevelopmentWorkflows:
            return "Sophisticated experiment management"
        case .predictiveArchitectureIntelligence:
            return "Problem prevention before occurrence"
        }
    }
    
    /// Dependencies on other features
    public var dependencies: Set<IntelligenceFeature> {
        switch self {
        case .architecturalDNA:
            return []
        case .intentDrivenEvolution:
            return [.architecturalDNA]
        case .naturalLanguageQueries:
            return [.architecturalDNA]
        case .selfOptimizingPerformance:
            return [.architecturalDNA]
        case .constraintPropagation:
            return [.architecturalDNA]
        case .emergentPatternDetection:
            return [.architecturalDNA]
        case .temporalDevelopmentWorkflows:
            return [.architecturalDNA, .emergentPatternDetection]
        case .predictiveArchitectureIntelligence:
            return Set(IntelligenceFeature.allCases.filter { $0 != .predictiveArchitectureIntelligence })
        }
    }
}

/// Level of automation for intelligence operations
public enum AutomationLevel: String, CaseIterable, Sendable {
    case manual = "manual"
    case supervised = "supervised"
    case autonomous = "autonomous"
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .manual:
            return "Human approval required for all actions"
        case .supervised:
            return "Human oversight with automatic execution"
        case .autonomous:
            return "Full automation with reporting"
        }
    }
}

/// Learning mode for continuous improvement
public enum LearningMode: String, CaseIterable, Sendable {
    case observation = "observation"
    case suggestion = "suggestion"
    case execution = "execution"
    
    /// Human-readable description
    public var description: String {
        switch self {
        case .observation:
            return "Learn but don't act"
        case .suggestion:
            return "Learn and suggest actions"
        case .execution:
            return "Learn and execute approved actions"
        }
    }
}

// MARK: - Intelligence Configuration

/// Performance configuration for intelligence operations
public struct IntelligencePerformanceConfiguration: Sendable {
    /// Maximum time allowed for intelligence operations
    public let maxResponseTime: TimeInterval
    
    /// Maximum memory allowed for intelligence caching
    public let maxMemoryUsage: Int
    
    /// Number of concurrent intelligence operations allowed
    public let maxConcurrentOperations: Int
    
    /// Enable caching for intelligence results
    public let enableCaching: Bool
    
    /// Cache expiration time
    public let cacheExpiration: TimeInterval
    
    public init(
        maxResponseTime: TimeInterval = 0.1,
        maxMemoryUsage: Int = 100_000_000, // 100MB
        maxConcurrentOperations: Int = 10,
        enableCaching: Bool = true,
        cacheExpiration: TimeInterval = 300 // 5 minutes
    ) {
        self.maxResponseTime = maxResponseTime
        self.maxMemoryUsage = maxMemoryUsage
        self.maxConcurrentOperations = maxConcurrentOperations
        self.enableCaching = enableCaching
        self.cacheExpiration = cacheExpiration
    }
}

// MARK: - Intelligence Metrics

/// Metrics for intelligence system performance
public struct IntelligenceMetrics: Sendable {
    /// Total number of intelligence operations performed
    public let totalOperations: Int
    
    /// Average response time for operations
    public let averageResponseTime: TimeInterval
    
    /// Cache hit rate (0.0 - 1.0)
    public let cacheHitRate: Double
    
    /// Number of successful predictions
    public let successfulPredictions: Int
    
    /// Prediction accuracy (0.0 - 1.0)
    public let predictionAccuracy: Double
    
    /// Feature-specific metrics
    public let featureMetrics: [IntelligenceFeature: FeatureMetrics]
    
    /// Timestamp of metrics collection
    public let timestamp: Date
    
    public init(
        totalOperations: Int,
        averageResponseTime: TimeInterval,
        cacheHitRate: Double,
        successfulPredictions: Int,
        predictionAccuracy: Double,
        featureMetrics: [IntelligenceFeature: FeatureMetrics],
        timestamp: Date
    ) {
        self.totalOperations = totalOperations
        self.averageResponseTime = averageResponseTime
        self.cacheHitRate = cacheHitRate
        self.successfulPredictions = successfulPredictions
        self.predictionAccuracy = predictionAccuracy
        self.featureMetrics = featureMetrics
        self.timestamp = timestamp
    }
}

/// Metrics specific to an intelligence feature
public struct FeatureMetrics: Sendable {
    /// Number of times this feature was used
    public let usageCount: Int
    
    /// Average execution time
    public let averageExecutionTime: TimeInterval
    
    /// Success rate (0.0 - 1.0)
    public let successRate: Double
    
    /// Memory usage in bytes
    public let memoryUsage: Int
    
    /// Last used timestamp
    public let lastUsed: Date?
    
    public init(
        usageCount: Int,
        averageExecutionTime: TimeInterval,
        successRate: Double,
        memoryUsage: Int,
        lastUsed: Date?
    ) {
        self.usageCount = usageCount
        self.averageExecutionTime = averageExecutionTime
        self.successRate = successRate
        self.memoryUsage = memoryUsage
        self.lastUsed = lastUsed
    }
}

// MARK: - Default Intelligence Implementation

/// Default implementation of the AxiomIntelligence protocol
public actor DefaultAxiomIntelligence: AxiomIntelligence {
    // MARK: State
    
    private var _enabledFeatures: Set<IntelligenceFeature>
    private var _confidenceThreshold: Double
    private var _automationLevel: AutomationLevel
    private var _learningMode: LearningMode
    private let _performanceConfiguration: IntelligencePerformanceConfiguration
    
    // Component engines
    private let introspectionEngine: ComponentIntrospectionEngine
    private let patternDetectionEngine: PatternDetectionEngine
    private let queryParser: NaturalLanguageQueryParser
    private let queryEngine: ArchitecturalQueryEngine
    private let performanceMonitor: PerformanceMonitor
    
    // Metrics tracking
    private var operationCount: Int = 0
    private var totalResponseTime: TimeInterval = 0
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    private var predictions: Int = 0
    private var successfulPredictions: Int = 0
    private var featureUsage: [IntelligenceFeature: FeatureMetrics] = [:]
    
    // MARK: Protocol Properties
    
    public var enabledFeatures: Set<IntelligenceFeature> { _enabledFeatures }
    public var confidenceThreshold: Double { _confidenceThreshold }
    public var automationLevel: AutomationLevel { _automationLevel }
    public var learningMode: LearningMode { _learningMode }
    public var performanceConfiguration: IntelligencePerformanceConfiguration { _performanceConfiguration }
    
    // MARK: Initialization
    
    public init(
        enabledFeatures: Set<IntelligenceFeature> = [.architecturalDNA, .naturalLanguageQueries],
        confidenceThreshold: Double = 0.8,
        automationLevel: AutomationLevel = .supervised,
        learningMode: LearningMode = .suggestion,
        performanceConfiguration: IntelligencePerformanceConfiguration = IntelligencePerformanceConfiguration()
    ) {
        self._enabledFeatures = enabledFeatures
        self._confidenceThreshold = max(0.0, min(1.0, confidenceThreshold))
        self._automationLevel = automationLevel
        self._learningMode = learningMode
        self._performanceConfiguration = performanceConfiguration
        
        // Initialize component engines
        self.performanceMonitor = PerformanceMonitor()
        self.introspectionEngine = ComponentIntrospectionEngine(performanceMonitor: performanceMonitor)
        self.patternDetectionEngine = PatternDetectionEngine(
            introspectionEngine: introspectionEngine,
            performanceMonitor: performanceMonitor
        )
        self.queryParser = NaturalLanguageQueryParser()
        self.queryEngine = ArchitecturalQueryEngine(
            introspectionEngine: introspectionEngine,
            patternDetectionEngine: patternDetectionEngine,
            performanceMonitor: performanceMonitor,
            queryParser: queryParser,
            configuration: QueryEngineConfiguration(
                minimumConfidenceThreshold: confidenceThreshold,
                enableCaching: performanceConfiguration.enableCaching,
                enableLearning: learningMode != .observation
            )
        )
    }
    
    // MARK: Feature Management
    
    public func enableFeature(_ feature: IntelligenceFeature) async {
        // Check dependencies
        let missingDependencies = feature.dependencies.subtracting(_enabledFeatures)
        if !missingDependencies.isEmpty {
            // Enable dependencies first
            for dependency in missingDependencies {
                await enableFeature(dependency)
            }
        }
        
        _enabledFeatures.insert(feature)
        await recordFeatureOperation(feature, success: true)
    }
    
    public func disableFeature(_ feature: IntelligenceFeature) async {
        // Check if other features depend on this one
        let dependentFeatures = _enabledFeatures.filter { $0.dependencies.contains(feature) }
        
        // Disable dependent features first
        for dependent in dependentFeatures {
            await disableFeature(dependent)
        }
        
        _enabledFeatures.remove(feature)
        await recordFeatureOperation(feature, success: true)
    }
    
    // MARK: Configuration
    
    public func setAutomationLevel(_ level: AutomationLevel) async {
        _automationLevel = level
    }
    
    public func setLearningMode(_ mode: LearningMode) async {
        _learningMode = mode
        
        // Update query engine configuration
        if let queryEngine = queryEngine as? ArchitecturalQueryEngine {
            // The query engine's learning mode is configured during initialization
            // In a real implementation, we would update it here
        }
    }
    
    // MARK: Metrics
    
    public func getMetrics() async -> IntelligenceMetrics {
        let hitRate = cacheHits + cacheMisses > 0 
            ? Double(cacheHits) / Double(cacheHits + cacheMisses) 
            : 0.0
        
        let predictionAccuracy = predictions > 0 
            ? Double(successfulPredictions) / Double(predictions) 
            : 0.0
        
        let avgResponseTime = operationCount > 0 
            ? totalResponseTime / Double(operationCount) 
            : 0.0
        
        return IntelligenceMetrics(
            totalOperations: operationCount,
            averageResponseTime: avgResponseTime,
            cacheHitRate: hitRate,
            successfulPredictions: successfulPredictions,
            predictionAccuracy: predictionAccuracy,
            featureMetrics: featureUsage,
            timestamp: Date()
        )
    }
    
    // MARK: Reset
    
    public func reset() async {
        operationCount = 0
        totalResponseTime = 0
        cacheHits = 0
        cacheMisses = 0
        predictions = 0
        successfulPredictions = 0
        featureUsage = [:]
        
        await performanceMonitor.resetMetrics()
    }
    
    // MARK: Intelligence Operations
    
    /// Process a natural language query
    public func processQuery(_ query: String) async throws -> QueryResponse {
        guard _enabledFeatures.contains(.naturalLanguageQueries) else {
            throw IntelligenceError.featureNotEnabled(.naturalLanguageQueries)
        }
        
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await recordOperation(duration: duration)
                await recordFeatureOperation(.naturalLanguageQueries, success: true, duration: duration)
            }
        }
        
        let parsedQuery = await queryParser.parseQuery(query)
        
        // Check confidence threshold
        if parsedQuery.confidence < _confidenceThreshold {
            throw IntelligenceError.lowConfidence(parsedQuery.confidence)
        }
        
        return try await queryEngine.processQuery(parsedQuery)
    }
    
    /// Get architectural DNA for a component
    public func getArchitecturalDNA(for componentID: ComponentID) async throws -> ArchitecturalDNA? {
        guard _enabledFeatures.contains(.architecturalDNA) else {
            throw IntelligenceError.featureNotEnabled(.architecturalDNA)
        }
        
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await recordOperation(duration: duration)
                await recordFeatureOperation(.architecturalDNA, success: true, duration: duration)
            }
        }
        
        let components = await introspectionEngine.discoverComponents()
        return components.first { $0.id == componentID }?.architecturalDNA
    }
    
    /// Detect patterns in the architecture
    public func detectPatterns() async throws -> [DetectedPattern] {
        guard _enabledFeatures.contains(.emergentPatternDetection) else {
            throw IntelligenceError.featureNotEnabled(.emergentPatternDetection)
        }
        
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            Task {
                await recordOperation(duration: duration)
                await recordFeatureOperation(.emergentPatternDetection, success: true, duration: duration)
            }
        }
        
        return await patternDetectionEngine.detectPatterns()
    }
    
    // MARK: Private Helpers
    
    private func recordOperation(duration: TimeInterval) async {
        operationCount += 1
        totalResponseTime += duration
    }
    
    private func recordFeatureOperation(_ feature: IntelligenceFeature, success: Bool, duration: TimeInterval? = nil) async {
        var metrics = featureUsage[feature] ?? FeatureMetrics(
            usageCount: 0,
            averageExecutionTime: 0,
            successRate: 0,
            memoryUsage: 0,
            lastUsed: nil
        )
        
        let newUsageCount = metrics.usageCount + 1
        let newAvgTime = duration.map { (metrics.averageExecutionTime * Double(metrics.usageCount) + $0) / Double(newUsageCount) } ?? metrics.averageExecutionTime
        let newSuccessRate = (metrics.successRate * Double(metrics.usageCount) + (success ? 1.0 : 0.0)) / Double(newUsageCount)
        
        featureUsage[feature] = FeatureMetrics(
            usageCount: newUsageCount,
            averageExecutionTime: newAvgTime,
            successRate: newSuccessRate,
            memoryUsage: metrics.memoryUsage, // Would calculate actual memory usage in production
            lastUsed: Date()
        )
    }
}

// MARK: - Intelligence Errors

/// Errors specific to intelligence operations
public enum IntelligenceError: Error, LocalizedError {
    case featureNotEnabled(IntelligenceFeature)
    case lowConfidence(Double)
    case operationTimeout
    case memoryLimitExceeded
    case concurrentOperationLimit
    case invalidConfiguration
    case learningDisabled
    
    public var errorDescription: String? {
        switch self {
        case .featureNotEnabled(let feature):
            return "Intelligence feature '\(feature.displayName)' is not enabled"
        case .lowConfidence(let confidence):
            return "Operation confidence (\(String(format: "%.1f%%", confidence * 100))) below threshold"
        case .operationTimeout:
            return "Intelligence operation timed out"
        case .memoryLimitExceeded:
            return "Intelligence memory limit exceeded"
        case .concurrentOperationLimit:
            return "Too many concurrent intelligence operations"
        case .invalidConfiguration:
            return "Invalid intelligence configuration"
        case .learningDisabled:
            return "Learning mode is disabled"
        }
    }
}

// MARK: - Global Intelligence Manager

/// Global shared intelligence manager
public actor GlobalIntelligenceManager {
    public static let shared = GlobalIntelligenceManager()
    
    private var intelligence: DefaultAxiomIntelligence?
    
    private init() {}
    
    public func getIntelligence() async -> DefaultAxiomIntelligence {
        if let intelligence = intelligence {
            return intelligence
        }
        
        let newIntelligence = DefaultAxiomIntelligence()
        self.intelligence = newIntelligence
        return newIntelligence
    }
    
    public func configure(
        enabledFeatures: Set<IntelligenceFeature>,
        confidenceThreshold: Double,
        automationLevel: AutomationLevel,
        learningMode: LearningMode,
        performanceConfiguration: IntelligencePerformanceConfiguration
    ) async {
        intelligence = DefaultAxiomIntelligence(
            enabledFeatures: enabledFeatures,
            confidenceThreshold: confidenceThreshold,
            automationLevel: automationLevel,
            learningMode: learningMode,
            performanceConfiguration: performanceConfiguration
        )
    }
    
    // MARK: - Application Integration Methods
    
    /// Initializes the intelligence system
    public func initialize() async throws {
        // Initialize intelligence components
    }
    
    /// Records an application event for learning
    public func recordApplicationEvent(_ event: ApplicationEvent) async {
        // Record application events for pattern learning
    }
    
    /// Saves the current intelligence state
    public func saveState() async {
        // Save intelligence state for persistence
    }
    
    /// Shuts down the intelligence system
    public func shutdown() async {
        // Cleanup intelligence resources
    }
    
    /// Registers a component with the intelligence system
    public func registerComponent<T: AxiomContext>(_ component: T) async {
        // Register component for intelligence tracking
    }
    
    /// Records an error for learning
    public func recordError(_ error: any AxiomError, context: String) async {
        // Record error for pattern analysis
    }
    
    /// Records a recovery failure for learning
    public func recordRecoveryFailure(_ recoveryError: Error, originalError: any AxiomError) async {
        // Record recovery failure for improvement
    }
}