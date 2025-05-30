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

// MARK: - Context State

/// Common state properties for contexts
@MainActor
public protocol ContextState: ObservableObject {
    var isLoading: Bool { get }
    var lastError: (any AxiomError)? { get set }
}

// MARK: - Default Context State

/// Default implementation of context state
@MainActor
public class DefaultContextState: ObservableObject, ContextState {
    @Published public var isLoading: Bool = false
    @Published public var lastError: (any AxiomError)?
    
    public init() {}
}


// MARK: - AxiomIntelligence Protocol (Placeholder)

/// Placeholder for the intelligence system - will be fully implemented later
public protocol AxiomIntelligence: Actor {
    var configuration: IntelligenceConfiguration { get set }
    var enabledFeatures: Set<IntelligenceFeature> { get set }
}

// MARK: - Default Intelligence Implementation

/// A default implementation of AxiomIntelligence for initial development
public actor DefaultAxiomIntelligence: AxiomIntelligence {
    public var configuration = IntelligenceConfiguration()
    public var enabledFeatures = Set<IntelligenceFeature>()
    
    public init() {}
}