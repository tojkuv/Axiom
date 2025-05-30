import SwiftUI

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
            .environmentObject(contextState)
            .task {
                await context.onAppear()
            }
            .onDisappear {
                Task {
                    await context.onDisappear()
                }
            }
            .axiomErrorOverlay(contextState)
            .axiomLoadingOverlay(contextState)
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