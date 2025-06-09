import Foundation
import SwiftUI

// MARK: - Implicit Action Subscription

/// Extension to Context protocol for implicit parent-child action subscription
extension Context {
    /// Emit an action to parent context
    /// The framework automatically delivers this to the parent's handleChildAction
    @MainActor
    public func emit<Action>(_ action: Action) {
        // Get parent context reference from BaseContext
        if let baseContext = self as? BaseContext,
           let parent = baseContext.parentContext {
            Task { @MainActor in
                parent.handleChildAction(action, from: self)
            }
        }
    }
    
}

// MARK: - Weak Context Wrapper

/// Internal wrapper for weak context references
public struct WeakContextWrapper: Hashable {
    weak var context: (any Context)?
    private let id: ObjectIdentifier
    
    init(_ context: any Context) {
        self.context = context
        self.id = ObjectIdentifier(context)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Weak Parent Wrapper

/// Internal wrapper for weak parent reference
private class WeakParentWrapper {
    weak var parent: (any Context)?
    
    init(_ parent: any Context) {
        self.parent = parent
    }
}

// MARK: - Parent-Child Relationship Extensions

extension BaseContext {
    // Associated object keys for storing parent/child relationships
    private static var parentContextKey: UInt8 = 0
    private static var childrenKey: UInt8 = 1
    
    // parentContext is already defined in BaseContext
    // This extension provides additional functionality using associated objects
    // when needed for advanced use cases
    
    // childContexts is already defined in BaseContext as an array
    // This extension could provide Set-based access if needed for advanced use cases
    
    // addChild and removeChild are already defined in BaseContext
    // This extension provides advanced child management using NSHashTable
    // for scenarios requiring weak object collections
    
    // cleanupDeallocatedChildren is already defined as private in BaseContext
    // NSHashTable with weak references automatically removes deallocated objects
}

// MARK: - Context Action Protocol

/// Base protocol for context actions
public protocol ContextAction {
    // Marker protocol for better type inference
}

// MARK: - Presentation Protocol

/// Marker protocol for views that require contexts
/// Only Presentation views participate in the isomorphic DAG constraint
public protocol PresentationView: View {
    associatedtype ContextType: Context
    var context: ContextType { get }
}