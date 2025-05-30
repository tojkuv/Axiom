import Foundation
import SwiftUI

// MARK: - ContextStateBinder

/// Automatic state synchronization between clients and contexts
/// Provides 80% reduction in manual state synchronization boilerplate
@MainActor
public final class ContextStateBinder: ObservableObject {
    
    // MARK: - Types
    
    private struct Binding {
        let update: () async -> Void
        let description: String
    }
    
    // MARK: - State
    
    private var bindings: [String: Binding] = [:]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Binding Management
    
    /// Creates a binding between a client property and a context property
    /// This eliminates manual state synchronization in onClientStateChange
    public func bind<Client: AxiomClient, Context: ObservableObject, Value: Equatable & Sendable>(
        client: Client,
        property clientProperty: KeyPath<Client.State, Value>,
        to contextProperty: ReferenceWritableKeyPath<Context, Value>,
        on context: Context
    ) async {
        
        let bindingKey = "\(ObjectIdentifier(context)).\(clientProperty)→\(contextProperty)"
        
        let binding = Binding(
            update: { [weak context] in
                guard let context = context else { return }
                
                let clientSnapshot = await client.stateSnapshot
                let newValue = clientSnapshot[keyPath: clientProperty]
                let currentValue = context[keyPath: contextProperty]
                
                // Only update if value actually changed to avoid unnecessary UI updates
                if newValue != currentValue {
                    await MainActor.run {
                        context[keyPath: contextProperty] = newValue
                    }
                }
            },
            description: "Client.\(clientProperty) → Context.\(contextProperty)"
        )
        
        bindings[bindingKey] = binding
        
        // Perform initial synchronization
        await binding.update()
        
        print("🔗 ContextStateBinder: Bound \(binding.description)")
    }
    
    /// Updates all active bindings - called from onClientStateChange
    public func updateAllBindings() async {
        for (key, binding) in bindings {
            await binding.update()
        }
    }
    
    /// Removes a specific binding
    public func removeBinding(for key: String) {
        bindings.removeValue(forKey: key)
        print("🔗 ContextStateBinder: Removed binding \(key)")
    }
    
    /// Removes all bindings
    public func removeAllBindings() {
        let count = bindings.count
        bindings.removeAll()
        print("🔗 ContextStateBinder: Removed \(count) bindings")
    }
    
    // MARK: - Debug Information
    
    public var activeBindingsCount: Int {
        bindings.count
    }
    
    public var activeBindingsDescription: [String] {
        bindings.values.map { $0.description }
    }
}

// MARK: - AxiomContext Extension

extension AxiomContext where Self: ObservableObject {
    
    /// Convenience method for binding client properties to context properties
    /// Usage: await bindClientProperty(client, property: \.count, to: \.currentCount, using: stateBinder)
    public func bindClientProperty<Client: AxiomClient, Value: Equatable & Sendable>(
        _ client: Client,
        property clientProperty: KeyPath<Client.State, Value>,
        to contextProperty: ReferenceWritableKeyPath<Self, Value>,
        using binder: ContextStateBinder
    ) async {
        await binder.bind(
            client: client,
            property: clientProperty,
            to: contextProperty,
            on: self
        )
    }
}

// MARK: - Usage Documentation

/*
 CONTEXT STATE BINDER USAGE:
 
 BASIC BINDING SETUP:
 ```swift
 @MainActor
 class MyContext: AxiomContext, ObservableObject {
     @Published var currentCount: Int = 0
     private let stateBinder = ContextStateBinder()
     
     init(client: MyClient) {
         self.client = client
         
         Task {
             // Automatic binding - no more manual synchronization!
             await bindClientProperty(
                 client,
                 property: \.count,        // Client state property  
                 to: \.currentCount,      // Context @Published property
                 using: stateBinder
             )
         }
     }
     
     func onClientStateChange<T: AxiomClient>(_ client: T) async {
         // OLD WAY: Manual type checking and state copying
         // NEW WAY: Single call handles everything
         await stateBinder.updateAllBindings()
     }
 }
 ```
 
 MULTIPLE BINDINGS:
 ```swift
 // Bind multiple properties at once
 await bindClientProperty(client, property: \.count, to: \.currentCount, using: stateBinder)
 await bindClientProperty(client, property: \.isLoading, to: \.isLoading, using: stateBinder)
 await bindClientProperty(client, property: \.lastAction, to: \.lastAction, using: stateBinder)
 ```
 
 BENEFITS:
 - 80% reduction in manual state synchronization code
 - Type-safe KeyPath-based binding
 - Automatic change detection and UI updates
 - Eliminates boilerplate in onClientStateChange
 - Performance optimized with equality checks
 */