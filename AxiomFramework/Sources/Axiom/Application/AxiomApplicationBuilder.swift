import Foundation
import SwiftUI

// MARK: - Simplified Application Builder

/// Streamlined builder for AxiomApplication setup
/// Eliminates common boilerplate from initialization patterns
@MainActor
public final class AxiomApplicationBuilder: ObservableObject {
    
    // MARK: - Published State
    @Published public private(set) var isInitialized = false
    @Published public private(set) var initializationError: (any AxiomError)?
    
    // MARK: - Configuration
    private var capabilities: Set<Capability> = []
    private var clientFactories: [() async throws -> any AxiomClient] = []
    
    // MARK: - Builder Methods
    
    /// Configure required capabilities for the application
    public func withCapabilities(_ capabilities: Capability...) -> Self {
        self.capabilities = Set(capabilities)
        return self
    }
    
    /// Add a client factory for automatic initialization
    public func withClient<T: AxiomClient>(_ factory: @escaping () async throws -> T) -> Self {
        clientFactories.append(factory)
        return self
    }
    
    /// Build and initialize the application asynchronously
    public func build() async {
        do {
            // Configure capabilities
            let capabilityManager = await GlobalCapabilityManager.shared.getManager()
            await capabilityManager.configure(availableCapabilities: capabilities)
            
            // Initialize clients
            for factory in clientFactories {
                let client = try await factory()
                try await client.initialize()
            }
            
            await MainActor.run {
                self.isInitialized = true
                self.initializationError = nil
            }
            
        } catch {
            await MainActor.run {
                self.initializationError = ApplicationBuilderError.initializationFailed(underlying: error)
                self.isInitialized = false
            }
        }
    }
    
    /// Create a context with automatic client and intelligence setup
    public func createContext<T: AxiomContext>(
        _ factory: @escaping (AxiomIntelligence, CapabilityManager) async throws -> T
    ) async throws -> T {
        
        guard isInitialized else {
            throw ApplicationBuilderError.notInitialized
        }
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        
        return try await factory(intelligence, capabilityManager)
    }
}

// MARK: - Convenience Extensions

extension AxiomApplicationBuilder {
    
    /// Quick setup for simple single-client applications
    public static func simpleApp<T: AxiomClient>(
        capabilities: [Capability],
        clientFactory: @escaping () async throws -> T
    ) -> AxiomApplicationBuilder {
        let builder = AxiomApplicationBuilder()
        builder.capabilities = Set(capabilities)
        builder.clientFactories = [clientFactory]
        return builder
    }
    
    /// Quick setup for counter app with all required components
    public static func counterApp() -> AxiomApplicationBuilder {
        AxiomApplicationBuilder()
            .withCapabilities(.businessLogic, .stateManagement)
    }
    
    /// Quick setup for task management app
    public static func taskApp() -> AxiomApplicationBuilder {
        AxiomApplicationBuilder()
            .withCapabilities(.businessLogic, .stateManagement, .storage, .analytics)
    }
}

// MARK: - Application Builder Errors

public enum ApplicationBuilderError: AxiomError {
    case initializationFailed(underlying: Error)
    case notInitialized
    case contextCreationFailed(reason: String)
    
    public var id: UUID { UUID() }
    public var category: ErrorCategory { .architectural }
    public var severity: ErrorSeverity { .error }
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID("AxiomApplicationBuilder"),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    public var recoveryActions: [RecoveryAction] { [] }
    
    public var userMessage: String {
        switch self {
        case .initializationFailed(let underlying):
            return "Failed to initialize application: \(underlying.localizedDescription)"
        case .notInitialized:
            return "Application not initialized. Call build() first."
        case .contextCreationFailed(let reason):
            return "Failed to create context: \(reason)"
        }
    }
}

// MARK: - SwiftUI Integration

/// View modifier to handle application initialization
public struct AxiomApplicationModifier: ViewModifier {
    @ObservedObject private var builder: AxiomApplicationBuilder
    
    public init(builder: AxiomApplicationBuilder) {
        self.builder = builder
    }
    
    public func body(content: Content) -> some View {
        if builder.isInitialized {
            content
        } else if let error = builder.initializationError {
            ApplicationErrorView(error: error, retry: {
                Task {
                    await builder.build()
                }
            })
        } else {
            ApplicationLoadingView()
                .onAppear {
                    Task {
                        await builder.build()
                    }
                }
        }
    }
}

// MARK: - Supporting Views

private struct ApplicationLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("🧠 Axiom Framework")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Initializing Intelligence...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .padding(.top)
        }
        .padding()
    }
}

private struct ApplicationErrorView: View {
    let error: any AxiomError
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Initialization Failed")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(error.userMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - View Extension

extension View {
    /// Apply AxiomApplication initialization handling
    public func axiomApplication(_ builder: AxiomApplicationBuilder) -> some View {
        modifier(AxiomApplicationModifier(builder: builder))
    }
}

// MARK: - Usage Example Extension

extension AxiomApplicationBuilder {
    /// Example: Create a complete counter context with automatic setup
    /// This demonstrates the simplified pattern for replacing complex manual initialization
    public func createCounterContext<ClientType: AxiomClient, StateType: Sendable>(
        clientFactory: @escaping (CapabilityManager) async throws -> ClientType
    ) async throws -> (client: ClientType, intelligence: AxiomIntelligence) where ClientType.State == StateType {
        
        guard isInitialized else {
            throw ApplicationBuilderError.notInitialized
        }
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        
        let client = try await clientFactory(capabilityManager)
        try await client.initialize()
        
        return (client: client, intelligence: intelligence)
    }
    
    /// Create a complete user context with automatic setup
    /// Supports sophisticated user domain initialization
    public func createUserContext<ClientType: AxiomClient, StateType: Sendable>(
        clientFactory: @escaping (CapabilityManager) async throws -> ClientType
    ) async throws -> (client: ClientType, intelligence: AxiomIntelligence) where ClientType.State == StateType {
        
        guard isInitialized else {
            throw ApplicationBuilderError.notInitialized
        }
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        
        let client = try await clientFactory(capabilityManager)
        try await client.initialize()
        
        return (client: client, intelligence: intelligence)
    }
    
    /// Create a complete data context with automatic setup
    /// Supports sophisticated data domain initialization
    public func createDataContext<ClientType: AxiomClient, StateType: Sendable>(
        clientFactory: @escaping (CapabilityManager) async throws -> ClientType
    ) async throws -> (client: ClientType, intelligence: AxiomIntelligence) where ClientType.State == StateType {
        
        guard isInitialized else {
            throw ApplicationBuilderError.notInitialized
        }
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        let capabilityManager = await GlobalCapabilityManager.shared.getManager()
        
        let client = try await clientFactory(capabilityManager)
        try await client.initialize()
        
        return (client: client, intelligence: intelligence)
    }
}