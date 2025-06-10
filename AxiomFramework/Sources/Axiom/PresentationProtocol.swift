import SwiftUI
import Foundation

// MARK: - Presentation Architecture Protocols

/// Protocol for compile-time validation of presentation-context pairs
///
/// This protocol ensures type safety between presentations and their contexts,
/// enforcing the single-context-per-presentation architectural constraint.
public protocol PresentationProtocol: View {
    /// The specific context type this presentation observes
    associatedtype ContextType: ObservableObject
    
    /// The context instance this presentation uses
    var context: ContextType { get }
}

/// Protocol for contexts that can be identified by type
///
/// This enables compile-time validation and type-safe context creation.
public protocol ContextIdentifiable {
    /// Unique identifier for this context type
    static var contextIdentifier: String { get }
}

/// Protocol for child presentations that derive from parent contexts
///
/// This enables hierarchical presentation architectures where child views
/// can have their own contexts derived from parent contexts.
public protocol ChildPresentation: PresentationProtocol {
    /// The parent context type this child derives from
    associatedtype ParentContext: ObservableObject
    
    /// Initialize this child presentation with a parent context
    init(parentContext: ParentContext)
}

// MARK: - Supporting Types for Presentation Architecture

/// Marker protocol for client types used in presentation architecture
public protocol PresentationClient: AnyObject {
    /// Stream of state updates from this client
    var stateStream: AsyncStream<Any> { get async }
}

/// Error thrown when architectural constraints are violated
public struct ArchitecturalViolation: Error, CustomStringConvertible {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
    
    public var description: String {
        return "Architectural Violation: \(message)"
    }
}

// MARK: - Compile-Time Validation Helpers

/// Namespace for compile-time validation utilities
public enum PresentationValidation {
    /// Validates that a presentation follows architectural constraints
    public static func validate<P: PresentationProtocol>(_ presentationType: P.Type) {
        // This function exists primarily for compile-time validation
        // Runtime validation can be added here if needed
    }
    
    /// Validates context-presentation type safety
    public static func validateContextPairing<P: PresentationProtocol, C: ObservableObject>(
        presentation: P.Type,
        context: C.Type
    ) where P.ContextType == C {
        // Type system ensures this relationship is valid at compile time
    }
}