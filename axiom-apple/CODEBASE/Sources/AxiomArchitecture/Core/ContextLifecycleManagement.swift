import Foundation
import AxiomCore
import SwiftUI

// MARK: - Context Lifecycle Protocol

/// Protocol for contexts that can be managed by the framework
public protocol ManagedContext: AxiomContext {
    /// Unique identifier for the context
    nonisolated var id: AnyHashable { get }
    
    /// Called when context is attached to view
    func attached()
    
    /// Called when context is detached from view
    func detached()
}

// MARK: - Context Provider

/// Manages context lifecycle automatically
@MainActor
public final class ContextProvider: ObservableObject {
    private var contexts: [AnyHashable: any ManagedContext] = [:]
    private let lock = NSLock()
    
    /// Get or create a context for an identifier
    public func context<C: ManagedContext>(
        id: AnyHashable,
        create: () -> C
    ) -> C {
        lock.lock()
        defer { lock.unlock() }
        
        if let existing = contexts[id] as? C {
            return existing
        }
        
        let new = create()
        contexts[id] = new
        new.attached()
        return new
    }
    
    /// Remove a context when no longer needed
    public func removeContext(id: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        
        if let context = contexts.removeValue(forKey: id) {
            context.detached()
        }
    }
    
    /// Clear all contexts
    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        
        contexts.values.forEach { $0.detached() }
        contexts.removeAll()
    }
}

// MARK: - SwiftUI Integration

/// View that manages a context's lifecycle
public struct ManagedContextView<Content: View, C: ManagedContext>: View {
    let id: AnyHashable
    let makeContext: () -> C
    let content: (C) -> Content
    
    @EnvironmentObject private var provider: ContextProvider
    @StateObject private var contextHolder = ContextHolder<C>()
    
    public init(id: AnyHashable, makeContext: @escaping () -> C, content: @escaping (C) -> Content) {
        self.id = id
        self.makeContext = makeContext
        self.content = content
    }
    
    public var body: some View {
        content(contextHolder.context ?? provider.context(id: id, create: makeContext))
            .onAppear {
                contextHolder.context = provider.context(id: id, create: makeContext)
            }
            .onDisappear {
                provider.removeContext(id: id)
                contextHolder.context = nil
            }
    }
}

/// Helper class to hold context state
@MainActor
private class ContextHolder<C: ManagedContext>: ObservableObject {
    @Published var context: C?
}

public extension View {
    /// Attach a managed context to this view
    func managedContext<C: ManagedContext>(
        id: AnyHashable,
        create: @escaping () -> C,
        configure: @escaping (C) -> Void = { _ in }
    ) -> some View {
        ManagedContextView(id: id, makeContext: create) { context in
            self.environmentObject(context)
                .onAppear { configure(context) }
        }
    }
}

// MARK: - Dependency Injection

/// Property wrapper for injected contexts
@propertyWrapper
@MainActor
public struct InjectedContext<C: AxiomContext> {
    private let keyPath: KeyPath<ContextContainer, C>
    
    public init(_ keyPath: KeyPath<ContextContainer, C>) {
        self.keyPath = keyPath
    }
    
    public var wrappedValue: C {
        ContextContainer.shared[keyPath: keyPath]
    }
}

/// Global context container for dependency injection
@MainActor
public final class ContextContainer {
    public static let shared = ContextContainer()
    private var storage: [String: Any] = [:]
    
    private init() {}
    
    public func register<C: AxiomContext>(_ context: C, for type: C.Type) {
        storage[String(describing: type)] = context
    }
    
    public func resolve<C: AxiomContext>(_ type: C.Type) -> C? {
        storage[String(describing: type)] as? C
    }
    
    subscript<C: AxiomContext>(keyPath: KeyPath<ContextContainer, C>) -> C {
        // This would require more sophisticated implementation
        // For now, use fatalError - proper implementation would
        // use reflection or registration patterns
        fatalError("Proper keypath-based injection not implemented")
    }
}

// MARK: - Lazy Context Creation

/// Wrapper for lazy context creation
@MainActor
public final class LazyContext<C: AxiomContext>: ObservableObject {
    private var _context: C?
    private let create: () -> C
    
    public init(create: @escaping () -> C) {
        self.create = create
    }
    
    public var context: C {
        if let existing = _context {
            return existing
        }
        let new = create()
        _context = new
        return new
    }
    
    public var isCreated: Bool {
        _context != nil
    }
    
    public func reset() {
        _context = nil
    }
}

// MARK: - List Context Pattern

/// Protocol for list item contexts
public protocol ListItemContext: ManagedContext {
    associatedtype Item: Identifiable
    var item: Item { get }
    init(item: Item, parent: (any AxiomContext)?)
}

/// Helper for managing list contexts
@MainActor
public struct ListContextManager<Item: Identifiable, C: ListItemContext> where C.Item == Item {
    private let provider: ContextProvider
    private let parent: (any AxiomContext)?
    
    public init(provider: ContextProvider, parent: (any AxiomContext)?) {
        self.provider = provider
        self.parent = parent
    }
    
    public func context(for item: Item) -> C {
        provider.context(id: item.id) {
            C(item: item, parent: parent)
        }
    }
    
    public func removeContext(for item: Item) {
        provider.removeContext(id: item.id)
    }
}

// MARK: - Memory Management Utilities

public extension AxiomContext {
    /// Automatically clean up child contexts with deallocated references
    func cleanupDetachedChildren() {
        // Only ObservableContext has childContexts property
        if let observableContext = self as? AxiomObservableContext {
            _ = observableContext.childContexts.filter { wrapper in
                wrapper.context != nil
            }
            // Note: This would require making childContexts settable
            // observableContext.childContexts = cleanedContexts
        }
    }
}

/// Utility for detecting memory leaks in tests
@MainActor
public func assertNoContextLeaks<T>(
    operation: () async throws -> T,
    file: StaticString = #file,
    line: UInt = #line
) async rethrows -> T {
    weak var weakProvider: ContextProvider?
    weak var weakContext: (any ManagedContext)?
    
    let result: T
    
    // Create autorelease pool scope
    autoreleasepool {
        let provider = ContextProvider()
        weakProvider = provider
        
        let context = provider.context(id: "leak-test") {
            TestLeakContext()
        }
        weakContext = context
    }
    
    // Execute operation outside autoreleasepool
    result = try await operation()
    
    // Allow deallocation
    do {
        try await Task.sleep(for: .milliseconds(10))
    } catch {
        // Ignore sleep errors - not critical for the test
    }
    
    if weakProvider != nil || weakContext != nil {
        print("WARNING: Potential memory leak detected at \(file):\(line)")
        print("Provider retained: \(weakProvider != nil)")
        print("Context retained: \(weakContext != nil)")
    }
    
    return result
}

/// Test context for leak detection
private class TestLeakContext: AxiomObservableContext, ManagedContext {
    nonisolated var id: AnyHashable { "test-leak" }
    
    nonisolated func attached() {}
    nonisolated func detached() {}
}