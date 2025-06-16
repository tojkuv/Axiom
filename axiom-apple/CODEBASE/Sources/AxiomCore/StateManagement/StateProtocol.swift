import Foundation

// MARK: - State Protocol

/// Protocol that all state types must conform to.
/// 
/// State represents the immutable data model owned by a Client.
/// All state mutations produce new instances, ensuring predictable updates.
/// 
/// ## Requirements
/// - Must be a value type (struct)
/// - All stored properties must be immutable (let)
/// - Must conform to Equatable for change detection
/// - Must conform to Hashable for efficient storage
/// - Must conform to Sendable for actor isolation
/// 
/// ## Example
/// ```swift
/// struct TodoState: AxiomState {
///     let items: [TodoItem]
///     let filter: Filter
///     
///     func withNewItem(_ item: TodoItem) -> TodoState {
///         TodoState(items: items + [item], filter: filter)
///     }
/// }
/// ```
public protocol AxiomState: Equatable, Hashable, Sendable {
    // Marker protocol for Axiom state types
}