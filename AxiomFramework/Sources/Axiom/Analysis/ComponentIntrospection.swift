import Foundation

// MARK: - Component Introspection Protocol

/// Protocol for introspecting and analyzing architectural components
/// This is one of the core analysis systems in Axiom
public protocol ComponentIntrospecting: Actor {
    /// Discovers all components in the current architecture
    func discoverComponents() async -> [IntrospectedComponent]
    
    /// Analyzes a specific component and its relationships
    func analyzeComponent(_ componentID: ComponentID) async throws -> ComponentAnalysis
    
    /// Maps relationships between all discovered components
    func mapComponentRelationships() async -> ComponentRelationshipMap
    
    /// Generates comprehensive documentation for all components
    func generateDocumentation() async -> ArchitecturalDocumentationSet
    
    /// Validates architectural integrity across all components
    func validateArchitecturalIntegrity() async -> SystemIntegrityReport
    
    /// Performs impact analysis for potential changes
    func performImpactAnalysis(_ changes: [ProposedChange]) async -> SystemImpactAnalysis
    
    /// Gets component metrics and statistics
    func getComponentMetrics() async -> ComponentMetricsReport
}

// MARK: - Component Introspection Engine

/// Actor-based component introspection engine with caching and performance optimization
public actor ComponentIntrospectionEngine: ComponentIntrospecting {
    // MARK: Properties
    
    /// Registry of discovered components
    private var componentRegistry: ComponentRegistry
    
    /// Relationship map cache
    private var relationshipCache: ComponentRelationshipMap?
    
    /// Documentation cache
    private var documentationCache: [ComponentID: ComponentDocumentation] = [:]
    
    /// Analysis cache with TTL
    private var analysisCache: [ComponentID: CachedAnalysis] = [:]
    
    /// Performance monitor for introspection operations
    private let performanceMonitor: PerformanceMonitor
    
    /// Configuration for introspection behavior
    private let configuration: IntrospectionConfiguration
    
    /// Cache TTL for analysis results (in seconds)
    private let cacheTimeout: TimeInterval
    
    // MARK: Initialization
    
    public init(
        configuration: IntrospectionConfiguration = IntrospectionConfiguration(),
        performanceMonitor: PerformanceMonitor,
        cacheTimeout: TimeInterval = 300.0 // 5 minutes
    ) {
        self.configuration = configuration
        self.performanceMonitor = performanceMonitor
        self.cacheTimeout = cacheTimeout
        self.componentRegistry = ComponentRegistry()
    }
    
    // MARK: Component Discovery
    
    public func discoverComponents() async -> [IntrospectedComponent] {
        let token = await performanceMonitor.startOperation("discover_components", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Clear existing registry for fresh discovery
        componentRegistry = ComponentRegistry()
        
        var discoveredComponents: [IntrospectedComponent] = []
        
        // Discover components based on configuration
        if configuration.enableClientDiscovery {
            discoveredComponents.append(contentsOf: await discoverClients())
        }
        
        if configuration.enableContextDiscovery {
            discoveredComponents.append(contentsOf: await discoverContexts())
        }
        
        if configuration.enableViewDiscovery {
            discoveredComponents.append(contentsOf: await discoverViews())
        }
        
        if configuration.enableDomainModelDiscovery {
            discoveredComponents.append(contentsOf: await discoverDomainModels())
        }
        
        if configuration.enableCapabilityDiscovery {
            discoveredComponents.append(contentsOf: await discoverCapabilities())
        }
        
        // Register all discovered components
        for component in discoveredComponents {
            await componentRegistry.register(component)
        }
        
        // Clear caches since component set may have changed
        relationshipCache = nil
        documentationCache.removeAll()
        analysisCache.removeAll()
        
        return discoveredComponents
    }
    
    // MARK: Component Analysis
    
    public func analyzeComponent(_ componentID: ComponentID) async throws -> ComponentAnalysis {
        let token = await performanceMonitor.startOperation("analyze_component", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Check cache first
        if let cachedAnalysis = analysisCache[componentID],
           !cachedAnalysis.isExpired(timeout: cacheTimeout) {
            return cachedAnalysis.analysis
        }
        
        // Get component from registry
        guard let component = await componentRegistry.getComponent(componentID) else {
            throw IntrospectionError.componentNotFound(componentID)
        }
        
        // Perform comprehensive analysis
        let analysis = await performComponentAnalysis(component)
        
        // Cache the result
        analysisCache[componentID] = CachedAnalysis(
            analysis: analysis,
            timestamp: Date()
        )
        
        return analysis
    }
    
    // MARK: Relationship Mapping
    
    public func mapComponentRelationships() async -> ComponentRelationshipMap {
        let token = await performanceMonitor.startOperation("map_relationships", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Return cached map if available and recent
        if let cachedMap = relationshipCache {
            return cachedMap
        }
        
        // Build comprehensive relationship map
        let allComponents = await componentRegistry.getAllComponents()
        var relationshipMap = ComponentRelationshipMap()
        
        // Analyze relationships for each component
        for component in allComponents {
            let relationships = await analyzeComponentRelationships(component)
            for relationship in relationships {
                relationshipMap.addRelationship(relationship)
            }
        }
        
        // Detect implied relationships
        let impliedRelationships = await detectImpliedRelationships(allComponents)
        for relationship in impliedRelationships {
            relationshipMap.addRelationship(relationship)
        }
        
        // Cache the result
        relationshipCache = relationshipMap
        
        return relationshipMap
    }
    
    // MARK: Documentation Generation
    
    public func generateDocumentation() async -> ArchitecturalDocumentationSet {
        let token = await performanceMonitor.startOperation("generate_documentation", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        let allComponents = await componentRegistry.getAllComponents()
        var documentationSet = ArchitecturalDocumentationSet()
        
        // Generate documentation for each component
        for component in allComponents {
            if let cachedDoc = documentationCache[component.id] {
                documentationSet.addComponentDocumentation(cachedDoc)
                continue
            }
            
            let documentation = await generateComponentDocumentation(component)
            documentationCache[component.id] = documentation
            documentationSet.addComponentDocumentation(documentation)
        }
        
        // Generate system-level documentation
        let systemDoc = await generateSystemDocumentation(allComponents)
        documentationSet.setSystemDocumentation(systemDoc)
        
        return documentationSet
    }
    
    // MARK: Architectural Validation
    
    public func validateArchitecturalIntegrity() async -> SystemIntegrityReport {
        let token = await performanceMonitor.startOperation("validate_integrity", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        let allComponents = await componentRegistry.getAllComponents()
        var violations: [SystemIntegrityViolation] = []
        var warnings: [SystemIntegrityWarning] = []
        var score = 1.0
        
        // Validate each component individually
        for component in allComponents {
            if let dna = component.architecturalDNA {
                do {
                    let validation = try await dna.validateArchitecturalIntegrity()
                    
                    // Add violations
                    for violation in validation.violations {
                        violations.append(SystemIntegrityViolation(
                            component: component.id,
                            violation: violation,
                            severity: violation.severity
                        ))
                    }
                    
                    // Add warnings
                    for warning in validation.warnings {
                        warnings.append(SystemIntegrityWarning(
                            component: component.id,
                            warning: warning
                        ))
                    }
                    
                    // Update score
                    score = min(score, validation.score)
                } catch {
                    violations.append(SystemIntegrityViolation(
                        component: component.id,
                        violation: ConstraintViolation(
                            constraint: ArchitecturalConstraint(
                                type: .sendableCompliance,
                                description: "Component validation failed",
                                rule: .all
                            ),
                            description: "Validation error: \(error)",
                            severity: .error
                        ),
                        severity: .error
                    ))
                }
            }
        }
        
        // Validate system-level constraints
        let systemViolations = await validateSystemConstraints(allComponents)
        violations.append(contentsOf: systemViolations)
        
        return SystemIntegrityReport(
            isValid: violations.isEmpty,
            overallScore: score,
            violations: violations,
            warnings: warnings,
            componentCount: allComponents.count,
            validatedAt: Date()
        )
    }
    
    // MARK: Impact Analysis
    
    public func performImpactAnalysis(_ changes: [ProposedChange]) async -> SystemImpactAnalysis {
        let token = await performanceMonitor.startOperation("impact_analysis", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var impacts: [ChangeImpact] = []
        var overallRisk = RiskLevel.minimal
        
        for change in changes {
            let impact = await analyzeChangeImpact(change)
            impacts.append(impact)
            
            // Update overall risk level
            if impact.riskLevel.rawValue > overallRisk.rawValue {
                overallRisk = impact.riskLevel
            }
        }
        
        // Calculate estimated effort
        let totalEffort = impacts.reduce(EffortLevel.minimal) { currentMax, impact in
            impact.estimatedEffort.rawValue > currentMax.rawValue ? impact.estimatedEffort : currentMax
        }
        
        // Generate recommendations
        let recommendations = await generateChangeRecommendations(impacts)
        
        return SystemImpactAnalysis(
            changes: changes,
            impacts: impacts,
            overallRisk: overallRisk,
            estimatedEffort: totalEffort,
            recommendations: recommendations,
            analyzedAt: Date()
        )
    }
    
    // MARK: Component Metrics
    
    public func getComponentMetrics() async -> ComponentMetricsReport {
        let token = await performanceMonitor.startOperation("component_metrics", category: .analysisQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        let allComponents = await componentRegistry.getAllComponents()
        let relationshipMap = await mapComponentRelationships()
        
        // Calculate metrics
        let totalComponents = allComponents.count
        let averageRelationships = Double(relationshipMap.totalRelationships) / Double(max(totalComponents, 1))
        
        // Analyze component distribution
        let categoryDistribution = analyzeCategoryDistribution(allComponents)
        let layerDistribution = analyzeLayerDistribution(allComponents)
        
        // Find highly coupled components
        let highlyCoupledComponents = findHighlyCoupledComponents(allComponents, relationshipMap)
        
        // Calculate complexity metrics
        let complexityMetrics = calculateComplexityMetrics(allComponents, relationshipMap)
        
        return ComponentMetricsReport(
            totalComponents: totalComponents,
            totalRelationships: relationshipMap.totalRelationships,
            averageRelationshipsPerComponent: averageRelationships,
            categoryDistribution: categoryDistribution,
            layerDistribution: layerDistribution,
            highlyCoupledComponents: highlyCoupledComponents,
            complexityMetrics: complexityMetrics,
            generatedAt: Date()
        )
    }
    
    // MARK: Private Implementation
    
    private func discoverClients() async -> [IntrospectedComponent] {
        // Discover AxiomClient implementations
        var clients: [IntrospectedComponent] = []
        
        // Add framework's core client types
        clients.append(IntrospectedComponent(
            id: ComponentID("axiom-client-protocol"),
            name: "AxiomClient",
            category: .client,
            type: "Protocol",
            architecturalDNA: createClientProtocolDNA()
        ))
        
        // Add performance monitor client
        clients.append(IntrospectedComponent(
            id: ComponentID("performance-monitor-client"),
            name: "PerformanceMonitor",
            category: .client,
            type: "Actor",
            architecturalDNA: createPerformanceMonitorDNA()
        ))
        
        return clients
    }
    
    private func discoverContexts() async -> [IntrospectedComponent] {
        // Discover AxiomContext implementations
        var contexts: [IntrospectedComponent] = []
        
        // Add framework's core context types
        contexts.append(IntrospectedComponent(
            id: ComponentID("axiom-context-protocol"),
            name: "AxiomContext",
            category: .context,
            type: "Protocol",
            architecturalDNA: createContextProtocolDNA()
        ))
        
        return contexts
    }
    
    private func discoverViews() async -> [IntrospectedComponent] {
        // Discover AxiomView implementations
        var views: [IntrospectedComponent] = []
        
        // Add framework's core view types
        views.append(IntrospectedComponent(
            id: ComponentID("axiom-view-protocol"),
            name: "AxiomView",
            category: .view,
            type: "Protocol",
            architecturalDNA: createViewProtocolDNA()
        ))
        
        return views
    }
    
    private func discoverDomainModels() async -> [IntrospectedComponent] {
        // Discover DomainModel implementations
        var domainModels: [IntrospectedComponent] = []
        
        // Add framework's core domain model types
        domainModels.append(IntrospectedComponent(
            id: ComponentID("domain-model-protocol"),
            name: "DomainModel",
            category: .domainModel,
            type: "Protocol",
            architecturalDNA: createDomainModelProtocolDNA()
        ))
        
        return domainModels
    }
    
    private func discoverCapabilities() async -> [IntrospectedComponent] {
        // Discover capability providers
        var capabilities: [IntrospectedComponent] = []
        
        // Add framework's core capability types
        capabilities.append(IntrospectedComponent(
            id: ComponentID("capability-manager"),
            name: "CapabilityManager",
            category: .capability,
            type: "Actor",
            architecturalDNA: createCapabilityManagerDNA()
        ))
        
        // Add analysis components
        capabilities.append(IntrospectedComponent(
            id: ComponentID("axiom-analyzer"),
            name: "FrameworkAnalyzer",
            category: .analysis,
            type: "Protocol",
            architecturalDNA: createAnalysisSystemDNA()
        ))
        
        return capabilities
    }
    
    private func performComponentAnalysis(_ component: IntrospectedComponent) async -> ComponentAnalysis {
        let relationships = await analyzeComponentRelationships(component)
        let constraints = component.architecturalDNA?.constraints ?? []
        let capabilities = ComponentCapabilityAnalysis(
            required: component.architecturalDNA?.requiredCapabilities ?? [],
            provided: component.architecturalDNA?.providedCapabilities ?? []
        )
        
        let complexity = calculateComponentComplexity(component, relationships)
        let qualityScore = calculateQualityScore(component)
        
        return ComponentAnalysis(
            component: component,
            relationships: relationships,
            constraints: constraints,
            capabilities: capabilities,
            complexity: complexity,
            qualityScore: qualityScore,
            analyzedAt: Date()
        )
    }
    
    private func analyzeComponentRelationships(_ component: IntrospectedComponent) async -> [AnalyzedRelationship] {
        guard let dna = component.architecturalDNA else {
            return []
        }
        
        return dna.relationships.map { relationship in
            AnalyzedRelationship(
                source: component.id,
                target: relationship.targetComponent,
                type: relationship.type,
                strength: relationship.couplingStrength,
                isRequired: relationship.isRequired,
                communicationPattern: relationship.communicationPattern,
                description: relationship.description
            )
        }
    }
    
    private func detectImpliedRelationships(_ components: [IntrospectedComponent]) async -> [AnalyzedRelationship] {
        var impliedRelationships: [AnalyzedRelationship] = []
        
        // Detect 1:1 View-Context relationships
        let views = components.filter { $0.category == .view }
        let contexts = components.filter { $0.category == .context }
        
        for view in views {
            // Find matching context based on naming patterns or type relationships
            if let matchingContext = findMatchingContext(for: view, in: contexts) {
                impliedRelationships.append(AnalyzedRelationship(
                    source: view.id,
                    target: matchingContext.id,
                    type: .dependsOn,
                    strength: 1.0,
                    isRequired: true,
                    communicationPattern: .synchronous,
                    description: "Implied 1:1 View-Context relationship"
                ))
            }
        }
        
        return impliedRelationships
    }
    
    private func findMatchingContext(for view: IntrospectedComponent, in contexts: [IntrospectedComponent]) -> IntrospectedComponent? {
        // Simple heuristic: match by similar names
        let viewName = view.name.replacingOccurrences(of: "View", with: "")
        return contexts.first { context in
            context.name.contains(viewName) || context.name.replacingOccurrences(of: "Context", with: "") == viewName
        }
    }
    
    private func generateComponentDocumentation(_ component: IntrospectedComponent) async -> ComponentDocumentation {
        guard let dna = component.architecturalDNA else {
            return ComponentDocumentation(
                componentID: component.id,
                name: component.name,
                overview: "Component with no architectural DNA available",
                generatedAt: Date()
            )
        }
        
        let description = dna.generateDescription()
        
        return ComponentDocumentation(
            componentID: component.id,
            name: component.name,
            overview: description.overview,
            purpose: description.purpose,
            architecture: description.architecture,
            interfaces: description.interfaces,
            implementation: description.implementation,
            examples: description.examples,
            relatedComponents: description.relatedComponents,
            generatedAt: Date()
        )
    }
    
    private func generateSystemDocumentation(_ components: [IntrospectedComponent]) async -> SystemDocumentation {
        let totalComponents = components.count
        let categoryDistribution = analyzeCategoryDistribution(components)
        let layerDistribution = analyzeLayerDistribution(components)
        
        let overview = """
        Axiom Framework System Overview
        
        Total Components: \(totalComponents)
        
        Layer Distribution:
        \(layerDistribution.map { "- \($0.key.rawValue): \($0.value) components" }.joined(separator: "\n"))
        
        Category Distribution:
        \(categoryDistribution.map { "- \($0.key.rawValue): \($0.value) components" }.joined(separator: "\n"))
        """
        
        return SystemDocumentation(
            overview: overview,
            architecture: SystemArchitectureDocumentation(),
            constraints: extractSystemConstraints(components),
            totalComponents: totalComponents,
            generatedAt: Date()
        )
    }
    
    private func validateSystemConstraints(_ components: [IntrospectedComponent]) async -> [SystemIntegrityViolation] {
        var violations: [SystemIntegrityViolation] = []
        
        // Validate 1:1 View-Context relationships
        let views = components.filter { $0.category == .view }
        let contexts = components.filter { $0.category == .context }
        
        if views.count != contexts.count {
            let constraint = ArchitecturalConstraint(
                type: .viewContextRelationship,
                description: "System must maintain 1:1 View-Context relationship",
                rule: .exactly(count: 1)
            )
            
            violations.append(SystemIntegrityViolation(
                component: ComponentID("SYSTEM"),
                violation: ConstraintViolation(
                    constraint: constraint,
                    description: "View count (\(views.count)) != Context count (\(contexts.count))",
                    severity: .error
                ),
                severity: .error
            ))
        }
        
        return violations
    }
    
    private func analyzeChangeImpact(_ change: ProposedChange) async -> ChangeImpact {
        let _ = await componentRegistry.getAllComponents()
        let relationshipMap = await mapComponentRelationships()
        
        // Find directly affected components
        var affectedComponents: Set<ComponentID> = [change.targetComponent]
        
        // Find components that depend on the target
        let dependentComponents = relationshipMap.getComponentsDependingOn(change.targetComponent)
        affectedComponents.formUnion(dependentComponents)
        
        // Assess risk based on change type and affected component count
        let riskLevel = assessChangeRisk(change, affectedComponentCount: affectedComponents.count)
        let estimatedEffort = assessChangeEffort(change, affectedComponents: Array(affectedComponents))
        
        return ChangeImpact(
            change: change,
            affectedComponents: Array(affectedComponents),
            riskLevel: riskLevel,
            estimatedEffort: estimatedEffort,
            recommendations: generateChangeSpecificRecommendations(change),
            potentialIssues: identifyPotentialIssues(change, affectedComponents: Array(affectedComponents))
        )
    }
    
    private func generateChangeRecommendations(_ impacts: [ChangeImpact]) async -> [String] {
        var recommendations: [String] = []
        
        let highRiskChanges = impacts.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        if !highRiskChanges.isEmpty {
            recommendations.append("Consider implementing high-risk changes in phases")
            recommendations.append("Implement comprehensive testing for high-risk changes")
        }
        
        let manyAffectedComponents = impacts.filter { $0.affectedComponents.count > 5 }
        if !manyAffectedComponents.isEmpty {
            recommendations.append("Changes affecting many components should be carefully coordinated")
        }
        
        return recommendations
    }
    
    private func analyzeCategoryDistribution(_ components: [IntrospectedComponent]) -> [ComponentCategory: Int] {
        var distribution: [ComponentCategory: Int] = [:]
        for component in components {
            distribution[component.category, default: 0] += 1
        }
        return distribution
    }
    
    private func analyzeLayerDistribution(_ components: [IntrospectedComponent]) -> [ArchitecturalLayer: Int] {
        var distribution: [ArchitecturalLayer: Int] = [:]
        for component in components {
            let layer = component.architecturalDNA?.architecturalLayer ?? .application
            distribution[layer, default: 0] += 1
        }
        return distribution
    }
    
    private func findHighlyCoupledComponents(_ components: [IntrospectedComponent], _ relationshipMap: ComponentRelationshipMap) -> [ComponentID] {
        let threshold = 5 // Components with more than 5 relationships are considered highly coupled
        
        return components.filter { component in
            let relationshipCount = relationshipMap.getRelationshipCount(for: component.id)
            return relationshipCount > threshold
        }.map { $0.id }
    }
    
    private func calculateComplexityMetrics(_ components: [IntrospectedComponent], _ relationshipMap: ComponentRelationshipMap) -> ComplexityMetrics {
        let totalRelationships = relationshipMap.totalRelationships
        let averageComplexity = components.map { calculateComponentComplexity($0, []) }.reduce(0, +) / Double(max(components.count, 1))
        
        return ComplexityMetrics(
            averageComponentComplexity: averageComplexity,
            systemCouplingIndex: Double(totalRelationships) / Double(max(components.count, 1)),
            maxComponentComplexity: components.map { calculateComponentComplexity($0, []) }.max() ?? 0
        )
    }
    
    private func calculateComponentComplexity(_ component: IntrospectedComponent, _ relationships: [AnalyzedRelationship]) -> Double {
        // Simple complexity calculation based on relationships and constraints
        let relationshipComplexity = Double(relationships.count) * 0.1
        let constraintComplexity = Double(component.architecturalDNA?.constraints.count ?? 0) * 0.05
        let capabilityComplexity = Double(component.architecturalDNA?.requiredCapabilities.count ?? 0) * 0.02
        
        return relationshipComplexity + constraintComplexity + capabilityComplexity
    }
    
    private func calculateQualityScore(_ component: IntrospectedComponent) -> Double {
        guard let dna = component.architecturalDNA else {
            return 0.5 // Default score for components without DNA
        }
        
        return dna.qualityAttributes.overallScore
    }
    
    private func extractSystemConstraints(_ components: [IntrospectedComponent]) -> [ArchitecturalConstraint] {
        var systemConstraints: Set<String> = []
        var constraints: [ArchitecturalConstraint] = []
        
        for component in components {
            guard let dna = component.architecturalDNA else { continue }
            
            for constraint in dna.constraints {
                let key = "\(constraint.type.rawValue):\(constraint.description)"
                if !systemConstraints.contains(key) {
                    systemConstraints.insert(key)
                    constraints.append(constraint)
                }
            }
        }
        
        return constraints
    }
    
    private func assessChangeRisk(_ change: ProposedChange, affectedComponentCount: Int) -> RiskLevel {
        switch change.scope {
        case .local:
            return affectedComponentCount > 1 ? .low : .minimal
        case .module:
            return affectedComponentCount > 3 ? .medium : .low
        case .layer:
            return affectedComponentCount > 5 ? .high : .medium
        case .system:
            return .high
        case .external:
            return .critical
        }
    }
    
    private func assessChangeEffort(_ change: ProposedChange, affectedComponents: [ComponentID]) -> EffortLevel {
        let baseEffort: EffortLevel
        
        switch change.type {
        case .interface:
            baseEffort = .medium
        case .implementation:
            baseEffort = .low
        case .performance:
            baseEffort = .medium
        case .capability:
            baseEffort = .low
        case .relationship:
            baseEffort = .medium
        case .constraint:
            baseEffort = .high
        case .behavior:
            baseEffort = .medium
        }
        
        // Increase effort based on affected component count
        if affectedComponents.count > 10 {
            return .high
        } else if affectedComponents.count > 5 {
            return baseEffort == .low ? .medium : .high
        }
        
        return baseEffort
    }
    
    private func generateChangeSpecificRecommendations(_ change: ProposedChange) -> [String] {
        var recommendations: [String] = []
        
        switch change.type {
        case .interface:
            recommendations.append("Maintain backward compatibility where possible")
            recommendations.append("Update all dependent components")
        case .performance:
            recommendations.append("Benchmark before and after changes")
            recommendations.append("Monitor performance metrics closely")
        case .capability:
            recommendations.append("Validate capability requirements across all clients")
        default:
            recommendations.append("Run comprehensive test suite")
        }
        
        return recommendations
    }
    
    private func identifyPotentialIssues(_ change: ProposedChange, affectedComponents: [ComponentID]) -> [String] {
        var issues: [String] = []
        
        if affectedComponents.count > 5 {
            issues.append("Large number of affected components may cause cascading failures")
        }
        
        if change.scope == .system || change.scope == .external {
            issues.append("System-wide changes may introduce unexpected side effects")
        }
        
        return issues
    }
    
    // MARK: - DNA Creation Methods
    
    private func createClientProtocolDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("axiom-client-protocol"),
            purpose: ComponentPurpose(
                category: .client,
                role: "Actor-based State Management",
                domain: "Framework Core",
                responsibilities: [
                    "Manage component state through actor isolation",
                    "Provide thread-safe state access",
                    "Implement observer pattern for state changes",
                    "Validate state transitions and business logic"
                ],
                businessValue: "Ensures thread-safe state management with architectural consistency"
            ),
            architecturalLayer: .domain,
            relationships: [],
            constraints: [
                ArchitecturalConstraint(type: .actorSafety, description: "Must use actor isolation", rule: .all),
                ArchitecturalConstraint(type: .sendableCompliance, description: "All state must be Sendable", rule: .all)
            ]
        )
    }
    
    private func createPerformanceMonitorDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("performance-monitor-client"),
            purpose: ComponentPurpose(
                category: .infrastructure,
                role: "Performance Monitoring",
                domain: "System Performance",
                responsibilities: [
                    "Monitor operation performance",
                    "Collect and analyze metrics",
                    "Provide performance insights",
                    "Enable performance-based optimizations"
                ],
                businessValue: "Enables data-driven performance optimization"
            ),
            architecturalLayer: .infrastructure,
            relationships: [],
            constraints: [
                ArchitecturalConstraint(type: .actorSafety, description: "Actor-based isolation", rule: .all)
            ]
        )
    }
    
    private func createContextProtocolDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("axiom-context-protocol"),
            purpose: ComponentPurpose(
                category: .context,
                role: "Client Orchestration Layer",
                domain: "Framework Core",
                responsibilities: [
                    "Orchestrate multiple client interactions",
                    "Provide SwiftUI integration layer",
                    "Maintain 1:1 relationship with views",
                    "Coordinate cross-cutting concerns"
                ],
                businessValue: "Enables clean separation between UI and business logic"
            ),
            architecturalLayer: .application,
            relationships: [
                ComponentRelationship(
                    type: .dependsOn,
                    targetComponent: ComponentID("axiom-client-protocol"),
                    description: "Orchestrates client components"
                )
            ],
            constraints: [
                ArchitecturalConstraint(type: .viewContextRelationship, description: "1:1 View-Context relationship", rule: .exactly(count: 1))
            ]
        )
    }
    
    private func createViewProtocolDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("axiom-view-protocol"),
            purpose: ComponentPurpose(
                category: .view,
                role: "SwiftUI Integration",
                domain: "User Interface",
                responsibilities: [
                    "Present user interface components",
                    "Bind to context state reactively",
                    "Handle user interactions",
                    "Maintain 1:1 relationship with context"
                ],
                businessValue: "Provides type-safe UI integration with framework"
            ),
            architecturalLayer: .presentation,
            relationships: [
                ComponentRelationship(
                    type: .dependsOn,
                    targetComponent: ComponentID("axiom-context-protocol"),
                    description: "1:1 binding to context"
                )
            ],
            constraints: [
                ArchitecturalConstraint(type: .viewContextRelationship, description: "1:1 View-Context relationship", rule: .exactly(count: 1))
            ]
        )
    }
    
    private func createDomainModelProtocolDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("domain-model-protocol"),
            purpose: ComponentPurpose(
                category: .domainModel,
                role: "Domain Entity Definition",
                domain: "Business Logic",
                responsibilities: [
                    "Define business entity structure",
                    "Implement business validation rules",
                    "Provide value object semantics",
                    "Enable query operations"
                ],
                businessValue: "Encapsulates business logic and domain knowledge"
            ),
            architecturalLayer: .domain,
            relationships: [],
            constraints: [
                ArchitecturalConstraint(type: .sendableCompliance, description: "Must be Sendable", rule: .all),
                ArchitecturalConstraint(type: .dataIntegrity, description: "Value object semantics", rule: .all)
            ]
        )
    }
    
    private func createCapabilityManagerDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("capability-manager"),
            purpose: ComponentPurpose(
                category: .capability,
                role: "Runtime Capability Management",
                domain: "System Capabilities",
                responsibilities: [
                    "Validate capability availability",
                    "Manage capability dependencies",
                    "Enable graceful degradation",
                    "Monitor capability health"
                ],
                businessValue: "Enables adaptive system behavior based on available capabilities"
            ),
            architecturalLayer: .infrastructure,
            relationships: [],
            constraints: [
                ArchitecturalConstraint(type: .actorSafety, description: "Thread-safe capability access", rule: .all)
            ]
        )
    }
    
    private func createAnalysisSystemDNA() -> DefaultArchitecturalDNA {
        DefaultArchitecturalDNA(
            componentID: ComponentID("axiom-analyzer"),
            purpose: ComponentPurpose(
                category: .analysis,
                role: "Architecture Analysis and Validation",
                domain: "Framework Analysis",
                responsibilities: [
                    "Analyze architectural patterns",
                    "Predict potential issues",
                    "Generate optimization suggestions",
                    "Provide natural language interfaces"
                ],
                businessValue: "Enables intelligent development assistance and architectural optimization"
            ),
            architecturalLayer: .intelligence,
            relationships: [
                ComponentRelationship(
                    type: .dependsOn,
                    targetComponent: ComponentID("performance-monitor-client"),
                    description: "Uses performance data for analysis"
                )
            ],
            constraints: [
                ArchitecturalConstraint(type: .actorSafety, description: "Thread-safe analysis operations", rule: .all)
            ]
        )
    }
}

// MARK: - Supporting Types

/// Configuration for component introspection behavior
public struct IntrospectionConfiguration: Sendable {
    public let enableClientDiscovery: Bool
    public let enableContextDiscovery: Bool
    public let enableViewDiscovery: Bool
    public let enableDomainModelDiscovery: Bool
    public let enableCapabilityDiscovery: Bool
    public let enableAutomaticDocumentation: Bool
    public let enableRelationshipMapping: Bool
    public let enablePerformanceMonitoring: Bool
    
    public init(
        enableClientDiscovery: Bool = true,
        enableContextDiscovery: Bool = true,
        enableViewDiscovery: Bool = true,
        enableDomainModelDiscovery: Bool = true,
        enableCapabilityDiscovery: Bool = true,
        enableAutomaticDocumentation: Bool = true,
        enableRelationshipMapping: Bool = true,
        enablePerformanceMonitoring: Bool = true
    ) {
        self.enableClientDiscovery = enableClientDiscovery
        self.enableContextDiscovery = enableContextDiscovery
        self.enableViewDiscovery = enableViewDiscovery
        self.enableDomainModelDiscovery = enableDomainModelDiscovery
        self.enableCapabilityDiscovery = enableCapabilityDiscovery
        self.enableAutomaticDocumentation = enableAutomaticDocumentation
        self.enableRelationshipMapping = enableRelationshipMapping
        self.enablePerformanceMonitoring = enablePerformanceMonitoring
    }
}

/// Represents a discovered component in the architecture
public struct IntrospectedComponent: Sendable, Identifiable {
    public let id: ComponentID
    public let name: String
    public let category: ComponentCategory
    public let type: String
    public let architecturalDNA: ArchitecturalDNA?
    public let discoveredAt: Date
    
    public init(
        id: ComponentID,
        name: String,
        category: ComponentCategory,
        type: String,
        architecturalDNA: ArchitecturalDNA? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.architecturalDNA = architecturalDNA
        self.discoveredAt = Date()
    }
}

/// Registry for managing discovered components
private actor ComponentRegistry {
    private var components: [ComponentID: IntrospectedComponent] = [:]
    
    func register(_ component: IntrospectedComponent) {
        components[component.id] = component
    }
    
    func getComponent(_ id: ComponentID) -> IntrospectedComponent? {
        return components[id]
    }
    
    func getAllComponents() -> [IntrospectedComponent] {
        return Array(components.values)
    }
    
    func removeComponent(_ id: ComponentID) {
        components.removeValue(forKey: id)
    }
    
    func clear() {
        components.removeAll()
    }
}

/// Comprehensive analysis of a component
public struct ComponentAnalysis: Sendable {
    public let component: IntrospectedComponent
    public let relationships: [AnalyzedRelationship]
    public let constraints: [ArchitecturalConstraint]
    public let capabilities: ComponentCapabilityAnalysis
    public let complexity: Double
    public let qualityScore: Double
    public let analyzedAt: Date
    
    public init(
        component: IntrospectedComponent,
        relationships: [AnalyzedRelationship],
        constraints: [ArchitecturalConstraint],
        capabilities: ComponentCapabilityAnalysis,
        complexity: Double,
        qualityScore: Double,
        analyzedAt: Date
    ) {
        self.component = component
        self.relationships = relationships
        self.constraints = constraints
        self.capabilities = capabilities
        self.complexity = complexity
        self.qualityScore = qualityScore
        self.analyzedAt = analyzedAt
    }
}

/// Analysis of component capabilities
public struct ComponentCapabilityAnalysis: Sendable {
    public let required: Set<Capability>
    public let provided: Set<Capability>
    
    public var capabilityBalance: Double {
        let total = required.count + provided.count
        guard total > 0 else { return 1.0 }
        return Double(provided.count) / Double(total)
    }
    
    public init(required: Set<Capability>, provided: Set<Capability>) {
        self.required = required
        self.provided = provided
    }
}

/// Analyzed relationship between components
public struct AnalyzedRelationship: Sendable {
    public let source: ComponentID
    public let target: ComponentID
    public let type: RelationshipType
    public let strength: Double
    public let isRequired: Bool
    public let communicationPattern: CommunicationPattern
    public let description: String?
    
    public init(
        source: ComponentID,
        target: ComponentID,
        type: RelationshipType,
        strength: Double,
        isRequired: Bool,
        communicationPattern: CommunicationPattern,
        description: String? = nil
    ) {
        self.source = source
        self.target = target
        self.type = type
        self.strength = strength
        self.isRequired = isRequired
        self.communicationPattern = communicationPattern
        self.description = description
    }
}

/// Map of all component relationships in the system
public struct ComponentRelationshipMap: Sendable {
    private var relationships: [AnalyzedRelationship] = []
    private var componentIndex: [ComponentID: [AnalyzedRelationship]] = [:]
    
    public var totalRelationships: Int {
        relationships.count
    }
    
    public mutating func addRelationship(_ relationship: AnalyzedRelationship) {
        relationships.append(relationship)
        
        // Update index
        componentIndex[relationship.source, default: []].append(relationship)
    }
    
    public func getRelationshipsFor(_ componentID: ComponentID) -> [AnalyzedRelationship] {
        return componentIndex[componentID] ?? []
    }
    
    public func getRelationshipInfoFor(_ componentID: ComponentID) -> [RelationshipInfo] {
        let outgoing = relationships.filter { $0.source == componentID }.map { rel in
            RelationshipInfo(
                sourceId: rel.source,
                targetId: rel.target,
                type: rel.type,
                direction: .outgoing
            )
        }
        
        let incoming = relationships.filter { $0.target == componentID }.map { rel in
            RelationshipInfo(
                sourceId: rel.source,
                targetId: rel.target,
                type: rel.type,
                direction: .incoming
            )
        }
        
        return outgoing + incoming
    }
    
    public func getRelationshipCount(for componentID: ComponentID) -> Int {
        return getRelationshipsFor(componentID).count
    }
    
    public func getComponentsDependingOn(_ componentID: ComponentID) -> [ComponentID] {
        return relationships.filter { $0.target == componentID }.map { $0.source }
    }
    
    public func getAllRelationships() -> [AnalyzedRelationship] {
        return relationships
    }
    
    public func getDependenciesOf(_ componentID: ComponentID) -> [ComponentID] {
        return relationships.filter { $0.source == componentID }.map { $0.target }
    }
    
    public func getMostConnectedComponents(limit: Int = 10) -> [(componentId: ComponentID, connectionCount: Int)] {
        var connectionCounts: [ComponentID: Int] = [:]
        
        for relationship in relationships {
            connectionCounts[relationship.source, default: 0] += 1
            connectionCounts[relationship.target, default: 0] += 1
        }
        
        return connectionCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (componentId: $0.key, connectionCount: $0.value) }
    }
    
    public func findCircularDependencies() -> [[ComponentID]] {
        var cycles: [[ComponentID]] = []
        var visited: Set<ComponentID> = []
        var recursionStack: Set<ComponentID> = []
        
        func dfs(_ node: ComponentID, path: [ComponentID]) {
            visited.insert(node)
            recursionStack.insert(node)
            
            let dependencies = getDependenciesOf(node)
            for dependency in dependencies {
                if recursionStack.contains(dependency) {
                    // Found a cycle
                    if let startIndex = path.firstIndex(of: dependency) {
                        let cycle = Array(path[startIndex...] + [dependency])
                        cycles.append(cycle)
                    }
                } else if !visited.contains(dependency) {
                    dfs(dependency, path: path + [dependency])
                }
            }
            
            recursionStack.remove(node)
        }
        
        // Get all unique component IDs
        let allComponents = Set(relationships.flatMap { [$0.source, $0.target] })
        
        for component in allComponents {
            if !visited.contains(component) {
                dfs(component, path: [component])
            }
        }
        
        return cycles
    }
}

/// Cached analysis result with timestamp
private struct CachedAnalysis {
    let analysis: ComponentAnalysis
    let timestamp: Date
    
    func isExpired(timeout: TimeInterval) -> Bool {
        return Date().timeIntervalSince(timestamp) > timeout
    }
}

/// Set of architectural documentation for all components
public struct ArchitecturalDocumentationSet: Sendable {
    private var componentDocumentation: [ComponentID: ComponentDocumentation] = [:]
    private var systemDocumentation: SystemDocumentation?
    
    public mutating func addComponentDocumentation(_ documentation: ComponentDocumentation) {
        componentDocumentation[documentation.componentID] = documentation
    }
    
    public mutating func setSystemDocumentation(_ documentation: SystemDocumentation) {
        systemDocumentation = documentation
    }
    
    public func getComponentDocumentation(_ componentID: ComponentID) -> ComponentDocumentation? {
        return componentDocumentation[componentID]
    }
    
    public func getAllComponentDocumentation() -> [ComponentDocumentation] {
        return Array(componentDocumentation.values)
    }
    
    public func getSystemDocumentation() -> SystemDocumentation? {
        return systemDocumentation
    }
}

/// Documentation for a single component
public struct ComponentDocumentation: Sendable {
    public let componentID: ComponentID
    public let name: String
    public let overview: String
    public let purpose: ComponentPurpose?
    public let architecture: ArchitectureDocumentation?
    public let interfaces: [InterfaceDocumentation]?
    public let implementation: ImplementationDocumentation?
    public let examples: [UsageExample]?
    public let relatedComponents: [ComponentReference]?
    public let generatedAt: Date
    
    public init(
        componentID: ComponentID,
        name: String,
        overview: String,
        purpose: ComponentPurpose? = nil,
        architecture: ArchitectureDocumentation? = nil,
        interfaces: [InterfaceDocumentation]? = nil,
        implementation: ImplementationDocumentation? = nil,
        examples: [UsageExample]? = nil,
        relatedComponents: [ComponentReference]? = nil,
        generatedAt: Date
    ) {
        self.componentID = componentID
        self.name = name
        self.overview = overview
        self.purpose = purpose
        self.architecture = architecture
        self.interfaces = interfaces
        self.implementation = implementation
        self.examples = examples
        self.relatedComponents = relatedComponents
        self.generatedAt = generatedAt
    }
}

/// System-level documentation
public struct SystemDocumentation: Sendable {
    public let overview: String
    public let architecture: SystemArchitectureDocumentation
    public let constraints: [ArchitecturalConstraint]
    public let totalComponents: Int
    public let generatedAt: Date
    
    public init(
        overview: String,
        architecture: SystemArchitectureDocumentation,
        constraints: [ArchitecturalConstraint],
        totalComponents: Int,
        generatedAt: Date
    ) {
        self.overview = overview
        self.architecture = architecture
        self.constraints = constraints
        self.totalComponents = totalComponents
        self.generatedAt = generatedAt
    }
}

/// System-level architecture documentation
public struct SystemArchitectureDocumentation: Sendable {
    public let patterns: [String]
    public let principles: [String]
    public let layerDescription: String
    
    public init(
        patterns: [String] = ["Actor-based Concurrency", "1:1 Relationships", "Unidirectional Flow"],
        principles: [String] = ["Single Responsibility", "Separation of Concerns", "Type Safety"],
        layerDescription: String = "Multi-layer architecture with presentation, application, domain, infrastructure, cross-cutting, and intelligence layers"
    ) {
        self.patterns = patterns
        self.principles = principles
        self.layerDescription = layerDescription
    }
}

/// System integrity validation report
public struct SystemIntegrityReport: Sendable {
    public let isValid: Bool
    public let overallScore: Double
    public let violations: [SystemIntegrityViolation]
    public let warnings: [SystemIntegrityWarning]
    public let componentCount: Int
    public let layerViolations: [LayerViolation]
    public let validatedAt: Date
    
    public init(
        isValid: Bool,
        overallScore: Double,
        violations: [SystemIntegrityViolation],
        warnings: [SystemIntegrityWarning],
        componentCount: Int,
        layerViolations: [LayerViolation] = [],
        validatedAt: Date
    ) {
        self.isValid = isValid
        self.overallScore = overallScore
        self.violations = violations
        self.warnings = warnings
        self.componentCount = componentCount
        self.layerViolations = layerViolations
        self.validatedAt = validatedAt
    }
}

/// Layer violation
public struct LayerViolation: Sendable {
    public let sourceComponent: ComponentID
    public let targetComponent: ComponentID
    public let sourceLayer: ArchitecturalLayer
    public let targetLayer: ArchitecturalLayer
    public let description: String
    
    public init(
        sourceComponent: ComponentID,
        targetComponent: ComponentID,
        sourceLayer: ArchitecturalLayer,
        targetLayer: ArchitecturalLayer,
        description: String
    ) {
        self.sourceComponent = sourceComponent
        self.targetComponent = targetComponent
        self.sourceLayer = sourceLayer
        self.targetLayer = targetLayer
        self.description = description
    }
}

/// System-level integrity violation
public struct SystemIntegrityViolation: Sendable {
    public let component: ComponentID
    public let violation: ConstraintViolation
    public let severity: ViolationSeverity
    
    public init(component: ComponentID, violation: ConstraintViolation, severity: ViolationSeverity) {
        self.component = component
        self.violation = violation
        self.severity = severity
    }
}

/// System-level integrity warning
public struct SystemIntegrityWarning: Sendable {
    public let component: ComponentID
    public let warning: ArchitecturalWarning
    
    public init(component: ComponentID, warning: ArchitecturalWarning) {
        self.component = component
        self.warning = warning
    }
}

/// Proposed change for impact analysis
public struct ProposedChange: Sendable {
    public let targetComponent: ComponentID
    public let type: ChangeType
    public let scope: ChangeScope
    public let description: String
    public let rationale: String
    
    public init(
        targetComponent: ComponentID,
        type: ChangeType,
        scope: ChangeScope,
        description: String,
        rationale: String
    ) {
        self.targetComponent = targetComponent
        self.type = type
        self.scope = scope
        self.description = description
        self.rationale = rationale
    }
}

/// Impact of a proposed change
public struct ChangeImpact: Sendable {
    public let change: ProposedChange
    public let affectedComponents: [ComponentID]
    public let riskLevel: RiskLevel
    public let estimatedEffort: EffortLevel
    public let recommendations: [String]
    public let potentialIssues: [String]
    
    public init(
        change: ProposedChange,
        affectedComponents: [ComponentID],
        riskLevel: RiskLevel,
        estimatedEffort: EffortLevel,
        recommendations: [String],
        potentialIssues: [String]
    ) {
        self.change = change
        self.affectedComponents = affectedComponents
        self.riskLevel = riskLevel
        self.estimatedEffort = estimatedEffort
        self.recommendations = recommendations
        self.potentialIssues = potentialIssues
    }
}

/// System-wide impact analysis
public struct SystemImpactAnalysis: Sendable {
    public let changes: [ProposedChange]
    public let impacts: [ChangeImpact]
    public let overallRisk: RiskLevel
    public let estimatedEffort: EffortLevel
    public let recommendations: [String]
    public let analyzedAt: Date
    
    public init(
        changes: [ProposedChange],
        impacts: [ChangeImpact],
        overallRisk: RiskLevel,
        estimatedEffort: EffortLevel,
        recommendations: [String],
        analyzedAt: Date
    ) {
        self.changes = changes
        self.impacts = impacts
        self.overallRisk = overallRisk
        self.estimatedEffort = estimatedEffort
        self.recommendations = recommendations
        self.analyzedAt = analyzedAt
    }
}

/// Component metrics and statistics
public struct ComponentMetricsReport: Sendable {
    public let totalComponents: Int
    public let totalRelationships: Int
    public let averageRelationshipsPerComponent: Double
    public let categoryDistribution: [ComponentCategory: Int]
    public let layerDistribution: [ArchitecturalLayer: Int]
    public let highlyCoupledComponents: [ComponentID]
    public let complexityMetrics: ComplexityMetrics
    public let componentComplexity: [ComponentID: Double]
    public let testCoverageMetrics: TestCoverageMetrics?
    public let documentationMetrics: DocumentationMetrics?
    public let generatedAt: Date
    
    public init(
        totalComponents: Int,
        totalRelationships: Int,
        averageRelationshipsPerComponent: Double,
        categoryDistribution: [ComponentCategory: Int],
        layerDistribution: [ArchitecturalLayer: Int],
        highlyCoupledComponents: [ComponentID],
        complexityMetrics: ComplexityMetrics,
        componentComplexity: [ComponentID: Double] = [:],
        testCoverageMetrics: TestCoverageMetrics? = nil,
        documentationMetrics: DocumentationMetrics? = nil,
        generatedAt: Date
    ) {
        self.totalComponents = totalComponents
        self.totalRelationships = totalRelationships
        self.averageRelationshipsPerComponent = averageRelationshipsPerComponent
        self.categoryDistribution = categoryDistribution
        self.layerDistribution = layerDistribution
        self.highlyCoupledComponents = highlyCoupledComponents
        self.complexityMetrics = complexityMetrics
        self.componentComplexity = componentComplexity
        self.testCoverageMetrics = testCoverageMetrics
        self.documentationMetrics = documentationMetrics
        self.generatedAt = generatedAt
    }
}

/// Test coverage metrics
public struct TestCoverageMetrics: Sendable {
    public let averageCoverage: Double
    public let componentCoverage: [ComponentID: Double]
    
    public init(averageCoverage: Double, componentCoverage: [ComponentID: Double]) {
        self.averageCoverage = averageCoverage
        self.componentCoverage = componentCoverage
    }
}

/// Documentation metrics
public struct DocumentationMetrics: Sendable {
    public let undocumentedComponents: [ComponentID]
    public let architecturalDocumentation: Bool
    
    public init(undocumentedComponents: [ComponentID], architecturalDocumentation: Bool) {
        self.undocumentedComponents = undocumentedComponents
        self.architecturalDocumentation = architecturalDocumentation
    }
}

/// System complexity metrics
public struct ComplexityMetrics: Sendable {
    public let averageComponentComplexity: Double
    public let systemCouplingIndex: Double
    public let maxComponentComplexity: Double
    
    public init(
        averageComponentComplexity: Double,
        systemCouplingIndex: Double,
        maxComponentComplexity: Double
    ) {
        self.averageComponentComplexity = averageComponentComplexity
        self.systemCouplingIndex = systemCouplingIndex
        self.maxComponentComplexity = maxComponentComplexity
    }
}

/// Errors that can occur during introspection
public enum IntrospectionError: Error, CustomStringConvertible {
    case componentNotFound(ComponentID)
    case analysisFailure(ComponentID, Error)
    case relationshipMappingFailure(Error)
    case documentationGenerationFailure(Error)
    
    public var description: String {
        switch self {
        case .componentNotFound(let id):
            return "Component not found: \(id)"
        case .analysisFailure(let id, let error):
            return "Analysis failed for component \(id): \(error)"
        case .relationshipMappingFailure(let error):
            return "Relationship mapping failed: \(error)"
        case .documentationGenerationFailure(let error):
            return "Documentation generation failed: \(error)"
        }
    }
}

// MARK: - Global Introspection

/// Global shared component introspection engine
public actor GlobalIntrospectionEngine {
    public static let shared = GlobalIntrospectionEngine()
    
    private var engine: ComponentIntrospectionEngine?
    
    private init() {
        // Engine will be lazily initialized when first accessed
    }
    
    public func getEngine() async -> ComponentIntrospectionEngine {
        if let engine = engine {
            return engine
        }
        
        let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
        let newEngine = ComponentIntrospectionEngine(
            performanceMonitor: performanceMonitor
        )
        self.engine = newEngine
        return newEngine
    }
}