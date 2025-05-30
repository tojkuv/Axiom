import Foundation
import SwiftUI

// MARK: - Simplified Context Factory

/// Utility for creating contexts with automatic setup and observer binding
@MainActor
public final class SimplifiedContextFactory {
    
    // MARK: - Context Creation with Observer Auto-binding
    
    /// Create a context with automatic client observer setup
    public static func create<T: AxiomContext>(
        contextType: T.Type,
        clients: T.Clients,
        intelligence: AxiomIntelligence,
        autoBindObservers: Bool = true
    ) async -> T {
        
        // This is a simplified factory - in a real implementation,
        // we'd use reflection or protocol witnesses to create the context
        fatalError("ContextFactory.create needs concrete implementation for \(T.self)")
    }
    
    /// Simplified single-client context creation
    public static func createSingleClient<
        ClientType: AxiomClient,
        ContextType: AxiomContext
    >(
        client: ClientType,
        contextType: ContextType.Type
    ) async throws -> ContextType where ContextType.Clients == SingleClientContainer<ClientType> {
        
        let intelligence = await GlobalIntelligenceManager.shared.getIntelligence()
        let clients = SingleClientContainer(client: client)
        
        // TODO: Auto-bind observer when implemented
        // await client.addObserver(context)
        
        fatalError("Concrete implementation needed")
    }
}

// MARK: - Single Client Container

/// Simplified container for contexts with a single client
public struct SingleClientContainer<T: AxiomClient>: ClientDependencies {
    public let client: T
    
    public init(client: T) {
        self.client = client
    }
    
    public init() {
        fatalError("SingleClientContainer requires a client instance")
    }
}

// MARK: - Context Builder with Fluent API

/// Fluent API for building contexts with automatic setup
@MainActor
public final class ContextBuilder<T: AxiomContext> {
    private var intelligence: AxiomIntelligence?
    private var clients: T.Clients?
    private var autoObservers = true
    
    /// Set the intelligence system
    public func intelligence(_ intelligence: AxiomIntelligence) -> Self {
        self.intelligence = intelligence
        return self
    }
    
    /// Set the client dependencies
    public func clients(_ clients: T.Clients) -> Self {
        self.clients = clients
        return self
    }
    
    /// Control automatic observer binding
    public func autoObservers(_ enabled: Bool) -> Self {
        self.autoObservers = enabled
        return self
    }
    
    /// Build the context with provided configuration
    public func build() async throws -> T {
        guard let intelligence = intelligence else {
            throw ContextBuilderError.missingIntelligence
        }
        
        guard let clients = clients else {
            throw ContextBuilderError.missingClients
        }
        
        // This would need concrete implementation based on context type
        fatalError("ContextBuilder.build() needs concrete implementation for \(T.self)")
    }
}

// MARK: - Context Builder Errors

public enum ContextBuilderError: AxiomError {
    case missingIntelligence
    case missingClients
    case initializationFailed(reason: String)
    
    public var id: UUID { UUID() }
    public var category: ErrorCategory { .architectural }
    public var severity: ErrorSeverity { .error }
    
    public var context: ErrorContext {
        ErrorContext(
            component: ComponentID("ContextBuilder"),
            timestamp: Date(),
            additionalInfo: [:]
        )
    }
    
    public var recoveryActions: [RecoveryAction] { [] }
    
    public var userMessage: String {
        switch self {
        case .missingIntelligence:
            return "Intelligence system not configured"
        case .missingClients:
            return "Client dependencies not provided"
        case .initializationFailed(let reason):
            return "Context initialization failed: \(reason)"
        }
    }
}

// MARK: - Observer Auto-binding Helper

/// Helper for automatic observer binding between clients and contexts
public actor ObserverManager {
    private var bindings: [(any AxiomClient, any AxiomContext)] = []
    
    /// Automatically bind a context as an observer to all its clients
    public func autoBindObservers<T: AxiomContext>(_ context: T) async {
        // This would use reflection to find all client properties
        // and automatically call addObserver on each one
        
        // Simplified implementation - would need to be more sophisticated
        print("📡 Auto-binding observers for context: \(type(of: context))")
    }
    
    /// Remove all observer bindings for a context
    public func removeObservers<T: AxiomContext>(_ context: T) async {
        // Remove context from all client observers
        print("📡 Removing observers for context: \(type(of: context))")
    }
}

// MARK: - Convenience Extensions

extension AxiomContext {
    /// Get a context builder for this context type
    public static func builder() -> ContextBuilder<Self> {
        return ContextBuilder<Self>()
    }
}