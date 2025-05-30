import Foundation
import SwiftUI

// MARK: - Developer Assistant

/// Intelligent assistant that provides contextual help and guidance for Axiom developers
public actor DeveloperAssistant {
    public static let shared = DeveloperAssistant()
    
    // MARK: - Configuration
    private var helpDatabase: HelpDatabase
    private var contextualHints: [String: ContextualHint] = [:]
    
    private init() {
        self.helpDatabase = HelpDatabase()
        // Setup hints will be called lazily when needed
    }
    
    // MARK: - Main Assistant Methods
    
    /// Get help for a specific error
    public func getHelpForError(_ error: any AxiomError) async -> ErrorGuidance {
        let guidance = ErrorGuidance(
            error: error,
            explanation: generateErrorExplanation(error),
            commonCauses: getCommonCauses(for: error),
            solutions: getSolutions(for: error),
            codeExamples: getCodeExamples(for: error),
            relatedDocumentation: getRelatedDocumentation(for: error)
        )
        
        // Log that help was requested
        await AxiomDebugger.shared.log(
            "Developer requested help for error: \(error.category.rawValue)",
            level: .info,
            component: "DeveloperAssistant"
        )
        
        return guidance
    }
    
    /// Get contextual hints for common development scenarios
    public func getContextualHint(for scenario: String) async -> ContextualHint? {
        if contextualHints.isEmpty {
            setupDefaultHints()
        }
        return contextualHints[scenario]
    }
    
    /// Analyze code patterns and suggest improvements
    public func analyzeCodePattern(_ pattern: String) async -> CodeAnalysis {
        // This would use the intelligence system to analyze code patterns
        return CodeAnalysis(
            pattern: pattern,
            suggestions: generateSuggestions(for: pattern),
            bestPractices: getBestPractices(for: pattern),
            antiPatterns: getAntiPatterns(for: pattern)
        )
    }
    
    /// Get quick start guidance for new developers
    public func getQuickStartGuide() async -> QuickStartGuide {
        return QuickStartGuide(
            steps: [
                QuickStartStep(
                    title: "1. Import Axiom",
                    description: "Add Axiom to your SwiftUI view",
                    code: "import Axiom",
                    explanation: "This gives you access to all Axiom framework components"
                ),
                QuickStartStep(
                    title: "2. Create a Client",
                    description: "Define an actor-based client for state management",
                    code: """
                    actor MyClient: AxiomClient {
                        typealias State = MyState
                        private(set) var stateSnapshot = MyState()
                        let capabilities: CapabilityManager
                        
                        init(capabilities: CapabilityManager) {
                            self.capabilities = capabilities
                        }
                    }
                    """,
                    explanation: "Clients manage state with thread safety through actors"
                ),
                QuickStartStep(
                    title: "3. Create a Context",
                    description: "Create a context to orchestrate your clients",
                    code: """
                    @MainActor
                    class MyContext: AxiomContext {
                        typealias View = MyView
                        typealias Clients = MyClients
                        
                        let myClient: MyClient
                        let intelligence: AxiomIntelligence
                        
                        var clients: MyClients {
                            MyClients(myClient: myClient)
                        }
                    }
                    """,
                    explanation: "Contexts coordinate clients and integrate with SwiftUI"
                ),
                QuickStartStep(
                    title: "4. Create a View",
                    description: "Build your SwiftUI view with 1:1 context binding",
                    code: """
                    struct MyView: AxiomView {
                        typealias Context = MyContext
                        @ObservedObject var context: MyContext
                        
                        var body: some View {
                            // Your SwiftUI content here
                        }
                    }
                    """,
                    explanation: "Views have a 1:1 relationship with their contexts"
                )
            ],
            commonMistakes: [
                "Forgetting to use @MainActor on contexts",
                "Not implementing all required protocol methods",
                "Creating circular dependencies between clients"
            ],
            nextSteps: [
                "Add capability validation to your clients",
                "Implement intelligence queries for user assistance",
                "Set up performance monitoring"
            ]
        )
    }
    
    // MARK: - Error Analysis
    
    private func generateErrorExplanation(_ error: any AxiomError) -> String {
        switch error.category {
        case .architectural:
            return "This is an architectural error, which typically means there's an issue with how framework components are structured or connected."
        case .capability:
            return "This capability error indicates a problem with the permission or availability system. A required capability may be missing or misconfigured."
        case .domain:
            return "This domain error relates to your business logic or data models. Check that your domain objects are properly configured."
        case .intelligence:
            return "This intelligence system error indicates an issue with AI-powered features like natural language queries or pattern detection."
        case .performance:
            return "This performance error suggests that an operation took longer than expected or used too many resources."
        case .validation:
            return "This validation error means that data failed to meet required constraints or format requirements."
        case .state:
            return "This state management error indicates an issue with how state is being updated or synchronized across the application."
        case .configuration:
            return "This configuration error suggests that the framework or one of its components is not properly set up."
        }
    }
    
    private func getCommonCauses(for error: any AxiomError) -> [String] {
        switch error.category {
        case .architectural:
            return [
                "Missing protocol conformance",
                "Incorrect type relationships",
                "Circular dependencies",
                "Invalid component initialization order"
            ]
        case .capability:
            return [
                "Capability not configured in CapabilityManager",
                "Capability disabled at runtime",
                "Missing permissions in app configuration",
                "Capability validation timing issues"
            ]
        case .domain:
            return [
                "Invalid business rule configuration",
                "Missing required properties in domain models",
                "Validation constraints not met",
                "Inconsistent data state"
            ]
        case .intelligence:
            return [
                "Intelligence system not initialized",
                "Query parsing errors",
                "Insufficient training data",
                "Network connectivity issues"
            ]
        case .performance:
            return [
                "Inefficient database queries",
                "Large data sets without pagination",
                "Blocking main thread operations",
                "Memory leaks or excessive allocations"
            ]
        case .validation:
            return [
                "Invalid input format",
                "Missing required fields",
                "Data type mismatches",
                "Business rule violations"
            ]
        case .state:
            return [
                "Concurrent state modifications",
                "Observer notification failures",
                "State synchronization timing",
                "Invalid state transitions"
            ]
        case .configuration:
            return [
                "Missing configuration files",
                "Invalid configuration values",
                "Environment-specific settings",
                "Dependency injection issues"
            ]
        }
    }
    
    private func getSolutions(for error: any AxiomError) -> [String] {
        switch error.category {
        case .architectural:
            return [
                "Verify all required protocol methods are implemented",
                "Check type constraints and associated types",
                "Review dependency injection setup",
                "Use AxiomDiagnostics to identify structural issues"
            ]
        case .capability:
            return [
                "Configure required capabilities in CapabilityManager",
                "Check capability availability before use",
                "Verify app permissions and entitlements",
                "Add error handling for capability failures"
            ]
        case .domain:
            return [
                "Validate domain model constraints",
                "Check business rule implementations",
                "Verify data integrity",
                "Review domain model relationships"
            ]
        case .intelligence:
            return [
                "Initialize intelligence system before use",
                "Check network connectivity",
                "Validate query syntax",
                "Review intelligence configuration"
            ]
        case .performance:
            return [
                "Use performance monitoring to identify bottlenecks",
                "Implement pagination for large data sets",
                "Move heavy operations off main thread",
                "Review memory allocation patterns"
            ]
        case .validation:
            return [
                "Check input data format and types",
                "Validate required fields are present",
                "Review validation rules",
                "Add proper error handling for invalid data"
            ]
        case .state:
            return [
                "Use proper actor isolation for state updates",
                "Verify observer registration",
                "Check state transition logic",
                "Review concurrency patterns"
            ]
        case .configuration:
            return [
                "Verify configuration file presence",
                "Check configuration value types",
                "Review environment-specific settings",
                "Validate dependency injection setup"
            ]
        }
    }
    
    private func getCodeExamples(for error: any AxiomError) -> [CodeExample] {
        switch error.category {
        case .capability:
            return [
                CodeExample(
                    title: "Proper Capability Validation",
                    code: """
                    // Check capability before use
                    do {
                        try await capabilities.validate(.businessLogic)
                        // Proceed with operation
                    } catch {
                        // Handle capability failure gracefully
                        await context.handleError(error)
                    }
                    """,
                    explanation: "Always validate capabilities before using them"
                )
            ]
        case .state:
            return [
                CodeExample(
                    title: "Safe State Updates",
                    code: """
                    // Update state safely in an actor
                    await updateState { state in
                        state.value = newValue
                        state.lastModified = Date()
                    }
                    """,
                    explanation: "Use the updateState method for thread-safe state modifications"
                )
            ]
        default:
            return []
        }
    }
    
    private func getRelatedDocumentation(for error: any AxiomError) -> [DocumentationLink] {
        return [
            DocumentationLink(
                title: "Error Handling Guide",
                url: "https://docs.axiom-framework.dev/error-handling",
                description: "Comprehensive guide to handling errors in Axiom applications"
            ),
            DocumentationLink(
                title: "\(error.category.rawValue.capitalized) Documentation",
                url: "https://docs.axiom-framework.dev/\(error.category.rawValue)",
                description: "Detailed documentation for the \(error.category.rawValue) system"
            )
        ]
    }
    
    // MARK: - Code Analysis
    
    private func generateSuggestions(for pattern: String) -> [String] {
        // This would use the intelligence system to analyze patterns
        return [
            "Consider using dependency injection for better testability",
            "Add error handling for network operations",
            "Use async/await for better concurrency management"
        ]
    }
    
    private func getBestPractices(for pattern: String) -> [String] {
        return [
            "Follow the 1:1 View-Context relationship",
            "Use actors for state management",
            "Validate capabilities before use",
            "Implement proper error handling"
        ]
    }
    
    private func getAntiPatterns(for pattern: String) -> [String] {
        return [
            "Directly accessing state from views",
            "Creating circular dependencies",
            "Ignoring capability validation",
            "Using force unwrapping without proper checks"
        ]
    }
    
    // MARK: - Setup
    
    private func setupDefaultHints() {
        contextualHints["client_creation"] = ContextualHint(
            id: "client_creation",
            title: "Creating AxiomClient",
            description: "Remember to use actors for thread safety",
            code: """
            actor MyClient: AxiomClient {
                typealias State = MyState
                private(set) var stateSnapshot = MyState()
                let capabilities: CapabilityManager
            }
            """,
            tips: ["Always use actors for clients", "Define your State type clearly"]
        )
        
        contextualHints["context_binding"] = ContextualHint(
            id: "context_binding",
            title: "Context-View Binding",
            description: "Maintain 1:1 relationship between views and contexts",
            code: """
            struct MyView: AxiomView {
                typealias Context = MyContext
                @ObservedObject var context: MyContext
            }
            """,
            tips: ["Use @ObservedObject for context binding", "Keep the 1:1 relationship"]
        )
    }
}

// MARK: - Data Structures

public struct ErrorGuidance: Sendable {
    public let error: any AxiomError
    public let explanation: String
    public let commonCauses: [String]
    public let solutions: [String]
    public let codeExamples: [CodeExample]
    public let relatedDocumentation: [DocumentationLink]
}

public struct CodeExample: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let code: String
    public let explanation: String
}

public struct DocumentationLink: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let url: String
    public let description: String
}

public struct ContextualHint: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let code: String
    public let tips: [String]
}

public struct CodeAnalysis: Sendable {
    public let pattern: String
    public let suggestions: [String]
    public let bestPractices: [String]
    public let antiPatterns: [String]
}

public struct QuickStartGuide: Sendable {
    public let steps: [QuickStartStep]
    public let commonMistakes: [String]
    public let nextSteps: [String]
}

public struct QuickStartStep: Sendable, Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let code: String
    public let explanation: String
}

// MARK: - Help Database

private struct HelpDatabase {
    // In a real implementation, this would load from external sources
    // like documentation, community Q&A, etc.
    
    func getHelpForTopic(_ topic: String) -> [HelpArticle] {
        return []
    }
}

private struct HelpArticle: Sendable {
    let title: String
    let content: String
    let tags: [String]
}

// MARK: - SwiftUI Integration

public struct DeveloperAssistantView: View {
    @State private var selectedTab = 0
    @State private var quickStartGuide: QuickStartGuide?
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            QuickStartView(guide: quickStartGuide)
                .tabItem {
                    Image(systemName: "play.circle")
                    Text("Quick Start")
                }
                .tag(0)
            
            ErrorHelpView()
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Error Help")
                }
                .tag(1)
            
            BestPracticesView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Best Practices")
                }
                .tag(2)
        }
        .onAppear {
            loadQuickStartGuide()
        }
    }
    
    private func loadQuickStartGuide() {
        Task {
            let guide = await DeveloperAssistant.shared.getQuickStartGuide()
            await MainActor.run {
                self.quickStartGuide = guide
            }
        }
    }
}

private struct QuickStartView: View {
    let guide: QuickStartGuide?
    
    var body: some View {
        NavigationView {
            if let guide = guide {
                List {
                    Section("Getting Started") {
                        ForEach(guide.steps) { step in
                            QuickStartStepView(step: step)
                        }
                    }
                    
                    Section("Common Mistakes to Avoid") {
                        ForEach(guide.commonMistakes, id: \.self) { mistake in
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(mistake)
                            }
                        }
                    }
                    
                    Section("Next Steps") {
                        ForEach(guide.nextSteps, id: \.self) { step in
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.blue)
                                Text(step)
                            }
                        }
                    }
                }
                .navigationTitle("Quick Start")
            } else {
                ProgressView("Loading guide...")
            }
        }
    }
}

private struct QuickStartStepView: View {
    let step: QuickStartStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            CodeBlockView(code: step.code)
            
            Text(step.explanation)
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 8)
    }
}

private struct CodeBlockView: View {
    let code: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

private struct ErrorHelpView: View {
    @State private var errorGuidance: ErrorGuidance?
    
    var body: some View {
        NavigationView {
            VStack {
                if let guidance = errorGuidance {
                    ErrorGuidanceView(guidance: guidance)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.diamond")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Error Help")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Get contextual help and solutions for Axiom framework errors")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Error Help")
        }
    }
}

private struct ErrorGuidanceView: View {
    let guidance: ErrorGuidance
    
    var body: some View {
        List {
            Section("Error Details") {
                Text(guidance.explanation)
            }
            
            Section("Common Causes") {
                ForEach(guidance.commonCauses, id: \.self) { cause in
                    Text("• \(cause)")
                }
            }
            
            Section("Solutions") {
                ForEach(guidance.solutions, id: \.self) { solution in
                    Text("• \(solution)")
                }
            }
            
            if !guidance.codeExamples.isEmpty {
                Section("Code Examples") {
                    ForEach(guidance.codeExamples) { example in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(example.title)
                                .fontWeight(.semibold)
                            CodeBlockView(code: example.code)
                            Text(example.explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct BestPracticesView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Architecture") {
                    PracticeRow(
                        title: "1:1 View-Context Relationship",
                        description: "Each view should have exactly one context"
                    )
                    PracticeRow(
                        title: "Actor-Based Clients",
                        description: "Use actors for thread-safe state management"
                    )
                }
                
                Section("Performance") {
                    PracticeRow(
                        title: "Capability Validation",
                        description: "Always validate capabilities before use"
                    )
                    PracticeRow(
                        title: "Error Handling",
                        description: "Implement comprehensive error handling"
                    )
                }
                
                Section("Testing") {
                    PracticeRow(
                        title: "Unit Testing",
                        description: "Test clients and contexts independently"
                    )
                    PracticeRow(
                        title: "Integration Testing",
                        description: "Test complete workflows with AxiomTesting"
                    )
                }
            }
            .navigationTitle("Best Practices")
        }
    }
}

private struct PracticeRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}