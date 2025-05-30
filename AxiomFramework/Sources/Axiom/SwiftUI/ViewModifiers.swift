import SwiftUI
import Combine

// MARK: - Capability Requirement Modifier

/// A view modifier that checks capability requirements before displaying content
public struct RequiresCapabilitiesModifier: ViewModifier {
    let capabilities: Set<Capability>
    let validationMode: ValidationMode
    let fallback: AnyView?
    
    @Environment(\.axiomContext) private var context
    @State private var hasValidatedCapabilities = false
    @State private var capabilitiesAvailable = false
    
    public enum ValidationMode {
        case strict      // All capabilities must be available
        case partial     // At least one capability must be available
        case graceful    // Degrade functionality if capabilities unavailable
    }
    
    public init(
        capabilities: Set<Capability>,
        mode: ValidationMode = .strict,
        fallback: AnyView? = nil
    ) {
        self.capabilities = capabilities
        self.validationMode = mode
        self.fallback = fallback
    }
    
    public func body(content: Content) -> some View {
        Group {
            if let context = context {
                if hasValidatedCapabilities && capabilitiesAvailable {
                    content
                        .task {
                            await validateCapabilities(context)
                        }
                } else if hasValidatedCapabilities && !capabilitiesAvailable {
                    if let fallback = fallback {
                        fallback
                    } else {
                        CapabilityUnavailableView(
                            missingCapabilities: capabilities,
                            context: context
                        )
                    }
                } else {
                    // Show loading while validating
                    ProgressView("Checking capabilities...")
                        .task {
                            await validateCapabilities(context)
                        }
                }
            } else if let fallback = fallback {
                fallback
            } else {
                Text("Context not available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func validateCapabilities(_ context: any AxiomContext) async {
        do {
            let manager = try await context.capabilityManager()
            
            switch validationMode {
            case .strict:
                capabilitiesAvailable = try await manager.validateCapabilities(Array(capabilities))
            case .partial:
                var anyAvailable = false
                for capability in capabilities {
                    if await manager.hasCapability(capability) {
                        anyAvailable = true
                        break
                    }
                }
                capabilitiesAvailable = anyAvailable
            case .graceful:
                // Always show content but with degraded functionality
                capabilitiesAvailable = true
            }
        } catch {
            capabilitiesAvailable = false
        }
        
        hasValidatedCapabilities = true
    }
}

/// View shown when capabilities are unavailable
struct CapabilityUnavailableView: View {
    let missingCapabilities: Set<Capability>
    let context: any AxiomContext
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Required Capabilities Unavailable")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(missingCapabilities), id: \.self) { capability in
                    Label(capability.displayName, systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Request Access") {
                Task {
                    await requestCapabilities()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func requestCapabilities() async {
        // Request capability access
    }
}

// MARK: - Performance Monitoring Modifier

/// Enhanced performance monitoring with detailed metrics
public struct PerformanceMonitoringModifier: ViewModifier {
    let operation: String
    let category: PerformanceCategory
    let trackMemory: Bool
    
    @Environment(\.axiomContext) private var context
    @Environment(\.axiomPerformanceTracker) private var performanceTracker
    @State private var operationToken: PerformanceToken?
    
    public init(
        operation: String,
        category: PerformanceCategory = .viewOperation,
        trackMemory: Bool = false
    ) {
        self.operation = operation
        self.category = category
        self.trackMemory = trackMemory
    }
    
    public func body(content: Content) -> some View {
        content
            .task {
                await startTracking()
            }
            .onDisappear {
                Task {
                    await endTracking()
                }
            }
            .onChange(of: operation) { newOperation in
                Task {
                    await endTracking()
                    await startTracking()
                }
            }
    }
    
    private func startTracking() async {
        guard let context = context else { return }
        
        do {
            let monitor = try await context.performanceMonitor()
            operationToken = await monitor.startOperation(operation, category: category)
            
            if trackMemory {
                await monitor.recordMetric(PerformanceMetric(
                    name: "\(operation).memory.start",
                    value: Double(getMemoryUsage()),
                    unit: .bytes,
                    category: category,
                    timestamp: Date()
                ))
            }
        } catch {
            print("[Axiom Performance] Failed to start tracking: \(error)")
        }
    }
    
    private func endTracking() async {
        guard let context = context,
              let token = operationToken else { return }
        
        do {
            let monitor = try await context.performanceMonitor()
            await monitor.endOperation(token)
            
            if trackMemory {
                await monitor.recordMetric(PerformanceMetric(
                    name: "\(operation).memory.end",
                    value: Double(getMemoryUsage()),
                    unit: .bytes,
                    category: category,
                    timestamp: Date()
                ))
            }
        } catch {
            print("[Axiom Performance] Failed to end tracking: \(error)")
        }
        
        operationToken = nil
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
}

// MARK: - Intelligence Integration Modifier

/// Enhanced intelligence features integration
public struct IntelligenceEnabledModifier: ViewModifier {
    let features: Set<IntelligenceFeature>
    let configuration: IntelligenceConfiguration
    
    @Environment(\.axiomContext) private var context
    @State private var intelligence: (any AxiomIntelligence)?
    @State private var queryResponse: QueryResponse?
    
    public struct IntelligenceConfiguration {
        public let enableNaturalLanguage: Bool
        public let enablePredictions: Bool
        public let enablePatternDetection: Bool
        public let confidenceThreshold: Double
        
        public init(
            enableNaturalLanguage: Bool = true,
            enablePredictions: Bool = true,
            enablePatternDetection: Bool = true,
            confidenceThreshold: Double = 0.7
        ) {
            self.enableNaturalLanguage = enableNaturalLanguage
            self.enablePredictions = enablePredictions
            self.enablePatternDetection = enablePatternDetection
            self.confidenceThreshold = confidenceThreshold
        }
    }
    
    public init(
        features: Set<IntelligenceFeature>,
        configuration: IntelligenceConfiguration = IntelligenceConfiguration()
    ) {
        self.features = features
        self.configuration = configuration
    }
    
    public func body(content: Content) -> some View {
        content
            .task {
                await setupIntelligence()
            }
            .overlay(alignment: .topTrailing) {
                if configuration.enableNaturalLanguage {
                    IntelligenceQueryButton { query in
                        await processQuery(query)
                    }
                }
            }
            .sheet(item: $queryResponse) { response in
                QueryResponseView(response: response)
            }
    }
    
    private func setupIntelligence() async {
        guard let context = context else { return }
        
        intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        
        // Enable requested features
        for feature in features {
            await intelligence?.enableFeature(feature)
        }
    }
    
    private func processQuery(_ query: String) async {
        guard let intelligence = intelligence else { return }
        
        do {
            queryResponse = try await intelligence.processQuery(query)
        } catch {
            print("[Axiom Intelligence] Query failed: \(error)")
        }
    }
}

/// Button for natural language queries
struct IntelligenceQueryButton: View {
    let onQuery: (String) async -> Void
    @State private var showingQueryInput = false
    @State private var queryText = ""
    
    var body: some View {
        Button {
            showingQueryInput = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
        .padding()
        .sheet(isPresented: $showingQueryInput) {
            NavigationView {
                VStack(spacing: 16) {
                    Text("Ask About This View")
                        .font(.headline)
                    
                    TextField("What would you like to know?", text: $queryText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Ask") {
                        Task {
                            await onQuery(queryText)
                            showingQueryInput = false
                            queryText = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(queryText.isEmpty)
                    
                    Spacer()
                }
                .padding()
                #if os(iOS)
                .navigationBarItems(trailing: Button("Cancel") {
                    showingQueryInput = false
                })
                #else
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingQueryInput = false
                        }
                    }
                }
                #endif
            }
        }
    }
}

/// View to display query responses
struct QueryResponseView: View, Identifiable {
    let response: QueryResponse
    var id: Date { response.respondedAt }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(response.answer)
                        .font(.body)
                    
                    if !response.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Related Questions")
                                .font(.headline)
                            
                            ForEach(response.suggestions, id: \.self) { suggestion in
                                Text("• \(suggestion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Intelligence Response")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - View Modifier Extensions

public extension View {
    /// Requires specific capabilities with enhanced options
    func requiresCapabilities(
        _ capabilities: Capability...,
        mode: RequiresCapabilitiesModifier.ValidationMode = .strict,
        fallback: (() -> AnyView)? = nil
    ) -> some View {
        self.modifier(
            RequiresCapabilitiesModifier(
                capabilities: Set(capabilities),
                mode: mode,
                fallback: fallback?()
            )
        )
    }
    
    /// Monitors performance with detailed tracking
    func performanceMonitored(
        _ operation: String,
        category: PerformanceCategory = .viewOperation,
        trackMemory: Bool = false
    ) -> some View {
        self.modifier(PerformanceMonitoringModifier(
            operation: operation,
            category: category,
            trackMemory: trackMemory
        ))
    }
    
    /// Enables intelligence features with configuration
    func intelligenceEnabled(
        _ features: Set<IntelligenceFeature>,
        configuration: IntelligenceEnabledModifier.IntelligenceConfiguration = .init()
    ) -> some View {
        self.modifier(IntelligenceEnabledModifier(
            features: features,
            configuration: configuration
        ))
    }
}

// MARK: - Analytics Integration

/// Tracks user interactions and view metrics
public struct AnalyticsModifier: ViewModifier {
    let event: String
    let parameters: [String: Any]
    
    @Environment(\.axiomContext) private var context
    
    public func body(content: Content) -> some View {
        content
            .onAppear {
                trackEvent("view.appeared")
            }
            .onDisappear {
                trackEvent("view.disappeared")
            }
    }
    
    private func trackEvent(_ action: String) {
        // Track analytics event
        Task {
            await context?.trackAnalyticsEvent("\(event).\(action)", parameters: parameters)
        }
    }
}

// MARK: - Error Handling Integration

/// Wrapper for AxiomError to make it Identifiable
private struct IdentifiableError: Identifiable {
    let id = UUID()
    let error: any AxiomError
}

/// Enhanced error handling with recovery actions
public struct ErrorHandlingModifier: ViewModifier {
    @Binding var error: (any AxiomError)?
    let recoveryHandler: ((any AxiomError) async -> Bool)?
    
    @State private var identifiableError: IdentifiableError?
    
    public func body(content: Content) -> some View {
        content
            .alert(isPresented: .constant(error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(error?.userMessage ?? "An error occurred"),
                    primaryButton: .default(Text("Retry")) {
                        if let currentError = error {
                            Task {
                                if let handler = recoveryHandler {
                                    let recovered = await handler(currentError)
                                    if recovered {
                                        self.error = nil
                                    }
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel {
                        self.error = nil
                    }
                )
            }
    }
}

// MARK: - Loading State Integration

/// Manages loading states with customizable indicators
public struct LoadingStateModifier: ViewModifier {
    @Binding var isLoading: Bool
    let message: String?
    let style: LoadingStyle
    
    public enum LoadingStyle {
        case overlay
        case inline
        case fullScreen
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading && style == .overlay)
            
            if isLoading {
                switch style {
                case .overlay:
                    LoadingOverlay(message: message)
                case .inline:
                    // Inline loading handled by content
                    EmptyView()
                case .fullScreen:
                    LoadingFullScreen(message: message)
                }
            }
        }
    }
}

struct LoadingOverlay: View {
    let message: String?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            #if os(iOS)
            .background(Color(.systemBackground))
            #else
            .background(Color(NSColor.windowBackgroundColor))
            #endif
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
}

struct LoadingFullScreen: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(2)
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
        .ignoresSafeArea()
    }
}

// MARK: - Accessibility Integration

/// Enhances accessibility with Axiom-specific features
public struct AccessibilityEnhancedModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits
    
    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

// MARK: - Additional View Extensions

public extension View {
    /// Tracks analytics events
    func analyticsTracked(_ event: String, parameters: [String: Any] = [:]) -> some View {
        self.modifier(AnalyticsModifier(event: event, parameters: parameters))
    }
    
    /// Adds error handling with recovery
    func errorHandled(
        _ error: Binding<(any AxiomError)?>,
        recover: ((any AxiomError) async -> Bool)? = nil
    ) -> some View {
        self.modifier(ErrorHandlingModifier(error: error, recoveryHandler: recover))
    }
    
    /// Manages loading states
    func loadingState(
        _ isLoading: Binding<Bool>,
        message: String? = nil,
        style: LoadingStateModifier.LoadingStyle = .overlay
    ) -> some View {
        self.modifier(LoadingStateModifier(
            isLoading: isLoading,
            message: message,
            style: style
        ))
    }
    
    /// Enhances accessibility
    func accessibilityEnhanced(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self.modifier(AccessibilityEnhancedModifier(
            label: label,
            hint: hint,
            traits: traits
        ))
    }
}

// MARK: - Conditional View Extensions

public extension View {
    /// Conditionally applies a modifier based on a boolean value
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditionally applies one of two modifiers based on a boolean value
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Applies a modifier only when a value is non-nil
    @ViewBuilder
    func ifLet<Value, Transform: View>(
        _ value: Value?,
        transform: (Self, Value) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Axiom Styling

/// Standard styling for Axiom framework components
public struct AxiomStyle {
    public static let cornerRadius: CGFloat = 12
    public static let padding: CGFloat = 16
    public static let shadowRadius: CGFloat = 4
    
    public static func primaryButton() -> some ViewModifier {
        PrimaryButtonStyle()
    }
    
    public static func secondaryButton() -> some ViewModifier {
        SecondaryButtonStyle()
    }
    
    public static func card() -> some ViewModifier {
        CardStyle()
    }
}

private struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AxiomStyle.padding)
            .padding(.vertical, AxiomStyle.padding / 2)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(AxiomStyle.cornerRadius)
    }
}

private struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AxiomStyle.padding)
            .padding(.vertical, AxiomStyle.padding / 2)
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(AxiomStyle.cornerRadius)
    }
}

private struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AxiomStyle.padding)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(NSColor.controlBackgroundColor))
            #endif
            .cornerRadius(AxiomStyle.cornerRadius)
            .shadow(radius: AxiomStyle.shadowRadius)
    }
}