import SwiftUI
import Combine

// MARK: - View-Context Binding

/// A property wrapper that automatically binds a view to its context
@propertyWrapper
@MainActor
public struct ContextBinding<Context: AxiomContext>: DynamicProperty {
    @ObservedObject private var context: Context
    
    public var wrappedValue: Context {
        get { context }
    }
    
    public var projectedValue: ObservedObject<Context>.Wrapper {
        $context
    }
    
    public init(_ context: Context) {
        self.context = context
    }
}

// MARK: - Reactive View Integration

/// A reactive view wrapper that automatically observes context changes
public struct ReactiveAxiomView<Context: AxiomContext, Content: View>: View {
    @ObservedObject private var context: Context
    @StateObject private var updateTrigger = UpdateTrigger()
    private let content: (Context) -> Content
    
    public init(
        context: Context,
        @ViewBuilder content: @escaping (Context) -> Content
    ) {
        self.context = context
        self.content = content
    }
    
    public var body: some View {
        content(context)
            .id(updateTrigger.id)
            .onReceive(context.objectWillChange) { _ in
                updateTrigger.trigger()
            }
            .task {
                await context.onAppear()
                await setupReactiveBindings()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
    }
    
    private func setupReactiveBindings() async {
        // Setup automatic state observation
        await context.setupAutomaticStateObservation()
    }
}

/// Trigger for forcing view updates
private class UpdateTrigger: ObservableObject {
    @Published var id = UUID()
    
    func trigger() {
        id = UUID()
    }
}

// MARK: - Axiom Environment Key

/// Environment key for passing AxiomContext through the view hierarchy
private struct AxiomContextKey: EnvironmentKey {
    static let defaultValue: (any AxiomContext)? = nil
}

extension EnvironmentValues {
    /// The current AxiomContext in the environment
    public var axiomContext: (any AxiomContext)? {
        get { self[AxiomContextKey.self] }
        set { self[AxiomContextKey.self] = newValue }
    }
}

// MARK: - View Container

/// A container view that provides Axiom framework integration
public struct AxiomContainer<Content: View>: View {
    private let content: Content
    private let context: any AxiomContext
    @StateObject private var contextState = DefaultContextState()
    @StateObject private var performanceTracker = ViewPerformanceTracker()
    
    public init(
        context: any AxiomContext,
        @ViewBuilder content: () -> Content
    ) {
        self.context = context
        self.content = content()
    }
    
    public var body: some View {
        content
            .environment(\.axiomContext, context)
            .environment(\.axiomPerformanceTracker, performanceTracker)
            .environmentObject(contextState)
            .task {
                performanceTracker.trackViewAppear()
                await context.onAppear()
            }
            .onDisappear {
                performanceTracker.trackViewDisappear()
                Task {
                    await context.onDisappear()
                }
            }
            .axiomErrorOverlay(contextState)
            .axiomLoadingOverlay(contextState)
            .axiomPerformanceOverlay(performanceTracker)
    }
}

// MARK: - Context Provider View

/// A view that provides a context to its content
public struct ContextProvider<Context: AxiomContext, Content: View>: View {
    @ObservedObject private var context: Context
    private let content: (Context) -> Content
    
    public init(
        context: Context,
        @ViewBuilder content: @escaping (Context) -> Content
    ) {
        self.context = context
        self.content = content
    }
    
    public var body: some View {
        content(context)
            .environment(\.axiomContext, context)
            .task {
                await context.onAppear()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
    }
}

// MARK: - Navigation Extensions

public extension View {
    /// Presents a sheet with an AxiomContext
    func axiomSheet<Context: AxiomContext, Content: View>(
        isPresented: Binding<Bool>,
        context: Context,
        @ViewBuilder content: @escaping (Context) -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ContextProvider(context: context, content: content)
        }
    }
    
    /// Presents a full screen cover with an AxiomContext (iOS only)
    #if os(iOS)
    func axiomFullScreenCover<Context: AxiomContext, Content: View>(
        isPresented: Binding<Bool>,
        context: Context,
        @ViewBuilder content: @escaping (Context) -> Content
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            ContextProvider(context: context, content: content)
        }
    }
    #endif
}

// MARK: - Navigation Link Support

/// A navigation link that provides context to the destination
public struct AxiomNavigationLink<Context: AxiomContext, Label: View, Destination: View>: View {
    private let context: Context
    private let destination: (Context) -> Destination
    private let label: Label
    
    public init(
        context: Context,
        @ViewBuilder destination: @escaping (Context) -> Destination,
        @ViewBuilder label: () -> Label
    ) {
        self.context = context
        self.destination = destination
        self.label = label()
    }
    
    public var body: some View {
        NavigationLink {
            ContextProvider(context: context, content: destination)
        } label: {
            label
        }
    }
}

// MARK: - Automatic Context Binding

/// Property wrapper for automatic context binding with lifecycle management
@propertyWrapper
@MainActor
public struct AutoBindContext<Context: AxiomContext>: DynamicProperty {
    @StateObject private var contextManager: ContextManager<Context>
    @Environment(\.axiomContext) private var environmentContext
    
    public var wrappedValue: Context {
        contextManager.context
    }
    
    public var projectedValue: Binding<Context> {
        Binding(
            get: { contextManager.context },
            set: { _ in } // Context is read-only
        )
    }
    
    public init(_ context: Context) {
        let manager = ContextManager<Context>(context: context)
        self._contextManager = StateObject(wrappedValue: manager)
    }
}

/// Manages context lifecycle and updates
private class ContextManager<Context: AxiomContext>: ObservableObject {
    @Published var context: Context
    private var cancellables = Set<AnyCancellable>()
    
    init(context: Context) {
        self.context = context
        setupBindings()
    }
    
    private func setupBindings() {
        // Observe context changes
        context.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Performance Tracking

/// Tracks view performance metrics
public class ViewPerformanceTracker: ObservableObject {
    @Published var renderCount: Int = 0
    @Published var lastRenderTime: TimeInterval = 0
    @Published var averageRenderTime: TimeInterval = 0
    
    private var renderTimes: [TimeInterval] = []
    private var appearTime: Date?
    
    func trackViewAppear() {
        appearTime = Date()
        renderCount += 1
    }
    
    func trackViewDisappear() {
        guard let appearTime = appearTime else { return }
        let renderTime = Date().timeIntervalSince(appearTime)
        renderTimes.append(renderTime)
        lastRenderTime = renderTime
        averageRenderTime = renderTimes.reduce(0, +) / Double(renderTimes.count)
        self.appearTime = nil
    }
}

// MARK: - Environment Extensions

private struct AxiomPerformanceTrackerKey: EnvironmentKey {
    static let defaultValue: ViewPerformanceTracker? = nil
}

extension EnvironmentValues {
    /// The current performance tracker in the environment
    public var axiomPerformanceTracker: ViewPerformanceTracker? {
        get { self[AxiomPerformanceTrackerKey.self] }
        set { self[AxiomPerformanceTrackerKey.self] = newValue }
    }
}

// MARK: - Reactive State Observation

public extension AxiomContext {
    /// Sets up automatic state observation for reactive updates
    func setupAutomaticStateObservation() async {
        // This would be implemented by specific context types
        // to set up their state observation
    }
}

// MARK: - Performance Overlay

public extension View {
    /// Adds performance metrics overlay (debug builds only)
    func axiomPerformanceOverlay(_ tracker: ViewPerformanceTracker?) -> some View {
        #if DEBUG
        self.overlay(alignment: .bottomTrailing) {
            if let tracker = tracker {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Renders: \(tracker.renderCount)")
                    Text("Last: \(String(format: "%.2fms", tracker.lastRenderTime * 1000))")
                    Text("Avg: \(String(format: "%.2fms", tracker.averageRenderTime * 1000))")
                }
                .font(.caption2)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
                .allowsHitTesting(false)
            }
        }
        #else
        self
        #endif
    }
}

// MARK: - Reactive State Updates

/// Protocol for contexts that support reactive state updates
public protocol ReactiveContext: AxiomContext {
    /// Stream of state changes
    var stateChanges: AnyPublisher<Void, Never> { get }
    
    /// Configure reactive bindings
    func configureReactiveBindings() async
}

// MARK: - View Update Strategies

/// Strategies for view updates based on state changes
public enum ViewUpdateStrategy {
    case immediate
    case debounced(TimeInterval)
    case throttled(TimeInterval)
    case manual
}

/// View modifier for configuring update strategy
public struct UpdateStrategyModifier: ViewModifier {
    let strategy: ViewUpdateStrategy
    @State private var updatePublisher = PassthroughSubject<Void, Never>()
    @State private var cancellable: AnyCancellable?
    
    public func body(content: Content) -> some View {
        content
            .onReceive(updatePublisher) { _ in
                // Force view update
            }
            .onAppear {
                setupUpdateStrategy()
            }
    }
    
    private func setupUpdateStrategy() {
        switch strategy {
        case .immediate:
            break
        case .debounced(let interval):
            cancellable = updatePublisher
                .debounce(for: .seconds(interval), scheduler: RunLoop.main)
                .sink { _ in }
        case .throttled(let interval):
            cancellable = updatePublisher
                .throttle(for: .seconds(interval), scheduler: RunLoop.main, latest: true)
                .sink { _ in }
        case .manual:
            break
        }
    }
}

public extension View {
    /// Configures the update strategy for this view
    func updateStrategy(_ strategy: ViewUpdateStrategy) -> some View {
        self.modifier(UpdateStrategyModifier(strategy: strategy))
    }
}

// MARK: - Lifecycle Hooks

/// Enhanced lifecycle management for Axiom views
public struct LifecycleModifier<Context: AxiomContext>: ViewModifier {
    let context: Context
    let onFirstAppear: ((Context) async -> Void)?
    let onEachAppear: ((Context) async -> Void)?
    let onDisappear: ((Context) async -> Void)?
    let onBackground: ((Context) async -> Void)?
    let onForeground: ((Context) async -> Void)?
    
    @State private var hasAppeared = false
    
    public func body(content: Content) -> some View {
        content
            .task {
                if !hasAppeared {
                    hasAppeared = true
                    await onFirstAppear?(context)
                }
                await onEachAppear?(context)
            }
            .onDisappear {
                Task {
                    await onDisappear?(context)
                }
            }
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                Task {
                    await onBackground?(context)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                Task {
                    await onForeground?(context)
                }
            }
            #elseif os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                Task {
                    await onBackground?(context)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
                Task {
                    await onForeground?(context)
                }
            }
            #endif
    }
}

public extension View {
    /// Adds enhanced lifecycle management
    func axiomLifecycle<Context: AxiomContext>(
        _ context: Context,
        onFirstAppear: ((Context) async -> Void)? = nil,
        onEachAppear: ((Context) async -> Void)? = nil,
        onDisappear: ((Context) async -> Void)? = nil,
        onBackground: ((Context) async -> Void)? = nil,
        onForeground: ((Context) async -> Void)? = nil
    ) -> some View {
        self.modifier(LifecycleModifier(
            context: context,
            onFirstAppear: onFirstAppear,
            onEachAppear: onEachAppear,
            onDisappear: onDisappear,
            onBackground: onBackground,
            onForeground: onForeground
        ))
    }
}