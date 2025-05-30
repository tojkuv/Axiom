import Foundation
import SwiftUI
import Combine

// MARK: - Automatic State Binding for Contexts

/// Eliminates manual state duplication between clients and contexts
/// Automatically synchronizes client state with @Published context properties
@MainActor
public final class ContextStateBinder: ObservableObject {
    
    // MARK: - Binding Registration
    
    private var bindings: [StateBinding] = []
    private var cancellables: Set<AnyCancellable> = []
    
    public init() {}
    
    /// Bind a client state property to a context @Published property
    public func bind<ClientType: AxiomClient, ContextType: ObservableObject, Value: Sendable>(
        client: ClientType,
        clientPath: KeyPath<ClientType.State, Value>,
        context: ContextType,
        contextPath: ReferenceWritableKeyPath<ContextType, Value>
    ) {
        
        let binding = StateBinding(
            clientId: ObjectIdentifier(client),
            updateHandler: { [weak context] in
                guard let context = context else { return }
                
                let clientState = await client.stateSnapshot
                let value = clientState[keyPath: clientPath]
                
                await MainActor.run {
                    context[keyPath: contextPath] = value
                }
            }
        )
        
        bindings.append(binding)
    }
    
    /// Automatically update all bindings when any client state changes
    public func updateAllBindings() async {
        for binding in bindings {
            await binding.updateHandler()
        }
    }
    
}

// MARK: - State Binding Internal Types

private struct StateBinding {
    let clientId: ObjectIdentifier
    let updateHandler: () async -> Void
}

// MARK: - Enhanced Context Protocol

/// Extension to AxiomContext for automatic state binding
extension AxiomContext {
    
    /// Sets up automatic state binding between client and context
    /// Eliminates manual state duplication and synchronization
    public func setupAutomaticStateBinding<ClientType: AxiomClient, Value: Sendable>(
        client: ClientType,
        clientPath: KeyPath<ClientType.State, Value>,
        contextPath: ReferenceWritableKeyPath<Self, Value>,
        binder: ContextStateBinder
    ) async {
        
        binder.bind(
            client: client,
            clientPath: clientPath,
            context: self,
            contextPath: contextPath
        )
        
        // Perform initial synchronization
        await binder.updateAllBindings()
    }
    
    /// Enhanced onClientStateChange with automatic binding support
    public func handleClientStateChangeWithBinding<T: AxiomClient>(
        _ client: T,
        binder: ContextStateBinder
    ) async {
        // Update all automatic bindings
        await binder.updateAllBindings()
        
        // Call the original onClientStateChange for custom logic
        await onClientStateChange(client)
    }
    
    /// Convenience method to create and setup a state binder
    public func createStateBinder() -> ContextStateBinder {
        return ContextStateBinder()
    }
}

// MARK: - Context Helper Extensions

/// Additional convenience methods for common state binding patterns
extension AxiomContext {
    
    /// Quick setup for binding specific client properties
    public func bindClientProperty<ClientType: AxiomClient, Value: Sendable>(
        _ client: ClientType,
        property: KeyPath<ClientType.State, Value>,
        to contextProperty: ReferenceWritableKeyPath<Self, Value>,
        using binder: ContextStateBinder
    ) async {
        
        binder.bind(
            client: client,
            clientPath: property,
            context: self,
            contextPath: contextProperty
        )
        
        await binder.updateAllBindings()
    }
}

// MARK: - Usage Examples in Comments

/*
 USAGE EXAMPLE - Before (Manual State Duplication):
 
 @MainActor
 final class MyContext: AxiomContext {
     @Published var currentCount: Int = 0  // Manual duplication
     @Published var isLoading: Bool = false
     
     let counterClient: CounterClient
     
     func onClientStateChange<T: AxiomClient>(_ client: T) async {
         // Manual synchronization
         if client is CounterClient {
             let count = await counterClient.getCurrentCount()
             await MainActor.run {
                 self.currentCount = count
             }
         }
     }
 }
 
 USAGE EXAMPLE - After (Automatic State Binding):
 
 @MainActor
 final class MyContext: AxiomContext {
     @Published var currentCount: Int = 0  // Automatically synced!
     
     let counterClient: CounterClient
     let intelligence: AxiomIntelligence
     let stateBinder = ContextStateBinder()
     
     var clients: MyClients {
         MyClients(counterClient: counterClient)
     }
     
     init(counterClient: CounterClient, intelligence: AxiomIntelligence) {
         self.counterClient = counterClient
         self.intelligence = intelligence
         
         Task {
             await bindClientProperty(
                 counterClient,
                 property: \.count,  // Client state property
                 to: \.currentCount,  // Context @Published property
                 using: stateBinder
             )
         }
     }
     
     func onClientStateChange<T: AxiomClient>(_ client: T) async {
         // Automatic binding handles state sync!
         await stateBinder.updateAllBindings()
     }
     
     // All other AxiomContext methods...
 }
*/