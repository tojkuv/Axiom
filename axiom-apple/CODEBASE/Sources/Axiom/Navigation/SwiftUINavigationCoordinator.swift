import SwiftUI
import Foundation

// MARK: - SwiftUI Navigation Coordinator

/// SwiftUI-native navigation coordinator that bridges UIKit NavigationService with SwiftUI
@MainActor
public class SwiftUINavigationCoordinator: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var navigationPath = NavigationPath()
    @Published public var presentedRoutes: [AnyTypeRoute] = []
    @Published public var isNavigating = false
    @Published public var navigationError: AxiomError?
    
    // MARK: - Private State
    
    private let navigationService: AxiomModularNavigationService
    private let routeResolver: RouteResolver
    private var navigationObserver: NavigationObserverImpl?
    
    // MARK: - Initialization
    
    public init(navigationService: AxiomModularNavigationService? = nil, routeResolver: RouteResolver? = nil) {
        self.navigationService = navigationService ?? AxiomModularNavigationService()
        self.routeResolver = routeResolver ?? RouteResolver()
        
        // Set up navigation observation
        self.navigationObserver = NavigationObserverImpl(coordinator: self)
        self.navigationService.addObserver(self.navigationObserver!)
    }
    
    // MARK: - Navigation Methods
    
    public func navigate<R: AxiomTypeSafeRoute>(to route: R) {
        Task {
            isNavigating = true
            navigationError = nil
            
            do {
                // Check if route is SwiftUI compatible
                let isSwiftUICompatible = await routeResolver.isSwiftUICompatible(route)
                
                if isSwiftUICompatible {
                    // Use SwiftUI navigation
                    navigationPath.append(AnyTypeRoute(route))
                } else {
                    // Fall back to UIKit navigation
                    let result = await navigationService.navigate(to: route.routeIdentifier)
                    if case .failure(let error) = result {
                        throw error
                    }
                }
                
            } catch {
                await MainActor.run {
                    navigationError = error as? AxiomError ?? AxiomError(legacy: error)
                }
            }
            
            await MainActor.run {
                isNavigating = false
            }
        }
    }
    
    public func present<R: AxiomTypeSafeRoute>(_ route: R, style: PresentationStyle = .present(.sheet)) {
        Task {
            // For now, just add to presented routes since AxiomModularNavigationService doesn't have present
            await MainActor.run {
                presentedRoutes.append(AnyTypeRoute(route))
            }
        }
    }
    
    public func pop() {
        Task {
            if !navigationPath.isEmpty {
                await MainActor.run {
                    navigationPath.removeLast()
                }
            } else {
                _ = await navigationService.pop()
            }
        }
    }
    
    public func dismiss() {
        Task {
            if !presentedRoutes.isEmpty {
                _ = await MainActor.run { [weak self] in
                    self?.presentedRoutes.removeLast()
                }
            } else {
                _ = await navigationService.dismiss()
            }
        }
    }
    
    public func popToRoot() {
        Task {
            await MainActor.run {
                navigationPath = NavigationPath()
            }
            _ = await navigationService.popToRoot()
        }
    }
    
    // MARK: - State Access
    
    public var canPop: Bool {
        return !navigationPath.isEmpty || 
               Task { await navigationService.canPop() }.result.map { $0 } ?? false
    }
    
    public var canDismiss: Bool {
        return !presentedRoutes.isEmpty || 
               Task { await navigationService.canDismiss() }.result.map { $0 } ?? false
    }
    
    // MARK: - State Management
    
    public func saveNavigationState() {
        // Implementation for saving navigation state
        // This would persist the current navigation and presentation stacks
    }
    
    public func restoreNavigationState() {
        // Implementation for restoring navigation state
        // This would restore the navigation and presentation stacks from persistence
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        navigationError = nil
    }
    
    internal func handleNavigationError(_ error: AxiomError) {
        navigationError = error
    }
}

// MARK: - Navigation Observer Implementation

@MainActor
private class NavigationObserverImpl: NavigationObserver {
    weak var coordinator: SwiftUINavigationCoordinator?
    
    init(coordinator: SwiftUINavigationCoordinator) {
        self.coordinator = coordinator
    }
    
    func navigationWillStart(to route: AnyTypeRoute) async {
        await MainActor.run {
            coordinator?.isNavigating = true
        }
    }
    
    func navigationDidComplete(to route: AnyTypeRoute) async {
        await MainActor.run {
            coordinator?.isNavigating = false
            // Note: Without action context, we can't determine the specific type of navigation
            // This could be enhanced by modifying the NavigationObserver protocol to include action info
        }
    }
    
    func navigationFailed(to route: AnyTypeRoute, error: AxiomError) async {
        await MainActor.run {
            coordinator?.isNavigating = false
            coordinator?.handleNavigationError(error)
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Configure this view with Axiom navigation support
    public func withAxiomNavigation(_ coordinator: SwiftUINavigationCoordinator) -> some View {
        self
            .navigationDestination(for: AnyTypeRoute.self) { route in
                RouteView(route: route)
                    .environmentObject(coordinator)
            }
            .sheet(item: Binding(
                get: { coordinator.presentedRoutes.last },
                set: { _ in coordinator.dismiss() }
            )) { route in
                RouteView(route: route)
                    .environmentObject(coordinator)
            }
            .alert("Navigation Error", isPresented: Binding(
                get: { coordinator.navigationError != nil },
                set: { _ in coordinator.clearError() }
            )) {
                Button("OK") {
                    coordinator.clearError()
                }
            } message: {
                if let error = coordinator.navigationError {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - Route View Resolution

/// View that resolves a route to its corresponding SwiftUI view
struct RouteView: View {
    let route: AnyTypeRoute
    @EnvironmentObject var coordinator: SwiftUINavigationCoordinator
    
    var body: some View {
        Group {
            if let view = resolveView(for: route) {
                AnyView(view)
            } else {
                Text("Route not found: \(route.routeIdentifier)")
                    .foregroundColor(.red)
            }
        }
    }
    
    private func resolveView(for route: AnyTypeRoute) -> (any View)? {
        // This would use the RouteResolver to get the actual view
        // For now, return placeholder views based on route patterns
        
        switch route.pathComponents {
        case "/":
            return HomeViewPlaceholder()
        case let path where path.hasPrefix("/profile/"):
            let userId = String(path.dropFirst("/profile/".count))
            return ProfileViewPlaceholder(userId: userId)
        case let path where path.hasPrefix("/detail/"):
            let itemId = String(path.dropFirst("/detail/".count))
            return DetailViewPlaceholder(itemId: itemId)
        case "/settings":
            return SettingsViewPlaceholder(section: nil)
        case let path where path.hasPrefix("/settings/"):
            let section = String(path.dropFirst("/settings/".count))
            return SettingsViewPlaceholder(section: section)
        default:
            return nil
        }
    }
}

// MARK: - NavigationStack Integration

/// Enhanced NavigationStack with Axiom integration
@available(iOS 16.0, *)
public struct AxiomNavigationStack<Content: View>: View {
    @StateObject private var coordinator: SwiftUINavigationCoordinator
    private let content: () -> Content
    
    public init(
        navigationService: AxiomModularNavigationService? = nil,
        routeResolver: RouteResolver? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._coordinator = StateObject(wrappedValue: SwiftUINavigationCoordinator(
            navigationService: navigationService,
            routeResolver: routeResolver
        ))
        self.content = content
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            content()
                .withAxiomNavigation(coordinator)
        }
        .environmentObject(coordinator)
        .onAppear {
            coordinator.restoreNavigationState()
        }
        .onDisappear {
            coordinator.saveNavigationState()
        }
    }
}

// MARK: - Dynamic Navigation Support

/// Protocol for providing navigation destinations
public protocol NavigationDestinationProvider {
    associatedtype Route: AxiomTypeSafeRoute
    associatedtype Destination: View
    
    @ViewBuilder
    func destination(for route: Route) -> Destination
}

/// Dynamic navigation stack that supports runtime destination registration
public struct DynamicNavigationStack<Content: View>: View {
    @StateObject private var coordinator: SwiftUINavigationCoordinator
    private let content: () -> Content
    private var providers: [Any] = []
    
    public init(
        navigationService: AxiomModularNavigationService? = nil,
        routeResolver: RouteResolver? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._coordinator = StateObject(wrappedValue: SwiftUINavigationCoordinator(
            navigationService: navigationService,
            routeResolver: routeResolver
        ))
        self.content = content
    }
    
    public func navigationDestination<P: NavigationDestinationProvider>(
        _ provider: P
    ) -> Self {
        var copy = self
        copy.providers.append(provider)
        return copy
    }
    
    public var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            content()
                .withAxiomNavigation(coordinator)
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Placeholder Views

private struct HomeViewPlaceholder: View {
    var body: some View {
        VStack {
            Text("Home")
                .font(.largeTitle)
            Text("Welcome to the home screen")
        }
        .navigationTitle("Home")
    }
}

private struct ProfileViewPlaceholder: View {
    let userId: String
    
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
            Text("User ID: \(userId)")
        }
        .navigationTitle("Profile")
    }
}

private struct DetailViewPlaceholder: View {
    let itemId: String
    
    var body: some View {
        VStack {
            Text("Detail")
                .font(.largeTitle)
            Text("Item ID: \(itemId)")
        }
        .navigationTitle("Detail")
    }
}

private struct SettingsViewPlaceholder: View {
    let section: String?
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
            if let section = section {
                Text("Section: \(section)")
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Declarative Navigation

/// Declarative navigation modifiers
extension View {
    public func navigation<Route: AxiomTypeSafeRoute>(
        to route: Route?,
        isActive: Binding<Bool>
    ) -> some View {
        self.onChange(of: isActive.wrappedValue) { _, newValue in
            if newValue, let route = route {
                if let coordinator = findCoordinator() {
                    coordinator.navigate(to: route)
                }
            }
        }
    }
    
    public func navigationLink<Route: AxiomTypeSafeRoute>(
        to route: Route
    ) -> some View {
        Button(action: {
            if let coordinator = findCoordinator() {
                coordinator.navigate(to: route)
            }
        }) {
            self
        }
        .buttonStyle(.plain)
    }
    
    private func findCoordinator() -> SwiftUINavigationCoordinator? {
        // This would traverse the environment to find the coordinator
        // For now, return nil as placeholder
        return nil
    }
}

// MARK: - Task Result Extension

private extension Task where Failure == Never {
    var result: Success? {
        // Simplified implementation - in real code would handle async properly
        return nil
    }
}