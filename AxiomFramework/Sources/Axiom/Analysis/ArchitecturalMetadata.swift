import Foundation

// MARK: - Architectural Metadata Protocol

/// Protocol that provides complete component metadata and documentation capabilities
/// Provides genuine architectural information and analysis without AI theater claims
public protocol ArchitecturalMetadata: Sendable {
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

// MARK: - Default Implementation

/// Default implementation of architectural metadata
/// Preserves all genuine functionality from ArchitecturalDNA without AI theater
public struct DefaultArchitecturalMetadata: ArchitecturalMetadata {
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
        let overview = """
        \(purpose.category.rawValue.capitalized) Component: \(purpose.role)
        
        Purpose: \(purpose.businessValue)
        
        Layer: \(architecturalLayer.rawValue.capitalized)
        
        Responsibilities:
        \(purpose.responsibilities.map { "- \($0)" }.joined(separator: "\n"))
        """
        
        let architecture = ArchitectureDocumentation(
            patterns: extractArchitecturalPatterns(),
            principles: extractDesignPrinciples(),
            constraints: constraints
        )
        
        let interfaces = generateInterfaceDocumentation()
        let implementation = generateImplementationDocumentation()
        let examples = generateUsageExamples()
        let relatedComponents = relationships.map { relationship in
            ComponentReference(
                componentID: relationship.targetComponent,
                relationshipType: relationship.type,
                description: relationship.description ?? "Related component"
            )
        }
        
        return ArchitecturalDescription(
            overview: overview,
            purpose: purpose,
            architecture: architecture,
            interfaces: interfaces,
            implementation: implementation,
            examples: examples,
            relatedComponents: relatedComponents
        )
    }
    
    public func validateArchitecturalIntegrity() async throws -> ArchitecturalValidationResult {
        var violations: [ConstraintViolation] = []
        var warnings: [ArchitecturalWarning] = []
        var score = 1.0
        
        // Validate each constraint
        for constraint in constraints {
            do {
                let isValid = try validateConstraint(constraint)
                if !isValid {
                    violations.append(ConstraintViolation(
                        constraint: constraint,
                        description: "Constraint validation failed: \(constraint.description)",
                        severity: .warning
                    ))
                    score -= 0.1
                }
            } catch {
                violations.append(ConstraintViolation(
                    constraint: constraint,
                    description: "Constraint validation error: \(error)",
                    severity: .error
                ))
                score -= 0.2
            }
        }
        
        // Validate capabilities
        for capability in requiredCapabilities {
            if !isCapabilityAvailable(capability) {
                warnings.append(ArchitecturalWarning(
                    type: .performance,
                    description: "Required capability '\(capability.rawValue)' may not be available"
                ))
                score -= 0.05
            }
        }
        
        // Ensure score doesn't go below 0
        score = max(0.0, score)
        
        return ArchitecturalValidationResult(
            isValid: violations.isEmpty,
            violations: violations,
            warnings: warnings,
            score: score,
            recommendations: []
        )
    }
    
    public func analyzeChangeImpact(_ change: ArchitecturalChange) async -> ChangeImpactAnalysis {
        // Analyze which components would be affected by this change
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
    
    // MARK: - Private Helper Methods
    
    private func extractArchitecturalPatterns() -> [ArchitecturalPattern] {
        var patterns: [ArchitecturalPattern] = []
        
        switch purpose.category {
        case .client:
            patterns.append(ArchitecturalPattern(
                name: "Actor Pattern",
                description: "Thread-safe state management using Swift actors",
                benefits: ["Thread safety", "Isolation", "Concurrency"]
            ))
            patterns.append(ArchitecturalPattern(
                name: "State Management Pattern", 
                description: "Centralized state management with observer notifications",
                benefits: ["Predictable state", "Single source of truth"]
            ))
        case .context:
            patterns.append(ArchitecturalPattern(
                name: "Orchestration Pattern",
                description: "Coordinates multiple client interactions",
                benefits: ["Separation of concerns", "Clean architecture"]
            ))
        case .view:
            patterns.append(ArchitecturalPattern(
                name: "Model-View Pattern",
                description: "SwiftUI integration with reactive bindings",
                benefits: ["Reactive UI", "Type safety"]
            ))
        default:
            patterns.append(ArchitecturalPattern(
                name: "Component Pattern",
                description: "Generic component architecture",
                benefits: ["Modularity", "Reusability"]
            ))
        }
        
        return patterns
    }
    
    private func extractDesignPrinciples() -> [ArchitecturalPrinciple] {
        var principles: [ArchitecturalPrinciple] = []
        
        if constraints.contains(where: { $0.type == .sendableCompliance }) {
            principles.append(ArchitecturalPrinciple(
                name: "Thread Safety",
                description: "Ensure thread-safe operations through Sendable compliance"
            ))
        }
        
        if constraints.contains(where: { $0.type == .actorSafety }) {
            principles.append(ArchitecturalPrinciple(
                name: "Actor Isolation", 
                description: "Use actor isolation for concurrent operations"
            ))
        }
        
        principles.append(ArchitecturalPrinciple(
            name: "Single Responsibility",
            description: "Each component has a single, well-defined responsibility"
        ))
        
        return principles
    }
    
    private func generateInterfaceDocumentation() -> [InterfaceDocumentation] {
        var interfaces: [InterfaceDocumentation] = []
        
        // Generate interface documentation based on component type
        switch purpose.category {
        case .client:
            interfaces.append(InterfaceDocumentation(
                name: "AxiomClient",
                type: .protocol,
                description: "Actor-based state management interface",
                methods: [
                    MethodDocumentation(
                        name: "stateSnapshot",
                        description: "Get current state snapshot",
                        returnValue: "State snapshot"
                    )
                ]
            ))
        case .context:
            interfaces.append(InterfaceDocumentation(
                name: "AxiomContext",
                type: .protocol,
                description: "Context orchestration interface",
                methods: [
                    MethodDocumentation(
                        name: "onAppear",
                        description: "Called when view appears"
                    )
                ]
            ))
        default:
            break
        }
        
        return interfaces
    }
    
    private func generateImplementationDocumentation() -> ImplementationDocumentation {
        var technologies: [String] = ["Swift", "SwiftUI"]
        var dependencies: [String] = []
        
        if requiredCapabilities.contains(.performanceMonitoring) {
            technologies.append("PerformanceMonitor")
        }
        
        for relationship in relationships {
            dependencies.append(relationship.targetComponent.description)
        }
        
        return ImplementationDocumentation(
            technologies: technologies,
            dependencies: dependencies,
            keyAlgorithms: ["State Management", "Observer Pattern"],
            performanceNotes: ["Actor-based concurrency", "Thread-safe operations"],
            securityConsiderations: ["Sendable compliance", "Memory safety"],
            limitations: ["iOS/macOS only"]
        )
    }
    
    private func generateUsageExamples() -> [UsageExample] {
        var examples: [UsageExample] = []
        
        switch purpose.category {
        case .client:
            examples.append(UsageExample(
                title: "Basic Client Usage",
                description: "How to implement and use an AxiomClient",
                code: """
                actor MyClient: AxiomClient {
                    typealias State = MyState
                    private(set) var stateSnapshot = MyState()
                }
                """,
                expectedOutput: "Thread-safe state management"
            ))
        case .context:
            examples.append(UsageExample(
                title: "Basic Context Usage",
                description: "How to implement and use an AxiomContext",
                code: """
                @MainActor
                class MyContext: AxiomContext {
                    let myClient: MyClient
                }
                """,
                expectedOutput: "Context orchestration"
            ))
        default:
            break
        }
        
        return examples
    }
    
    private func validateConstraint(_ constraint: ArchitecturalConstraint) throws -> Bool {
        // Basic constraint validation - in a real implementation this would be more sophisticated
        switch constraint.type {
        case .sendableCompliance:
            return true // Assume Sendable compliance is checked at compile time
        case .actorSafety:
            return purpose.category == .client || purpose.category == .capability
        case .viewContextRelationship:
            return purpose.category == .view ? relationships.count == 1 : true
        default:
            return true
        }
    }
    
    private func isCapabilityAvailable(_ capability: Capability) -> Bool {
        // Basic capability check - in a real implementation this would check actual availability
        return true
    }
}

// MARK: - Metadata Generator

/// Utility for generating architectural metadata for components
/// Replaces ArchitecturalDNAGenerator with cleaner naming
public actor ArchitecturalMetadataGenerator {
    /// Generates basic metadata for a component
    public func generateMetadata(
        for componentID: ComponentID,
        category: ComponentCategory,
        role: String,
        domain: String? = nil
    ) -> DefaultArchitecturalMetadata {
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
        
        return DefaultArchitecturalMetadata(
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
            return .infrastructure  // Changed from .intelligence to .infrastructure (remove AI theater)
        case .integration, .validation, .transformation, .orchestration:
            return .application
        case .unknown:
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