import Foundation

// MARK: - Architectural DNA Protocol

/// Protocol that provides complete introspection and self-documentation capabilities
/// This is one of the 8 breakthrough intelligence systems in Axiom
public protocol ArchitecturalDNA: Sendable {
    /// Unique identifier for this architectural component
    var componentID: ComponentID { get }
    
    /// The primary purpose of this component
    var purpose: ComponentPurpose { get }
    
    /// The architectural layer this component belongs to
    var architecturalLayer: ArchitecturalLayer { get }
    
    /// Dependencies and relationships to other components
    var relationships: [ComponentRelationship] { get }
    
    /// Constraints that this component enforces or follows
    var constraints: [ArchitecturalConstraint] { get }
    
    /// Capabilities required by this component
    var requiredCapabilities: Set<Capability> { get }
    
    /// Capabilities provided by this component
    var providedCapabilities: Set<Capability> { get }
    
    /// Performance characteristics of this component
    var performanceProfile: PerformanceProfile { get }
    
    /// Quality attributes supported by this component
    var qualityAttributes: QualityAttributes { get }
    
    /// Generates a comprehensive architectural description
    func generateDescription() -> ArchitecturalDescription
    
    /// Validates that this component adheres to its architectural constraints
    func validateArchitecturalIntegrity() async throws -> ArchitecturalValidationResult
    
    /// Analyzes the impact of potential changes to this component
    func analyzeChangeImpact(_ change: ArchitecturalChange) async -> ChangeImpactAnalysis
    
    /// Gets evolution suggestions for this component
    func getEvolutionSuggestions() async -> [EvolutionSuggestion]
}

// MARK: - Component Purpose

/// Defines the primary purpose and responsibility of an architectural component
public struct ComponentPurpose: Sendable, CustomStringConvertible {
    /// High-level category of the component
    public let category: ComponentCategory
    
    /// Specific role within the category
    public let role: String
    
    /// Business domain this component serves
    public let domain: String?
    
    /// Detailed description of responsibilities
    public let responsibilities: [String]
    
    /// Business value provided by this component
    public let businessValue: String
    
    /// Key behaviors this component exhibits
    public let keyBehaviors: [ComponentBehavior]
    
    public init(
        category: ComponentCategory,
        role: String,
        domain: String? = nil,
        responsibilities: [String],
        businessValue: String,
        keyBehaviors: [ComponentBehavior] = []
    ) {
        self.category = category
        self.role = role
        self.domain = domain
        self.responsibilities = responsibilities
        self.businessValue = businessValue
        self.keyBehaviors = keyBehaviors
    }
    
    public var description: String {
        let domainText = domain != nil ? " in \(domain!)" : ""
        return "\(category.rawValue) - \(role)\(domainText): \(businessValue)"
    }
}

/// Categories of architectural components
public enum ComponentCategory: String, CaseIterable, Sendable {
    case client = "client"                     // AxiomClient implementations
    case context = "context"                   // AxiomContext implementations
    case view = "view"                         // AxiomView implementations
    case domainModel = "domain_model"          // Domain model entities
    case capability = "capability"             // Capability providers
    case intelligence = "intelligence"         // Intelligence system components
    case infrastructure = "infrastructure"    // Infrastructure services
    case crossCutting = "cross_cutting"      // Cross-cutting concerns
    case integration = "integration"          // External system integration
    case validation = "validation"            // Validation and rule engines
    case transformation = "transformation"    // Data transformation components
    case orchestration = "orchestration"      // Workflow orchestration
}

/// Specific behaviors exhibited by components
public enum ComponentBehavior: String, CaseIterable, Sendable {
    case stateManagement = "state_management"
    case dataValidation = "data_validation"
    case businessLogic = "business_logic"
    case uiPresentation = "ui_presentation"
    case dataTransformation = "data_transformation"
    case eventHandling = "event_handling"
    case caching = "caching"
    case monitoring = "monitoring"
    case security = "security"
    case integration = "integration"
    case orchestration = "orchestration"
    case intelligence = "intelligence"
}

// MARK: - Component Relationships

/// Represents a relationship between architectural components
public struct ComponentRelationship: Sendable, Hashable {
    /// Type of relationship
    public let type: RelationshipType
    
    /// The component this relationship points to
    public let targetComponent: ComponentID
    
    /// Optional description of the relationship
    public let description: String?
    
    /// Strength of the coupling (0.0 to 1.0)
    public let couplingStrength: Double
    
    /// Whether this relationship is required for operation
    public let isRequired: Bool
    
    /// Communication pattern used in this relationship
    public let communicationPattern: CommunicationPattern
    
    public init(
        type: RelationshipType,
        targetComponent: ComponentID,
        description: String? = nil,
        couplingStrength: Double = 0.5,
        isRequired: Bool = true,
        communicationPattern: CommunicationPattern = .synchronous
    ) {
        self.type = type
        self.targetComponent = targetComponent
        self.description = description
        self.couplingStrength = max(0.0, min(1.0, couplingStrength))
        self.isRequired = isRequired
        self.communicationPattern = communicationPattern
    }
}

/// Types of relationships between components
public enum RelationshipType: String, CaseIterable, Sendable {
    case dependsOn = "depends_on"           // This component depends on the target
    case provides = "provides"              // This component provides services to the target
    case owns = "owns"                      // This component owns the target (1:1 ownership)
    case orchestrates = "orchestrates"      // This component orchestrates the target
    case observes = "observes"              // This component observes the target
    case validates = "validates"            // This component validates the target
    case transforms = "transforms"          // This component transforms data for the target
    case aggregates = "aggregates"          // This component aggregates multiple targets
    case composes = "composes"              // This component is composed of the target
    case delegates = "delegates"            // This component delegates to the target
    case inherits = "inherits"              // This component inherits from the target
    case implements = "implements"          // This component implements the target interface
}

/// Communication patterns between components
public enum CommunicationPattern: String, CaseIterable, Sendable {
    case synchronous = "synchronous"
    case asynchronous = "asynchronous"
    case eventDriven = "event_driven"
    case requestResponse = "request_response"
    case publishSubscribe = "publish_subscribe"
    case streaming = "streaming"
    case polling = "polling"
}

// MARK: - Architectural Constraints

/// Represents an architectural constraint that components must follow
public struct ArchitecturalConstraint: Sendable {
    /// Type of constraint
    public let type: ConstraintType
    
    /// Human-readable description
    public let description: String
    
    /// Whether this constraint is enforced at compile time
    public let isCompileTimeEnforced: Bool
    
    /// Whether this constraint is enforced at runtime
    public let isRuntimeEnforced: Bool
    
    /// Severity level if constraint is violated
    public let violationSeverity: ViolationSeverity
    
    /// Rule definition for validation
    public let rule: ConstraintRule
    
    public init(
        type: ConstraintType,
        description: String,
        isCompileTimeEnforced: Bool = false,
        isRuntimeEnforced: Bool = true,
        violationSeverity: ViolationSeverity = .error,
        rule: ConstraintRule
    ) {
        self.type = type
        self.description = description
        self.isCompileTimeEnforced = isCompileTimeEnforced
        self.isRuntimeEnforced = isRuntimeEnforced
        self.violationSeverity = violationSeverity
        self.rule = rule
    }
}

/// Types of architectural constraints
public enum ConstraintType: String, CaseIterable, Sendable {
    case viewContextRelationship = "view_context_relationship"     // 1:1 View-Context
    case clientOwnership = "client_ownership"                      // Single ownership
    case unidirectionalFlow = "unidirectional_flow"              // Data flow direction
    case capabilityValidation = "capability_validation"           // Capability requirements
    case domainIsolation = "domain_isolation"                     // Domain boundaries
    case actorSafety = "actor_safety"                            // Actor concurrency
    case sendableCompliance = "sendable_compliance"               // Thread safety
    case performanceThreshold = "performance_threshold"           // Performance limits
    case memoryConstraint = "memory_constraint"                   // Memory usage limits
    case securityConstraint = "security_constraint"               // Security requirements
    case businessRule = "business_rule"                          // Business logic constraints
    case dataIntegrity = "data_integrity"                        // Data consistency rules
}

/// Severity levels for constraint violations
public enum ViolationSeverity: String, CaseIterable, Sendable {
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

/// Rule definition for constraint validation
public enum ConstraintRule: Sendable {
    case exactly(count: Int)
    case atMost(count: Int)
    case atLeast(count: Int)
    case between(min: Int, max: Int)
    case none
    case all
    case custom(description: String, validation: @Sendable () async -> Bool)
    
    public func validate(actualCount: Int) async -> Bool {
        switch self {
        case .exactly(let count):
            return actualCount == count
        case .atMost(let count):
            return actualCount <= count
        case .atLeast(let count):
            return actualCount >= count
        case .between(let min, let max):
            return actualCount >= min && actualCount <= max
        case .none:
            return actualCount == 0
        case .all:
            return true
        case .custom(_, let validation):
            return await validation()
        }
    }
}

// MARK: - Architectural Layers

/// Defines the architectural layers in the Axiom framework
public enum ArchitecturalLayer: String, CaseIterable, Sendable {
    case presentation = "presentation"      // Views and UI components
    case application = "application"        // Application logic and contexts
    case domain = "domain"                  // Domain models and business logic
    case infrastructure = "infrastructure" // External services and data access
    case crossCutting = "cross_cutting"    // Logging, security, monitoring, etc.
    case intelligence = "intelligence"      // AI and intelligence features
}

// MARK: - Performance Profile

/// Describes the performance characteristics of a component
public struct PerformanceProfile: Sendable {
    /// Expected latency characteristics
    public let latency: LatencyProfile
    
    /// Expected throughput characteristics
    public let throughput: ThroughputProfile
    
    /// Memory usage characteristics
    public let memory: MemoryProfile
    
    /// CPU usage characteristics
    public let cpu: CPUProfile
    
    /// Scaling characteristics
    public let scaling: ScalingProfile
    
    public init(
        latency: LatencyProfile = LatencyProfile(),
        throughput: ThroughputProfile = ThroughputProfile(),
        memory: MemoryProfile = MemoryProfile(),
        cpu: CPUProfile = CPUProfile(),
        scaling: ScalingProfile = ScalingProfile()
    ) {
        self.latency = latency
        self.throughput = throughput
        self.memory = memory
        self.cpu = cpu
        self.scaling = scaling
    }
}

/// Latency performance characteristics
public struct LatencyProfile: Sendable {
    public let typical: TimeInterval
    public let maximum: TimeInterval
    public let p95: TimeInterval
    public let p99: TimeInterval
    
    public init(
        typical: TimeInterval = 0.010,
        maximum: TimeInterval = 0.100,
        p95: TimeInterval = 0.020,
        p99: TimeInterval = 0.050
    ) {
        self.typical = typical
        self.maximum = maximum
        self.p95 = p95
        self.p99 = p99
    }
}

/// Throughput performance characteristics
public struct ThroughputProfile: Sendable {
    public let operationsPerSecond: Double
    public let peakOperationsPerSecond: Double
    public let sustainedOperationsPerSecond: Double
    
    public init(
        operationsPerSecond: Double = 100.0,
        peakOperationsPerSecond: Double = 1000.0,
        sustainedOperationsPerSecond: Double = 500.0
    ) {
        self.operationsPerSecond = operationsPerSecond
        self.peakOperationsPerSecond = peakOperationsPerSecond
        self.sustainedOperationsPerSecond = sustainedOperationsPerSecond
    }
}

/// Memory usage characteristics
public struct MemoryProfile: Sendable {
    public let baselineBytes: Int
    public let maxBytes: Int
    public let growthPattern: MemoryGrowthPattern
    
    public init(
        baselineBytes: Int = 1024 * 1024,      // 1MB default
        maxBytes: Int = 10 * 1024 * 1024,      // 10MB default  
        growthPattern: MemoryGrowthPattern = .linear
    ) {
        self.baselineBytes = baselineBytes
        self.maxBytes = maxBytes
        self.growthPattern = growthPattern
    }
}

public enum MemoryGrowthPattern: String, CaseIterable, Sendable {
    case constant = "constant"
    case linear = "linear"
    case logarithmic = "logarithmic"
    case exponential = "exponential"
}

/// CPU usage characteristics
public struct CPUProfile: Sendable {
    public let baselineUtilization: Double    // 0.0 to 1.0
    public let peakUtilization: Double        // 0.0 to 1.0
    public let averageUtilization: Double     // 0.0 to 1.0
    
    public init(
        baselineUtilization: Double = 0.01,
        peakUtilization: Double = 0.50,
        averageUtilization: Double = 0.05
    ) {
        self.baselineUtilization = max(0.0, min(1.0, baselineUtilization))
        self.peakUtilization = max(0.0, min(1.0, peakUtilization))
        self.averageUtilization = max(0.0, min(1.0, averageUtilization))
    }
}

/// Scaling characteristics
public struct ScalingProfile: Sendable {
    public let scalingFactor: ScalingFactor
    public let bottlenecks: [PerformanceBottleneck]
    public let optimalLoadRange: ClosedRange<Double>
    
    public init(
        scalingFactor: ScalingFactor = .linear,
        bottlenecks: [PerformanceBottleneck] = [],
        optimalLoadRange: ClosedRange<Double> = 0.1...0.8
    ) {
        self.scalingFactor = scalingFactor
        self.bottlenecks = bottlenecks
        self.optimalLoadRange = optimalLoadRange
    }
}

public enum ScalingFactor: String, CaseIterable, Sendable {
    case constant = "constant"
    case linear = "linear"
    case sublinear = "sublinear"
    case superlinear = "superlinear"
}

public enum PerformanceBottleneck: String, CaseIterable, Sendable {
    case cpu = "cpu"
    case memory = "memory"
    case network = "network"
    case disk = "disk"
    case database = "database"
    case concurrency = "concurrency"
    case serialization = "serialization"
}

// MARK: - Quality Attributes

/// Quality attributes supported by a component
public struct QualityAttributes: Sendable {
    public let reliability: Double          // 0.0 to 1.0
    public let availability: Double         // 0.0 to 1.0 
    public let maintainability: Double      // 0.0 to 1.0
    public let testability: Double          // 0.0 to 1.0
    public let security: Double             // 0.0 to 1.0
    public let usability: Double            // 0.0 to 1.0
    public let interoperability: Double     // 0.0 to 1.0
    public let portability: Double          // 0.0 to 1.0
    
    public init(
        reliability: Double = 0.95,
        availability: Double = 0.99,
        maintainability: Double = 0.85,
        testability: Double = 0.90,
        security: Double = 0.95,
        usability: Double = 0.80,
        interoperability: Double = 0.85,
        portability: Double = 0.75
    ) {
        self.reliability = max(0.0, min(1.0, reliability))
        self.availability = max(0.0, min(1.0, availability))
        self.maintainability = max(0.0, min(1.0, maintainability))
        self.testability = max(0.0, min(1.0, testability))
        self.security = max(0.0, min(1.0, security))
        self.usability = max(0.0, min(1.0, usability))
        self.interoperability = max(0.0, min(1.0, interoperability))
        self.portability = max(0.0, min(1.0, portability))
    }
    
    /// Overall quality score
    public var overallScore: Double {
        (reliability + availability + maintainability + testability + 
         security + usability + interoperability + portability) / 8.0
    }
}

// MARK: - Architectural Description

/// Comprehensive description of a component's architecture
public struct ArchitecturalDescription: Sendable {
    /// Component overview
    public let overview: String
    
    /// Detailed purpose and responsibilities
    public let purpose: ComponentPurpose
    
    /// Architecture documentation
    public let architecture: ArchitectureDocumentation
    
    /// Interface documentation
    public let interfaces: [InterfaceDocumentation]
    
    /// Implementation notes
    public let implementation: ImplementationDocumentation
    
    /// Usage examples
    public let examples: [UsageExample]
    
    /// Related components
    public let relatedComponents: [ComponentReference]
    
    public init(
        overview: String,
        purpose: ComponentPurpose,
        architecture: ArchitectureDocumentation,
        interfaces: [InterfaceDocumentation] = [],
        implementation: ImplementationDocumentation,
        examples: [UsageExample] = [],
        relatedComponents: [ComponentReference] = []
    ) {
        self.overview = overview
        self.purpose = purpose
        self.architecture = architecture
        self.interfaces = interfaces
        self.implementation = implementation
        self.examples = examples
        self.relatedComponents = relatedComponents
    }
}

/// Architecture-level documentation
public struct ArchitectureDocumentation: Sendable {
    public let patterns: [ArchitecturalPattern]
    public let principles: [ArchitecturalPrinciple]
    public let tradeoffs: [ArchitecturalTradeoff]
    public let constraints: [ArchitecturalConstraint]
    
    public init(
        patterns: [ArchitecturalPattern] = [],
        principles: [ArchitecturalPrinciple] = [],
        tradeoffs: [ArchitecturalTradeoff] = [],
        constraints: [ArchitecturalConstraint] = []
    ) {
        self.patterns = patterns
        self.principles = principles
        self.tradeoffs = tradeoffs
        self.constraints = constraints
    }
}

/// Architectural patterns used by the component
public struct ArchitecturalPattern: Sendable, Hashable {
    public let name: String
    public let description: String
    public let benefits: [String]
    public let drawbacks: [String]
    
    public init(name: String, description: String, benefits: [String] = [], drawbacks: [String] = []) {
        self.name = name
        self.description = description
        self.benefits = benefits
        self.drawbacks = drawbacks
    }
}

/// Architectural principles followed by the component
public struct ArchitecturalPrinciple: Sendable, Hashable {
    public let name: String
    public let description: String
    public let rationale: String
    
    public init(name: String, description: String, rationale: String = "") {
        self.name = name
        self.description = description
        self.rationale = rationale
    }
}

/// Architectural tradeoffs made in the component
public struct ArchitecturalTradeoff: Sendable, Hashable {
    public let decision: String
    public let alternatives: [String]
    public let rationale: String
    public let consequences: [String]
    
    public init(decision: String, alternatives: [String] = [], rationale: String, consequences: [String] = []) {
        self.decision = decision
        self.alternatives = alternatives
        self.rationale = rationale
        self.consequences = consequences
    }
}

/// Interface documentation
public struct InterfaceDocumentation: Sendable, Hashable {
    public let name: String
    public let type: InterfaceType
    public let description: String
    public let methods: [MethodDocumentation]
    public let examples: [String]
    
    public init(name: String, type: InterfaceType, description: String, methods: [MethodDocumentation] = [], examples: [String] = []) {
        self.name = name
        self.type = type
        self.description = description
        self.methods = methods
        self.examples = examples
    }
}

public enum InterfaceType: String, CaseIterable, Sendable {
    case `protocol` = "protocol"
    case api = "api"
    case event = "event"
    case configuration = "configuration"
}

/// Method documentation
public struct MethodDocumentation: Sendable, Hashable {
    public let name: String
    public let description: String
    public let parameters: [ParameterDocumentation]
    public let returnValue: String?
    public let examples: [String]
    
    public init(name: String, description: String, parameters: [ParameterDocumentation] = [], returnValue: String? = nil, examples: [String] = []) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.returnValue = returnValue
        self.examples = examples
    }
}

/// Parameter documentation
public struct ParameterDocumentation: Sendable, Hashable {
    public let name: String
    public let type: String
    public let description: String
    public let isOptional: Bool
    
    public init(name: String, type: String, description: String, isOptional: Bool = false) {
        self.name = name
        self.type = type
        self.description = description
        self.isOptional = isOptional
    }
}

/// Implementation documentation
public struct ImplementationDocumentation: Sendable {
    public let technologies: [String]
    public let dependencies: [String]
    public let keyAlgorithms: [String]
    public let performanceNotes: [String]
    public let securityConsiderations: [String]
    public let limitations: [String]
    
    public init(
        technologies: [String] = [],
        dependencies: [String] = [],
        keyAlgorithms: [String] = [],
        performanceNotes: [String] = [],
        securityConsiderations: [String] = [],
        limitations: [String] = []
    ) {
        self.technologies = technologies
        self.dependencies = dependencies
        self.keyAlgorithms = keyAlgorithms
        self.performanceNotes = performanceNotes
        self.securityConsiderations = securityConsiderations
        self.limitations = limitations
    }
}

/// Usage example
public struct UsageExample: Sendable, Hashable {
    public let title: String
    public let description: String
    public let code: String
    public let expectedOutput: String?
    
    public init(title: String, description: String, code: String, expectedOutput: String? = nil) {
        self.title = title
        self.description = description
        self.code = code
        self.expectedOutput = expectedOutput
    }
}

/// Reference to a related component
public struct ComponentReference: Sendable, Hashable {
    public let componentID: ComponentID
    public let relationshipType: RelationshipType
    public let description: String
    
    public init(componentID: ComponentID, relationshipType: RelationshipType, description: String) {
        self.componentID = componentID
        self.relationshipType = relationshipType
        self.description = description
    }
}

// MARK: - Validation and Analysis

/// Result of architectural validation
public struct ArchitecturalValidationResult: Sendable {
    public let isValid: Bool
    public let violations: [ConstraintViolation]
    public let warnings: [ArchitecturalWarning]
    public let score: Double // 0.0 to 1.0
    public let recommendations: [ArchitecturalRecommendation]
    
    public init(
        isValid: Bool,
        violations: [ConstraintViolation] = [],
        warnings: [ArchitecturalWarning] = [],
        score: Double = 1.0,
        recommendations: [ArchitecturalRecommendation] = []
    ) {
        self.isValid = isValid
        self.violations = violations
        self.warnings = warnings
        self.score = max(0.0, min(1.0, score))
        self.recommendations = recommendations
    }
}

/// Constraint violation details
public struct ConstraintViolation: Sendable {
    public let constraint: ArchitecturalConstraint
    public let description: String
    public let severity: ViolationSeverity
    public let suggestedFix: String?
    
    public init(constraint: ArchitecturalConstraint, description: String, severity: ViolationSeverity, suggestedFix: String? = nil) {
        self.constraint = constraint
        self.description = description
        self.severity = severity
        self.suggestedFix = suggestedFix
    }
}

/// Architectural warning
public struct ArchitecturalWarning: Sendable {
    public let type: WarningType
    public let description: String
    public let recommendation: String?
    
    public init(type: WarningType, description: String, recommendation: String? = nil) {
        self.type = type
        self.description = description
        self.recommendation = recommendation
    }
}

public enum WarningType: String, CaseIterable, Sendable {
    case performance = "performance"
    case maintainability = "maintainability"
    case security = "security"
    case scalability = "scalability"
    case complexity = "complexity"
    case coupling = "coupling"
    case cohesion = "cohesion"
}

// Note: ArchitecturalRecommendation is defined in QueryEngine.swift with full implementation

public enum ImpactLevel: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public enum EffortLevel: String, CaseIterable, Sendable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case extensive = "extensive"
}

/// Change impact analysis
public struct ChangeImpactAnalysis: Sendable {
    public let change: ArchitecturalChange
    public let affectedComponents: [ComponentID]
    public let riskLevel: RiskLevel
    public let estimatedEffort: EffortLevel
    public let recommendations: [String]
    public let potentialIssues: [String]
    public let mitigationStrategies: [String]
    
    public init(
        change: ArchitecturalChange,
        affectedComponents: [ComponentID] = [],
        riskLevel: RiskLevel = .low,
        estimatedEffort: EffortLevel = .minimal,
        recommendations: [String] = [],
        potentialIssues: [String] = [],
        mitigationStrategies: [String] = []
    ) {
        self.change = change
        self.affectedComponents = affectedComponents
        self.riskLevel = riskLevel
        self.estimatedEffort = estimatedEffort
        self.recommendations = recommendations
        self.potentialIssues = potentialIssues
        self.mitigationStrategies = mitigationStrategies
    }
}

/// Architectural change description
public struct ArchitecturalChange: Sendable, Hashable {
    public let type: ChangeType
    public let description: String
    public let scope: ChangeScope
    public let rationale: String
    
    public init(type: ChangeType, description: String, scope: ChangeScope, rationale: String) {
        self.type = type
        self.description = description
        self.scope = scope
        self.rationale = rationale
    }
}

public enum ChangeType: String, CaseIterable, Sendable {
    case interface = "interface"
    case implementation = "implementation"
    case performance = "performance"
    case capability = "capability"
    case relationship = "relationship"
    case constraint = "constraint"
    case behavior = "behavior"
}

public enum ChangeScope: String, CaseIterable, Sendable {
    case local = "local"
    case module = "module"
    case layer = "layer"
    case system = "system"
    case external = "external"
}

public enum RiskLevel: String, CaseIterable, Sendable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Evolution suggestion
public struct EvolutionSuggestion: Sendable {
    public let type: EvolutionType
    public let title: String
    public let description: String
    public let benefits: [String]
    public let risks: [String]
    public let estimatedEffort: EffortLevel
    public let priority: Priority
    
    public init(
        type: EvolutionType,
        title: String,
        description: String,
        benefits: [String] = [],
        risks: [String] = [],
        estimatedEffort: EffortLevel = .medium,
        priority: Priority = .medium
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.benefits = benefits
        self.risks = risks
        self.estimatedEffort = estimatedEffort
        self.priority = priority
    }
}

public enum EvolutionType: String, CaseIterable, Sendable {
    case optimization = "optimization"
    case modernization = "modernization"
    case scalability = "scalability"
    case reliability = "reliability"
    case security = "security"
    case usability = "usability"
    case maintainability = "maintainability"
    case performance = "performance"
}

public enum Priority: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Default Implementation

/// Default implementation of ArchitecturalDNA for components that don't provide custom DNA
public struct DefaultArchitecturalDNA: ArchitecturalDNA {
    public let componentID: ComponentID
    public let purpose: ComponentPurpose
    public let architecturalLayer: ArchitecturalLayer
    public let relationships: [ComponentRelationship]
    public let constraints: [ArchitecturalConstraint]
    public let requiredCapabilities: Set<Capability>
    public let providedCapabilities: Set<Capability>
    public let performanceProfile: PerformanceProfile
    public let qualityAttributes: QualityAttributes
    
    public init(
        componentID: ComponentID,
        purpose: ComponentPurpose,
        architecturalLayer: ArchitecturalLayer,
        relationships: [ComponentRelationship] = [],
        constraints: [ArchitecturalConstraint] = [],
        requiredCapabilities: Set<Capability> = [],
        providedCapabilities: Set<Capability> = [],
        performanceProfile: PerformanceProfile = PerformanceProfile(),
        qualityAttributes: QualityAttributes = QualityAttributes()
    ) {
        self.componentID = componentID
        self.purpose = purpose
        self.architecturalLayer = architecturalLayer
        self.relationships = relationships
        self.constraints = constraints
        self.requiredCapabilities = requiredCapabilities
        self.providedCapabilities = providedCapabilities
        self.performanceProfile = performanceProfile
        self.qualityAttributes = qualityAttributes
    }
    
    public func generateDescription() -> ArchitecturalDescription {
        let overview = "Component \(componentID) serves as \(purpose.role) in the \(architecturalLayer.rawValue) layer."
        
        let architecture = ArchitectureDocumentation(
            patterns: [
                ArchitecturalPattern(
                    name: "Default Pattern",
                    description: "Standard Axiom component pattern"
                )
            ],
            principles: [
                ArchitecturalPrinciple(
                    name: "Single Responsibility",
                    description: "Component has a single, well-defined responsibility"
                )
            ]
        )
        
        let implementation = ImplementationDocumentation(
            technologies: ["Swift", "SwiftUI", "Axiom Framework"],
            dependencies: relationships.map { $0.targetComponent.description }
        )
        
        return ArchitecturalDescription(
            overview: overview,
            purpose: purpose,
            architecture: architecture,
            implementation: implementation
        )
    }
    
    public func validateArchitecturalIntegrity() async throws -> ArchitecturalValidationResult {
        var violations: [ConstraintViolation] = []
        var warnings: [ArchitecturalWarning] = []
        var score = 1.0
        
        // Validate each constraint
        for constraint in constraints {
            let isValid = await constraint.rule.validate(actualCount: relationships.count)
            if !isValid {
                violations.append(ConstraintViolation(
                    constraint: constraint,
                    description: "Constraint '\(constraint.description)' violated",
                    severity: constraint.violationSeverity
                ))
                score -= 0.1
            }
        }
        
        // Check for potential issues
        if relationships.count > 10 {
            warnings.append(ArchitecturalWarning(
                type: .coupling,
                description: "Component has many relationships (\(relationships.count))",
                recommendation: "Consider reducing coupling by consolidating related functionality"
            ))
        }
        
        let isValid = violations.isEmpty
        
        return ArchitecturalValidationResult(
            isValid: isValid,
            violations: violations,
            warnings: warnings,
            score: max(0.0, score)
        )
    }
    
    public func analyzeChangeImpact(_ change: ArchitecturalChange) async -> ChangeImpactAnalysis {
        let affectedComponents = relationships.map { $0.targetComponent }
        
        let riskLevel: RiskLevel
        switch change.scope {
        case .local:
            riskLevel = .minimal
        case .module:
            riskLevel = .low
        case .layer:
            riskLevel = .medium
        case .system:
            riskLevel = .high
        case .external:
            riskLevel = .critical
        }
        
        return ChangeImpactAnalysis(
            change: change,
            affectedComponents: affectedComponents,
            riskLevel: riskLevel,
            estimatedEffort: .medium,
            recommendations: ["Analyze dependent components", "Run comprehensive tests"],
            potentialIssues: ["Breaking changes may affect dependent components"],
            mitigationStrategies: ["Implement backward compatibility", "Use feature flags"]
        )
    }
    
    public func getEvolutionSuggestions() async -> [EvolutionSuggestion] {
        var suggestions: [EvolutionSuggestion] = []
        
        // Performance optimization suggestion
        if performanceProfile.latency.typical > 0.050 {
            suggestions.append(EvolutionSuggestion(
                type: .performance,
                title: "Optimize Response Time",
                description: "Current typical latency is \(performanceProfile.latency.typical)s, consider optimization",
                benefits: ["Improved user experience", "Better resource utilization"],
                priority: .high
            ))
        }
        
        // Maintainability suggestion
        if qualityAttributes.maintainability < 0.8 {
            suggestions.append(EvolutionSuggestion(
                type: .maintainability,
                title: "Improve Code Maintainability",
                description: "Current maintainability score is \(qualityAttributes.maintainability)",
                benefits: ["Easier future modifications", "Reduced technical debt"],
                priority: .medium
            ))
        }
        
        return suggestions
    }
}

// MARK: - DNA Generator

/// Utility for generating architectural DNA for components
public actor ArchitecturalDNAGenerator {
    /// Generates basic DNA for a component
    public func generateDNA(
        for componentID: ComponentID,
        category: ComponentCategory,
        role: String,
        domain: String? = nil
    ) -> DefaultArchitecturalDNA {
        let purpose = ComponentPurpose(
            category: category,
            role: role,
            domain: domain,
            responsibilities: ["Handle \(role) operations"],
            businessValue: "Provides \(role) functionality"
        )
        
        let layer = determineLayer(for: category)
        let constraints = generateDefaultConstraints(for: category)
        let capabilities = generateDefaultCapabilities(for: category)
        
        return DefaultArchitecturalDNA(
            componentID: componentID,
            purpose: purpose,
            architecturalLayer: layer,
            constraints: constraints,
            requiredCapabilities: capabilities.required,
            providedCapabilities: capabilities.provided
        )
    }
    
    private func determineLayer(for category: ComponentCategory) -> ArchitecturalLayer {
        switch category {
        case .view:
            return .presentation
        case .context:
            return .application
        case .client, .domainModel:
            return .domain
        case .capability, .infrastructure:
            return .infrastructure
        case .crossCutting:
            return .crossCutting
        case .intelligence:
            return .intelligence
        case .integration, .validation, .transformation, .orchestration:
            return .application
        }
    }
    
    private func generateDefaultConstraints(for category: ComponentCategory) -> [ArchitecturalConstraint] {
        var constraints: [ArchitecturalConstraint] = []
        
        switch category {
        case .view:
            constraints.append(ArchitecturalConstraint(
                type: .viewContextRelationship,
                description: "View must have exactly one Context relationship",
                rule: .exactly(count: 1)
            ))
        case .client:
            constraints.append(ArchitecturalConstraint(
                type: .clientOwnership,
                description: "Client must maintain single ownership of domain models",
                rule: .all
            ))
        case .domainModel:
            constraints.append(ArchitecturalConstraint(
                type: .domainIsolation,
                description: "Domain model must maintain isolation boundaries",
                rule: .all
            ))
        default:
            break
        }
        
        // All components must be Sendable
        constraints.append(ArchitecturalConstraint(
            type: .sendableCompliance,
            description: "Component must conform to Sendable for thread safety",
            isCompileTimeEnforced: true,
            rule: .all
        ))
        
        return constraints
    }
    
    private func generateDefaultCapabilities(for category: ComponentCategory) -> (required: Set<Capability>, provided: Set<Capability>) {
        var required: Set<Capability> = []
        var provided: Set<Capability> = []
        
        switch category {
        case .client:
            required.insert(.stateManagement)
            provided.insert(.businessLogic)
        case .context:
            required.insert(.stateManagement)
            provided.insert(.stateManagement)
        case .view:
            required.insert(.stateManagement)
            provided.insert(.navigation)
        case .intelligence:
            required.insert(.analytics)
            provided.insert(.performanceMonitoring)
        default:
            break
        }
        
        return (required: required, provided: provided)
    }
}