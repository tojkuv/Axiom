import XCTest
@testable import Axiom

/// Comprehensive tests for the Architectural Query Engine
final class QueryEngineTests: XCTestCase {
    
    // MARK: Test Properties
    
    private var queryEngine: ArchitecturalQueryEngine!
    private var mockIntrospectionEngine: MockComponentIntrospectionEngine!
    private var mockPatternDetectionEngine: MockPatternDetectionEngine!
    private var mockPerformanceMonitor: MockPerformanceMonitor!
    private var mockQueryParser: MockNaturalLanguageQueryParser!
    
    // MARK: Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockIntrospectionEngine = MockComponentIntrospectionEngine()
        mockPatternDetectionEngine = MockPatternDetectionEngine()
        mockPerformanceMonitor = MockPerformanceMonitor()
        mockQueryParser = MockNaturalLanguageQueryParser()
        
        queryEngine = ArchitecturalQueryEngine(
            introspectionEngine: mockIntrospectionEngine,
            patternDetectionEngine: mockPatternDetectionEngine,
            performanceMonitor: mockPerformanceMonitor,
            queryParser: mockQueryParser,
            configuration: QueryEngineConfiguration(
                minimumConfidenceThreshold: 0.5,
                enableCaching: true,
                enableLearning: true
            )
        )
    }
    
    override func tearDown() async throws {
        queryEngine = nil
        mockIntrospectionEngine = nil
        mockPatternDetectionEngine = nil
        mockPerformanceMonitor = nil
        mockQueryParser = nil
        try await super.tearDown()
    }
    
    // MARK: Query Processing Tests
    
    func testProcessDescribeComponentQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "What is the UserManager component?",
            normalizedQuery: "what is userManager component",
            intent: .describeComponent,
            parameters: ["componentName": "UserManager"],
            entities: [Entity(type: .componentName, value: "UserManager", confidence: 0.9)],
            confidence: 0.85,
            parsedAt: Date()
        )
        
        let mockComponent = IntrospectedComponent(
            id: ComponentID("UserManager"),
            name: "UserManager",
            category: .client,
            type: "actor UserManager",
            architecturalDNA: createMockArchitecturalDNA()
        )
        
        mockIntrospectionEngine.mockComponents = [mockComponent]
        mockIntrospectionEngine.mockAnalysis = createMockComponentAnalysis(for: mockComponent)
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .describeComponent)
        XCTAssertEqual(response.confidence, 0.85)
        XCTAssertTrue(response.answer.contains("UserManager"))
        XCTAssertTrue(response.answer.contains("Client"))
        XCTAssertNotNil(response.data["component"])
        XCTAssertNotNil(response.data["explanation"])
        XCTAssertFalse(response.suggestions.isEmpty)
    }
    
    func testProcessListComponentsQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Show me all client components",
            normalizedQuery: "show me all client components",
            intent: .listComponents,
            parameters: ["componentType": "client"],
            entities: [Entity(type: .componentType, value: "client", confidence: 0.8)],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        let mockComponents = [
            IntrospectedComponent(id: ComponentID("UserManager"), name: "UserManager", category: .client, type: "actor"),
            IntrospectedComponent(id: ComponentID("OrderManager"), name: "OrderManager", category: .client, type: "actor"),
            IntrospectedComponent(id: ComponentID("UserView"), name: "UserView", category: .view, type: "struct")
        ]
        
        mockIntrospectionEngine.mockComponents = mockComponents
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .listComponents)
        XCTAssertTrue(response.answer.contains("2 components"))
        XCTAssertTrue(response.answer.contains("UserManager"))
        XCTAssertTrue(response.answer.contains("OrderManager"))
        XCTAssertFalse(response.answer.contains("UserView")) // Should be filtered out
        
        if let components = response.data["components"] as? [IntrospectedComponent] {
            XCTAssertEqual(components.count, 2)
            XCTAssertTrue(components.allSatisfy { $0.category == .client })
        } else {
            XCTFail("Components not found in response data")
        }
    }
    
    func testProcessCountComponentsQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "How many components are there?",
            normalizedQuery: "how many components are there",
            intent: .countComponents,
            parameters: [:],
            entities: [],
            confidence: 0.95,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .countComponents)
        XCTAssertTrue(response.answer.contains("5 components"))
        XCTAssertTrue(response.answer.contains("Client: 2"))
        XCTAssertTrue(response.answer.contains("View: 2"))
        XCTAssertTrue(response.answer.contains("Context: 1"))
    }
    
    func testProcessDetectPatternsQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "What patterns do you detect?",
            normalizedQuery: "what patterns do you detect",
            intent: .detectPatterns,
            parameters: [:],
            entities: [],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        let mockPatterns = [
            DetectedPattern(
                type: .actorConcurrency,
                name: "Actor Concurrency Pattern",
                description: "Thread-safe actor implementation",
                components: [ComponentID("UserManager")],
                confidence: 0.95,
                evidence: ["Actor-based implementation"],
                location: PatternLocation(componentID: ComponentID("UserManager")),
                detectedAt: Date()
            )
        ]
        
        mockPatternDetectionEngine.mockPatterns = mockPatterns
        mockPatternDetectionEngine.mockPatternStats = createMockPatternStatistics()
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .detectPatterns)
        XCTAssertTrue(response.answer.contains("Actor Concurrency Pattern"))
        XCTAssertTrue(response.answer.contains("95% confidence"))
        XCTAssertNotNil(response.data["patterns"])
        XCTAssertNotNil(response.data["statistics"])
    }
    
    func testProcessValidateArchitectureQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Validate the architecture",
            normalizedQuery: "validate architecture",
            intent: .validateArchitecture,
            parameters: [:],
            entities: [],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockIntegrityReport = createMockIntegrityReport()
        mockPatternDetectionEngine.mockPatternCompliance = createMockPatternComplianceReport()
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .validateArchitecture)
        XCTAssertTrue(response.answer.contains("VALID") || response.answer.contains("ISSUES"))
        XCTAssertTrue(response.answer.contains("90.0%")) // Integrity score
        XCTAssertNotNil(response.data["integrityReport"])
        XCTAssertNotNil(response.data["patternCompliance"])
    }
    
    // MARK: Component Explanation Tests
    
    func testExplainComponent() async throws {
        // Given
        let componentID = ComponentID("UserManager")
        let mockComponent = IntrospectedComponent(
            id: componentID,
            name: "UserManager",
            category: .client,
            type: "actor UserManager",
            architecturalDNA: createMockArchitecturalDNA()
        )
        
        mockIntrospectionEngine.mockAnalysis = createMockComponentAnalysis(for: mockComponent)
        mockIntrospectionEngine.mockDocumentation = createMockDocumentationSet(for: mockComponent)
        mockPatternDetectionEngine.mockPatterns = [
            DetectedPattern(
                type: .actorConcurrency,
                name: "Actor Pattern",
                description: "Thread-safe implementation",
                components: [componentID],
                confidence: 0.9,
                evidence: ["Actor implementation"],
                location: PatternLocation(componentID: componentID),
                detectedAt: Date()
            )
        ]
        
        // When
        let explanation = try await queryEngine.explainComponent(componentID)
        
        // Then
        XCTAssertEqual(explanation.componentID, componentID)
        XCTAssertEqual(explanation.name, "UserManager")
        XCTAssertEqual(explanation.category, .client)
        XCTAssertTrue(explanation.detailedDescription.contains("UserManager"))
        XCTAssertTrue(explanation.detailedDescription.contains("Client"))
        XCTAssertEqual(explanation.patterns.count, 1)
        XCTAssertFalse(explanation.recommendations.isEmpty)
    }
    
    // MARK: Impact Analysis Tests
    
    func testAnalyzeImpact() async throws {
        // Given
        let changeDescription = "Update UserManager interface to support async operations"
        
        mockIntrospectionEngine.mockSystemImpactAnalysis = createMockSystemImpactAnalysis()
        
        // When
        let impact = try await queryEngine.analyzeImpact(of: changeDescription)
        
        // Then
        XCTAssertEqual(impact.change, changeDescription)
        XCTAssertNotNil(impact.systemImpact)
        XCTAssertNotNil(impact.riskAssessment)
        XCTAssertFalse(impact.recommendations.isEmpty)
        XCTAssertNotNil(impact.timelineEstimate)
    }
    
    // MARK: Complexity Report Tests
    
    func testGenerateComplexityReport() async throws {
        // Given
        let domain: String? = nil // System-wide report
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockPatternDetectionEngine.mockPatternStats = createMockPatternStatistics()
        mockPatternDetectionEngine.mockAntiPatterns = createMockAntiPatterns()
        
        // When
        let report = try await queryEngine.generateComplexityReport(for: domain)
        
        // Then
        XCTAssertNil(report.domain)
        XCTAssertGreaterThan(report.overallComplexity, 0)
        XCTAssertFalse(report.componentComplexity.isEmpty)
        XCTAssertGreaterThan(report.relationshipComplexity, 0)
        XCTAssertFalse(report.recommendations.isEmpty)
    }
    
    func testGenerateComplexityReportForDomain() async throws {
        // Given
        let domain = "User Management"
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockPatternDetectionEngine.mockPatternStats = createMockPatternStatistics()
        mockPatternDetectionEngine.mockAntiPatterns = []
        
        // When
        let report = try await queryEngine.generateComplexityReport(for: domain)
        
        // Then
        XCTAssertEqual(report.domain, domain)
        XCTAssertGreaterThan(report.overallComplexity, 0)
    }
    
    // MARK: Recommendations Tests
    
    func testGeneratePerformanceRecommendations() async throws {
        // Given
        let context = RecommendationContext(
            type: .performance,
            scope: .system,
            priority: .high,
            constraints: ["Improve response time", "Reduce memory usage"]
        )
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockPatternDetectionEngine.mockPatterns = []
        mockPatternDetectionEngine.mockAntiPatterns = []
        mockIntrospectionEngine.mockIntegrityReport = createMockIntegrityReport()
        
        // When
        let recommendations = try await queryEngine.generateRecommendations(for: context)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertTrue(recommendations.allSatisfy { $0.type == .performance })
        
        // Verify recommendations are sorted by priority and confidence
        for i in 0..<(recommendations.count - 1) {
            let current = recommendations[i]
            let next = recommendations[i + 1]
            XCTAssertTrue(
                current.priority.rawValue >= next.priority.rawValue ||
                (current.priority == next.priority && current.confidence >= next.confidence)
            )
        }
    }
    
    // MARK: System Overview Tests
    
    func testGetSystemOverview() async throws {
        // Given
        mockIntrospectionEngine.mockComponents = createMockComponents()
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockIntrospectionEngine.mockRelationshipMap = createMockRelationshipMap()
        mockPatternDetectionEngine.mockPatterns = []
        mockPatternDetectionEngine.mockAntiPatterns = []
        mockIntrospectionEngine.mockIntegrityReport = createMockIntegrityReport()
        
        // When
        let overview = try await queryEngine.getSystemOverview()
        
        // Then
        XCTAssertEqual(overview.totalComponents, 5)
        XCTAssertEqual(overview.totalRelationships, 8)
        XCTAssertFalse(overview.componentDistribution.isEmpty)
        XCTAssertFalse(overview.layerDistribution.isEmpty)
        XCTAssertGreaterThanOrEqual(overview.healthScore, 0)
        XCTAssertLessThanOrEqual(overview.healthScore, 1)
        XCTAssertGreaterThanOrEqual(overview.integrityScore, 0)
        XCTAssertLessThanOrEqual(overview.integrityScore, 1)
    }
    
    // MARK: Error Handling Tests
    
    func testProcessQueryWithLowConfidence() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Something unclear",
            normalizedQuery: "something unclear",
            intent: .unknown,
            parameters: [:],
            entities: [],
            confidence: 0.3, // Below threshold
            parsedAt: Date()
        )
        
        // When & Then
        do {
            _ = try await queryEngine.processQuery(parsedQuery)
            XCTFail("Expected QueryEngineError.lowConfidenceQuery")
        } catch QueryEngineError.lowConfidenceQuery(let confidence) {
            XCTAssertEqual(confidence, 0.3)
        }
    }
    
    func testProcessQueryWithMissingParameter() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "What is the component?",
            normalizedQuery: "what is component",
            intent: .describeComponent,
            parameters: [:], // Missing componentName
            entities: [],
            confidence: 0.8,
            parsedAt: Date()
        )
        
        // When & Then
        do {
            _ = try await queryEngine.processQuery(parsedQuery)
            XCTFail("Expected QueryEngineError.missingParameter")
        } catch QueryEngineError.missingParameter(let param) {
            XCTAssertEqual(param, "componentName")
        }
    }
    
    func testProcessQueryWithComponentNotFound() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "What is the NonExistentComponent?",
            normalizedQuery: "what is nonexistentcomponent",
            intent: .describeComponent,
            parameters: ["componentName": "NonExistentComponent"],
            entities: [],
            confidence: 0.8,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockComponents = [] // Empty components
        
        // When & Then
        do {
            _ = try await queryEngine.processQuery(parsedQuery)
            XCTFail("Expected QueryEngineError.componentNotFound")
        } catch QueryEngineError.componentNotFound(let name) {
            XCTAssertEqual(name, "NonExistentComponent")
        }
    }
    
    // MARK: Caching Tests
    
    func testQueryCaching() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "How many components are there?",
            normalizedQuery: "how many components are there",
            intent: .countComponents,
            parameters: [:],
            entities: [],
            confidence: 0.95,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        
        // When - First query
        let response1 = try await queryEngine.processQuery(parsedQuery)
        
        // When - Second identical query (should be cached)
        let response2 = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response1.answer, response2.answer)
        XCTAssertEqual(response1.confidence, response2.confidence)
        // Second query should be faster due to caching
        XCTAssertLessThanOrEqual(response2.executionTime, response1.executionTime)
    }
    
    // MARK: Additional Query Processing Tests
    
    func testProcessFindDependenciesQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "What components depend on UserManager?",
            normalizedQuery: "what components depend on usermanager",
            intent: .findDependencies,
            parameters: ["componentName": "UserManager"],
            entities: [Entity(type: .componentName, value: "UserManager", confidence: 0.9)],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        let userManager = IntrospectedComponent(id: ComponentID("UserManager"), name: "UserManager", category: .client, type: "actor")
        let orderView = IntrospectedComponent(id: ComponentID("OrderView"), name: "OrderView", category: .view, type: "struct")
        
        mockIntrospectionEngine.mockComponents = [userManager, orderView]
        
        var relationshipMap = ComponentRelationshipMap()
        relationshipMap.addRelationship(AnalyzedRelationship(
            source: ComponentID("OrderView"),
            target: ComponentID("UserManager"),
            type: .dependsOn,
            strength: 1.0,
            isRequired: true,
            communicationPattern: .synchronous
        ))
        mockIntrospectionEngine.mockRelationshipMap = relationshipMap
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .findDependencies)
        XCTAssertTrue(response.answer.contains("UserManager"))
        XCTAssertTrue(response.answer.contains("OrderView"))
        XCTAssertNotNil(response.data["sourceComponent"])
        XCTAssertNotNil(response.data["dependentComponents"])
    }
    
    func testProcessHelpQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Help me understand the query system",
            normalizedQuery: "help me understand query system",
            intent: .help,
            parameters: [:],
            entities: [],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .help)
        XCTAssertTrue(response.answer.contains("Axiom Intelligence"))
        XCTAssertTrue(response.answer.contains("What I Can Help You With"))
        XCTAssertNotNil(response.data["help"])
        XCTAssertFalse(response.suggestions.isEmpty)
    }
    
    func testProcessGetOverviewQuery() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Show me the system overview",
            normalizedQuery: "show me system overview",
            intent: .getOverview,
            parameters: [:],
            entities: [],
            confidence: 0.95,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockComponents = createMockComponents()
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockIntrospectionEngine.mockRelationshipMap = createMockRelationshipMap()
        mockPatternDetectionEngine.mockPatterns = []
        mockPatternDetectionEngine.mockAntiPatterns = []
        mockIntrospectionEngine.mockIntegrityReport = createMockIntegrityReport()
        
        // When
        let response = try await queryEngine.processQuery(parsedQuery)
        
        // Then
        XCTAssertEqual(response.intent, .getOverview)
        XCTAssertTrue(response.answer.contains("System Overview"))
        XCTAssertTrue(response.answer.contains("Total Components"))
        XCTAssertNotNil(response.data["overview"])
        XCTAssertFalse(response.suggestions.isEmpty)
    }
    
    func testImpactAnalysisWithPatternImpact() async throws {
        // Given
        let changeDescription = "Refactor UserManager to split user data and preferences"
        
        mockIntrospectionEngine.mockSystemImpactAnalysis = createMockSystemImpactAnalysis()
        mockPatternDetectionEngine.mockPatterns = [
            DetectedPattern(
                type: .actorConcurrency,
                name: "Actor Pattern",
                description: "Thread-safe implementation",
                components: [ComponentID("UserManager")],
                confidence: 0.9,
                evidence: ["Actor implementation"],
                location: PatternLocation(componentID: ComponentID("UserManager")),
                detectedAt: Date()
            )
        ]
        
        // When
        let impact = try await queryEngine.analyzeImpact(of: changeDescription)
        
        // Then
        XCTAssertEqual(impact.change, changeDescription)
        XCTAssertNotNil(impact.patternImpact)
        XCTAssertGreaterThan(impact.patternImpact.affectedPatterns, 0)
        XCTAssertFalse(impact.patternImpact.impacts.isEmpty)
        XCTAssertNotNil(impact.riskAssessment)
        XCTAssertFalse(impact.recommendations.isEmpty)
    }
    
    func testGenerateRecommendationsForDifferentTypes() async throws {
        // Given - Maintainability recommendations
        let maintainabilityContext = RecommendationContext(
            type: .maintainability,
            scope: .system,
            priority: .high
        )
        
        mockIntrospectionEngine.mockMetrics = createMockComponentMetrics()
        mockPatternDetectionEngine.mockPatterns = []
        mockPatternDetectionEngine.mockAntiPatterns = [
            AntiPatternDetection(
                type: .godObject,
                componentID: ComponentID("ComplexManager"),
                description: "Component has too many responsibilities",
                severity: .high,
                impact: "Reduces maintainability",
                recommendation: "Split into focused components"
            )
        ]
        mockIntrospectionEngine.mockIntegrityReport = SystemIntegrityReport(
            isValid: false,
            overallScore: 0.7,
            violations: [
                SystemIntegrityViolation(
                    component: ComponentID("TestComponent"),
                    violation: ConstraintViolation(
                        constraint: ArchitecturalConstraint(type: .actorSafety, description: "Test violation", rule: .required),
                        description: "Test violation",
                        severity: .error
                    ),
                    severity: .error
                )
            ],
            warnings: [],
            componentCount: 5,
            validatedAt: Date()
        )
        
        // When
        let recommendations = try await queryEngine.generateRecommendations(for: maintainabilityContext)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertTrue(recommendations.allSatisfy { $0.type == .maintainability })
        
        // Should have recommendations for anti-patterns and violations
        XCTAssertTrue(recommendations.contains { $0.title.contains("Anti-Patterns") })
        XCTAssertTrue(recommendations.contains { $0.title.contains("Violations") })
    }
    
    // MARK: Performance Tests
    
    func testQueryProcessingPerformance() async throws {
        // Given
        let parsedQuery = ParsedQuery(
            originalQuery: "Show me all components",
            normalizedQuery: "show me all components",
            intent: .listComponents,
            parameters: [:],
            entities: [],
            confidence: 0.9,
            parsedAt: Date()
        )
        
        mockIntrospectionEngine.mockComponents = createMockComponents()
        
        // When
        let startTime = Date()
        _ = try await queryEngine.processQuery(parsedQuery)
        let endTime = Date()
        
        // Then
        let executionTime = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
    }
    
    // MARK: Mock Creation Helpers
    
    private func createMockArchitecturalDNA() -> ArchitecturalDNA {
        return TestArchitecturalDNA(
            componentId: ComponentID("UserManager"),
            purpose: ComponentPurpose(
                description: "Manages user data and authentication",
                businessValue: .essential,
                userImpact: .high
            ),
            constraints: [
                ArchitecturalConstraint(
                    type: .actorSafety,
                    description: "Must use actor for thread safety",
                    rule: .required
                )
            ],
            relationships: [],
            requiredCapabilities: [.stateManagement, .authentication],
            providedCapabilities: [.userManagement],
            performanceProfile: PerformanceProfile(
                latency: LatencyProfile(typical: 0.050, maximum: 0.200),
                throughput: ThroughputProfile(typical: 1000, maximum: 5000),
                memory: MemoryProfile(typical: 1024, maximum: 4096)
            ),
            qualityAttributes: QualityAttributes(overallScore: 0.85)
        )
    }
    
    private func createMockComponentAnalysis(for component: IntrospectedComponent) -> ComponentAnalysis {
        return ComponentAnalysis(
            component: component,
            relationships: [],
            constraints: component.architecturalDNA?.constraints ?? [],
            capabilities: ComponentCapabilityAnalysis(
                required: component.architecturalDNA?.requiredCapabilities ?? [],
                provided: component.architecturalDNA?.providedCapabilities ?? []
            ),
            complexity: 0.3,
            qualityScore: 0.85,
            analyzedAt: Date()
        )
    }
    
    private func createMockComponentMetrics() -> ComponentMetricsReport {
        return ComponentMetricsReport(
            totalComponents: 5,
            totalRelationships: 8,
            averageRelationshipsPerComponent: 1.6,
            categoryDistribution: [
                .client: 2,
                .view: 2,
                .context: 1
            ],
            layerDistribution: [
                .application: 3,
                .presentation: 2
            ],
            highlyCoupledComponents: [],
            complexityMetrics: ComplexityMetrics(
                averageComponentComplexity: 0.4,
                systemCouplingIndex: 1.6,
                maxComponentComplexity: 0.8
            ),
            generatedAt: Date()
        )
    }
    
    private func createMockPatternStatistics() -> PatternStatistics {
        return PatternStatistics(
            totalPatternsDetected: 3,
            patternDistribution: [
                .actorConcurrency: 2,
                .viewContextBinding: 1
            ],
            averageCompliance: 0.85,
            complianceByPattern: [
                .actorConcurrency: 0.9,
                .viewContextBinding: 0.8
            ],
            complexityScores: [
                .actorConcurrency: 0.3,
                .viewContextBinding: 0.2
            ],
            antiPatternCount: 0,
            generatedAt: Date()
        )
    }
    
    private func createMockIntegrityReport() -> SystemIntegrityReport {
        return SystemIntegrityReport(
            isValid: true,
            overallScore: 0.9,
            violations: [],
            warnings: [],
            componentCount: 5,
            validatedAt: Date()
        )
    }
    
    private func createMockPatternComplianceReport() -> PatternComplianceReport {
        return PatternComplianceReport(
            overallScore: 0.85,
            patternScores: [
                .actorConcurrency: 0.9,
                .viewContextBinding: 0.8
            ],
            violations: [],
            validatedAt: Date()
        )
    }
    
    private func createMockDocumentationSet(for component: IntrospectedComponent) -> ArchitecturalDocumentationSet {
        var docSet = ArchitecturalDocumentationSet()
        let componentDoc = ComponentDocumentation(
            componentID: component.id,
            name: component.name,
            overview: "Test component documentation",
            generatedAt: Date()
        )
        docSet.addComponentDocumentation(componentDoc)
        return docSet
    }
    
    private func createMockComponents() -> [IntrospectedComponent] {
        return [
            IntrospectedComponent(id: ComponentID("UserManager"), name: "UserManager", category: .client, type: "actor"),
            IntrospectedComponent(id: ComponentID("OrderManager"), name: "OrderManager", category: .client, type: "actor"),
            IntrospectedComponent(id: ComponentID("UserView"), name: "UserView", category: .view, type: "struct"),
            IntrospectedComponent(id: ComponentID("OrderView"), name: "OrderView", category: .view, type: "struct"),
            IntrospectedComponent(id: ComponentID("AppContext"), name: "AppContext", category: .context, type: "class")
        ]
    }
    
    private func createMockRelationshipMap() -> ComponentRelationshipMap {
        var map = ComponentRelationshipMap()
        map.addRelationship(AnalyzedRelationship(
            source: ComponentID("UserView"),
            target: ComponentID("AppContext"),
            type: .dependsOn,
            strength: 1.0,
            isRequired: true,
            communicationPattern: .synchronous
        ))
        return map
    }
    
    private func createMockSystemImpactAnalysis() -> SystemImpactAnalysis {
        let change = ProposedChange(
            targetComponent: ComponentID("UserManager"),
            type: .interface,
            scope: .module,
            description: "Update interface",
            rationale: "Test change"
        )
        
        return SystemImpactAnalysis(
            changes: [change],
            impacts: [],
            overallRisk: .medium,
            estimatedEffort: .medium,
            recommendations: ["Test recommendation"],
            analyzedAt: Date()
        )
    }
    
    private func createMockAntiPatterns() -> [AntiPatternDetection] {
        return []
    }
}

// MARK: - Mock Implementations

/// Mock component introspection engine for testing
private actor MockComponentIntrospectionEngine: ComponentIntrospecting {
    var mockComponents: [IntrospectedComponent] = []
    var mockAnalysis: ComponentAnalysis?
    var mockRelationshipMap = ComponentRelationshipMap()
    var mockDocumentation = ArchitecturalDocumentationSet()
    var mockIntegrityReport: SystemIntegrityReport?
    var mockSystemImpactAnalysis: SystemImpactAnalysis?
    var mockMetrics: ComponentMetricsReport?
    
    func discoverComponents() async -> [IntrospectedComponent] {
        return mockComponents
    }
    
    func analyzeComponent(_ componentID: ComponentID) async throws -> ComponentAnalysis {
        guard let analysis = mockAnalysis else {
            throw IntrospectionError.componentNotFound(componentID)
        }
        return analysis
    }
    
    func mapComponentRelationships() async -> ComponentRelationshipMap {
        return mockRelationshipMap
    }
    
    func generateDocumentation() async -> ArchitecturalDocumentationSet {
        return mockDocumentation
    }
    
    func validateArchitecturalIntegrity() async -> SystemIntegrityReport {
        return mockIntegrityReport ?? SystemIntegrityReport(
            isValid: true,
            overallScore: 1.0,
            violations: [],
            warnings: [],
            componentCount: mockComponents.count,
            validatedAt: Date()
        )
    }
    
    func performImpactAnalysis(_ changes: [ProposedChange]) async -> SystemImpactAnalysis {
        return mockSystemImpactAnalysis ?? SystemImpactAnalysis(
            changes: changes,
            impacts: [],
            overallRisk: .low,
            estimatedEffort: .low,
            recommendations: [],
            analyzedAt: Date()
        )
    }
    
    func getComponentMetrics() async -> ComponentMetricsReport {
        return mockMetrics ?? ComponentMetricsReport(
            totalComponents: mockComponents.count,
            totalRelationships: 0,
            averageRelationshipsPerComponent: 0,
            categoryDistribution: [:],
            layerDistribution: [:],
            highlyCoupledComponents: [],
            complexityMetrics: ComplexityMetrics(
                averageComponentComplexity: 0,
                systemCouplingIndex: 0,
                maxComponentComplexity: 0
            ),
            generatedAt: Date()
        )
    }
}

/// Mock pattern detection engine for testing
private actor MockPatternDetectionEngine: PatternDetecting {
    var mockPatterns: [DetectedPattern] = []
    var mockPatternStats: PatternStatistics?
    var mockPatternCompliance: PatternComplianceReport?
    var mockAntiPatterns: [AntiPatternDetection] = []
    
    func detectPatterns() async -> [DetectedPattern] {
        return mockPatterns
    }
    
    func analyzePattern(_ patternType: PatternType) async -> PatternAnalysis {
        return PatternAnalysis(
            patternType: patternType,
            totalInstances: 1,
            averageConfidence: 0.8,
            usage: PatternUsage(total: 1, highConfidence: 1, mediumConfidence: 0, lowConfidence: 0),
            compliance: 0.8,
            effectiveness: PatternEffectiveness(overallScore: 0.8, consistencyScore: 0.8, impactScore: 0.8, averageConfidence: 0.8),
            recommendations: [],
            analyzedAt: Date()
        )
    }
    
    func validatePatternCompliance() async -> PatternComplianceReport {
        return mockPatternCompliance ?? PatternComplianceReport(
            overallScore: 0.85,
            patternScores: [:],
            violations: [],
            validatedAt: Date()
        )
    }
    
    func suggestPatterns(for context: PatternSuggestionContext) async -> [PatternSuggestion] {
        return []
    }
    
    func codifyPattern(_ pattern: DetectedPattern) async -> CodifiedPattern {
        return CodifiedPattern(
            type: pattern.type,
            name: pattern.name,
            description: pattern.description,
            structure: PatternStructure(components: [], relationships: [], constraints: []),
            constraints: [],
            benefits: [],
            tradeoffs: [],
            examples: [],
            applicabilityRules: [],
            codifiedAt: Date()
        )
    }
    
    func detectAntiPatterns() async -> [AntiPatternDetection] {
        return mockAntiPatterns
    }
    
    func getPatternStatistics() async -> PatternStatistics {
        return mockPatternStats ?? PatternStatistics(
            totalPatternsDetected: mockPatterns.count,
            patternDistribution: [:],
            averageCompliance: 0.85,
            complianceByPattern: [:],
            complexityScores: [:],
            antiPatternCount: mockAntiPatterns.count,
            generatedAt: Date()
        )
    }
}

/// Mock natural language query parser for testing
private actor MockNaturalLanguageQueryParser: QueryParsing {
    func parseQuery(_ query: String) async -> ParsedQuery {
        return ParsedQuery(
            originalQuery: query,
            normalizedQuery: query.lowercased(),
            intent: .unknown,
            parameters: [:],
            entities: [],
            confidence: 0.5,
            parsedAt: Date()
        )
    }
    
    func suggestQueries(for context: QueryContext) async -> [QuerySuggestion] {
        return []
    }
    
    func validateQuery(_ parsedQuery: ParsedQuery) async -> QueryValidationResult {
        return QueryValidationResult(
            isValid: true,
            confidence: parsedQuery.confidence,
            errors: [],
            warnings: [],
            validatedAt: Date()
        )
    }
    
    func getQueryHelp() async -> QueryHelp {
        return QueryHelp(
            supportedIntents: [],
            exampleQueries: [],
            parameterTypes: [],
            syntax: QuerySyntaxHelp(basicSyntax: "", supportedQuestions: [], tips: [])
        )
    }
    
    func learnFromQuery(_ query: String, result: QueryResult) async {
        // Mock implementation
    }
}

/// Mock performance monitor for testing
private actor MockPerformanceMonitor: PerformanceMonitoring {
    func startOperation(_ name: String, category: PerformanceCategory) async -> PerformanceToken {
        return PerformanceToken(id: UUID(), startTime: Date(), operationName: name, category: category)
    }
    
    func endOperation(_ token: PerformanceToken) async {
        // Mock implementation
    }
    
    func recordMetric(_ metric: PerformanceMetric) async {
        // Mock implementation
    }
    
    func getMetrics(for category: PerformanceCategory?) async -> [PerformanceMetric] {
        return []
    }
    
    func getCurrentReport() async -> PerformanceReport {
        return PerformanceReport(
            totalOperations: 0,
            averageExecutionTime: 0,
            categoryBreakdown: [:],
            slowOperations: [],
            generatedAt: Date()
        )
    }
    
    func resetMetrics() async {
        // Mock implementation
    }
}

// MARK: - Test Helper Types

/// Test implementation of ArchitecturalDNA
private struct TestArchitecturalDNA: ArchitecturalDNA {
    let componentId: ComponentID
    let purpose: ComponentPurpose
    let constraints: [ArchitecturalConstraint]
    let relationships: [ComponentRelationship]
    let requiredCapabilities: Set<Capability>
    let providedCapabilities: Set<Capability>
    let performanceProfile: PerformanceProfile
    let qualityAttributes: QualityAttributes
    let architecturalLayer: ArchitecturalLayer = .application
    
    func validateArchitecturalIntegrity() async throws -> ArchitecturalValidationResult {
        return ArchitecturalValidationResult(
            isValid: true,
            score: 1.0,
            violations: [],
            warnings: []
        )
    }
    
    func generateDescription() -> ComponentDescription {
        return ComponentDescription(
            overview: "Test component",
            purpose: "Testing",
            architecture: "Test architecture",
            interfaces: "Test interfaces",
            implementation: "Test implementation",
            examples: "Test examples",
            relatedComponents: "None"
        )
    }
}