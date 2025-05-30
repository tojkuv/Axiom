import Foundation

// MARK: - Pattern Detection Protocol

/// Protocol for detecting and analyzing architectural patterns
/// This is one of the 8 breakthrough intelligence systems in Axiom
public protocol PatternDetecting: Actor {
    /// Detects all patterns in the current architecture
    func detectPatterns() async -> [DetectedPattern]
    
    /// Analyzes a specific pattern in the architecture
    func analyzePattern(_ patternType: PatternType) async -> PatternAnalysis
    
    /// Validates that components follow expected patterns
    func validatePatternCompliance() async -> PatternComplianceReport
    
    /// Suggests patterns for new components or improvements
    func suggestPatterns(for context: PatternSuggestionContext) async -> [PatternSuggestion]
    
    /// Codifies discovered patterns for reuse
    func codifyPattern(_ pattern: DetectedPattern) async -> CodifiedPattern
    
    /// Detects anti-patterns and issues
    func detectAntiPatterns() async -> [AntiPatternDetection]
    
    /// Gets pattern usage statistics
    func getPatternStatistics() async -> PatternStatistics
}

// MARK: - Pattern Detection Engine

/// Actor-based pattern detection engine with learning capabilities
public actor PatternDetectionEngine: PatternDetecting {
    // MARK: Properties
    
    /// Component introspection engine for analyzing architecture
    private let introspectionEngine: ComponentIntrospectionEngine
    
    /// Performance monitor for pattern detection operations
    private let performanceMonitor: PerformanceMonitor
    
    /// Cache for detected patterns
    private var patternCache: [PatternType: [DetectedPattern]] = [:]
    
    /// Cache for pattern analyses
    private var analysisCache: [PatternType: CachedPatternAnalysis] = [:]
    
    /// Codified patterns repository
    private var codifiedPatterns: [PatternType: CodifiedPattern] = [:]
    
    /// Pattern detection configuration
    private let configuration: PatternDetectionConfiguration
    
    /// Cache TTL (in seconds)
    private let cacheTimeout: TimeInterval
    
    // MARK: Initialization
    
    public init(
        introspectionEngine: ComponentIntrospectionEngine,
        performanceMonitor: PerformanceMonitor,
        configuration: PatternDetectionConfiguration = PatternDetectionConfiguration(),
        cacheTimeout: TimeInterval = 300.0
    ) {
        self.introspectionEngine = introspectionEngine
        self.performanceMonitor = performanceMonitor
        self.configuration = configuration
        self.cacheTimeout = cacheTimeout
        
        // Initialize with built-in Axiom patterns
        Task {
            await initializeAxiomPatterns()
        }
    }
    
    // MARK: Pattern Detection
    
    public func detectPatterns() async -> [DetectedPattern] {
        let token = await performanceMonitor.startOperation("detect_patterns", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var allPatterns: [DetectedPattern] = []
        
        // Detect patterns by type
        for patternType in PatternType.allCases {
            if configuration.enabledPatterns.contains(patternType) {
                let patterns = await detectPatternsOfType(patternType)
                allPatterns.append(contentsOf: patterns)
                patternCache[patternType] = patterns
            }
        }
        
        return allPatterns
    }
    
    public func analyzePattern(_ patternType: PatternType) async -> PatternAnalysis {
        let token = await performanceMonitor.startOperation("analyze_pattern", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Check cache first
        if let cachedAnalysis = analysisCache[patternType],
           !cachedAnalysis.isExpired(timeout: cacheTimeout) {
            return cachedAnalysis.analysis
        }
        
        // Detect patterns of the specified type
        let patterns = await detectPatternsOfType(patternType)
        
        // Analyze the patterns
        let analysis = await performPatternAnalysis(patternType, patterns: patterns)
        
        // Cache the result
        analysisCache[patternType] = CachedPatternAnalysis(
            analysis: analysis,
            timestamp: Date()
        )
        
        return analysis
    }
    
    // MARK: Pattern Validation
    
    public func validatePatternCompliance() async -> PatternComplianceReport {
        let token = await performanceMonitor.startOperation("validate_patterns", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var violations: [PatternViolation] = []
        var complianceScores: [PatternType: Double] = [:]
        var totalScore = 1.0
        
        // Validate each enabled pattern type
        for patternType in configuration.enabledPatterns {
            let compliance = await validatePatternType(patternType)
            violations.append(contentsOf: compliance.violations)
            complianceScores[patternType] = compliance.score
            totalScore = min(totalScore, compliance.score)
        }
        
        return PatternComplianceReport(
            overallScore: totalScore,
            patternScores: complianceScores,
            violations: violations,
            validatedAt: Date()
        )
    }
    
    // MARK: Pattern Suggestions
    
    public func suggestPatterns(for context: PatternSuggestionContext) async -> [PatternSuggestion] {
        let token = await performanceMonitor.startOperation("suggest_patterns", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var suggestions: [PatternSuggestion] = []
        
        // Analyze the context to determine suitable patterns
        switch context.category {
        case .client:
            suggestions.append(contentsOf: await suggestClientPatterns(context))
        case .context:
            suggestions.append(contentsOf: await suggestContextPatterns(context))
        case .view:
            suggestions.append(contentsOf: await suggestViewPatterns(context))
        case .domainModel:
            suggestions.append(contentsOf: await suggestDomainModelPatterns(context))
        case .capability:
            suggestions.append(contentsOf: await suggestCapabilityPatterns(context))
        default:
            suggestions.append(contentsOf: await suggestGenericPatterns(context))
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: Pattern Codification
    
    public func codifyPattern(_ pattern: DetectedPattern) async -> CodifiedPattern {
        let token = await performanceMonitor.startOperation("codify_pattern", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        let codifiedPattern = CodifiedPattern(
            type: pattern.type,
            name: pattern.name,
            description: generatePatternDescription(pattern),
            structure: extractPatternStructure(pattern),
            constraints: extractPatternConstraints(pattern),
            benefits: identifyPatternBenefits(pattern),
            tradeoffs: identifyPatternTradeoffs(pattern),
            examples: generatePatternExamples(pattern),
            applicabilityRules: generateApplicabilityRules(pattern),
            codifiedAt: Date()
        )
        
        // Store in repository
        codifiedPatterns[pattern.type] = codifiedPattern
        
        return codifiedPattern
    }
    
    // MARK: Anti-Pattern Detection
    
    public func detectAntiPatterns() async -> [AntiPatternDetection] {
        let token = await performanceMonitor.startOperation("detect_antipatterns", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var antiPatterns: [AntiPatternDetection] = []
        
        // Get all components for analysis
        let components = await introspectionEngine.discoverComponents()
        let relationshipMap = await introspectionEngine.mapComponentRelationships()
        
        // Detect various anti-patterns
        antiPatterns.append(contentsOf: await detectGodObjectAntiPattern(components))
        antiPatterns.append(contentsOf: await detectTightCouplingAntiPattern(components, relationshipMap))
        antiPatterns.append(contentsOf: await detectCircularDependencyAntiPattern(relationshipMap))
        antiPatterns.append(contentsOf: await detectSingletonAbuseAntiPattern(components))
        antiPatterns.append(contentsOf: await detectBigBallOfMudAntiPattern(components, relationshipMap))
        antiPatterns.append(contentsOf: await detectPerformanceAntiPatterns(components))
        
        return antiPatterns
    }
    
    // MARK: Pattern Statistics
    
    public func getPatternStatistics() async -> PatternStatistics {
        let token = await performanceMonitor.startOperation("pattern_statistics", category: .patternDetection)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Detect all patterns for statistics
        let allPatterns = await detectPatterns()
        
        // Calculate pattern distribution
        var patternDistribution: [PatternType: Int] = [:]
        for pattern in allPatterns {
            patternDistribution[pattern.type, default: 0] += 1
        }
        
        // Calculate compliance scores
        let complianceReport = await validatePatternCompliance()
        
        // Calculate pattern complexity
        let complexityScores = await calculatePatternComplexity(allPatterns)
        
        return PatternStatistics(
            totalPatternsDetected: allPatterns.count,
            patternDistribution: patternDistribution,
            averageCompliance: complianceReport.overallScore,
            complianceByPattern: complianceReport.patternScores,
            complexityScores: complexityScores,
            antiPatternCount: (await detectAntiPatterns()).count,
            generatedAt: Date()
        )
    }
    
    // MARK: Private Pattern Detection Methods
    
    private func initializeAxiomPatterns() async {
        // Initialize built-in Axiom patterns
        await initializeActorPattern()
        await initializeViewContextPattern()
        await initializeClientOwnershipPattern()
        await initializeCapabilityPattern()
        await initializeStateManagementPattern()
        await initializeErrorHandlingPattern()
    }
    
    private func detectPatternsOfType(_ patternType: PatternType) async -> [DetectedPattern] {
        switch patternType {
        case .actorConcurrency:
            return await detectActorConcurrencyPatterns()
        case .viewContextBinding:
            return await detectViewContextBindingPatterns()
        case .clientOwnership:
            return await detectClientOwnershipPatterns()
        case .capabilityValidation:
            return await detectCapabilityValidationPatterns()
        case .stateManagement:
            return await detectStateManagementPatterns()
        case .errorHandling:
            return await detectErrorHandlingPatterns()
        case .performanceOptimization:
            return await detectPerformanceOptimizationPatterns()
        case .unidirectionalFlow:
            return await detectUnidirectionalFlowPatterns()
        case .domainModelPattern:
            return await detectDomainModelPatterns()
        case .crossCuttingConcerns:
            return await detectCrossCuttingConcernPatterns()
        }
    }
    
    private func detectActorConcurrencyPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        // Detect components using actor-based concurrency
        let actorComponents = components.filter { component in
            component.type.contains("actor") || 
            component.name.contains("Actor") ||
            (component.architecturalDNA?.constraints.contains { $0.type == .actorSafety } ?? false)
        }
        
        for component in actorComponents {
            patterns.append(DetectedPattern(
                type: .actorConcurrency,
                name: "Actor Concurrency in \(component.name)",
                description: "Component uses actor-based concurrency for thread safety",
                components: [component.id],
                confidence: 0.9,
                evidence: ["Actor-based implementation", "Thread-safe design"],
                location: PatternLocation(componentID: component.id),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    private func detectViewContextBindingPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        let relationshipMap = await introspectionEngine.mapComponentRelationships()
        var patterns: [DetectedPattern] = []
        
        let views = components.filter { $0.category == .view }
        let contexts = components.filter { $0.category == .context }
        
        // Detect 1:1 View-Context relationships
        for view in views {
            let viewRelationships = relationshipMap.getRelationshipsFor(view.id)
            let contextRelationships = viewRelationships.filter { relationship in
                contexts.contains { $0.id == relationship.target }
            }
            
            if contextRelationships.count == 1 {
                let contextID = contextRelationships[0].target
                patterns.append(DetectedPattern(
                    type: .viewContextBinding,
                    name: "1:1 View-Context Binding",
                    description: "Perfect 1:1 relationship between \(view.name) and context",
                    components: [view.id, contextID],
                    confidence: 0.95,
                    evidence: ["Exactly one context relationship", "Proper separation of concerns"],
                    location: PatternLocation(componentID: view.id, relatedComponents: [contextID]),
                    detectedAt: Date()
                ))
            }
        }
        
        return patterns
    }
    
    private func detectClientOwnershipPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        let clients = components.filter { $0.category == .client }
        let _ = components.filter { $0.category == .domainModel }
        
        // Analyze client-domain model relationships
        for client in clients {
            // In a real implementation, this would analyze ownership relationships
            patterns.append(DetectedPattern(
                type: .clientOwnership,
                name: "Client Domain Ownership in \(client.name)",
                description: "Client maintains single ownership of domain models",
                components: [client.id],
                confidence: 0.8,
                evidence: ["Single ownership principle", "Clear responsibility boundaries"],
                location: PatternLocation(componentID: client.id),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    private func detectCapabilityValidationPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        // Detect components with capability validation
        for component in components {
            if let dna = component.architecturalDNA,
               !dna.requiredCapabilities.isEmpty {
                patterns.append(DetectedPattern(
                    type: .capabilityValidation,
                    name: "Capability Validation in \(component.name)",
                    description: "Component properly validates required capabilities",
                    components: [component.id],
                    confidence: 0.85,
                    evidence: ["Capability requirements declared", "Validation implemented"],
                    location: PatternLocation(componentID: component.id),
                    detectedAt: Date()
                ))
            }
        }
        
        return patterns
    }
    
    private func detectStateManagementPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        // Detect state management patterns
        let stateManagers = components.filter { component in
            component.architecturalDNA?.requiredCapabilities.contains(.stateManagement) ?? false ||
            component.name.lowercased().contains("state") ||
            component.category == .client
        }
        
        for component in stateManagers {
            patterns.append(DetectedPattern(
                type: .stateManagement,
                name: "State Management in \(component.name)",
                description: "Component implements proper state management patterns",
                components: [component.id],
                confidence: 0.8,
                evidence: ["State management capability", "Proper encapsulation"],
                location: PatternLocation(componentID: component.id),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    private func detectErrorHandlingPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        // Detect error handling patterns (simplified)
        for component in components {
            if component.name.contains("Error") || 
               component.type.contains("throws") ||
               (component.architecturalDNA?.constraints.contains { $0.description.contains("error") } ?? false) {
                patterns.append(DetectedPattern(
                    type: .errorHandling,
                    name: "Error Handling in \(component.name)",
                    description: "Component implements proper error handling patterns",
                    components: [component.id],
                    confidence: 0.7,
                    evidence: ["Error handling implementation", "Proper error propagation"],
                    location: PatternLocation(componentID: component.id),
                    detectedAt: Date()
                ))
            }
        }
        
        return patterns
    }
    
    private func detectPerformanceOptimizationPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        // Detect performance optimization patterns
        for component in components {
            if let dna = component.architecturalDNA {
                let hasPerformanceProfile = dna.performanceProfile.latency.typical < 0.050 // 50ms
                if hasPerformanceProfile {
                    patterns.append(DetectedPattern(
                        type: .performanceOptimization,
                        name: "Performance Optimization in \(component.name)",
                        description: "Component implements performance optimization patterns",
                        components: [component.id],
                        confidence: 0.75,
                        evidence: ["Optimized performance profile", "Efficient implementation"],
                        location: PatternLocation(componentID: component.id),
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        return patterns
    }
    
    private func detectUnidirectionalFlowPatterns() async -> [DetectedPattern] {
        let relationshipMap = await introspectionEngine.mapComponentRelationships()
        var patterns: [DetectedPattern] = []
        
        // Analyze data flow patterns (simplified implementation)
        let allRelationships = relationshipMap.getAllRelationships()
        let flowPatterns = allRelationships.filter { $0.type == .dependsOn || $0.type == .provides }
        
        if !flowPatterns.isEmpty {
            patterns.append(DetectedPattern(
                type: .unidirectionalFlow,
                name: "Unidirectional Data Flow",
                description: "System maintains unidirectional data flow pattern",
                components: flowPatterns.flatMap { [$0.source, $0.target] },
                confidence: 0.8,
                evidence: ["Dependency relationships", "Clear data flow direction"],
                location: PatternLocation(componentID: flowPatterns[0].source),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    private func detectDomainModelPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        let domainModels = components.filter { $0.category == .domainModel }
        
        for model in domainModels {
            patterns.append(DetectedPattern(
                type: .domainModelPattern,
                name: "Domain Model Pattern in \(model.name)",
                description: "Component follows domain model pattern with proper encapsulation",
                components: [model.id],
                confidence: 0.9,
                evidence: ["Domain model structure", "Business logic encapsulation"],
                location: PatternLocation(componentID: model.id),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    private func detectCrossCuttingConcernPatterns() async -> [DetectedPattern] {
        let components = await introspectionEngine.discoverComponents()
        var patterns: [DetectedPattern] = []
        
        let crossCuttingComponents = components.filter { 
            $0.architecturalDNA?.architecturalLayer == .crossCutting 
        }
        
        for component in crossCuttingComponents {
            patterns.append(DetectedPattern(
                type: .crossCuttingConcerns,
                name: "Cross-Cutting Concern in \(component.name)",
                description: "Component implements cross-cutting concern pattern",
                components: [component.id],
                confidence: 0.85,
                evidence: ["Cross-cutting layer placement", "Aspect-oriented design"],
                location: PatternLocation(componentID: component.id),
                detectedAt: Date()
            ))
        }
        
        return patterns
    }
    
    // MARK: Pattern Analysis
    
    private func performPatternAnalysis(_ patternType: PatternType, patterns: [DetectedPattern]) async -> PatternAnalysis {
        let usage = calculatePatternUsage(patterns)
        let compliance = await calculatePatternCompliance(patternType, patterns: patterns)
        let effectiveness = calculatePatternEffectiveness(patterns)
        let recommendations = generatePatternRecommendations(patternType, patterns: patterns)
        
        return PatternAnalysis(
            patternType: patternType,
            totalInstances: patterns.count,
            averageConfidence: patterns.isEmpty ? 0 : patterns.map { $0.confidence }.reduce(0, +) / Double(patterns.count),
            usage: usage,
            compliance: compliance,
            effectiveness: effectiveness,
            recommendations: recommendations,
            analyzedAt: Date()
        )
    }
    
    private func calculatePatternUsage(_ patterns: [DetectedPattern]) -> PatternUsage {
        let highConfidencePatterns = patterns.filter { $0.confidence >= 0.8 }
        let mediumConfidencePatterns = patterns.filter { $0.confidence >= 0.5 && $0.confidence < 0.8 }
        let lowConfidencePatterns = patterns.filter { $0.confidence < 0.5 }
        
        return PatternUsage(
            total: patterns.count,
            highConfidence: highConfidencePatterns.count,
            mediumConfidence: mediumConfidencePatterns.count,
            lowConfidence: lowConfidencePatterns.count
        )
    }
    
    private func calculatePatternCompliance(_ patternType: PatternType, patterns: [DetectedPattern]) async -> Double {
        guard !patterns.isEmpty else { return 0.0 }
        
        // Calculate compliance based on pattern-specific rules
        let complianceScores = patterns.map { pattern in
            // Simple compliance calculation based on confidence
            return pattern.confidence
        }
        
        return complianceScores.reduce(0, +) / Double(complianceScores.count)
    }
    
    private func calculatePatternEffectiveness(_ patterns: [DetectedPattern]) -> PatternEffectiveness {
        let averageConfidence = patterns.isEmpty ? 0 : patterns.map { $0.confidence }.reduce(0, +) / Double(patterns.count)
        let consistencyScore = calculateConsistencyScore(patterns)
        let impactScore = calculateImpactScore(patterns)
        
        return PatternEffectiveness(
            overallScore: (averageConfidence + consistencyScore + impactScore) / 3.0,
            consistencyScore: consistencyScore,
            impactScore: impactScore,
            averageConfidence: averageConfidence
        )
    }
    
    private func calculateConsistencyScore(_ patterns: [DetectedPattern]) -> Double {
        guard patterns.count > 1 else { return 1.0 }
        
        // Calculate variance in confidence scores
        let confidences = patterns.map { $0.confidence }
        let average = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.map { pow($0 - average, 2) }.reduce(0, +) / Double(confidences.count)
        
        // Lower variance = higher consistency
        return max(0.0, 1.0 - variance)
    }
    
    private func calculateImpactScore(_ patterns: [DetectedPattern]) -> Double {
        // Simple impact calculation based on number of components affected
        let totalComponents = patterns.flatMap { $0.components }.count
        let uniqueComponents = Set(patterns.flatMap { $0.components }).count
        
        guard uniqueComponents > 0 else { return 0.0 }
        
        // Higher ratio of total to unique components indicates more widespread impact
        return min(1.0, Double(totalComponents) / Double(uniqueComponents * 10))
    }
    
    private func generatePatternRecommendations(_ patternType: PatternType, patterns: [DetectedPattern]) -> [String] {
        var recommendations: [String] = []
        
        if patterns.isEmpty {
            recommendations.append("Consider implementing \(patternType.rawValue) pattern for better architecture")
        } else {
            let averageConfidence = patterns.map { $0.confidence }.reduce(0, +) / Double(patterns.count)
            
            if averageConfidence < 0.7 {
                recommendations.append("Improve \(patternType.rawValue) pattern implementation quality")
            }
            
            if patterns.count < 3 {
                recommendations.append("Consider applying \(patternType.rawValue) pattern to more components")
            }
        }
        
        return recommendations
    }
    
    // MARK: Pattern Validation
    
    private func validatePatternType(_ patternType: PatternType) async -> PatternTypeCompliance {
        let patterns = await detectPatternsOfType(patternType)
        var violations: [PatternViolation] = []
        var score = 1.0
        
        // Validate pattern-specific rules
        switch patternType {
        case .viewContextBinding:
            violations.append(contentsOf: await validateViewContextBinding())
        case .clientOwnership:
            violations.append(contentsOf: await validateClientOwnership())
        case .actorConcurrency:
            violations.append(contentsOf: await validateActorConcurrency())
        default:
            // Generic validation
            break
        }
        
        // Calculate score based on violations
        score = max(0.0, 1.0 - (Double(violations.count) * 0.1))
        
        return PatternTypeCompliance(
            patternType: patternType,
            score: score,
            violations: violations,
            patternsDetected: patterns.count
        )
    }
    
    private func validateViewContextBinding() async -> [PatternViolation] {
        var violations: [PatternViolation] = []
        
        let components = await introspectionEngine.discoverComponents()
        let views = components.filter { $0.category == .view }
        let contexts = components.filter { $0.category == .context }
        
        // Check for 1:1 relationship violation
        if views.count != contexts.count {
            violations.append(PatternViolation(
                patternType: .viewContextBinding,
                componentID: ComponentID("SYSTEM"),
                description: "View count (\(views.count)) does not match Context count (\(contexts.count))",
                severity: .error,
                suggestedFix: "Ensure each View has exactly one corresponding Context"
            ))
        }
        
        return violations
    }
    
    private func validateClientOwnership() async -> [PatternViolation] {
        let violations: [PatternViolation] = []
        
        // In a real implementation, this would validate single ownership rules
        // For now, return empty array
        
        return violations
    }
    
    private func validateActorConcurrency() async -> [PatternViolation] {
        var violations: [PatternViolation] = []
        
        let components = await introspectionEngine.discoverComponents()
        
        // Check for non-actor components in concurrent contexts
        for component in components {
            if component.category == .client && !component.type.contains("actor") {
                violations.append(PatternViolation(
                    patternType: .actorConcurrency,
                    componentID: component.id,
                    description: "Client component should use actor for thread safety",
                    severity: .warning,
                    suggestedFix: "Convert to actor or ensure thread safety"
                ))
            }
        }
        
        return violations
    }
    
    // MARK: Pattern Suggestions
    
    private func suggestClientPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .actorConcurrency,
            confidence: 0.9,
            rationale: "Clients should use actor-based concurrency for thread safety",
            implementation: "Declare as 'actor' and use async/await for state access",
            benefits: ["Thread safety", "Concurrent access protection", "State isolation"]
        ))
        
        suggestions.append(PatternSuggestion(
            pattern: .stateManagement,
            confidence: 0.85,
            rationale: "Clients should implement proper state management",
            implementation: "Use StateSnapshot and StateTransaction for state handling",
            benefits: ["Atomic updates", "State history", "Rollback capability"]
        ))
        
        return suggestions
    }
    
    private func suggestContextPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .viewContextBinding,
            confidence: 0.95,
            rationale: "Contexts should maintain 1:1 relationship with Views",
            implementation: "Ensure ObservableObject conformance and proper lifecycle management",
            benefits: ["Clear separation", "Predictable updates", "Easy testing"]
        ))
        
        return suggestions
    }
    
    private func suggestViewPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .viewContextBinding,
            confidence: 0.9,
            rationale: "Views should bind to exactly one Context",
            implementation: "Use @StateObject or @ObservedObject with single Context",
            benefits: ["Simplified state management", "Clear data flow", "Better performance"]
        ))
        
        return suggestions
    }
    
    private func suggestDomainModelPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .domainModelPattern,
            confidence: 0.88,
            rationale: "Domain models should encapsulate business logic",
            implementation: "Use value types with computed properties and validation",
            benefits: ["Business logic encapsulation", "Immutability", "Testability"]
        ))
        
        return suggestions
    }
    
    private func suggestCapabilityPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .capabilityValidation,
            confidence: 0.8,
            rationale: "Components should validate required capabilities",
            implementation: "Declare capabilities and use CapabilityManager for validation",
            benefits: ["Runtime safety", "Clear dependencies", "Graceful degradation"]
        ))
        
        return suggestions
    }
    
    private func suggestGenericPatterns(_ context: PatternSuggestionContext) async -> [PatternSuggestion] {
        var suggestions: [PatternSuggestion] = []
        
        suggestions.append(PatternSuggestion(
            pattern: .errorHandling,
            confidence: 0.75,
            rationale: "All components should implement proper error handling",
            implementation: "Use Result types and proper error propagation",
            benefits: ["Robust error handling", "Better user experience", "Easier debugging"]
        ))
        
        return suggestions
    }
    
    // MARK: Anti-Pattern Detection
    
    private func detectGodObjectAntiPattern(_ components: [IntrospectedComponent]) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        for component in components {
            if let dna = component.architecturalDNA {
                let relationshipCount = dna.relationships.count
                let capabilityCount = dna.requiredCapabilities.count + dna.providedCapabilities.count
                
                // God object heuristic: many relationships and capabilities
                if relationshipCount > 10 || capabilityCount > 8 {
                    antiPatterns.append(AntiPatternDetection(
                        type: .godObject,
                        componentID: component.id,
                        description: "Component has too many responsibilities (relationships: \(relationshipCount), capabilities: \(capabilityCount))",
                        severity: .high,
                        impact: "Reduces maintainability and testability",
                        recommendation: "Split into smaller, focused components"
                    ))
                }
            }
        }
        
        return antiPatterns
    }
    
    private func detectTightCouplingAntiPattern(_ components: [IntrospectedComponent], _ relationshipMap: ComponentRelationshipMap) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        // Detect components with high coupling
        for component in components {
            let relationshipCount = relationshipMap.getRelationshipCount(for: component.id)
            
            if relationshipCount > 8 {
                antiPatterns.append(AntiPatternDetection(
                    type: .tightCoupling,
                    componentID: component.id,
                    description: "Component has excessive coupling (\(relationshipCount) relationships)",
                    severity: .medium,
                    impact: "Makes changes difficult and increases fragility",
                    recommendation: "Reduce dependencies through abstraction and dependency injection"
                ))
            }
        }
        
        return antiPatterns
    }
    
    private func detectCircularDependencyAntiPattern(_ relationshipMap: ComponentRelationshipMap) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        // Simple circular dependency detection
        let allRelationships = relationshipMap.getAllRelationships()
        let dependencyMap: [ComponentID: Set<ComponentID>] = allRelationships.reduce(into: [:]) { result, relationship in
            if relationship.type == .dependsOn {
                result[relationship.source, default: Set()].insert(relationship.target)
            }
        }
        
        // Check for circular dependencies (simplified)
        for (source, targets) in dependencyMap {
            for target in targets {
                if dependencyMap[target]?.contains(source) == true {
                    antiPatterns.append(AntiPatternDetection(
                        type: .circularDependency,
                        componentID: source,
                        description: "Circular dependency detected between \(source) and \(target)",
                        severity: .critical,
                        impact: "Prevents proper initialization and testing",
                        recommendation: "Break circular dependency through abstraction or inversion"
                    ))
                }
            }
        }
        
        return antiPatterns
    }
    
    private func detectSingletonAbuseAntiPattern(_ components: [IntrospectedComponent]) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        // Detect potential singleton abuse
        let potentialSingletons = components.filter { component in
            component.name.contains("Singleton") || 
            component.name.contains("Shared") ||
            component.name.contains("Global")
        }
        
        if potentialSingletons.count > 3 {
            for singleton in potentialSingletons {
                antiPatterns.append(AntiPatternDetection(
                    type: .singletonAbuse,
                    componentID: singleton.id,
                    description: "Potential singleton abuse in \(singleton.name)",
                    severity: .medium,
                    impact: "Makes testing difficult and creates hidden dependencies",
                    recommendation: "Consider dependency injection or actor-based alternatives"
                ))
            }
        }
        
        return antiPatterns
    }
    
    private func detectBigBallOfMudAntiPattern(_ components: [IntrospectedComponent], _ relationshipMap: ComponentRelationshipMap) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        // Detect lack of clear architecture
        let totalRelationships = relationshipMap.totalRelationships
        let averageRelationships = Double(totalRelationships) / Double(max(components.count, 1))
        
        if averageRelationships > 5.0 && components.count > 10 {
            antiPatterns.append(AntiPatternDetection(
                type: .bigBallOfMud,
                componentID: ComponentID("SYSTEM"),
                description: "System shows signs of Big Ball of Mud (avg \(String(format: "%.1f", averageRelationships)) relationships per component)",
                severity: .high,
                impact: "Makes system difficult to understand and modify",
                recommendation: "Refactor to establish clear architectural boundaries and layers"
            ))
        }
        
        return antiPatterns
    }
    
    private func detectPerformanceAntiPatterns(_ components: [IntrospectedComponent]) async -> [AntiPatternDetection] {
        var antiPatterns: [AntiPatternDetection] = []
        
        // Detect potential performance anti-patterns
        for component in components {
            if let dna = component.architecturalDNA {
                let latency = dna.performanceProfile.latency.typical
                
                if latency > 0.5 { // 500ms threshold
                    antiPatterns.append(AntiPatternDetection(
                        type: .performanceAntiPattern,
                        componentID: component.id,
                        description: "Component has high latency (\(String(format: "%.1f", latency * 1000))ms)",
                        severity: .medium,
                        impact: "Degrades user experience and system responsiveness",
                        recommendation: "Optimize algorithms, add caching, or use asynchronous processing"
                    ))
                }
            }
        }
        
        return antiPatterns
    }
    
    // MARK: Pattern Utility Methods
    
    private func initializeActorPattern() async {
        // Initialize built-in actor pattern
    }
    
    private func initializeViewContextPattern() async {
        // Initialize built-in view-context pattern
    }
    
    private func initializeClientOwnershipPattern() async {
        // Initialize built-in client ownership pattern
    }
    
    private func initializeCapabilityPattern() async {
        // Initialize built-in capability pattern
    }
    
    private func initializeStateManagementPattern() async {
        // Initialize built-in state management pattern
    }
    
    private func initializeErrorHandlingPattern() async {
        // Initialize built-in error handling pattern
    }
    
    private func generatePatternDescription(_ pattern: DetectedPattern) -> String {
        return "Pattern \(pattern.name) detected with \(pattern.confidence * 100)% confidence"
    }
    
    private func extractPatternStructure(_ pattern: DetectedPattern) -> PatternStructure {
        return PatternStructure(
            components: pattern.components,
            relationships: [], // Would extract from pattern analysis
            constraints: []
        )
    }
    
    private func extractPatternConstraints(_ pattern: DetectedPattern) -> [ArchitecturalConstraint] {
        // Extract constraints from the pattern
        return []
    }
    
    private func identifyPatternBenefits(_ pattern: DetectedPattern) -> [String] {
        return pattern.evidence
    }
    
    private func identifyPatternTradeoffs(_ pattern: DetectedPattern) -> [String] {
        return [] // Would analyze tradeoffs
    }
    
    private func generatePatternExamples(_ pattern: DetectedPattern) -> [UsageExample] {
        return []
    }
    
    private func generateApplicabilityRules(_ pattern: DetectedPattern) -> [ApplicabilityRule] {
        return []
    }
    
    private func calculatePatternComplexity(_ patterns: [DetectedPattern]) async -> [PatternType: Double] {
        var complexityScores: [PatternType: Double] = [:]
        
        for patternType in PatternType.allCases {
            let patternsOfType = patterns.filter { $0.type == patternType }
            let averageComplexity = patternsOfType.isEmpty ? 0 : 
                patternsOfType.map { Double($0.components.count) }.reduce(0, +) / Double(patternsOfType.count)
            complexityScores[patternType] = averageComplexity
        }
        
        return complexityScores
    }
}

// MARK: - Supporting Types

/// Configuration for pattern detection behavior
public struct PatternDetectionConfiguration: Sendable {
    public let enabledPatterns: Set<PatternType>
    public let sensitivityThreshold: Double
    public let enableAntiPatternDetection: Bool
    public let enablePatternSuggestions: Bool
    public let enablePatternLearning: Bool
    
    public init(
        enabledPatterns: Set<PatternType> = Set(PatternType.allCases),
        sensitivityThreshold: Double = 0.7,
        enableAntiPatternDetection: Bool = true,
        enablePatternSuggestions: Bool = true,
        enablePatternLearning: Bool = true
    ) {
        self.enabledPatterns = enabledPatterns
        self.sensitivityThreshold = max(0.0, min(1.0, sensitivityThreshold))
        self.enableAntiPatternDetection = enableAntiPatternDetection
        self.enablePatternSuggestions = enablePatternSuggestions
        self.enablePatternLearning = enablePatternLearning
    }
}

/// Types of architectural patterns that can be detected
public enum PatternType: String, CaseIterable, Sendable {
    case actorConcurrency = "actor_concurrency"
    case viewContextBinding = "view_context_binding"
    case clientOwnership = "client_ownership"
    case capabilityValidation = "capability_validation"
    case stateManagement = "state_management"
    case errorHandling = "error_handling"
    case performanceOptimization = "performance_optimization"
    case unidirectionalFlow = "unidirectional_flow"
    case domainModelPattern = "domain_model"
    case crossCuttingConcerns = "cross_cutting_concerns"
}

/// A detected pattern instance in the architecture
public struct DetectedPattern: Sendable, Identifiable {
    public let id = UUID()
    public let type: PatternType
    public let name: String
    public let description: String
    public let components: [ComponentID]
    public let confidence: Double
    public let evidence: [String]
    public let location: PatternLocation
    public let detectedAt: Date
    
    public init(
        type: PatternType,
        name: String,
        description: String,
        components: [ComponentID],
        confidence: Double,
        evidence: [String],
        location: PatternLocation,
        detectedAt: Date
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.components = components
        self.confidence = max(0.0, min(1.0, confidence))
        self.evidence = evidence
        self.location = location
        self.detectedAt = detectedAt
    }
}

/// Location information for a detected pattern
public struct PatternLocation: Sendable {
    public let componentID: ComponentID
    public let relatedComponents: [ComponentID]
    public let filePath: String?
    public let lineRange: ClosedRange<Int>?
    
    public init(
        componentID: ComponentID,
        relatedComponents: [ComponentID] = [],
        filePath: String? = nil,
        lineRange: ClosedRange<Int>? = nil
    ) {
        self.componentID = componentID
        self.relatedComponents = relatedComponents
        self.filePath = filePath
        self.lineRange = lineRange
    }
}

/// Analysis result for a specific pattern type
public struct PatternAnalysis: Sendable {
    public let patternType: PatternType
    public let totalInstances: Int
    public let averageConfidence: Double
    public let usage: PatternUsage
    public let compliance: Double
    public let effectiveness: PatternEffectiveness
    public let recommendations: [String]
    public let analyzedAt: Date
    
    public init(
        patternType: PatternType,
        totalInstances: Int,
        averageConfidence: Double,
        usage: PatternUsage,
        compliance: Double,
        effectiveness: PatternEffectiveness,
        recommendations: [String],
        analyzedAt: Date
    ) {
        self.patternType = patternType
        self.totalInstances = totalInstances
        self.averageConfidence = averageConfidence
        self.usage = usage
        self.compliance = compliance
        self.effectiveness = effectiveness
        self.recommendations = recommendations
        self.analyzedAt = analyzedAt
    }
}

/// Pattern usage statistics
public struct PatternUsage: Sendable {
    public let total: Int
    public let highConfidence: Int
    public let mediumConfidence: Int
    public let lowConfidence: Int
    
    public var highConfidenceRate: Double {
        guard total > 0 else { return 0.0 }
        return Double(highConfidence) / Double(total)
    }
    
    public init(total: Int, highConfidence: Int, mediumConfidence: Int, lowConfidence: Int) {
        self.total = total
        self.highConfidence = highConfidence
        self.mediumConfidence = mediumConfidence
        self.lowConfidence = lowConfidence
    }
}

/// Pattern effectiveness metrics
public struct PatternEffectiveness: Sendable {
    public let overallScore: Double
    public let consistencyScore: Double
    public let impactScore: Double
    public let averageConfidence: Double
    
    public init(overallScore: Double, consistencyScore: Double, impactScore: Double, averageConfidence: Double) {
        self.overallScore = overallScore
        self.consistencyScore = consistencyScore
        self.impactScore = impactScore
        self.averageConfidence = averageConfidence
    }
}

/// Cached pattern analysis result
private struct CachedPatternAnalysis {
    let analysis: PatternAnalysis
    let timestamp: Date
    
    func isExpired(timeout: TimeInterval) -> Bool {
        return Date().timeIntervalSince(timestamp) > timeout
    }
}

/// Pattern compliance report
public struct PatternComplianceReport: Sendable {
    public let overallScore: Double
    public let patternScores: [PatternType: Double]
    public let violations: [PatternViolation]
    public let validatedAt: Date
    
    public init(
        overallScore: Double,
        patternScores: [PatternType: Double],
        violations: [PatternViolation],
        validatedAt: Date
    ) {
        self.overallScore = overallScore
        self.patternScores = patternScores
        self.violations = violations
        self.validatedAt = validatedAt
    }
}

/// Pattern compliance for a specific pattern type
private struct PatternTypeCompliance {
    let patternType: PatternType
    let score: Double
    let violations: [PatternViolation]
    let patternsDetected: Int
}

/// Violation of a pattern rule
public struct PatternViolation: Sendable {
    public let patternType: PatternType
    public let componentID: ComponentID
    public let description: String
    public let severity: ViolationSeverity
    public let suggestedFix: String
    
    public init(
        patternType: PatternType,
        componentID: ComponentID,
        description: String,
        severity: ViolationSeverity,
        suggestedFix: String
    ) {
        self.patternType = patternType
        self.componentID = componentID
        self.description = description
        self.severity = severity
        self.suggestedFix = suggestedFix
    }
}

/// Context for pattern suggestions
public struct PatternSuggestionContext: Sendable {
    public let category: ComponentCategory
    public let purpose: String
    public let requirements: [String]
    public let existingPatterns: [PatternType]
    
    public init(
        category: ComponentCategory,
        purpose: String,
        requirements: [String] = [],
        existingPatterns: [PatternType] = []
    ) {
        self.category = category
        self.purpose = purpose
        self.requirements = requirements
        self.existingPatterns = existingPatterns
    }
}

/// Suggested pattern for a context
public struct PatternSuggestion: Sendable {
    public let pattern: PatternType
    public let confidence: Double
    public let rationale: String
    public let implementation: String
    public let benefits: [String]
    
    public init(
        pattern: PatternType,
        confidence: Double,
        rationale: String,
        implementation: String,
        benefits: [String]
    ) {
        self.pattern = pattern
        self.confidence = max(0.0, min(1.0, confidence))
        self.rationale = rationale
        self.implementation = implementation
        self.benefits = benefits
    }
}

/// Codified pattern for reuse
public struct CodifiedPattern: Sendable {
    public let type: PatternType
    public let name: String
    public let description: String
    public let structure: PatternStructure
    public let constraints: [ArchitecturalConstraint]
    public let benefits: [String]
    public let tradeoffs: [String]
    public let examples: [UsageExample]
    public let applicabilityRules: [ApplicabilityRule]
    public let codifiedAt: Date
    
    public init(
        type: PatternType,
        name: String,
        description: String,
        structure: PatternStructure,
        constraints: [ArchitecturalConstraint],
        benefits: [String],
        tradeoffs: [String],
        examples: [UsageExample],
        applicabilityRules: [ApplicabilityRule],
        codifiedAt: Date
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.structure = structure
        self.constraints = constraints
        self.benefits = benefits
        self.tradeoffs = tradeoffs
        self.examples = examples
        self.applicabilityRules = applicabilityRules
        self.codifiedAt = codifiedAt
    }
}

/// Structure definition of a pattern
public struct PatternStructure: Sendable {
    public let components: [ComponentID]
    public let relationships: [ComponentRelationship]
    public let constraints: [ArchitecturalConstraint]
    
    public init(
        components: [ComponentID],
        relationships: [ComponentRelationship],
        constraints: [ArchitecturalConstraint]
    ) {
        self.components = components
        self.relationships = relationships
        self.constraints = constraints
    }
}

/// Rule for when a pattern applies
public struct ApplicabilityRule: Sendable {
    public let condition: String
    public let description: String
    public let priority: Priority
    
    public init(condition: String, description: String, priority: Priority) {
        self.condition = condition
        self.description = description
        self.priority = priority
    }
}

/// Types of anti-patterns that can be detected
public enum AntiPatternType: String, CaseIterable, Sendable {
    case godObject = "god_object"
    case tightCoupling = "tight_coupling"
    case circularDependency = "circular_dependency"
    case singletonAbuse = "singleton_abuse"
    case bigBallOfMud = "big_ball_of_mud"
    case performanceAntiPattern = "performance_anti_pattern"
}

/// Detected anti-pattern instance
public struct AntiPatternDetection: Sendable {
    public let type: AntiPatternType
    public let componentID: ComponentID
    public let description: String
    public let severity: ImpactLevel
    public let impact: String
    public let recommendation: String
    
    public init(
        type: AntiPatternType,
        componentID: ComponentID,
        description: String,
        severity: ImpactLevel,
        impact: String,
        recommendation: String
    ) {
        self.type = type
        self.componentID = componentID
        self.description = description
        self.severity = severity
        self.impact = impact
        self.recommendation = recommendation
    }
}

/// Overall pattern statistics for the system
public struct PatternStatistics: Sendable {
    public let totalPatternsDetected: Int
    public let patternDistribution: [PatternType: Int]
    public let averageCompliance: Double
    public let complianceByPattern: [PatternType: Double]
    public let complexityScores: [PatternType: Double]
    public let antiPatternCount: Int
    public let generatedAt: Date
    
    public init(
        totalPatternsDetected: Int,
        patternDistribution: [PatternType: Int],
        averageCompliance: Double,
        complianceByPattern: [PatternType: Double],
        complexityScores: [PatternType: Double],
        antiPatternCount: Int,
        generatedAt: Date
    ) {
        self.totalPatternsDetected = totalPatternsDetected
        self.patternDistribution = patternDistribution
        self.averageCompliance = averageCompliance
        self.complianceByPattern = complianceByPattern
        self.complexityScores = complexityScores
        self.antiPatternCount = antiPatternCount
        self.generatedAt = generatedAt
    }
}

// MARK: - Global Pattern Detection

/// Global shared pattern detection engine
public actor GlobalPatternDetectionEngine {
    public static let shared = GlobalPatternDetectionEngine()
    
    private var engine: PatternDetectionEngine?
    
    private init() {
        // Engine will be lazily initialized when first accessed
    }
    
    public func getEngine() async -> PatternDetectionEngine {
        if let engine = engine {
            return engine
        }
        
        let introspectionEngine = await GlobalIntrospectionEngine.shared.getEngine()
        let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
        
        let newEngine = PatternDetectionEngine(
            introspectionEngine: introspectionEngine,
            performanceMonitor: performanceMonitor
        )
        self.engine = newEngine
        return newEngine
    }
}