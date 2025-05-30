import Foundation
import SwiftUI
import Combine

// MARK: - AxiomContext Protocol

/// The core protocol for contexts that orchestrate clients and provide SwiftUI integration
@MainActor
public protocol AxiomContext: ObservableObject {
    associatedtype View: AxiomView where View.Context == Self
    associatedtype Clients: ClientDependencies
    
    /// The clients managed by this context
    var clients: Clients { get }
    
    /// The intelligence system for this context
    var intelligence: AxiomIntelligence { get }
    
    // MARK: Lifecycle
    
    /// Called when the associated view appears
    func onAppear() async
    
    /// Called when the associated view disappears
    func onDisappear() async
    
    /// Called when a client's state changes
    func onClientStateChange<T: AxiomClient>(_ client: T) async
    
    // MARK: Error Handling
    
    /// Handles errors that occur within the context
    func handleError(_ error: any AxiomError) async
}

// MARK: - Default Context State

/// Default implementation of context state
@MainActor
public class DefaultContextState: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var lastError: (any AxiomError)?
    
    public init() {}
}

// MARK: - AxiomContext Extensions

extension AxiomContext {
    /// Configures error handling for the context
    public func configureErrorHandling(_ handler: @escaping (any AxiomError) async -> Void) async {
        // Configure automatic error handling
        // In a full implementation, this would set up error observation
    }
}