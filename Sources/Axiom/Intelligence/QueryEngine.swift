import Foundation

// MARK: - Query Engine Protocol

/// Protocol for processing architectural queries and generating intelligent responses
/// This is part of the natural language intelligence system in Axiom
public protocol QueryProcessing: Actor {
    /// Processes a parsed query and generates a comprehensive response
    func processQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse
    
    /// Explains a specific component in detail
    func explainComponent(_ componentID: ComponentID) async throws -> ComponentExplanation
    
    /// Analyzes the impact of a proposed change
    func analyzeImpact(of change: String) async throws -> ImpactAnalysis
    
    /// Generates a complexity report for the system or specific domain
    func generateComplexityReport(for domain: String?) async throws -> ComplexityReport
    
    /// Provides architectural recommendations
    func generateRecommendations(for context: RecommendationContext) async throws -> [ArchitecturalRecommendation]
    
    /// Gets system overview and statistics
    func getSystemOverview() async throws -> SystemOverview
}

// MARK: - Architectural Query Engine

/// Actor-based query engine that processes natural language queries about architecture
public actor ArchitecturalQueryEngine: QueryProcessing {
    // MARK: Properties
    
    /// Component introspection engine for architectural analysis
    private let introspectionEngine: ComponentIntrospectionEngine
    
    /// Pattern detection engine for pattern analysis
    private let patternDetectionEngine: PatternDetectionEngine
    
    /// Performance monitor for query engine operations
    private let performanceMonitor: PerformanceMonitor
    
    /// Query parser for processing natural language
    private let queryParser: NaturalLanguageQueryParser
    
    /// Response cache for frequently asked questions
    private var responseCache: [String: CachedResponse] = [:]
    
    /// Engine configuration
    private let configuration: QueryEngineConfiguration
    
    /// Cache TTL (in seconds)
    private let cacheTimeout: TimeInterval
    
    // MARK: Initialization
    
    public init(
        introspectionEngine: ComponentIntrospectionEngine,
        patternDetectionEngine: PatternDetectionEngine,
        performanceMonitor: PerformanceMonitor,
        queryParser: NaturalLanguageQueryParser,
        configuration: QueryEngineConfiguration = QueryEngineConfiguration(),
        cacheTimeout: TimeInterval = 300.0
    ) {
        self.introspectionEngine = introspectionEngine
        self.patternDetectionEngine = patternDetectionEngine
        self.performanceMonitor = performanceMonitor
        self.queryParser = queryParser
        self.configuration = configuration
        self.cacheTimeout = cacheTimeout
    }
    
    // MARK: Query Processing
    
    public func processQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let token = await performanceMonitor.startOperation("process_query", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Check cache first if enabled
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(parsedQuery)
            if let cachedResponse = responseCache[cacheKey],
               !cachedResponse.isExpired(timeout: cacheTimeout) {
                return cachedResponse.response
            }
        }
        
        // Validate query confidence
        if parsedQuery.confidence < configuration.minimumConfidenceThreshold {
            throw QueryEngineError.lowConfidenceQuery(parsedQuery.confidence)
        }
        
        // Process based on intent
        let response = try await processQueryByIntent(parsedQuery)
        
        // Cache the response if enabled
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(parsedQuery)
            responseCache[cacheKey] = CachedResponse(
                response: response,
                timestamp: Date()
            )
        }
        
        // Learn from the query
        if configuration.enableLearning {
            let result = QueryResult(
                wasSuccessful: true,
                responseTime: Date().timeIntervalSince(parsedQuery.parsedAt),
                resultCount: response.data.count,
                userSatisfaction: nil
            )
            await queryParser.learnFromQuery(parsedQuery.originalQuery, result: result)
        }
        
        return response
    }
    
    public func explainComponent(_ componentID: ComponentID) async throws -> ComponentExplanation {
        let token = await performanceMonitor.startOperation("explain_component", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Get component analysis
        let analysis = try await introspectionEngine.analyzeComponent(componentID)
        
        // Get component documentation
        let documentation = await introspectionEngine.generateDocumentation()
        let componentDoc = documentation.getComponentDocumentation(componentID)
        
        // Get pattern information
        let patterns = await patternDetectionEngine.detectPatterns()
        let componentPatterns = patterns.filter { $0.components.contains(componentID) }
        
        // Generate explanation
        let explanation = generateComponentExplanation(
            analysis: analysis,
            documentation: componentDoc,
            patterns: componentPatterns
        )
        
        return explanation
    }
    
    public func analyzeImpact(of change: String) async throws -> ImpactAnalysis {
        let token = await performanceMonitor.startOperation("analyze_impact", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Parse the change description to extract details
        let changeDetails = try parseChangeDescription(change)
        
        // Create proposed change for analysis
        let proposedChange = ProposedChange(
            targetComponent: changeDetails.targetComponent,
            type: changeDetails.changeType,
            scope: changeDetails.scope,
            description: change,
            rationale: changeDetails.rationale
        )
        
        // Perform impact analysis
        let systemImpact = await introspectionEngine.performImpactAnalysis([proposedChange])
        
        // Enhance with pattern analysis
        let patternImpact = await analyzePatternImpact(proposedChange)
        
        // Generate comprehensive impact analysis
        return ImpactAnalysis(
            change: change,
            systemImpact: systemImpact,
            patternImpact: patternImpact,
            riskAssessment: generateRiskAssessment(systemImpact),
            recommendations: generateImpactRecommendations(systemImpact, patternImpact),
            timelineEstimate: estimateImplementationTimeline(systemImpact),
            analyzedAt: Date()
        )
    }
    
    public func generateComplexityReport(for domain: String?) async throws -> ComplexityReport {
        let token = await performanceMonitor.startOperation("complexity_report", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Get component metrics
        let metrics = await introspectionEngine.getComponentMetrics()
        
        // Get pattern statistics
        let patternStats = await patternDetectionEngine.getPatternStatistics()
        
        // Get anti-patterns
        let antiPatterns = await patternDetectionEngine.detectAntiPatterns()
        
        // Filter by domain if specified
        let filteredComponents = await filterComponentsByDomain(domain)
        let domainMetrics = await calculateDomainSpecificMetrics(filteredComponents)
        
        // Generate complexity analysis
        let complexityAnalysis = generateComplexityAnalysis(
            metrics: metrics,
            patternStats: patternStats,
            antiPatterns: antiPatterns,
            domainMetrics: domainMetrics
        )
        
        return ComplexityReport(
            domain: domain,
            overallComplexity: complexityAnalysis.overallScore,
            componentComplexity: complexityAnalysis.componentScores,
            relationshipComplexity: complexityAnalysis.relationshipComplexity,
            patternComplexity: complexityAnalysis.patternComplexity,
            recommendations: complexityAnalysis.recommendations,
            trends: complexityAnalysis.trends,
            generatedAt: Date()
        )
    }
    
    public func generateRecommendations(for context: RecommendationContext) async throws -> [ArchitecturalRecommendation] {
        let token = await performanceMonitor.startOperation("generate_recommendations", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var recommendations: [ArchitecturalRecommendation] = []
        
        // Get current system state
        let metrics = await introspectionEngine.getComponentMetrics()
        let patterns = await patternDetectionEngine.detectPatterns()
        let antiPatterns = await patternDetectionEngine.detectAntiPatterns()
        let integrityReport = await introspectionEngine.validateArchitecturalIntegrity()
        
        // Generate recommendations based on context
        switch context.type {
        case .performance:
            recommendations.append(contentsOf: generatePerformanceRecommendations(metrics, patterns))
        case .maintainability:
            recommendations.append(contentsOf: generateMaintainabilityRecommendations(antiPatterns, integrityReport))
        case .scalability:
            recommendations.append(contentsOf: generateScalabilityRecommendations(metrics, patterns))
        case .security:
            recommendations.append(contentsOf: generateSecurityRecommendations(integrityReport))
        case .general:
            recommendations.append(contentsOf: generateGeneralRecommendations(metrics, patterns, antiPatterns, integrityReport))
        }
        
        // Sort by priority and confidence
        return recommendations.sorted { 
            if $0.priority != $1.priority {
                return $0.priority.rawValue > $1.priority.rawValue
            }
            return $0.confidence > $1.confidence
        }
    }
    
    public func getSystemOverview() async throws -> SystemOverview {
        let token = await performanceMonitor.startOperation("system_overview", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Gather comprehensive system information
        let components = await introspectionEngine.discoverComponents()
        let metrics = await introspectionEngine.getComponentMetrics()
        let relationshipMap = await introspectionEngine.mapComponentRelationships()
        let patterns = await patternDetectionEngine.detectPatterns()
        let antiPatterns = await patternDetectionEngine.detectAntiPatterns()
        let integrityReport = await introspectionEngine.validateArchitecturalIntegrity()
        
        // Calculate system health score
        let healthScore = calculateSystemHealthScore(
            integrityReport: integrityReport,
            patterns: patterns,
            antiPatterns: antiPatterns,
            metrics: metrics
        )
        
        return SystemOverview(
            totalComponents: components.count,
            totalRelationships: relationshipMap.totalRelationships,
            componentDistribution: metrics.categoryDistribution,
            layerDistribution: metrics.layerDistribution,
            patternCount: patterns.count,
            antiPatternCount: antiPatterns.count,
            integrityScore: integrityReport.overallScore,
            healthScore: healthScore,
            topIssues: extractTopIssues(integrityReport, antiPatterns),
            quickWins: generateQuickWins(patterns, antiPatterns, metrics),
            generatedAt: Date()
        )
    }
    
    // MARK: Private Query Processing Methods
    
    private func processQueryByIntent(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        switch parsedQuery.intent {
        case .describeComponent:
            return try await processDescribeComponentQuery(parsedQuery)
        case .listComponents:
            return try await processListComponentsQuery(parsedQuery)
        case .countComponents:
            return try await processCountComponentsQuery(parsedQuery)
        case .findDependencies:
            return try await processFindDependenciesQuery(parsedQuery)
        case .findDependents:
            return try await processFindDependentsQuery(parsedQuery)
        case .mapRelationships:
            return try await processMapRelationshipsQuery(parsedQuery)
        case .detectPatterns:
            return try await processDetectPatternsQuery(parsedQuery)
        case .checkPattern:
            return try await processCheckPatternQuery(parsedQuery)
        case .detectAntiPatterns:
            return try await processDetectAntiPatternsQuery(parsedQuery)
        case .getPerformance:
            return try await processGetPerformanceQuery(parsedQuery)
        case .analyzePerformance:
            return try await processAnalyzePerformanceQuery(parsedQuery)
        case .validateArchitecture:
            return try await processValidateArchitectureQuery(parsedQuery)
        case .findIssues:
            return try await processFindIssuesQuery(parsedQuery)
        case .suggestImprovements:
            return try await processSuggestImprovementsQuery(parsedQuery)
        case .getOverview:
            return try await processGetOverviewQuery(parsedQuery)
        case .help:
            return try await processHelpQuery(parsedQuery)
        case .unknown:
            throw QueryEngineError.unknownIntent(parsedQuery.intent)
        }
    }
    
    private func processDescribeComponentQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        guard let componentName = parsedQuery.parameters["componentName"] as? String else {
            throw QueryEngineError.missingParameter("componentName")
        }
        
        // Find component by name
        let components = await introspectionEngine.discoverComponents()
        guard let component = components.first(where: { $0.name.lowercased() == componentName.lowercased() }) else {
            throw QueryEngineError.componentNotFound(componentName)
        }
        
        // Get detailed explanation
        let explanation = try await explainComponent(component.id)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: explanation.detailedDescription,
            data: [
                "component": component,
                "explanation": explanation
            ],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: generateFollowUpSuggestions(for: component),
            respondedAt: Date()
        )
    }
    
    private func processListComponentsQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let components = await introspectionEngine.discoverComponents()
        let filteredComponents: [IntrospectedComponent]
        
        if let componentType = parsedQuery.parameters["componentType"] as? String {
            // Filter by type
            let targetCategory = mapStringToCategory(componentType)
            filteredComponents = components.filter { $0.category == targetCategory }
        } else {
            filteredComponents = components
        }
        
        let answer = generateComponentListAnswer(filteredComponents)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: ["components": filteredComponents],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: generateListSuggestions(filteredComponents),
            respondedAt: Date()
        )
    }
    
    private func processCountComponentsQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let metrics = await introspectionEngine.getComponentMetrics()
        
        let answer = """
        The system contains **\(metrics.totalComponents) components** in total:
        
        \(metrics.categoryDistribution.map { "• \($0.key.rawValue.capitalized): \($0.value)" }.joined(separator: "\n"))
        
        These components are distributed across \(metrics.layerDistribution.count) architectural layers with \(metrics.totalRelationships) total relationships.
        """
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: ["metrics": metrics],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: [
                "Show me the component distribution by layer",
                "What are the most connected components?",
                "Analyze the system complexity"
            ],
            respondedAt: Date()
        )
    }
    
    private func processFindDependenciesQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        guard let componentName = parsedQuery.parameters["componentName"] as? String else {
            throw QueryEngineError.missingParameter("componentName")
        }
        
        let components = await introspectionEngine.discoverComponents()
        guard let component = components.first(where: { $0.name.lowercased() == componentName.lowercased() }) else {
            throw QueryEngineError.componentNotFound(componentName)
        }
        
        let relationshipMap = await introspectionEngine.mapComponentRelationships()
        let dependents = relationshipMap.getComponentsDependingOn(component.id)
        
        let dependentComponents = components.filter { dependents.contains($0.id) }
        
        let answer = generateDependencyAnswer(component, dependents: dependentComponents)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: [
                "sourceComponent": component,
                "dependentComponents": dependentComponents
            ],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: generateDependencySuggestions(component),
            respondedAt: Date()
        )
    }
    
    private func processDetectPatternsQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let patterns = await patternDetectionEngine.detectPatterns()
        let patternStats = await patternDetectionEngine.getPatternStatistics()
        
        let answer = generatePatternDetectionAnswer(patterns, stats: patternStats)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: [
                "patterns": patterns,
                "statistics": patternStats
            ],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: [
                "Find anti-patterns in the system",
                "Check pattern compliance",
                "Suggest pattern improvements"
            ],
            respondedAt: Date()
        )
    }
    
    private func processValidateArchitectureQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let integrityReport = await introspectionEngine.validateArchitecturalIntegrity()
        let patternCompliance = await patternDetectionEngine.validatePatternCompliance()
        
        let answer = generateValidationAnswer(integrityReport, patternCompliance: patternCompliance)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: [
                "integrityReport": integrityReport,
                "patternCompliance": patternCompliance
            ],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: [
                "Show me the specific violations",
                "Suggest fixes for the issues",
                "Generate compliance report"
            ],
            respondedAt: Date()
        )
    }
    
    private func processGetOverviewQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let overview = try await getSystemOverview()
        
        let answer = generateOverviewAnswer(overview)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: ["overview": overview],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: [
                "Show me the detailed metrics",
                "What are the main issues?",
                "Suggest architectural improvements"
            ],
            respondedAt: Date()
        )
    }
    
    private func processHelpQuery(_ parsedQuery: ParsedQuery) async throws -> QueryResponse {
        let help = await queryParser.getQueryHelp()
        
        let answer = generateHelpAnswer(help)
        
        return QueryResponse(
            query: parsedQuery.originalQuery,
            intent: parsedQuery.intent,
            answer: answer,
            data: ["help": help],
            confidence: parsedQuery.confidence,
            executionTime: Date().timeIntervalSince(parsedQuery.parsedAt),
            suggestions: help.exampleQueries.prefix(5).map { $0.query },
            respondedAt: Date()
        )
    }
    
    // Additional processing methods for other intents would go here...
    
    // MARK: Private Helper Methods
    
    private func generateComponentExplanation(
        analysis: ComponentAnalysis,
        documentation: ComponentDocumentation?,
        patterns: [DetectedPattern]
    ) -> ComponentExplanation {
        let component = analysis.component
        
        let detailedDescription = """
        ## \(component.name)
        
        **Type**: \(component.category.rawValue.capitalized)
        **Purpose**: \(documentation?.purpose?.description ?? "No specific purpose documented")
        
        ### Architecture
        \(documentation?.architecture?.description ?? "No architectural details available")
        
        ### Relationships
        \(analysis.relationships.isEmpty ? "No relationships found" : analysis.relationships.map { "• \($0.type.description) with \($0.target)" }.joined(separator: "\n"))
        
        ### Patterns
        \(patterns.isEmpty ? "No patterns detected" : patterns.map { "• \($0.name) (\(String(format: "%.0f", $0.confidence * 100))% confidence)" }.joined(separator: "\n"))
        
        ### Quality Score
        \(String(format: "%.1f", analysis.qualityScore * 10))/10 - \(getQualityDescription(analysis.qualityScore))
        
        ### Complexity
        \(String(format: "%.2f", analysis.complexity)) - \(getComplexityDescription(analysis.complexity))
        """
        
        return ComponentExplanation(
            componentID: component.id,
            name: component.name,
            category: component.category,
            detailedDescription: detailedDescription,
            purpose: documentation?.purpose,
            architecture: documentation?.architecture,
            relationships: analysis.relationships,
            patterns: patterns,
            qualityMetrics: ComponentQualityMetrics(
                overallScore: analysis.qualityScore,
                complexity: analysis.complexity,
                coupling: Double(analysis.relationships.count),
                cohesion: calculateCohesionScore(analysis)
            ),
            recommendations: generateComponentRecommendations(analysis, patterns),
            explainedAt: Date()
        )
    }
    
    private func parseChangeDescription(_ change: String) throws -> ChangeDetails {
        // Simple parsing - in a real implementation, this would be more sophisticated
        let lowercased = change.lowercased()
        
        // Extract component name (look for capitalized words)
        let componentPattern = "\\b[A-Z][a-zA-Z]*(?:Manager|Service|Client|Context|View|Model|Controller|Handler)\\b"
        let componentMatches = change.matches(for: componentPattern)
        let targetComponent = ComponentID(componentMatches.first ?? "Unknown")
        
        // Determine change type
        let changeType: ChangeType
        if lowercased.contains("interface") || lowercased.contains("api") {
            changeType = .interface
        } else if lowercased.contains("performance") || lowercased.contains("optimize") {
            changeType = .performance
        } else if lowercased.contains("capability") {
            changeType = .capability
        } else if lowercased.contains("relationship") || lowercased.contains("dependency") {
            changeType = .relationship
        } else if lowercased.contains("constraint") || lowercased.contains("rule") {
            changeType = .constraint
        } else {
            changeType = .implementation
        }
        
        // Determine scope
        let scope: ChangeScope
        if lowercased.contains("system") || lowercased.contains("architecture") {
            scope = .system
        } else if lowercased.contains("layer") {
            scope = .layer
        } else if lowercased.contains("module") {
            scope = .module
        } else {
            scope = .local
        }
        
        return ChangeDetails(
            targetComponent: targetComponent,
            changeType: changeType,
            scope: scope,
            rationale: "Parsed from change description"
        )
    }
    
    private func generateCacheKey(_ parsedQuery: ParsedQuery) -> String {
        let parametersString = parsedQuery.parameters.map { "\($0.key):\($0.value)" }.sorted().joined(separator: ",")
        return "\(parsedQuery.intent.rawValue)|\(parametersString)"
    }
    
    private func mapStringToCategory(_ type: String) -> ComponentCategory {
        switch type.lowercased() {
        case "client", "clients":
            return .client
        case "context", "contexts":
            return .context
        case "view", "views":
            return .view
        case "model", "models", "domain":
            return .domainModel
        case "capability", "capabilities":
            return .capability
        default:
            return .unknown
        }
    }
    
    private func generateComponentListAnswer(_ components: [IntrospectedComponent]) -> String {
        guard !components.isEmpty else {
            return "No components found matching your criteria."
        }
        
        let grouped = Dictionary(grouping: components) { $0.category }
        
        var answer = "Found **\(components.count) components**:\n\n"
        
        for (category, comps) in grouped.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            answer += "### \(category.rawValue.capitalized)s (\(comps.count))\n"
            for comp in comps.sorted(by: { $0.name < $1.name }) {
                answer += "• **\(comp.name)** - \(comp.architecturalDNA?.purpose.description ?? "No description")\n"
            }
            answer += "\n"
        }
        
        return answer
    }
    
    private func generateDependencyAnswer(_ component: IntrospectedComponent, dependents: [IntrospectedComponent]) -> String {
        if dependents.isEmpty {
            return "**\(component.name)** has no components depending on it. It appears to be a leaf component."
        }
        
        let answer = """
        **\(component.name)** is depended upon by **\(dependents.count) component\(dependents.count == 1 ? "" : "s")**:
        
        \(dependents.map { "• **\($0.name)** (\($0.category.rawValue))" }.joined(separator: "\n"))
        
        This indicates that \(component.name) is a \(dependents.count > 3 ? "heavily used core component" : "moderately used component") in the system.
        """
        
        return answer
    }
    
    private func generatePatternDetectionAnswer(_ patterns: [DetectedPattern], stats: PatternStatistics) -> String {
        let answer = """
        ## Detected Patterns (\(patterns.count) total)
        
        ### Pattern Distribution
        \(stats.patternDistribution.map { "• **\($0.key.rawValue)**: \($0.value) instances" }.joined(separator: "\n"))
        
        ### High-Confidence Patterns
        \(patterns.filter { $0.confidence >= 0.8 }.prefix(5).map { "• **\($0.name)** - \(String(format: "%.0f", $0.confidence * 100))% confidence" }.joined(separator: "\n"))
        
        ### Overall Compliance
        **\(String(format: "%.1f", stats.averageCompliance * 100))%** average pattern compliance
        
        \(stats.antiPatternCount > 0 ? "⚠️ **\(stats.antiPatternCount) anti-patterns detected** - consider addressing these issues." : "✅ No anti-patterns detected - excellent architectural health!")
        """
        
        return answer
    }
    
    private func generateValidationAnswer(_ integrityReport: SystemIntegrityReport, patternCompliance: PatternComplianceReport) -> String {
        let status = integrityReport.isValid ? "✅ VALID" : "❌ ISSUES FOUND"
        
        let answer = """
        ## Architecture Validation: \(status)
        
        ### Overall Health
        • **Integrity Score**: \(String(format: "%.1f", integrityReport.overallScore * 100))%
        • **Pattern Compliance**: \(String(format: "%.1f", patternCompliance.overallScore * 100))%
        • **Components Analyzed**: \(integrityReport.componentCount)
        
        \(integrityReport.violations.isEmpty ? "### ✅ No Violations Found" : """
        ### ⚠️ Violations (\(integrityReport.violations.count))
        \(integrityReport.violations.prefix(5).map { "• \($0.violation.description)" }.joined(separator: "\n"))
        """)
        
        \(integrityReport.warnings.isEmpty ? "" : """
        ### 💡 Warnings (\(integrityReport.warnings.count))
        \(integrityReport.warnings.prefix(3).map { "• \($0.warning.description)" }.joined(separator: "\n"))
        """)
        
        ### Recommendations
        \(integrityReport.violations.isEmpty ? "• Continue following current architectural practices" : "• Address critical violations first")
        • Regular validation helps maintain architecture quality
        • Consider automated checks in your CI/CD pipeline
        """
        
        return answer
    }
    
    private func generateOverviewAnswer(_ overview: SystemOverview) -> String {
        let healthEmoji = overview.healthScore >= 0.8 ? "🟢" : overview.healthScore >= 0.6 ? "🟡" : "🔴"
        
        let answer = """
        ## System Overview \(healthEmoji)
        
        ### Components & Structure
        • **Total Components**: \(overview.totalComponents)
        • **Total Relationships**: \(overview.totalRelationships)
        • **Architectural Layers**: \(overview.layerDistribution.count)
        
        ### Distribution
        \(overview.componentDistribution.map { "• **\($0.key.rawValue.capitalized)**: \($0.value)" }.joined(separator: "\n"))
        
        ### Health Metrics
        • **System Health**: \(String(format: "%.1f", overview.healthScore * 100))% \(healthEmoji)
        • **Architectural Integrity**: \(String(format: "%.1f", overview.integrityScore * 100))%
        • **Patterns Detected**: \(overview.patternCount)
        • **Issues Found**: \(overview.antiPatternCount)
        
        \(overview.topIssues.isEmpty ? "### ✅ No Critical Issues" : """
        ### 🚨 Top Issues
        \(overview.topIssues.prefix(3).joined(separator: "\n"))
        """)
        
        ### 🚀 Quick Wins
        \(overview.quickWins.prefix(3).joined(separator: "\n"))
        """
        
        return answer
    }
    
    private func generateHelpAnswer(_ help: QueryHelp) -> String {
        let answer = """
        ## Axiom Intelligence Query Help
        
        ### What I Can Help You With
        I can answer questions about your architecture using natural language. Here are some things you can ask:
        
        \(help.syntax.supportedQuestions.map { "• \($0)" }.joined(separator: "\n"))
        
        ### Example Queries
        \(help.exampleQueries.prefix(6).map { "• \"\($0.query)\" - \($0.description)" }.joined(separator: "\n"))
        
        ### Parameter Types
        \(help.parameterTypes.map { "• **\($0.name)**: \($0.description)" }.joined(separator: "\n"))
        
        ### Tips
        \(help.syntax.tips.map { "• \($0)" }.joined(separator: "\n"))
        
        Just ask me anything about your architecture in plain English!
        """
        
        return answer
    }
    
    // Additional helper methods would go here...
    
    private func calculateSystemHealthScore(
        integrityReport: SystemIntegrityReport,
        patterns: [DetectedPattern],
        antiPatterns: [AntiPatternDetection],
        metrics: ComponentMetricsReport
    ) -> Double {
        var score = 1.0
        
        // Factor in integrity score (40% weight)
        score *= 0.6 + (0.4 * integrityReport.overallScore)
        
        // Factor in anti-patterns (30% weight)
        let antiPatternPenalty = min(0.3, Double(antiPatterns.count) * 0.05)
        score -= antiPatternPenalty
        
        // Factor in complexity (20% weight)
        let complexityScore = max(0.0, 1.0 - (metrics.complexityMetrics.averageComponentComplexity / 10.0))
        score *= 0.8 + (0.2 * complexityScore)
        
        // Factor in pattern adoption (10% weight)
        let patternScore = min(1.0, Double(patterns.count) / Double(max(metrics.totalComponents / 2, 1)))
        score *= 0.9 + (0.1 * patternScore)
        
        return max(0.0, min(1.0, score))
    }
    
    private func generateFollowUpSuggestions(for component: IntrospectedComponent) -> [String] {
        return [
            "What components depend on \(component.name)?",
            "Show me the performance metrics for \(component.name)",
            "What patterns does \(component.name) implement?",
            "Analyze the complexity of \(component.name)",
            "What would happen if I change \(component.name)?"
        ]
    }
    
    private func generateListSuggestions(_ components: [IntrospectedComponent]) -> [String] {
        let categories = Set(components.map { $0.category })
        return [
            "Show me the relationships between these components",
            "What patterns are used by these components?",
            "Analyze the complexity of these components",
            "Which of these components are most coupled?"
        ] + categories.map { "Show me only the \($0.rawValue) components" }
    }
    
    private func generateDependencySuggestions(_ component: IntrospectedComponent) -> [String] {
        return [
            "What components does \(component.name) depend on?",
            "Show me the relationship map for \(component.name)",
            "What would break if I remove \(component.name)?",
            "How tightly coupled is \(component.name)?",
            "Suggest ways to reduce \(component.name)'s dependencies"
        ]
    }
    
    private func analyzePatternImpact(_ change: ProposedChange) async -> PatternImpactAnalysis {
        let patterns = await patternDetectionEngine.detectPatterns()
        let affectedPatterns = patterns.filter { $0.components.contains(change.targetComponent) }
        
        var impacts: [PatternImpact] = []
        
        for pattern in affectedPatterns {
            let severity = assessPatternImpactSeverity(pattern, change: change)
            let mitigations = generatePatternMitigations(pattern, change: change)
            
            impacts.append(PatternImpact(
                pattern: pattern,
                severity: severity,
                description: "Change affects \(pattern.name) pattern implementation",
                mitigations: mitigations
            ))
        }
        
        return PatternImpactAnalysis(
            affectedPatterns: affectedPatterns.count,
            impacts: impacts,
            overallRisk: calculateOverallPatternRisk(impacts),
            recommendations: generatePatternRecommendations(impacts)
        )
    }
    
    private func generateRiskAssessment(_ systemImpact: SystemImpactAnalysis) -> RiskAssessment {
        var risks: [IdentifiedRisk] = []
        
        // Assess impact based on affected components
        if systemImpact.overallRisk == .critical {
            risks.append(IdentifiedRisk(
                type: .systemStability,
                probability: .high,
                impact: .critical,
                description: "Change affects critical system components",
                mitigation: "Implement comprehensive testing and staged rollout"
            ))
        }
        
        if systemImpact.estimatedEffort == .high {
            risks.append(IdentifiedRisk(
                type: .developmentComplexity,
                probability: .medium,
                impact: .medium,
                description: "High implementation effort may lead to delays",
                mitigation: "Break change into smaller, incremental updates"
            ))
        }
        
        return RiskAssessment(
            overallRisk: systemImpact.overallRisk,
            identifiedRisks: risks,
            mitigationStrategies: risks.map { $0.mitigation },
            riskScore: calculateRiskScore(systemImpact),
            assessedAt: Date()
        )
    }
    
    private func generateImpactRecommendations(_ systemImpact: SystemImpactAnalysis, _ patternImpact: PatternImpactAnalysis) -> [String] {
        var recommendations: [String] = []
        
        // System-level recommendations
        recommendations.append(contentsOf: systemImpact.recommendations)
        
        // Pattern-specific recommendations
        recommendations.append(contentsOf: patternImpact.recommendations)
        
        // General best practices
        if systemImpact.overallRisk.rawValue >= RiskLevel.medium.rawValue {
            recommendations.append("Implement comprehensive testing before deployment")
            recommendations.append("Consider feature flags for gradual rollout")
        }
        
        if systemImpact.impacts.count > 5 {
            recommendations.append("Break change into smaller, focused updates")
        }
        
        return Array(Set(recommendations)) // Remove duplicates
    }
    
    private func estimateImplementationTimeline(_ systemImpact: SystemImpactAnalysis) -> TimelineEstimate {
        let baseHours = estimateBaseHours(systemImpact.estimatedEffort)
        let componentMultiplier = Double(systemImpact.impacts.count) * 0.5
        let riskMultiplier = getRiskMultiplier(systemImpact.overallRisk)
        
        let totalHours = baseHours * (1 + componentMultiplier) * riskMultiplier
        
        return TimelineEstimate(
            estimatedHours: totalHours,
            estimatedDays: totalHours / 8.0,
            confidence: calculateTimelineConfidence(systemImpact),
            factors: [
                "Base effort: \(systemImpact.estimatedEffort.rawValue)",
                "Affected components: \(systemImpact.impacts.count)",
                "Risk level: \(systemImpact.overallRisk.rawValue)"
            ]
        )
    }
    
    private func filterComponentsByDomain(_ domain: String?) async -> [IntrospectedComponent] {
        let allComponents = await introspectionEngine.discoverComponents()
        
        guard let domain = domain else {
            return allComponents
        }
        
        return allComponents.filter { component in
            let componentName = component.name.lowercased()
            let domainLower = domain.lowercased()
            
            return componentName.contains(domainLower) ||
                   component.architecturalDNA?.purpose.domain.description.lowercased().contains(domainLower) ?? false
        }
    }
    
    private func calculateDomainSpecificMetrics(_ components: [IntrospectedComponent]) async -> DomainMetrics {
        let complexityScores = components.compactMap { component -> Double? in
            component.architecturalDNA?.qualityAttributes.overallScore
        }
        
        let averageComplexity = complexityScores.isEmpty ? 0 : complexityScores.reduce(0, +) / Double(complexityScores.count)
        
        return DomainMetrics(
            componentCount: components.count,
            averageComplexity: averageComplexity,
            relationshipDensity: calculateRelationshipDensity(components),
            patternAdoption: await calculatePatternAdoption(components)
        )
    }
    
    private func generateComplexityAnalysis(
        metrics: ComponentMetricsReport,
        patternStats: PatternStatistics,
        antiPatterns: [AntiPatternDetection],
        domainMetrics: DomainMetrics
    ) -> ComplexityAnalysis {
        let overallScore = calculateOverallComplexityScore(metrics, patternStats, antiPatterns, domainMetrics)
        
        return ComplexityAnalysis(
            overallScore: overallScore,
            componentScores: metrics.complexityMetrics,
            relationshipComplexity: metrics.averageRelationshipsPerComponent,
            patternComplexity: patternStats.averageCompliance,
            recommendations: generateComplexityRecommendations(overallScore, antiPatterns),
            trends: generateComplexityTrends(metrics)
        )
    }
    
    // Additional helper methods
    private func getQualityDescription(_ score: Double) -> String {
        switch score {
        case 0.9...1.0: return "Excellent"
        case 0.8..<0.9: return "Very Good"
        case 0.7..<0.8: return "Good"
        case 0.6..<0.7: return "Fair"
        case 0.5..<0.6: return "Needs Improvement"
        default: return "Poor"
        }
    }
    
    private func getComplexityDescription(_ complexity: Double) -> String {
        switch complexity {
        case 0.0..<0.2: return "Very Simple"
        case 0.2..<0.4: return "Simple"
        case 0.4..<0.6: return "Moderate"
        case 0.6..<0.8: return "Complex"
        case 0.8..<1.0: return "Very Complex"
        default: return "Extremely Complex"
        }
    }
    
    private func calculateCohesionScore(_ analysis: ComponentAnalysis) -> Double {
        // Simple cohesion calculation based on relationships and purpose
        let relationshipScore = 1.0 - min(1.0, Double(analysis.relationships.count) / 10.0)
        let qualityScore = analysis.qualityScore
        return (relationshipScore + qualityScore) / 2.0
    }
    
    private func generateComponentRecommendations(_ analysis: ComponentAnalysis, _ patterns: [DetectedPattern]) -> [String] {
        var recommendations: [String] = []
        
        if analysis.complexity > 0.8 {
            recommendations.append("Consider breaking this component into smaller, focused pieces")
        }
        
        if analysis.relationships.count > 8 {
            recommendations.append("High coupling detected - consider reducing dependencies")
        }
        
        if analysis.qualityScore < 0.6 {
            recommendations.append("Quality score is low - review implementation and add tests")
        }
        
        if patterns.isEmpty {
            recommendations.append("No patterns detected - consider applying established patterns")
        }
        
        return recommendations
    }
    
    // Helper calculation methods
    private func assessPatternImpactSeverity(_ pattern: DetectedPattern, change: ProposedChange) -> ImpactSeverity {
        if pattern.confidence > 0.9 && pattern.components.count == 1 {
            return .high
        } else if pattern.confidence > 0.7 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generatePatternMitigations(_ pattern: DetectedPattern, change: ProposedChange) -> [String] {
        return [
            "Ensure pattern integrity is maintained after change",
            "Update pattern documentation if needed",
            "Validate pattern compliance in tests"
        ]
    }
    
    private func calculateOverallPatternRisk(_ impacts: [PatternImpact]) -> RiskLevel {
        let highRiskCount = impacts.filter { $0.severity == .high }.count
        let mediumRiskCount = impacts.filter { $0.severity == .medium }.count
        
        if highRiskCount > 0 {
            return .high
        } else if mediumRiskCount > 2 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func generatePatternRecommendations(_ impacts: [PatternImpact]) -> [String] {
        if impacts.isEmpty {
            return ["No pattern impacts detected"]
        }
        
        return [
            "Review pattern implementations after change",
            "Ensure pattern documentation is updated",
            "Validate pattern compliance with integration tests"
        ]
    }
    
    private func calculateRiskScore(_ systemImpact: SystemImpactAnalysis) -> Double {
        var score = 0.0
        
        score += Double(systemImpact.overallRisk.rawValue) * 0.4
        score += Double(systemImpact.estimatedEffort.rawValue) * 0.3
        score += min(1.0, Double(systemImpact.impacts.count) / 10.0) * 0.3
        
        return min(1.0, score)
    }
    
    private func estimateBaseHours(_ effort: EffortLevel) -> Double {
        switch effort {
        case .minimal: return 2.0
        case .low: return 8.0
        case .medium: return 24.0
        case .high: return 48.0
        }
    }
    
    private func getRiskMultiplier(_ risk: RiskLevel) -> Double {
        switch risk {
        case .minimal: return 1.0
        case .low: return 1.2
        case .medium: return 1.5
        case .high: return 2.0
        case .critical: return 3.0
        }
    }
    
    private func calculateTimelineConfidence(_ systemImpact: SystemImpactAnalysis) -> Double {
        var confidence = 0.8
        
        if systemImpact.overallRisk == .critical {
            confidence -= 0.3
        } else if systemImpact.overallRisk == .high {
            confidence -= 0.2
        }
        
        if systemImpact.impacts.count > 5 {
            confidence -= 0.1
        }
        
        return max(0.3, confidence)
    }
    
    private func calculateRelationshipDensity(_ components: [IntrospectedComponent]) -> Double {
        let totalRelationships = components.compactMap { $0.architecturalDNA?.relationships.count }.reduce(0, +)
        let componentCount = components.count
        
        return componentCount > 0 ? Double(totalRelationships) / Double(componentCount) : 0.0
    }
    
    private func calculatePatternAdoption(_ components: [IntrospectedComponent]) async -> Double {
        let patterns = await patternDetectionEngine.detectPatterns()
        let componentsWithPatterns = Set(patterns.flatMap { $0.components }).count
        
        return components.count > 0 ? Double(componentsWithPatterns) / Double(components.count) : 0.0
    }
    
    private func calculateOverallComplexityScore(
        _ metrics: ComponentMetricsReport,
        _ patternStats: PatternStatistics,
        _ antiPatterns: [AntiPatternDetection],
        _ domainMetrics: DomainMetrics
    ) -> Double {
        var score = 0.5 // Base score
        
        // Factor in component complexity
        score += (1.0 - min(1.0, metrics.complexityMetrics.averageComponentComplexity / 5.0)) * 0.3
        
        // Factor in pattern compliance
        score += patternStats.averageCompliance * 0.3
        
        // Factor in anti-patterns (penalty)
        let antiPatternPenalty = min(0.2, Double(antiPatterns.count) * 0.02)
        score -= antiPatternPenalty
        
        // Factor in domain-specific metrics
        score += (1.0 - min(1.0, domainMetrics.averageComplexity)) * 0.2
        
        return max(0.0, min(1.0, score))
    }
    
    private func generateComplexityRecommendations(_ overallScore: Double, _ antiPatterns: [AntiPatternDetection]) -> [String] {
        var recommendations: [String] = []
        
        if overallScore < 0.6 {
            recommendations.append("System complexity is high - consider architectural refactoring")
        }
        
        if !antiPatterns.isEmpty {
            recommendations.append("Address detected anti-patterns to reduce complexity")
        }
        
        recommendations.append("Regular complexity monitoring helps maintain system health")
        
        return recommendations
    }
    
    private func generateComplexityTrends(_ metrics: ComponentMetricsReport) -> [String] {
        return [
            "Monitor component growth trends",
            "Track relationship density over time",
            "Watch for complexity accumulation in specific domains"
        ]
    }
    
    private func extractTopIssues(_ integrityReport: SystemIntegrityReport, _ antiPatterns: [AntiPatternDetection]) -> [String] {
        var issues: [String] = []
        
        // Add critical violations
        let criticalViolations = integrityReport.violations.filter { $0.severity == .error }.prefix(3)
        issues.append(contentsOf: criticalViolations.map { "🚨 \($0.violation.description)" })
        
        // Add high-severity anti-patterns
        let criticalAntiPatterns = antiPatterns.filter { $0.severity == .high }.prefix(2)
        issues.append(contentsOf: criticalAntiPatterns.map { "⚠️ \($0.description)" })
        
        return issues
    }
    
    private func generateQuickWins(_ patterns: [DetectedPattern], _ antiPatterns: [AntiPatternDetection], _ metrics: ComponentMetricsReport) -> [String] {
        var wins: [String] = []
        
        if patterns.count > metrics.totalComponents / 2 {
            wins.append("🎉 Good pattern adoption across the system")
        }
        
        if antiPatterns.filter({ $0.severity == .low }).count > 0 {
            wins.append("🔧 Several low-risk improvements available")
        }
        
        if metrics.complexityMetrics.averageComponentComplexity < 0.5 {
            wins.append("✨ Overall component complexity is well-managed")
        }
        
        return wins
    }
    
    // MARK: - Recommendation Generation Methods
    
    private func generatePerformanceRecommendations(_ metrics: ComponentMetricsReport, _ patterns: [DetectedPattern]) -> [ArchitecturalRecommendation] {
        var recommendations: [ArchitecturalRecommendation] = []
        
        // High coupling recommendation
        if !metrics.highlyCoupledComponents.isEmpty {
            recommendations.append(ArchitecturalRecommendation(
                id: "performance-reduce-coupling",
                type: .performance,
                title: "Reduce Component Coupling",
                description: "Several components have high coupling which may impact performance",
                rationale: "High coupling increases memory usage and reduces parallelization opportunities",
                priority: .high,
                confidence: 0.85,
                effort: .medium,
                benefits: ["Improved memory efficiency", "Better parallelization", "Faster state access"],
                risks: ["Refactoring effort", "Temporary complexity increase"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Identify coupling hotspots",
                        "Extract shared logic into utility components",
                        "Implement dependency injection",
                        "Update tests"
                    ],
                    testingStrategy: "Performance regression tests and coupling metrics validation",
                    rollbackPlan: "Maintain backward compatibility during transition"
                )
            ))
        }
        
        // Complex components recommendation
        if metrics.complexityMetrics.maxComponentComplexity > 0.8 {
            recommendations.append(ArchitecturalRecommendation(
                id: "performance-simplify-complex",
                type: .performance,
                title: "Simplify Complex Components",
                description: "High complexity components may have performance implications",
                rationale: "Complex components are harder to optimize and may have hidden performance bottlenecks",
                priority: .medium,
                confidence: 0.75,
                effort: .high,
                benefits: ["Better performance predictability", "Easier optimization", "Improved maintainability"],
                risks: ["Significant refactoring required", "Risk of introducing bugs"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Analyze complex components",
                        "Identify separation opportunities",
                        "Extract focused sub-components",
                        "Optimize individual parts"
                    ],
                    testingStrategy: "Comprehensive unit and integration testing",
                    rollbackPlan: "Gradual migration with feature flags"
                )
            ))
        }
        
        return recommendations
    }
    
    private func generateMaintainabilityRecommendations(_ antiPatterns: [AntiPatternDetection], _ integrityReport: SystemIntegrityReport) -> [ArchitecturalRecommendation] {
        var recommendations: [ArchitecturalRecommendation] = []
        
        // Anti-pattern recommendations
        let highSeverityAntiPatterns = antiPatterns.filter { $0.severity == .high }
        if !highSeverityAntiPatterns.isEmpty {
            recommendations.append(ArchitecturalRecommendation(
                id: "maintainability-fix-antipatterns",
                type: .maintainability,
                title: "Address Critical Anti-Patterns",
                description: "Critical anti-patterns detected that impact maintainability",
                rationale: "Anti-patterns make code harder to understand, modify, and extend",
                priority: .high,
                confidence: 0.9,
                effort: .medium,
                benefits: ["Improved code readability", "Easier modifications", "Reduced bug risk"],
                risks: ["Initial refactoring effort", "Potential disruption"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Prioritize anti-patterns by impact",
                        "Create refactoring plan",
                        "Implement fixes incrementally",
                        "Validate improvements"
                    ],
                    testingStrategy: "Regression testing and code quality metrics",
                    rollbackPlan: "Incremental changes with easy reversion"
                )
            ))
        }
        
        // Integrity violations
        if !integrityReport.violations.isEmpty {
            recommendations.append(ArchitecturalRecommendation(
                id: "maintainability-fix-violations",
                type: .maintainability,
                title: "Fix Architectural Violations",
                description: "Architectural integrity violations detected",
                rationale: "Violations compromise the architectural foundation and long-term maintainability",
                priority: .high,
                confidence: 0.95,
                effort: .medium,
                benefits: ["Stronger architectural foundation", "Predictable behavior", "Easier evolution"],
                risks: ["Some changes may require interface updates"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Review each violation",
                        "Plan corrective actions",
                        "Implement fixes systematically",
                        "Add validation to prevent recurrence"
                    ],
                    testingStrategy: "Architectural compliance testing",
                    rollbackPlan: "Violations are tracked for safe resolution"
                )
            ))
        }
        
        return recommendations
    }
    
    private func generateScalabilityRecommendations(_ metrics: ComponentMetricsReport, _ patterns: [DetectedPattern]) -> [ArchitecturalRecommendation] {
        var recommendations: [ArchitecturalRecommendation] = []
        
        // High relationship density
        if metrics.averageRelationshipsPerComponent > 5.0 {
            recommendations.append(ArchitecturalRecommendation(
                id: "scalability-reduce-relationships",
                type: .scalability,
                title: "Reduce Relationship Density",
                description: "High relationship density may limit scalability",
                rationale: "Dense relationships create bottlenecks and make horizontal scaling difficult",
                priority: .medium,
                confidence: 0.8,
                effort: .high,
                benefits: ["Better scalability", "Reduced dependencies", "Cleaner architecture"],
                risks: ["Complex refactoring", "Potential functionality gaps"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Map relationship bottlenecks",
                        "Design decoupling strategies",
                        "Implement message-based communication",
                        "Validate scalability improvements"
                    ],
                    testingStrategy: "Load testing and scalability validation",
                    rollbackPlan: "Maintain compatibility layers during transition"
                )
            ))
        }
        
        return recommendations
    }
    
    private func generateSecurityRecommendations(_ integrityReport: SystemIntegrityReport) -> [ArchitecturalRecommendation] {
        var recommendations: [ArchitecturalRecommendation] = []
        
        // Security-related violations
        let securityViolations = integrityReport.violations.filter { 
            $0.violation.description.lowercased().contains("security") ||
            $0.violation.description.lowercased().contains("access") ||
            $0.violation.description.lowercased().contains("permission")
        }
        
        if !securityViolations.isEmpty {
            recommendations.append(ArchitecturalRecommendation(
                id: "security-fix-violations",
                type: .security,
                title: "Address Security Violations",
                description: "Security-related architectural violations detected",
                rationale: "Security violations can lead to vulnerabilities and compliance issues",
                priority: .high,
                confidence: 0.9,
                effort: .medium,
                benefits: ["Improved security posture", "Compliance adherence", "Risk reduction"],
                risks: ["May require interface changes", "Potential access restrictions"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Audit security violations",
                        "Design security improvements",
                        "Implement access controls",
                        "Validate security measures"
                    ],
                    testingStrategy: "Security testing and penetration testing",
                    rollbackPlan: "Security changes require careful validation"
                )
            ))
        }
        
        return recommendations
    }
    
    private func generateGeneralRecommendations(
        _ metrics: ComponentMetricsReport,
        _ patterns: [DetectedPattern], 
        _ antiPatterns: [AntiPatternDetection],
        _ integrityReport: SystemIntegrityReport
    ) -> [ArchitecturalRecommendation] {
        var recommendations: [ArchitecturalRecommendation] = []
        
        // Combine recommendations from all categories
        recommendations.append(contentsOf: generatePerformanceRecommendations(metrics, patterns))
        recommendations.append(contentsOf: generateMaintainabilityRecommendations(antiPatterns, integrityReport))
        recommendations.append(contentsOf: generateScalabilityRecommendations(metrics, patterns))
        recommendations.append(contentsOf: generateSecurityRecommendations(integrityReport))
        
        // General system health recommendation
        if integrityReport.overallScore < 0.8 {
            recommendations.append(ArchitecturalRecommendation(
                id: "general-improve-health",
                type: .general,
                title: "Improve Overall System Health",
                description: "System health score indicates room for improvement",
                rationale: "Low system health affects development velocity and system reliability",
                priority: .medium,
                confidence: 0.7,
                effort: .medium,
                benefits: ["Better development experience", "Improved reliability", "Easier maintenance"],
                risks: ["Requires coordinated effort", "Multiple changes needed"],
                implementation: ImplementationGuidance(
                    steps: [
                        "Identify top health issues",
                        "Create improvement roadmap",
                        "Implement changes incrementally",
                        "Monitor health improvements"
                    ],
                    testingStrategy: "Comprehensive system health monitoring",
                    rollbackPlan: "Health improvements are generally safe"
                )
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

/// Configuration for query engine behavior
public struct QueryEngineConfiguration: Sendable {
    public let minimumConfidenceThreshold: Double
    public let enableCaching: Bool
    public let enableLearning: Bool
    public let maxCacheSize: Int
    public let enableAdvancedAnalysis: Bool
    
    public init(
        minimumConfidenceThreshold: Double = 0.6,
        enableCaching: Bool = true,
        enableLearning: Bool = true,
        maxCacheSize: Int = 1000,
        enableAdvancedAnalysis: Bool = true
    ) {
        self.minimumConfidenceThreshold = max(0.0, min(1.0, minimumConfidenceThreshold))
        self.enableCaching = enableCaching
        self.enableLearning = enableLearning
        self.maxCacheSize = max(10, maxCacheSize)
        self.enableAdvancedAnalysis = enableAdvancedAnalysis
    }
}

/// Response from query processing
public struct QueryResponse: Sendable {
    public let query: String
    public let intent: QueryIntent
    public let answer: String
    public let data: [String: Any]
    public let confidence: Double
    public let executionTime: TimeInterval
    public let suggestions: [String]
    public let respondedAt: Date
    
    public init(
        query: String,
        intent: QueryIntent,
        answer: String,
        data: [String: Any],
        confidence: Double,
        executionTime: TimeInterval,
        suggestions: [String],
        respondedAt: Date
    ) {
        self.query = query
        self.intent = intent
        self.answer = answer
        self.data = data
        self.confidence = confidence
        self.executionTime = executionTime
        self.suggestions = suggestions
        self.respondedAt = respondedAt
    }
}

/// Cached query response
private struct CachedResponse {
    let response: QueryResponse
    let timestamp: Date
    
    func isExpired(timeout: TimeInterval) -> Bool {
        return Date().timeIntervalSince(timestamp) > timeout
    }
}

/// Detailed component explanation
public struct ComponentExplanation: Sendable {
    public let componentID: ComponentID
    public let name: String
    public let category: ComponentCategory
    public let detailedDescription: String
    public let purpose: ComponentPurpose?
    public let architecture: ArchitectureDocumentation?
    public let relationships: [AnalyzedRelationship]
    public let patterns: [DetectedPattern]
    public let qualityMetrics: ComponentQualityMetrics
    public let recommendations: [String]
    public let explainedAt: Date
    
    public init(
        componentID: ComponentID,
        name: String,
        category: ComponentCategory,
        detailedDescription: String,
        purpose: ComponentPurpose?,
        architecture: ArchitectureDocumentation?,
        relationships: [AnalyzedRelationship],
        patterns: [DetectedPattern],
        qualityMetrics: ComponentQualityMetrics,
        recommendations: [String],
        explainedAt: Date
    ) {
        self.componentID = componentID
        self.name = name
        self.category = category
        self.detailedDescription = detailedDescription
        self.purpose = purpose
        self.architecture = architecture
        self.relationships = relationships
        self.patterns = patterns
        self.qualityMetrics = qualityMetrics
        self.recommendations = recommendations
        self.explainedAt = explainedAt
    }
}

/// Component quality metrics
public struct ComponentQualityMetrics: Sendable {
    public let overallScore: Double
    public let complexity: Double
    public let coupling: Double
    public let cohesion: Double
    
    public init(overallScore: Double, complexity: Double, coupling: Double, cohesion: Double) {
        self.overallScore = overallScore
        self.complexity = complexity
        self.coupling = coupling
        self.cohesion = cohesion
    }
}

/// Impact analysis result
public struct ImpactAnalysis: Sendable {
    public let change: String
    public let systemImpact: SystemImpactAnalysis
    public let patternImpact: PatternImpactAnalysis
    public let riskAssessment: RiskAssessment
    public let recommendations: [String]
    public let timelineEstimate: TimelineEstimate
    public let analyzedAt: Date
    
    public init(
        change: String,
        systemImpact: SystemImpactAnalysis,
        patternImpact: PatternImpactAnalysis,
        riskAssessment: RiskAssessment,
        recommendations: [String],
        timelineEstimate: TimelineEstimate,
        analyzedAt: Date
    ) {
        self.change = change
        self.systemImpact = systemImpact
        self.patternImpact = patternImpact
        self.riskAssessment = riskAssessment
        self.recommendations = recommendations
        self.timelineEstimate = timelineEstimate
        self.analyzedAt = analyzedAt
    }
}

/// System overview information
public struct SystemOverview: Sendable {
    public let totalComponents: Int
    public let totalRelationships: Int
    public let componentDistribution: [ComponentCategory: Int]
    public let layerDistribution: [ArchitecturalLayer: Int]
    public let patternCount: Int
    public let antiPatternCount: Int
    public let integrityScore: Double
    public let healthScore: Double
    public let topIssues: [String]
    public let quickWins: [String]
    public let generatedAt: Date
    
    public init(
        totalComponents: Int,
        totalRelationships: Int,
        componentDistribution: [ComponentCategory: Int],
        layerDistribution: [ArchitecturalLayer: Int],
        patternCount: Int,
        antiPatternCount: Int,
        integrityScore: Double,
        healthScore: Double,
        topIssues: [String],
        quickWins: [String],
        generatedAt: Date
    ) {
        self.totalComponents = totalComponents
        self.totalRelationships = totalRelationships
        self.componentDistribution = componentDistribution
        self.layerDistribution = layerDistribution
        self.patternCount = patternCount
        self.antiPatternCount = antiPatternCount
        self.integrityScore = integrityScore
        self.healthScore = healthScore
        self.topIssues = topIssues
        self.quickWins = quickWins
        self.generatedAt = generatedAt
    }
}

/// Query engine errors
public enum QueryEngineError: Error, CustomStringConvertible {
    case lowConfidenceQuery(Double)
    case unknownIntent(QueryIntent)
    case missingParameter(String)
    case componentNotFound(String)
    case processingFailure(String)
    case invalidQuery(String)
    
    public var description: String {
        switch self {
        case .lowConfidenceQuery(let confidence):
            return "Query confidence too low: \(String(format: "%.1f", confidence * 100))%"
        case .unknownIntent(let intent):
            return "Unknown query intent: \(intent.rawValue)"
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .componentNotFound(let name):
            return "Component not found: \(name)"
        case .processingFailure(let reason):
            return "Query processing failed: \(reason)"
        case .invalidQuery(let query):
            return "Invalid query: \(query)"
        }
    }
}

/// Pattern impact analysis result
public struct PatternImpactAnalysis: Sendable {
    public let affectedPatterns: Int
    public let impacts: [PatternImpact]
    public let overallRisk: RiskLevel
    public let recommendations: [String]
    
    public init(affectedPatterns: Int, impacts: [PatternImpact], overallRisk: RiskLevel, recommendations: [String]) {
        self.affectedPatterns = affectedPatterns
        self.impacts = impacts
        self.overallRisk = overallRisk
        self.recommendations = recommendations
    }
}

/// Impact of a change on a specific pattern
public struct PatternImpact: Sendable {
    public let pattern: DetectedPattern
    public let severity: ImpactSeverity
    public let description: String
    public let mitigations: [String]
    
    public init(pattern: DetectedPattern, severity: ImpactSeverity, description: String, mitigations: [String]) {
        self.pattern = pattern
        self.severity = severity
        self.description = description
        self.mitigations = mitigations
    }
}

/// Risk assessment for architectural changes
public struct RiskAssessment: Sendable {
    public let overallRisk: RiskLevel
    public let identifiedRisks: [IdentifiedRisk]
    public let mitigationStrategies: [String]
    public let riskScore: Double
    public let assessedAt: Date
    
    public init(overallRisk: RiskLevel, identifiedRisks: [IdentifiedRisk], mitigationStrategies: [String], riskScore: Double, assessedAt: Date) {
        self.overallRisk = overallRisk
        self.identifiedRisks = identifiedRisks
        self.mitigationStrategies = mitigationStrategies
        self.riskScore = riskScore
        self.assessedAt = assessedAt
    }
}

/// Specific risk identified during assessment
public struct IdentifiedRisk: Sendable {
    public let type: RiskType
    public let probability: Probability
    public let impact: ImpactLevel
    public let description: String
    public let mitigation: String
    
    public init(type: RiskType, probability: Probability, impact: ImpactLevel, description: String, mitigation: String) {
        self.type = type
        self.probability = probability
        self.impact = impact
        self.description = description
        self.mitigation = mitigation
    }
}

/// Timeline estimation for implementation
public struct TimelineEstimate: Sendable {
    public let estimatedHours: Double
    public let estimatedDays: Double
    public let confidence: Double
    public let factors: [String]
    
    public init(estimatedHours: Double, estimatedDays: Double, confidence: Double, factors: [String]) {
        self.estimatedHours = estimatedHours
        self.estimatedDays = estimatedDays
        self.confidence = confidence
        self.factors = factors
    }
}

/// Domain-specific metrics
public struct DomainMetrics: Sendable {
    public let componentCount: Int
    public let averageComplexity: Double
    public let relationshipDensity: Double
    public let patternAdoption: Double
    
    public init(componentCount: Int, averageComplexity: Double, relationshipDensity: Double, patternAdoption: Double) {
        self.componentCount = componentCount
        self.averageComplexity = averageComplexity
        self.relationshipDensity = relationshipDensity
        self.patternAdoption = patternAdoption
    }
}

/// Complexity analysis result
public struct ComplexityAnalysis: Sendable {
    public let overallScore: Double
    public let componentScores: ComplexityMetrics
    public let relationshipComplexity: Double
    public let patternComplexity: Double
    public let recommendations: [String]
    public let trends: [String]
    
    public init(overallScore: Double, componentScores: ComplexityMetrics, relationshipComplexity: Double, patternComplexity: Double, recommendations: [String], trends: [String]) {
        self.overallScore = overallScore
        self.componentScores = componentScores
        self.relationshipComplexity = relationshipComplexity
        self.patternComplexity = patternComplexity
        self.recommendations = recommendations
        self.trends = trends
    }
}

/// Complexity report for system or domain
public struct ComplexityReport: Sendable {
    public let domain: String?
    public let overallComplexity: Double
    public let componentComplexity: ComplexityMetrics
    public let relationshipComplexity: Double
    public let patternComplexity: Double
    public let recommendations: [String]
    public let trends: [String]
    public let generatedAt: Date
    
    public init(domain: String?, overallComplexity: Double, componentComplexity: ComplexityMetrics, relationshipComplexity: Double, patternComplexity: Double, recommendations: [String], trends: [String], generatedAt: Date) {
        self.domain = domain
        self.overallComplexity = overallComplexity
        self.componentComplexity = componentComplexity
        self.relationshipComplexity = relationshipComplexity
        self.patternComplexity = patternComplexity
        self.recommendations = recommendations
        self.trends = trends
        self.generatedAt = generatedAt
    }
}

/// Recommendation context for generating suggestions
public struct RecommendationContext: Sendable {
    public let type: RecommendationType
    public let scope: RecommendationScope
    public let priority: Priority
    public let constraints: [String]
    
    public init(type: RecommendationType, scope: RecommendationScope, priority: Priority, constraints: [String] = []) {
        self.type = type
        self.scope = scope
        self.priority = priority
        self.constraints = constraints
    }
}

/// Architectural recommendation
public struct ArchitecturalRecommendation: Sendable {
    public let id: String
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let rationale: String
    public let priority: Priority
    public let confidence: Double
    public let effort: EffortLevel
    public let benefits: [String]
    public let risks: [String]
    public let implementation: ImplementationGuidance
    
    public init(id: String, type: RecommendationType, title: String, description: String, rationale: String, priority: Priority, confidence: Double, effort: EffortLevel, benefits: [String], risks: [String], implementation: ImplementationGuidance) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.rationale = rationale
        self.priority = priority
        self.confidence = confidence
        self.effort = effort
        self.benefits = benefits
        self.risks = risks
        self.implementation = implementation
    }
}

/// Implementation guidance for recommendations
public struct ImplementationGuidance: Sendable {
    public let steps: [String]
    public let codeExamples: [String]
    public let testingStrategy: String
    public let rollbackPlan: String
    
    public init(steps: [String], codeExamples: [String] = [], testingStrategy: String, rollbackPlan: String) {
        self.steps = steps
        self.codeExamples = codeExamples
        self.testingStrategy = testingStrategy
        self.rollbackPlan = rollbackPlan
    }
}

/// Change details parsed from description
public struct ChangeDetails: Sendable {
    public let targetComponent: ComponentID
    public let changeType: ChangeType
    public let scope: ChangeScope
    public let rationale: String
    
    public init(targetComponent: ComponentID, changeType: ChangeType, scope: ChangeScope, rationale: String) {
        self.targetComponent = targetComponent
        self.changeType = changeType
        self.scope = scope
        self.rationale = rationale
    }
}

/// Types of recommendations
public enum RecommendationType: String, CaseIterable, Sendable {
    case performance = "performance"
    case maintainability = "maintainability"
    case scalability = "scalability"
    case security = "security"
    case testing = "testing"
    case documentation = "documentation"
    case architecture = "architecture"
    case general = "general"
}

/// Scope of recommendations
public enum RecommendationScope: String, CaseIterable, Sendable {
    case component = "component"
    case module = "module"
    case layer = "layer"
    case system = "system"
}

/// Types of risks
public enum RiskType: String, CaseIterable, Sendable {
    case systemStability = "system_stability"
    case developmentComplexity = "development_complexity"
    case performanceRegression = "performance_regression"
    case securityVulnerability = "security_vulnerability"
    case dataLoss = "data_loss"
    case userExperience = "user_experience"
    case maintainability = "maintainability"
}

/// Probability levels
public enum Probability: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case certain = "certain"
}

/// Impact severity levels
public enum ImpactSeverity: String, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Global Query Engine

/// Global shared query engine
public actor GlobalQueryEngine {
    public static let shared = GlobalQueryEngine()
    
    private var engine: ArchitecturalQueryEngine?
    
    private init() {
        // Engine will be lazily initialized when first accessed
    }
    
    public func getEngine() async -> ArchitecturalQueryEngine {
        if let engine = engine {
            return engine
        }
        
        let introspectionEngine = await GlobalIntrospectionEngine.shared.getEngine()
        let patternDetectionEngine = await GlobalPatternDetectionEngine.shared.getEngine()
        let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
        let queryParser = await GlobalQueryParser.shared.getParser()
        
        let newEngine = ArchitecturalQueryEngine(
            introspectionEngine: introspectionEngine,
            patternDetectionEngine: patternDetectionEngine,
            performanceMonitor: performanceMonitor,
            queryParser: queryParser
        )
        self.engine = newEngine
        return newEngine
    }
}

// MARK: - String Extension for Regex Matching

extension String {
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch {
            return []
        }
    }
}