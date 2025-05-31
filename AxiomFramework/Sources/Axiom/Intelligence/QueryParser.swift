import Foundation

// MARK: - Query Parser Protocol

/// Protocol for parsing natural language queries about the architecture
/// This is part of the natural language intelligence system in Axiom
public protocol QueryParsing: Actor {
    /// Parses a natural language query and extracts intent and parameters
    func parseQuery(_ query: String) async -> ParsedQuery
    
    /// Suggests possible queries based on context
    func suggestQueries(for context: QueryContext) async -> [QuerySuggestion]
    
    /// Validates that a query can be executed
    func validateQuery(_ parsedQuery: ParsedQuery) async -> QueryValidationResult
    
    /// Gets help information for query syntax
    func getQueryHelp() async -> QueryHelp
    
    /// Learns from query patterns to improve parsing
    func learnFromQuery(_ query: String, result: QueryResult) async
}

// MARK: - Natural Language Query Parser

/// Actor-based natural language query parser with intent recognition
public actor NaturalLanguageQueryParser: QueryParsing {
    // MARK: Properties
    
    /// Performance monitor for query parsing operations
    private let performanceMonitor: PerformanceMonitor
    
    /// Query patterns for intent recognition
    private var queryPatterns: [QueryPattern]
    
    /// Intent classifiers for different query types
    private let intentClassifiers: [QueryIntent: IntentClassifier]
    
    /// Entity extractor for parameter identification
    private let entityExtractor: EntityExtractor
    
    /// Query learning system for continuous improvement
    private var learningSystem: QueryLearningSystem
    
    /// Configuration for query parsing
    private let configuration: QueryParserConfiguration
    
    // MARK: Initialization
    
    public init(
        performanceMonitor: PerformanceMonitor,
        configuration: QueryParserConfiguration = QueryParserConfiguration()
    ) {
        self.performanceMonitor = performanceMonitor
        self.configuration = configuration
        self.queryPatterns = []
        self.intentClassifiers = [:]
        self.entityExtractor = EntityExtractor()
        self.learningSystem = QueryLearningSystem()
        
        Task {
            await initializeQueryPatterns()
            await initializeIntentClassifiers()
        }
    }
    
    // MARK: Query Parsing
    
    public func parseQuery(_ query: String) async -> ParsedQuery {
        let token = await performanceMonitor.startOperation("parse_query", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        // Normalize the query
        let normalizedQuery = normalizeQuery(query)
        
        // Extract intent
        let intent = await classifyIntent(normalizedQuery)
        
        // Extract entities and parameters
        let entities = await entityExtractor.extractEntities(from: normalizedQuery)
        let parameters = extractParameters(from: entities, for: intent)
        
        // Calculate confidence score
        let confidence = calculateParsingConfidence(query: normalizedQuery, intent: intent, entities: entities)
        
        return ParsedQuery(
            originalQuery: query,
            normalizedQuery: normalizedQuery,
            intent: intent,
            parameters: parameters,
            entities: entities,
            confidence: confidence,
            parsedAt: Date()
        )
    }
    
    public func suggestQueries(for context: QueryContext) async -> [QuerySuggestion] {
        let token = await performanceMonitor.startOperation("suggest_queries", category: .intelligenceQuery)
        defer { Task { await performanceMonitor.endOperation(token) } }
        
        var suggestions: [QuerySuggestion] = []
        
        // Add context-specific suggestions
        switch context.type {
        case .component:
            suggestions.append(contentsOf: generateComponentSuggestions(context))
        case .architecture:
            suggestions.append(contentsOf: generateArchitectureSuggestions(context))
        case .pattern:
            suggestions.append(contentsOf: generatePatternSuggestions(context))
        case .performance:
            suggestions.append(contentsOf: generatePerformanceSuggestions(context))
        case .general:
            suggestions.append(contentsOf: generateGeneralSuggestions(context))
        }
        
        // Add learning-based suggestions
        let learnedSuggestions = await learningSystem.generateSuggestions(for: context)
        suggestions.append(contentsOf: learnedSuggestions)
        
        return suggestions.sorted { $0.relevance > $1.relevance }
    }
    
    public func validateQuery(_ parsedQuery: ParsedQuery) async -> QueryValidationResult {
        var errors: [QueryValidationError] = []
        var warnings: [QueryValidationWarning] = []
        
        // Validate intent
        if parsedQuery.intent == .unknown {
            errors.append(QueryValidationError(
                type: .unknownIntent,
                message: "Could not understand the intent of the query",
                suggestion: "Try rephrasing your question or use one of the suggested queries"
            ))
        }
        
        // Validate required parameters
        let requiredParams = getRequiredParameters(for: parsedQuery.intent)
        for param in requiredParams {
            if parsedQuery.parameters[param] == nil {
                errors.append(QueryValidationError(
                    type: .missingParameter,
                    message: "Missing required parameter: \(param)",
                    suggestion: "Please specify the \(param) in your query"
                ))
            }
        }
        
        // Check confidence threshold
        if parsedQuery.confidence < configuration.minimumConfidenceThreshold {
            warnings.append(QueryValidationWarning(
                type: .lowConfidence,
                message: "Query interpretation confidence is low (\(String(format: "%.1f", parsedQuery.confidence * 100))%)",
                suggestion: "Consider rephrasing for better accuracy"
            ))
        }
        
        let isValid = errors.isEmpty
        
        return QueryValidationResult(
            isValid: isValid,
            confidence: parsedQuery.confidence,
            errors: errors,
            warnings: warnings,
            validatedAt: Date()
        )
    }
    
    public func getQueryHelp() async -> QueryHelp {
        return QueryHelp(
            supportedIntents: Array(QueryIntent.allCases),
            exampleQueries: generateExampleQueries(),
            parameterTypes: generateParameterTypeHelp(),
            syntax: generateSyntaxHelp()
        )
    }
    
    public func learnFromQuery(_ query: String, result: QueryResult) async {
        await learningSystem.recordQuery(query, result: result)
        
        // Update query patterns if learning is enabled
        if configuration.enableLearning {
            await updateQueryPatterns(from: query, result: result)
        }
    }
    
    // MARK: Private Implementation
    
    private func initializeQueryPatterns() async {
        queryPatterns = [
            // Component queries
            QueryPattern(
                pattern: "(?:what|tell me about|describe|explain) (?:the )?(?:component|class|type) (\\w+)",
                intent: .describeComponent,
                parameterNames: ["componentName"]
            ),
            QueryPattern(
                pattern: "(?:show me|list|find) (?:all )?components? (?:of type|that are) (\\w+)",
                intent: .listComponents,
                parameterNames: ["componentType"]
            ),
            QueryPattern(
                pattern: "(?:how many|count) components? (?:are there|exist)",
                intent: .countComponents,
                parameterNames: []
            ),
            
            // Relationship queries
            QueryPattern(
                pattern: "(?:what|which) components? depend on (\\w+)",
                intent: .findDependencies,
                parameterNames: ["componentName"]
            ),
            QueryPattern(
                pattern: "(?:what|which) components? does (\\w+) depend on",
                intent: .findDependents,
                parameterNames: ["componentName"]
            ),
            QueryPattern(
                pattern: "(?:show me|map|visualize) (?:the )?relationships?",
                intent: .mapRelationships,
                parameterNames: []
            ),
            
            // Pattern queries
            QueryPattern(
                pattern: "(?:what|which) patterns? (?:are|do you) (?:detect|find|see)",
                intent: .detectPatterns,
                parameterNames: []
            ),
            QueryPattern(
                pattern: "(?:does|is) (\\w+) (?:follow|use|implement) (?:the )?(\\w+) pattern",
                intent: .checkPattern,
                parameterNames: ["componentName", "patternType"]
            ),
            QueryPattern(
                pattern: "(?:find|detect|show) anti[- ]patterns?",
                intent: .detectAntiPatterns,
                parameterNames: []
            ),
            
            // Performance queries
            QueryPattern(
                pattern: "(?:how fast|what.*performance|show.*metrics) (?:is|of|for) (\\w+)",
                intent: .getPerformance,
                parameterNames: ["componentName"]
            ),
            QueryPattern(
                pattern: "(?:what|which) components? (?:are|perform) (?:slow|fast|efficient)",
                intent: .analyzePerformance,
                parameterNames: []
            ),
            
            // Architecture queries
            QueryPattern(
                pattern: "(?:validate|check|verify) (?:the )?architecture",
                intent: .validateArchitecture,
                parameterNames: []
            ),
            QueryPattern(
                pattern: "(?:what.*problems|issues|violations|errors)",
                intent: .findIssues,
                parameterNames: []
            ),
            QueryPattern(
                pattern: "(?:suggest|recommend|advise) (?:improvements|optimizations|changes)",
                intent: .suggestImprovements,
                parameterNames: []
            ),
            
            // General queries
            QueryPattern(
                pattern: "(?:help|what can (?:you|i) do|commands|syntax)",
                intent: .help,
                parameterNames: []
            ),
            QueryPattern(
                pattern: "(?:overview|summary|status) (?:of )?(?:the )?(?:system|architecture|framework)",
                intent: .getOverview,
                parameterNames: []
            )
        ]
    }
    
    private func initializeIntentClassifiers() async {
        // Initialize intent classifiers for each query intent
        // In a real implementation, these would use ML models or sophisticated NLP
        // For now, we'll use pattern-based classification
    }
    
    private func normalizeQuery(_ query: String) -> String {
        // Convert to lowercase
        var normalized = query.lowercased()
        
        // Remove extra whitespace
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove punctuation at the end
        normalized = normalized.replacingOccurrences(of: "[.?!]+$", with: "", options: .regularExpression)
        
        // Normalize common variations
        normalized = normalized.replacingOccurrences(of: "\\b(?:please|could you|can you|would you)\\b", with: "", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: "\\b(?:the|a|an)\\b", with: "", options: .regularExpression)
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    private func classifyIntent(_ query: String) async -> QueryIntent {
        // Try to match against known patterns
        for pattern in queryPatterns {
            if let _ = query.range(of: pattern.pattern, options: .regularExpression) {
                return pattern.intent
            }
        }
        
        // Fallback to keyword-based classification
        return classifyByKeywords(query)
    }
    
    private func classifyByKeywords(_ query: String) -> QueryIntent {
        let words = query.components(separatedBy: .whitespaces)
        
        // Component-related keywords
        if words.contains(where: { ["component", "class", "type", "module"].contains($0) }) {
            if words.contains(where: { ["list", "show", "find", "all"].contains($0) }) {
                return .listComponents
            } else if words.contains(where: { ["count", "how", "many"].contains($0) }) {
                return .countComponents
            } else {
                return .describeComponent
            }
        }
        
        // Relationship keywords
        if words.contains(where: { ["depend", "relationship", "connect", "link"].contains($0) }) {
            return .findDependencies
        }
        
        // Pattern keywords
        if words.contains(where: { ["pattern", "anti-pattern", "antipattern"].contains($0) }) {
            if words.contains(where: { ["anti", "bad", "problem"].contains($0) }) {
                return .detectAntiPatterns
            } else {
                return .detectPatterns
            }
        }
        
        // Performance keywords
        if words.contains(where: { ["performance", "speed", "fast", "slow", "metric"].contains($0) }) {
            return .getPerformance
        }
        
        // Architecture keywords
        if words.contains(where: { ["validate", "check", "verify", "architecture"].contains($0) }) {
            return .validateArchitecture
        }
        
        // Help keywords
        if words.contains(where: { ["help", "syntax", "command", "what"].contains($0) }) {
            return .help
        }
        
        // Overview keywords
        if words.contains(where: { ["overview", "summary", "status"].contains($0) }) {
            return .getOverview
        }
        
        return .unknown
    }
    
    private func extractParameters(from entities: [Entity], for intent: QueryIntent) -> [String: String] {
        var parameters: [String: String] = [:]
        
        for entity in entities {
            switch entity.type {
            case .componentName:
                parameters["componentName"] = entity.value
            case .componentType:
                parameters["componentType"] = entity.value
            case .patternType:
                parameters["patternType"] = entity.value
            case .metric:
                parameters["metric"] = entity.value
            case .number:
                parameters["count"] = String(Int(entity.value) ?? 0)
            }
        }
        
        return parameters
    }
    
    private func calculateParsingConfidence(query: String, intent: QueryIntent, entities: [Entity]) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Boost confidence if we found a known intent
        if intent != .unknown {
            confidence += 0.3
        }
        
        // Boost confidence based on entities found
        if !entities.isEmpty {
            confidence += 0.1 * Double(entities.count)
        }
        
        // Boost confidence if query matches a known pattern well
        for pattern in queryPatterns {
            if pattern.intent == intent {
                if let _ = query.range(of: pattern.pattern, options: .regularExpression) {
                    confidence += 0.2
                    break
                }
            }
        }
        
        return min(1.0, confidence)
    }
    
    private func getRequiredParameters(for intent: QueryIntent) -> [String] {
        switch intent {
        case .describeComponent, .findDependencies, .findDependents, .getPerformance:
            return ["componentName"]
        case .checkPattern:
            return ["componentName", "patternType"]
        case .listComponents:
            return [] // componentType is optional
        default:
            return []
        }
    }
    
    private func generateComponentSuggestions(_ context: QueryContext) -> [QuerySuggestion] {
        return [
            QuerySuggestion(
                query: "What is the \(context.componentName ?? "MyComponent") component?",
                description: "Get detailed information about a specific component",
                intent: .describeComponent,
                relevance: 0.9
            ),
            QuerySuggestion(
                query: "What components depend on \(context.componentName ?? "MyComponent")?",
                description: "Find components that depend on this one",
                intent: .findDependencies,
                relevance: 0.8
            ),
            QuerySuggestion(
                query: "What is the performance of \(context.componentName ?? "MyComponent")?",
                description: "Get performance metrics for this component",
                intent: .getPerformance,
                relevance: 0.7
            )
        ]
    }
    
    private func generateArchitectureSuggestions(_ context: QueryContext) -> [QuerySuggestion] {
        return [
            QuerySuggestion(
                query: "Show me the architecture overview",
                description: "Get a high-level view of the entire system",
                intent: .getOverview,
                relevance: 0.9
            ),
            QuerySuggestion(
                query: "Validate the architecture",
                description: "Check for architectural violations and issues",
                intent: .validateArchitecture,
                relevance: 0.8
            ),
            QuerySuggestion(
                query: "Map the component relationships",
                description: "Visualize how components are connected",
                intent: .mapRelationships,
                relevance: 0.7
            )
        ]
    }
    
    private func generatePatternSuggestions(_ context: QueryContext) -> [QuerySuggestion] {
        return [
            QuerySuggestion(
                query: "What patterns do you detect?",
                description: "Find architectural patterns in the system",
                intent: .detectPatterns,
                relevance: 0.9
            ),
            QuerySuggestion(
                query: "Find anti-patterns in the system",
                description: "Identify potential architectural problems",
                intent: .detectAntiPatterns,
                relevance: 0.8
            ),
            QuerySuggestion(
                query: "Does MyComponent follow the actor pattern?",
                description: "Check if a component follows a specific pattern",
                intent: .checkPattern,
                relevance: 0.7
            )
        ]
    }
    
    private func generatePerformanceSuggestions(_ context: QueryContext) -> [QuerySuggestion] {
        return [
            QuerySuggestion(
                query: "What components are slow?",
                description: "Find components with performance issues",
                intent: .analyzePerformance,
                relevance: 0.9
            ),
            QuerySuggestion(
                query: "Show performance metrics",
                description: "Get overall system performance data",
                intent: .getPerformance,
                relevance: 0.8
            )
        ]
    }
    
    private func generateGeneralSuggestions(_ context: QueryContext) -> [QuerySuggestion] {
        return [
            QuerySuggestion(
                query: "How many components are there?",
                description: "Get a count of all components in the system",
                intent: .countComponents,
                relevance: 0.6
            ),
            QuerySuggestion(
                query: "Suggest improvements for the architecture",
                description: "Get recommendations for architectural improvements",
                intent: .suggestImprovements,
                relevance: 0.7
            ),
            QuerySuggestion(
                query: "What can you help me with?",
                description: "Get help with query syntax and capabilities",
                intent: .help,
                relevance: 0.5
            )
        ]
    }
    
    private func generateExampleQueries() -> [ExampleQuery] {
        return [
            ExampleQuery(
                query: "What is the UserManager component?",
                description: "Get information about a specific component",
                intent: .describeComponent
            ),
            ExampleQuery(
                query: "Show me all client components",
                description: "List components of a specific type",
                intent: .listComponents
            ),
            ExampleQuery(
                query: "What components depend on NetworkService?",
                description: "Find dependencies of a component",
                intent: .findDependencies
            ),
            ExampleQuery(
                query: "What patterns do you detect?",
                description: "Discover architectural patterns",
                intent: .detectPatterns
            ),
            ExampleQuery(
                query: "Validate the architecture",
                description: "Check for architectural issues",
                intent: .validateArchitecture
            ),
            ExampleQuery(
                query: "What is the performance of DataProcessor?",
                description: "Get performance metrics for a component",
                intent: .getPerformance
            )
        ]
    }
    
    private func generateParameterTypeHelp() -> [ParameterTypeHelp] {
        return [
            ParameterTypeHelp(
                name: "componentName",
                description: "The name of a specific component (e.g., UserManager, DataProcessor)",
                examples: ["UserManager", "NetworkService", "ViewContext"]
            ),
            ParameterTypeHelp(
                name: "componentType",
                description: "The type or category of components (e.g., client, context, view)",
                examples: ["client", "context", "view", "domain model"]
            ),
            ParameterTypeHelp(
                name: "patternType",
                description: "The name of an architectural pattern (e.g., actor, singleton, observer)",
                examples: ["actor", "view-context binding", "state management"]
            )
        ]
    }
    
    private func generateSyntaxHelp() -> QuerySyntaxHelp {
        return QuerySyntaxHelp(
            basicSyntax: "Ask questions in natural English about your architecture",
            supportedQuestions: [
                "What/Which questions: 'What is the UserManager component?'",
                "How many questions: 'How many components are there?'",
                "Show/List commands: 'Show me all client components'",
                "Find/Detect commands: 'Find anti-patterns'",
                "Validate commands: 'Validate the architecture'"
            ],
            tips: [
                "Use specific component names for detailed information",
                "Ask about patterns, performance, or relationships",
                "Try 'help' to see what I can do",
                "Be specific about what you want to know"
            ]
        )
    }
    
    private func updateQueryPatterns(from query: String, result: QueryResult) async {
        // In a real implementation, this would use machine learning to improve patterns
        // For now, we'll just track successful queries
        await learningSystem.updatePatterns(query: query, result: result)
    }
}

// MARK: - Supporting Types

/// Configuration for query parser behavior
public struct QueryParserConfiguration: Sendable {
    public let minimumConfidenceThreshold: Double
    public let enableLearning: Bool
    public let maxSuggestions: Int
    public let enableAdvancedNLP: Bool
    
    public init(
        minimumConfidenceThreshold: Double = 0.6,
        enableLearning: Bool = true,
        maxSuggestions: Int = 10,
        enableAdvancedNLP: Bool = false
    ) {
        self.minimumConfidenceThreshold = max(0.0, min(1.0, minimumConfidenceThreshold))
        self.enableLearning = enableLearning
        self.maxSuggestions = max(1, maxSuggestions)
        self.enableAdvancedNLP = enableAdvancedNLP
    }
}

/// Query pattern for intent recognition
public struct QueryPattern: Sendable {
    public let pattern: String
    public let intent: QueryIntent
    public let parameterNames: [String]
    
    public init(pattern: String, intent: QueryIntent, parameterNames: [String]) {
        self.pattern = pattern
        self.intent = intent
        self.parameterNames = parameterNames
    }
}

/// Types of query intents
public enum QueryIntent: String, CaseIterable, Sendable {
    case describeComponent = "describe_component"
    case listComponents = "list_components"
    case countComponents = "count_components"
    case findDependencies = "find_dependencies"
    case findDependents = "find_dependents"
    case mapRelationships = "map_relationships"
    case detectPatterns = "detect_patterns"
    case checkPattern = "check_pattern"
    case detectAntiPatterns = "detect_anti_patterns"
    case getPerformance = "get_performance"
    case analyzePerformance = "analyze_performance"
    case validateArchitecture = "validate_architecture"
    case findIssues = "find_issues"
    case suggestImprovements = "suggest_improvements"
    case getOverview = "get_overview"
    case help = "help"
    case unknown = "unknown"
}

/// Parsed natural language query
public struct ParsedQuery: Sendable {
    public let originalQuery: String
    public let normalizedQuery: String
    public let intent: QueryIntent
    public let parameters: [String: String] // Changed to Sendable type
    public let entities: [Entity]
    public let confidence: Double
    public let parsedAt: Date
    
    public init(
        originalQuery: String,
        normalizedQuery: String,
        intent: QueryIntent,
        parameters: [String: String],
        entities: [Entity],
        confidence: Double,
        parsedAt: Date
    ) {
        self.originalQuery = originalQuery
        self.normalizedQuery = normalizedQuery
        self.intent = intent
        self.parameters = parameters
        self.entities = entities
        self.confidence = confidence
        self.parsedAt = parsedAt
    }
}

/// Context for query suggestions
public struct QueryContext: Sendable {
    public let type: QueryContextType
    public let componentName: String?
    public let additionalContext: [String: String]
    
    public init(
        type: QueryContextType,
        componentName: String? = nil,
        additionalContext: [String: String] = [:]
    ) {
        self.type = type
        self.componentName = componentName
        self.additionalContext = additionalContext
    }
}

/// Types of query contexts
public enum QueryContextType: String, CaseIterable, Sendable {
    case component = "component"
    case architecture = "architecture"
    case pattern = "pattern"
    case performance = "performance"
    case general = "general"
}

/// Suggested query
public struct QuerySuggestion: Sendable {
    public let query: String
    public let description: String
    public let intent: QueryIntent
    public let relevance: Double
    
    public init(query: String, description: String, intent: QueryIntent, relevance: Double) {
        self.query = query
        self.description = description
        self.intent = intent
        self.relevance = max(0.0, min(1.0, relevance))
    }
}

/// Query validation result
public struct QueryValidationResult: Sendable {
    public let isValid: Bool
    public let confidence: Double
    public let errors: [QueryValidationError]
    public let warnings: [QueryValidationWarning]
    public let validatedAt: Date
    
    public init(
        isValid: Bool,
        confidence: Double,
        errors: [QueryValidationError],
        warnings: [QueryValidationWarning],
        validatedAt: Date
    ) {
        self.isValid = isValid
        self.confidence = confidence
        self.errors = errors
        self.warnings = warnings
        self.validatedAt = validatedAt
    }
}

/// Query validation error
public struct QueryValidationError: Sendable {
    public let type: QueryValidationErrorType
    public let message: String
    public let suggestion: String
    
    public init(type: QueryValidationErrorType, message: String, suggestion: String) {
        self.type = type
        self.message = message
        self.suggestion = suggestion
    }
}

/// Types of query validation errors
public enum QueryValidationErrorType: String, CaseIterable, Sendable {
    case unknownIntent = "unknown_intent"
    case missingParameter = "missing_parameter"
    case invalidParameter = "invalid_parameter"
    case unsupportedQuery = "unsupported_query"
}

/// Query validation warning
public struct QueryValidationWarning: Sendable {
    public let type: QueryValidationWarningType
    public let message: String
    public let suggestion: String
    
    public init(type: QueryValidationWarningType, message: String, suggestion: String) {
        self.type = type
        self.message = message
        self.suggestion = suggestion
    }
}

/// Types of query validation warnings
public enum QueryValidationWarningType: String, CaseIterable, Sendable {
    case lowConfidence = "low_confidence"
    case ambiguousQuery = "ambiguous_query"
    case deprecatedSyntax = "deprecated_syntax"
}

/// Help information for queries
public struct QueryHelp: Sendable {
    public let supportedIntents: [QueryIntent]
    public let exampleQueries: [ExampleQuery]
    public let parameterTypes: [ParameterTypeHelp]
    public let syntax: QuerySyntaxHelp
    
    public init(
        supportedIntents: [QueryIntent],
        exampleQueries: [ExampleQuery],
        parameterTypes: [ParameterTypeHelp],
        syntax: QuerySyntaxHelp
    ) {
        self.supportedIntents = supportedIntents
        self.exampleQueries = exampleQueries
        self.parameterTypes = parameterTypes
        self.syntax = syntax
    }
}

/// Example query for help
public struct ExampleQuery: Sendable {
    public let query: String
    public let description: String
    public let intent: QueryIntent
    
    public init(query: String, description: String, intent: QueryIntent) {
        self.query = query
        self.description = description
        self.intent = intent
    }
}

/// Parameter type help information
public struct ParameterTypeHelp: Sendable {
    public let name: String
    public let description: String
    public let examples: [String]
    
    public init(name: String, description: String, examples: [String]) {
        self.name = name
        self.description = description
        self.examples = examples
    }
}

/// Query syntax help
public struct QuerySyntaxHelp: Sendable {
    public let basicSyntax: String
    public let supportedQuestions: [String]
    public let tips: [String]
    
    public init(basicSyntax: String, supportedQuestions: [String], tips: [String]) {
        self.basicSyntax = basicSyntax
        self.supportedQuestions = supportedQuestions
        self.tips = tips
    }
}

// MARK: - Entity Extraction

/// Entity extractor for parameter identification
public struct EntityExtractor: Sendable {
    
    public init() {}
    
    public func extractEntities(from query: String) async -> [Entity] {
        var entities: [Entity] = []
        
        // Extract component names (PascalCase words)
        let componentPattern = "\\b[A-Z][a-zA-Z]*(?:Manager|Service|Client|Context|View|Model|Controller|Handler)\\b"
        entities.append(contentsOf: extractEntitiesWithPattern(query, pattern: componentPattern, type: .componentName))
        
        // Extract component types
        let typePattern = "\\b(?:client|context|view|model|component|service|manager)s?\\b"
        entities.append(contentsOf: extractEntitiesWithPattern(query, pattern: typePattern, type: .componentType))
        
        // Extract pattern names
        let patternPattern = "\\b(?:actor|singleton|observer|factory|builder|strategy|command|mvc|mvvm)\\b"
        entities.append(contentsOf: extractEntitiesWithPattern(query, pattern: patternPattern, type: .patternType))
        
        // Extract numbers
        let numberPattern = "\\b\\d+\\b"
        entities.append(contentsOf: extractEntitiesWithPattern(query, pattern: numberPattern, type: .number))
        
        // Extract metrics
        let metricPattern = "\\b(?:performance|speed|latency|throughput|memory|cpu)\\b"
        entities.append(contentsOf: extractEntitiesWithPattern(query, pattern: metricPattern, type: .metric))
        
        return entities
    }
    
    private func extractEntitiesWithPattern(_ query: String, pattern: String, type: EntityType) -> [Entity] {
        var entities: [Entity] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: query, options: [], range: NSRange(location: 0, length: query.count))
            
            for match in matches {
                if let range = Range(match.range, in: query) {
                    let value = String(query[range])
                    entities.append(Entity(type: type, value: value, confidence: 0.8))
                }
            }
        } catch {
            // Regex error - continue without this pattern
        }
        
        return entities
    }
}

/// Extracted entity from query
public struct Entity: Sendable {
    public let type: EntityType
    public let value: String
    public let confidence: Double
    
    public init(type: EntityType, value: String, confidence: Double) {
        self.type = type
        self.value = value
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

/// Types of entities that can be extracted
public enum EntityType: String, CaseIterable, Sendable {
    case componentName = "component_name"
    case componentType = "component_type"
    case patternType = "pattern_type"
    case metric = "metric"
    case number = "number"
}

// MARK: - Intent Classification

/// Intent classifier for specific query types
public struct IntentClassifier: Sendable {
    public let intent: QueryIntent
    public let keywords: [String]
    public let patterns: [String]
    
    public init(intent: QueryIntent, keywords: [String], patterns: [String]) {
        self.intent = intent
        self.keywords = keywords
        self.patterns = patterns
    }
}

// MARK: - Learning System

/// Query learning system for continuous improvement
public actor QueryLearningSystem {
    private var queryHistory: [LearnedQuery] = []
    private var successfulPatterns: [String: Int] = [:]
    
    public init() {}
    
    public func recordQuery(_ query: String, result: QueryResult) {
        let learnedQuery = LearnedQuery(
            query: query,
            result: result,
            timestamp: Date()
        )
        queryHistory.append(learnedQuery)
        
        // Track successful patterns
        if result.wasSuccessful {
            successfulPatterns[query, default: 0] += 1
        }
        
        // Limit history size
        if queryHistory.count > 1000 {
            queryHistory.removeFirst(queryHistory.count - 1000)
        }
    }
    
    public func generateSuggestions(for context: QueryContext) -> [QuerySuggestion] {
        // Generate suggestions based on successful query history
        let relevantQueries = queryHistory.filter { $0.result.wasSuccessful }
        
        return relevantQueries.prefix(5).map { learned in
            QuerySuggestion(
                query: learned.query,
                description: "Previously successful query",
                intent: .unknown, // Would determine from learned query
                relevance: 0.6
            )
        }
    }
    
    public func updatePatterns(query: String, result: QueryResult) {
        // Update internal patterns based on query success
        if result.wasSuccessful {
            successfulPatterns[query, default: 0] += 1
        }
    }
}

/// Learned query for pattern improvement
private struct LearnedQuery {
    let query: String
    let result: QueryResult
    let timestamp: Date
}

/// Query result for learning purposes
public struct QueryResult: Sendable {
    public let wasSuccessful: Bool
    public let responseTime: TimeInterval
    public let resultCount: Int
    public let userSatisfaction: Double?
    
    public init(
        wasSuccessful: Bool,
        responseTime: TimeInterval,
        resultCount: Int,
        userSatisfaction: Double? = nil
    ) {
        self.wasSuccessful = wasSuccessful
        self.responseTime = responseTime
        self.resultCount = resultCount
        self.userSatisfaction = userSatisfaction
    }
}

// MARK: - Global Query Parser

/// Global shared query parser
public actor GlobalQueryParser {
    public static let shared = GlobalQueryParser()
    
    private var parser: NaturalLanguageQueryParser?
    
    private init() {
        // Parser will be lazily initialized when first accessed
    }
    
    public func getParser() async -> NaturalLanguageQueryParser {
        if let parser = parser {
            return parser
        }
        
        let performanceMonitor = await GlobalPerformanceMonitor.shared.getMonitor()
        
        let newParser = NaturalLanguageQueryParser(
            performanceMonitor: performanceMonitor
        )
        self.parser = newParser
        return newParser
    }
}