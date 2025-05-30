import SwiftUI
import Combine

// MARK: - Context-View Binding System

/// Protocol for views that require specific context types
public protocol ContextBoundView: View {
    associatedtype BoundContext: AxiomContext
    var boundContext: BoundContext { get }
}

// MARK: - Type-Safe Context Binding

/// Ensures compile-time type safety for context-view relationships
public struct TypeSafeContextBinding<Context: AxiomContext, ViewType: AxiomView> where ViewType.Context == Context {
    private let context: Context
    private let viewType: ViewType.Type
    
    public init(context: Context, viewType: ViewType.Type) {
        self.context = context
        self.viewType = viewType
    }
    
    /// Creates a view with guaranteed type-safe context binding
    public func createView() -> ViewType {
        return ViewType(context: context)
    }
}

// MARK: - Context State Synchronization

/// Manages state synchronization between context and view
@MainActor
public class ContextStateSynchronizer<Context: AxiomContext>: ObservableObject {
    private let context: Context
    private var cancellables = Set<AnyCancellable>()
    @Published private var updateToken = UUID()
    
    public init(context: Context) {
        self.context = context
        setupSynchronization()
    }
    
    private func setupSynchronization() {
        // Observe context changes and trigger view updates
        context.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateToken = UUID()
            }
            .store(in: &cancellables)
    }
    
    /// Forces a view update
    public func forceUpdate() {
        updateToken = UUID()
    }
}

// MARK: - Bidirectional Binding

/// Provides bidirectional data binding between context state and view
@propertyWrapper
public struct ContextState<Value>: DynamicProperty where Value: Equatable {
    @ObservedObject private var context: AnyObject
    private let keyPath: ReferenceWritableKeyPath<AnyObject, Value>
    private let animation: Animation?
    
    public var wrappedValue: Value {
        get { context[keyPath: keyPath] }
        nonmutating set {
            if animation != nil {
                withAnimation(animation) {
                    context[keyPath: keyPath] = newValue
                }
            } else {
                context[keyPath: keyPath] = newValue
            }
        }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
    
    public init<Context: AxiomContext>(
        _ keyPath: ReferenceWritableKeyPath<Context, Value>,
        context: Context,
        animation: Animation? = nil
    ) {
        self.context = context as AnyObject
        self.keyPath = keyPath as! ReferenceWritableKeyPath<AnyObject, Value>
        self.animation = animation
    }
}

// MARK: - Context Relationship Validator

/// Validates context-view relationships at runtime
public struct ContextRelationshipValidator {
    /// Validates that a view can be bound to a context
    public static func validate<V: AxiomView, C: AxiomContext>(
        viewType: V.Type,
        contextType: C.Type
    ) -> ValidationResult {
        // Check if view's associated context type matches
        if V.Context.self == C.self {
            return .valid
        } else {
            return .invalid(reason: "View type \(V.self) requires context type \(V.Context.self), but got \(C.self)")
        }
    }
    
    public enum ValidationResult {
        case valid
        case invalid(reason: String)
    }
}

// MARK: - Context View Container

/// A container that enforces 1:1 context-view relationships
public struct ContextBoundContainer<Context: AxiomContext, BoundView: AxiomView>: View 
    where BoundView.Context == Context {
    
    @ObservedObject private var context: Context
    @StateObject private var synchronizer: ContextStateSynchronizer<Context>
    private let viewBuilder: (Context) -> BoundView
    
    public init(
        context: Context,
        @ViewBuilder view: @escaping (Context) -> BoundView
    ) {
        self.context = context
        self._synchronizer = StateObject(wrappedValue: ContextStateSynchronizer(context: context))
        self.viewBuilder = view
    }
    
    public var body: some View {
        viewBuilder(context)
            .id(synchronizer.updateToken)
            .environment(\.axiomContext, context)
            .environmentObject(context)
            .task {
                await context.onAppear()
                await validateBinding()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
    }
    
    private func validateBinding() async {
        // Validate the binding at runtime
        let result = ContextRelationshipValidator.validate(
            viewType: BoundView.self,
            contextType: Context.self
        )
        
        if case .invalid(let reason) = result {
            print("[Axiom] Warning: Invalid context-view binding: \(reason)")
        }
    }
}

// MARK: - Context Hierarchy

/// Manages parent-child context relationships
public class ContextHierarchy<Parent: AxiomContext, Child: AxiomContext>: ObservableObject {
    @Published public private(set) var parent: Parent
    @Published public private(set) var children: [Child] = []
    private var cancellables = Set<AnyCancellable>()
    
    public init(parent: Parent) {
        self.parent = parent
        setupHierarchy()
    }
    
    private func setupHierarchy() {
        // Propagate parent changes to children
        parent.objectWillChange
            .sink { [weak self] _ in
                self?.notifyChildren()
            }
            .store(in: &cancellables)
    }
    
    public func addChild(_ child: Child) {
        children.append(child)
        setupChildBinding(child)
    }
    
    public func removeChild(_ child: Child) {
        children.removeAll { $0 === child }
    }
    
    private func setupChildBinding(_ child: Child) {
        // Setup bidirectional communication if needed
    }
    
    private func notifyChildren() {
        children.forEach { _ = $0.objectWillChange.send() }
    }
}

// MARK: - Context Navigation

/// Manages navigation state between contexts
public struct ContextNavigation<Source: AxiomContext, Destination: AxiomContext> {
    public let source: Source
    public let destination: Destination
    public let transition: NavigationTransition
    
    public init(
        from source: Source,
        to destination: Destination,
        transition: NavigationTransition = .push
    ) {
        self.source = source
        self.destination = destination
        self.transition = transition
    }
    
    public enum NavigationTransition {
        case push
        case present
        case replace
    }
}

// MARK: - Context Lifecycle Observer

/// Observes and manages context lifecycle events
public class ContextLifecycleObserver<Context: AxiomContext>: ObservableObject {
    private weak var context: Context?
    @Published public private(set) var state: LifecycleState = .initialized
    @Published public private(set) var appearCount: Int = 0
    @Published public private(set) var lastAppearTime: Date?
    
    public init(context: Context) {
        self.context = context
    }
    
    public func didAppear() {
        state = .appeared
        appearCount += 1
        lastAppearTime = Date()
    }
    
    public func willDisappear() {
        state = .willDisappear
    }
    
    public func didDisappear() {
        state = .disappeared
    }
    
    public enum LifecycleState {
        case initialized
        case appeared
        case willDisappear
        case disappeared
    }
}

// MARK: - View Modifiers for Context Binding

public extension View {
    /// Binds a view to a specific context with type safety
    func contextBound<C: AxiomContext>(
        to context: C,
        validate: Bool = true
    ) -> some View {
        self
            .environmentObject(context)
            .environment(\.axiomContext, context)
            .task {
                if validate {
                    // Perform runtime validation
                    await validateContextBinding(context)
                }
            }
    }
    
    /// Creates a scoped context for child views
    func scopedContext<C: AxiomContext>(
        _ context: C,
        inherit: Bool = true
    ) -> some View {
        Group {
            if inherit {
                self
                    .environmentObject(context)
                    .environment(\.axiomContext, context)
            } else {
                // Create isolated context scope
                self
                    .transformEnvironment(\.axiomContext) { _ in
                        // Replace with new context
                        _ = context
                    }
            }
        }
    }
    
    private func validateContextBinding<C: AxiomContext>(_ context: C) async {
        // Validation logic would go here
        print("[Axiom] Context bound: \(type(of: context))")
    }
}

// MARK: - Context State Bridge

/// Bridges context state to SwiftUI state management
@propertyWrapper
public struct ContextStateBridge<Context: AxiomContext, Value>: DynamicProperty {
    @ObservedObject private var context: Context
    private let keyPath: KeyPath<Context, Value>
    private let transform: ((Value) -> Value)?
    
    public var wrappedValue: Value {
        if let transform = transform {
            return transform(context[keyPath: keyPath])
        }
        return context[keyPath: keyPath]
    }
    
    public init(
        _ keyPath: KeyPath<Context, Value>,
        context: Context,
        transform: ((Value) -> Value)? = nil
    ) {
        self.keyPath = keyPath
        self.context = context
        self.transform = transform
    }
}

// MARK: - Context Injection

/// Environment key for context injection
private struct InjectedContextKey<Context: AxiomContext>: EnvironmentKey {
    static var defaultValue: Context? { nil }
}

public extension EnvironmentValues {
    /// Injects a specific context type into the environment
    subscript<C: AxiomContext>(contextType type: C.Type) -> C? {
        get { self[InjectedContextKey<C>.self] }
        set { self[InjectedContextKey<C>.self] = newValue }
    }
}

// MARK: - Context Observation

/// Observes changes in a context and triggers actions
public struct ContextObserver<Context: AxiomContext>: ViewModifier {
    let context: Context
    let onChange: (Context) -> Void
    
    public func body(content: Content) -> some View {
        content
            .onReceive(context.objectWillChange) { _ in
                onChange(context)
            }
    }
}

public extension View {
    /// Observes changes in the specified context
    func observeContext<C: AxiomContext>(
        _ context: C,
        onChange: @escaping (C) -> Void
    ) -> some View {
        self.modifier(ContextObserver(context: context, onChange: onChange))
    }
}

// MARK: - Debug Support

#if DEBUG
public extension View {
    /// Adds debug information about context binding
    func debugContextBinding<C: AxiomContext>(_ context: C) -> some View {
        self.overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Context: \(String(describing: type(of: context)))")
                Text("ID: \(String(describing: context.id).prefix(8))")
            }
            .font(.caption2)
            .padding(4)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(4)
            .padding(4)
        }
    }
}
#endif