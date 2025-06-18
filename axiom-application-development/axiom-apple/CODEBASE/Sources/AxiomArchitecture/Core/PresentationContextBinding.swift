import SwiftUI
import AxiomCore
import Observation

// MARK: - Protocols

/// Protocol for types that can be bound to a presentation
public protocol PresentationBindable: AnyObject {
    var bindingIdentifier: String { get }
}

/// Protocol for presentation types that can be bound to contexts
public protocol BindablePresentation: Hashable {
    var presentationIdentifier: String { get }
}

// MARK: - Binding Management

/// Manages presentation-context bindings to ensure 1:1 relationships
@MainActor
public final class PresentationContextBindingManager {
    /// Singleton instance for global binding management
    public static let shared = PresentationContextBindingManager()
    
    private var bindings: [AnyHashable: WeakBox<AnyObject>] = [:]
    private var contextToPresentationMap: [String: AnyHashable] = [:]
    private var lifecycleObservers: [AnyHashable: Any] = [:]
    
    /// Last error message for debugging
    public private(set) var lastError: String?
    
    private init() {}
    
    /// Binds a context to a presentation with 1:1 enforcement
    public func bind<P: BindablePresentation, C: PresentationBindable>(
        _ context: C,
        to presentation: P
    ) -> Bool {
        let presentationKey = AnyHashable(presentation)
        
        // Check if presentation already has a context
        if let existingBox = bindings[presentationKey],
           let existingContext = existingBox.value as? any PresentationBindable {
            lastError = "Presentation '\(presentation.presentationIdentifier)' already has context '\(existingContext.bindingIdentifier)' bound; cannot bind '\(context.bindingIdentifier)'"
            return false
        }
        
        // Check if context is already bound to another presentation
        if contextToPresentationMap[context.bindingIdentifier] != nil {
            lastError = "Context '\(context.bindingIdentifier)' is already bound to another presentation"
            return false
        }
        
        // Perform binding
        bindings[presentationKey] = WeakBox(context)
        contextToPresentationMap[context.bindingIdentifier] = presentationKey
        
        // Set up lifecycle management
        setupLifecycleObservation(for: presentation, context: context)
        
        lastError = nil
        return true
    }
    
    /// Retrieves the context bound to a presentation
    public func context<P: BindablePresentation, C: PresentationBindable>(
        for presentation: P,
        as type: C.Type
    ) -> C? {
        let presentationKey = AnyHashable(presentation)
        return bindings[presentationKey]?.value as? C
    }
    
    /// Unbinds a presentation
    public func unbind<P: BindablePresentation>(_ presentation: P) {
        let presentationKey = AnyHashable(presentation)
        
        // Clean up context mapping
        if let box = bindings[presentationKey],
           let context = box.value as? PresentationBindable {
            contextToPresentationMap.removeValue(forKey: context.bindingIdentifier)
        }
        
        // Remove binding and observers
        bindings.removeValue(forKey: presentationKey)
        lifecycleObservers.removeValue(forKey: presentationKey)
    }
    
    // MARK: - Lifecycle Management
    
    private func setupLifecycleObservation<P: BindablePresentation, C: PresentationBindable>(
        for presentation: P,
        context: C
    ) {
        let presentationKey = AnyHashable(presentation)
        
        // Use Combine or observation framework for real implementation
        // This is a placeholder for the actual lifecycle observation
        lifecycleObservers[presentationKey] = context
    }
    
    // MARK: - Statistics
    
    /// Total number of active bindings
    public var bindingCount: Int {
        bindings.compactMap { $0.value.value }.count
    }
    
    /// Number of unique presentations with bindings
    public var uniquePresentationCount: Int {
        bindingCount
    }
    
    /// Number of unique contexts bound
    public var uniqueContextCount: Int {
        contextToPresentationMap.count
    }
    
}

// MARK: - Property Wrapper

/// Property wrapper that enforces single context binding for presentations
@propertyWrapper
@MainActor
public struct PresentationContext<Context: PresentationBindable> {
    private let context: Context
    private var hasBeenAccessed = false
    
    public var wrappedValue: Context {
        context
    }
    
    public var projectedValue: Binding<Context> {
        Binding(
            get: { self.context },
            set: { _ in
                // Silently ignore reassignment attempts instead of crashing
                print("Warning: @PresentationContext does not support reassignment")
            }
        )
    }
    
    public init(wrappedValue: Context) {
        self.context = wrappedValue
    }
}

// MARK: - Supporting Types

/// Weak reference wrapper to prevent retain cycles
private final class WeakBox<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

// MARK: - SwiftUI Integration

/// Environment key for presentation context
private struct PresentationContextKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: (any PresentationBindable)? = nil
}

/// Environment values extension for presentation context
extension EnvironmentValues {
    public var presentationContext: (any PresentationBindable)? {
        get { self[PresentationContextKey.self] }
        set { self[PresentationContextKey.self] = newValue }
    }
}

