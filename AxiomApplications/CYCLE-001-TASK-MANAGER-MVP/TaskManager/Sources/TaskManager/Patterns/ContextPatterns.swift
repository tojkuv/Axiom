import Foundation
import SwiftUI
import Axiom

// MARK: - Refactored Context Patterns

/// Base class for contexts that automatically syncs initial state
@MainActor
class AutoSyncContext<C: Client>: ClientObservingContext<C> {
    override init(client: C) {
        super.init(client: client)
        
        // Automatically sync initial state
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            await self.syncInitialState()
        }
    }
    
    /// Override this to handle initial state setup
    func syncInitialState() async {
        // Subclasses should override
    }
}

// MARK: - View Modifiers for Context Lifecycle

struct ContextLifecycle: ViewModifier {
    let context: any Context
    
    func body(content: Content) -> some View {
        content
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

extension View {
    /// Automatically manages context lifecycle
    func contextLifecycle(_ context: any Context) -> some View {
        modifier(ContextLifecycle(context: context))
    }
}

// MARK: - Preview Support

/// Helper for creating preview contexts
struct PreviewContext {
    /// Creates a context with mock data for previews
    static func makeTaskListContext(
        tasks: [TaskItem] = [],
        isLoading: Bool = false,
        error: TaskError? = nil
    ) async -> TaskListContext {
        let client = TaskClient()
        
        // Pre-populate client state
        for task in tasks {
            await client.send(.addTask(
                title: task.title,
                description: task.description
            ))
        }
        
        return await TaskListContext(client: client)
    }
}

// MARK: - Error Handling Pattern

extension View {
    /// Standard error banner for any context with error state
    func errorBanner<T>(
        error: Binding<T?>,
        clearAction: @escaping () -> Void
    ) -> some View where T: Error {
        self.overlay(alignment: .top) {
            if let errorValue = error.wrappedValue {
                ErrorBannerView(
                    error: errorValue,
                    clearAction: clearAction
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct ErrorBannerView<E: Error>: View {
    let error: E
    let clearAction: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(error.localizedDescription)
                .foregroundColor(.white)
                .font(.footnote)
            
            Spacer()
            
            Button(action: clearAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red)
    }
}

// MARK: - Navigation Pattern

/// Type-safe navigation coordinator
@MainActor
class NavigationCoordinator<Route: Hashable>: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: Route?
    @Published var presentedFullScreen: Route?
    
    func push(_ route: Route) {
        navigationPath.append(route)
    }
    
    func present(_ route: Route, fullScreen: Bool = false) {
        if fullScreen {
            presentedFullScreen = route
        } else {
            presentedSheet = route
        }
    }
    
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

// MARK: - List Empty State Pattern

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}