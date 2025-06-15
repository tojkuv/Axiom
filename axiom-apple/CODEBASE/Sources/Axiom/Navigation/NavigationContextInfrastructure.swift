import Foundation
import SwiftUI
import Combine

// MARK: - Missing Type Stubs for Compilation

/// Temporary stub for DeepLinkHandler
public struct DeepLinkHandler: Sendable {
    public init() {}
    
    public func processDeepLink(_ url: URL) async throws -> any AxiomTypeSafeRoute {
        // Simplified deep link processing - return a basic route
        return AxiomStandardRoute.custom(path: url.path)
    }
}

/// Type-erased route wrapper
public struct AnyTypeRoute: Hashable, Sendable, Codable, Identifiable {
    private let _identifier: String
    
    public init<R: AxiomTypeSafeRoute>(_ route: R) {
        self._identifier = route.routeIdentifier
    }
    
    public init(identifier: String) {
        self._identifier = identifier
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self._identifier = try container.decode(String.self)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_identifier)
    }
    
    public var identifier: String {
        _identifier
    }
    
    public var routeIdentifier: String {
        _identifier
    }
    
    public var pathComponents: String {
        _identifier
    }
    
    public var id: String {
        _identifier
    }
}

/// Navigation observer protocol
public protocol NavigationObserver {
    func navigationWillStart(to route: AnyTypeRoute) async
    func navigationDidComplete(to route: AnyTypeRoute) async
    func navigationFailed(to route: AnyTypeRoute, error: AxiomError) async
}

/// Route analytics stub
public struct RouteAnalytics {
    public static func trackNavigation(to route: String) {}
    public static func trackNavigationFailure(route: String, error: String) {}
}
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Navigation Context Infrastructure (W-02-003)

/// Navigation context for maintaining state across the application
@MainActor
public final class NavigationContext: ObservableObject {
    public static let shared = NavigationContext()
    
    // MARK: - Published State
    
    @Published public var currentRoute: (any AxiomTypeSafeRoute)?
    @Published public var navigationStack: [any AxiomTypeSafeRoute] = []
    @Published public var presentedRoutes: [any AxiomTypeSafeRoute] = []
    @Published public var isNavigating = false
    @Published public var navigationHistory: [NavigationHistoryEntry] = []
    @Published public var canGoBack = false
    @Published public var canGoForward = false
    
    // MARK: - Private State
    
    private var navigationCoordinator: SwiftUINavigationCoordinator?
    private var navigationService: AxiomModularNavigationService
    private var routeResolver: RouteResolver
    private var deepLinkHandler: DeepLinkHandler
    private var navigationPersistence: NavigationPersistence
    private var contextSubscriptions: Set<AnyCancellable> = []
    private let maxHistorySize = 100
    
    // MARK: - Initialization
    
    private init() {
        self.navigationService = AxiomModularNavigationService()
        self.routeResolver = RouteResolver()
        self.deepLinkHandler = DeepLinkHandler()
        self.navigationPersistence = NavigationPersistence()
        
        setupNavigationObservation()
        setupContextSubscriptions()
    }
    
    /// Configure the navigation context with dependencies
    public func configure(
        coordinator: SwiftUINavigationCoordinator? = nil,
        service: AxiomModularNavigationService? = nil,
        resolver: RouteResolver? = nil
    ) {
        if let coordinator = coordinator {
            self.navigationCoordinator = coordinator
        }
        if let service = service {
            self.navigationService = service
        }
        if let resolver = resolver {
            self.routeResolver = resolver
        }
        
        setupNavigationObservation()
    }
    
    // MARK: - Navigation Operations
    
    /// Navigate to a route with context tracking
    public func navigate<R: AxiomTypeSafeRoute>(
        to route: R,
        context: NavigationOperationContext = .default
    ) async {
        isNavigating = true
        
        let historyEntry = NavigationHistoryEntry(
            route: AnyTypeRoute(route),
            timestamp: Date(),
            context: context
        )
        
        // Update navigation state
        currentRoute = route
        addToHistory(historyEntry)
        
        // Perform navigation based on context
        switch context.presentationStyle {
        case .push:
            await pushToStack(route)
        case .present(let style):
            await presentRoute(route, style: style)
        case .replace:
            await replaceCurrentRoute(route)
        case .replaceRoot:
            await replaceRootRoute(route)
        }
        
        // Delegate to appropriate navigation handler
        if let coordinator = navigationCoordinator {
            coordinator.navigate(to: route)
        } else {
            _ = await navigationService.navigate(to: route.routeIdentifier)
        }
        
        // Track navigation analytics
        await trackNavigation(to: route, context: context)
        
        isNavigating = false
    }
    
    /// Pop the current route
    public func pop(animated: Bool = true) async {
        guard !navigationStack.isEmpty else { return }
        
        let poppedRoute = navigationStack.removeLast()
        currentRoute = navigationStack.last
        updateNavigationState()
        
        if let coordinator = navigationCoordinator {
            coordinator.pop()
        } else {
            _ = await navigationService.pop()
        }
        
        await trackNavigation(action: .popped, route: poppedRoute)
    }
    
    /// Dismiss the current presented route
    public func dismiss(animated: Bool = true) async {
        guard !presentedRoutes.isEmpty else { return }
        
        let dismissedRoute = presentedRoutes.removeLast()
        updateNavigationState()
        
        if let coordinator = navigationCoordinator {
            coordinator.dismiss()
        } else {
            _ = await navigationService.dismiss()
        }
        
        await trackNavigation(action: .dismissed, route: dismissedRoute)
    }
    
    /// Pop to root of navigation stack
    public func popToRoot(animated: Bool = true) async {
        guard !navigationStack.isEmpty else { return }
        
        let rootRoute = navigationStack.first
        navigationStack = rootRoute.map { [$0] } ?? []
        currentRoute = rootRoute
        updateNavigationState()
        
        if let coordinator = navigationCoordinator {
            coordinator.popToRoot()
        } else {
            _ = await navigationService.popToRoot()
        }
        
        await trackNavigation(action: .poppedToRoot, route: nil)
    }
    
    /// Handle deep link navigation
    public func handleDeepLink(_ url: URL) async throws {
        let route = try await deepLinkHandler.processDeepLink(url)
        await navigate(to: route, context: .init(
            presentationStyle: .push,
            source: .deepLink,
            metadata: ["url": url.absoluteString]
        ))
    }
    
    // MARK: - State Management
    
    /// Save current navigation state
    public func saveNavigationState() async {
        let state = NavigationState(
            currentRoute: currentRoute.map { AnyTypeRoute(identifier: $0.routeIdentifier) },
            navigationStack: navigationStack.map { AnyTypeRoute(identifier: $0.routeIdentifier) },
            presentedRoutes: presentedRoutes.map { AnyTypeRoute(identifier: $0.routeIdentifier) },
            timestamp: Date()
        )
        
        await navigationPersistence.saveState(state)
    }
    
    /// Restore saved navigation state
    public func restoreNavigationState() async {
        guard await navigationPersistence.loadState() != nil else { return }
        
        // For now, we can't restore the exact routes since we only have identifiers
        // In a full implementation, you'd need a route registry to reconstruct routes from identifiers
        currentRoute = nil
        navigationStack = []
        presentedRoutes = []
        updateNavigationState()
    }
    
    /// Clear navigation history
    public func clearHistory() {
        navigationHistory.removeAll()
    }
    
    /// Get navigation statistics
    public func getNavigationStatistics() -> NavigationStatistics {
        let totalNavigations = navigationHistory.count
        let uniqueRoutes = Set(navigationHistory.map { $0.route.identifier }).count
        let averageNavigationsPerRoute = totalNavigations > 0 ? Double(totalNavigations) / Double(uniqueRoutes) : 0
        
        let navigationSources = Dictionary(grouping: navigationHistory) { $0.context.source }
            .mapValues { $0.count }
        
        return NavigationStatistics(
            totalNavigations: totalNavigations,
            uniqueRoutes: uniqueRoutes,
            averageNavigationsPerRoute: averageNavigationsPerRoute,
            navigationSources: navigationSources,
            currentStackDepth: navigationStack.count,
            presentedRoutesCount: presentedRoutes.count
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupNavigationObservation() {
        Task {
            navigationService.addObserver(NavigationContextObserver(context: self))
        }
    }
    
    private func setupContextSubscriptions() {
        // Monitor navigation stack changes
        $navigationStack
            .sink { [weak self] stack in
                self?.canGoBack = !stack.isEmpty
            }
            .store(in: &contextSubscriptions)
        
        // Monitor presented routes changes
        $presentedRoutes
            .sink { [weak self] presented in
                self?.updateNavigationState()
            }
            .store(in: &contextSubscriptions)
    }
    
    private func pushToStack<R: AxiomTypeSafeRoute>(_ route: R) async {
        navigationStack.append(route)
        updateNavigationState()
    }
    
    private func presentRoute<R: AxiomTypeSafeRoute>(_ route: R, style: PresentationStyle.ModalPresentationStyle) async {
        presentedRoutes.append(route)
        updateNavigationState()
    }
    
    private func replaceCurrentRoute<R: AxiomTypeSafeRoute>(_ route: R) async {
        if !navigationStack.isEmpty {
            navigationStack[navigationStack.count - 1] = route
        } else {
            navigationStack.append(route)
        }
        updateNavigationState()
    }
    
    private func replaceRootRoute<R: AxiomTypeSafeRoute>(_ route: R) async {
        navigationStack = [route]
        presentedRoutes.removeAll()
        updateNavigationState()
    }
    
    private func updateNavigationState() {
        canGoBack = !navigationStack.isEmpty
        canGoForward = false // Future enhancement for forward navigation
    }
    
    private func addToHistory(_ entry: NavigationHistoryEntry) {
        navigationHistory.append(entry)
        
        // Trim history if needed
        if navigationHistory.count > maxHistorySize {
            navigationHistory.removeFirst(navigationHistory.count - maxHistorySize)
        }
    }
    
    private func trackNavigation<R: AxiomTypeSafeRoute>(
        to route: R,
        context: NavigationOperationContext
    ) async {
        RouteAnalytics.trackNavigation(to: route.routeIdentifier)
    }
    
    private func trackNavigation(
        action: NavigationAction,
        route: (any AxiomTypeSafeRoute)?
    ) async {
        if let route = route {
            RouteAnalytics.trackNavigation(to: route.routeIdentifier)
        }
    }
}

/// Navigation operation context
public struct NavigationOperationContext: Sendable {
    public let presentationStyle: NavigationPresentationStyle
    public let source: NavigationSource
    public let animated: Bool
    public let metadata: [String: String]
    
    public init(
        presentationStyle: NavigationPresentationStyle = .push,
        source: NavigationSource = .programmatic,
        animated: Bool = true,
        metadata: [String: String] = [:]
    ) {
        self.presentationStyle = presentationStyle
        self.source = source
        self.animated = animated
        self.metadata = metadata
    }
    
    public static let `default` = NavigationOperationContext()
}

/// Navigation presentation styles
public enum NavigationPresentationStyle: Sendable {
    case push
    case present(PresentationStyle.ModalPresentationStyle)
    case replace
    case replaceRoot
}

/// Navigation sources for analytics
public enum NavigationSource: String, CaseIterable, Sendable {
    case programmatic
    case userAction
    case deepLink
    case notification
    case shortcut
    case widget
    case siri
    case spotlight
}

/// Navigation actions for tracking
public enum NavigationAction: String {
    case navigated
    case popped
    case dismissed
    case poppedToRoot
    case replaced
}

/// Navigation history entry
public struct NavigationHistoryEntry {
    public let route: AnyTypeRoute
    public let timestamp: Date
    public let context: NavigationOperationContext
    
    public init(route: AnyTypeRoute, timestamp: Date, context: NavigationOperationContext) {
        self.route = route
        self.timestamp = timestamp
        self.context = context
    }
}

/// Navigation state for persistence
public struct NavigationState: Codable, Sendable {
    public let currentRoute: AnyTypeRoute?
    public let navigationStack: [AnyTypeRoute]
    public let presentedRoutes: [AnyTypeRoute]
    public let timestamp: Date
    
    public init(
        currentRoute: AnyTypeRoute?,
        navigationStack: [AnyTypeRoute],
        presentedRoutes: [AnyTypeRoute],
        timestamp: Date
    ) {
        self.currentRoute = currentRoute
        self.navigationStack = navigationStack
        self.presentedRoutes = presentedRoutes
        self.timestamp = timestamp
    }
}

/// Navigation statistics
public struct NavigationStatistics {
    public let totalNavigations: Int
    public let uniqueRoutes: Int
    public let averageNavigationsPerRoute: Double
    public let navigationSources: [NavigationSource: Int]
    public let currentStackDepth: Int
    public let presentedRoutesCount: Int
}

/// Navigation context observer
private class NavigationContextObserver: NavigationObserver, @unchecked Sendable {
    weak var context: NavigationContext?
    
    init(context: NavigationContext) {
        self.context = context
    }
    
    func navigationWillStart(to route: AnyTypeRoute) async {
        await MainActor.run {
            context?.isNavigating = true
        }
    }
    
    func navigationDidComplete(to route: AnyTypeRoute) async {
        await MainActor.run {
            context?.isNavigating = false
            // Cannot assign AnyTypeRoute to AxiomTypeSafeRoute - would need route conversion
            // context?.currentRoute = route
        }
    }
    
    func navigationFailed(to route: AnyTypeRoute, error: AxiomError) async {
        await MainActor.run {
            context?.isNavigating = false
        }
    }
}

// MARK: - Navigation Persistence

/// Handles persistence of navigation state
public actor NavigationPersistence {
    private let userDefaults = UserDefaults.standard
    private let stateKey = "AxiomNavigationState"
    
    public init() {}
    
    /// Save navigation state to persistent storage
    public func saveState(_ state: NavigationState) async {
        do {
            let data = try JSONEncoder().encode(state)
            userDefaults.set(data, forKey: stateKey)
        } catch {
            print("Failed to save navigation state: \(error)")
        }
    }
    
    /// Load navigation state from persistent storage
    public func loadState() async -> NavigationState? {
        guard let data = userDefaults.data(forKey: stateKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(NavigationState.self, from: data)
        } catch {
            print("Failed to load navigation state: \(error)")
            return nil
        }
    }
    
    /// Clear saved navigation state
    public func clearState() async {
        userDefaults.removeObject(forKey: stateKey)
    }
}

// MARK: - Context-Aware Navigation Coordinator

/// Unified navigation coordinator that integrates all navigation components
@MainActor
public final class ContextAwareNavigationCoordinator: ObservableObject {
    public let context: NavigationContext
    private let swiftUICoordinator: SwiftUINavigationCoordinator?
    private let navigationService: AxiomModularNavigationService
    private let routeResolver: RouteResolver
    
    public init(
        context: NavigationContext = .shared,
        swiftUICoordinator: SwiftUINavigationCoordinator? = nil,
        navigationService: AxiomModularNavigationService? = nil,
        routeResolver: RouteResolver? = nil
    ) {
        self.context = context
        self.swiftUICoordinator = swiftUICoordinator
        self.navigationService = navigationService ?? AxiomModularNavigationService()
        self.routeResolver = routeResolver ?? RouteResolver()
        
        // Configure context with dependencies
        context.configure(
            coordinator: swiftUICoordinator,
            service: self.navigationService,
            resolver: self.routeResolver
        )
    }
    
    /// Navigate with context awareness
    public func navigate<R: AxiomTypeSafeRoute>(
        to route: R,
        from source: NavigationSource = .userAction,
        animated: Bool = true,
        metadata: [String: String] = [:]
    ) async throws {
        let operationContext = NavigationOperationContext(
            source: source,
            animated: animated,
            metadata: metadata
        )
        
        await context.navigate(to: route, context: operationContext)
    }
    
    /// Present route with context
    public func present<R: AxiomTypeSafeRoute>(
        _ route: R,
        style: PresentationStyle.ModalPresentationStyle = .sheet,
        animated: Bool = true
    ) async throws {
        let operationContext = NavigationOperationContext(
            presentationStyle: .present(style),
            source: .userAction,
            animated: animated
        )
        
        await context.navigate(to: route, context: operationContext)
    }
    
    /// Handle deep link with context
    public func handleDeepLink(_ url: URL) async throws {
        try await context.handleDeepLink(url)
    }
    
    /// Pop with context tracking
    public func pop(animated: Bool = true) async {
        await context.pop(animated: animated)
    }
    
    /// Dismiss with context tracking
    public func dismiss(animated: Bool = true) async {
        await context.dismiss(animated: animated)
    }
}

// MARK: - Error Types

public enum NavigationContextError: LocalizedError {
    case navigationFailed(any Error)
    case routeResolutionFailed(String)
    case contextNotInitialized
    case invalidNavigationState(String)
    
    public var errorDescription: String? {
        switch self {
        case .navigationFailed(let error):
            return "Navigation failed: \(error.localizedDescription)"
        case .routeResolutionFailed(let route):
            return "Failed to resolve route: \(route)"
        case .contextNotInitialized:
            return "Navigation context not properly initialized"
        case .invalidNavigationState(let message):
            return "Invalid navigation state: \(message)"
        }
    }
}

// MARK: - SwiftUI Integration

/// Environment key for navigation context
private struct NavigationContextKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = NavigationContext.shared
}

public extension EnvironmentValues {
    var navigationContext: NavigationContext {
        get { self[NavigationContextKey.self] }
        set { self[NavigationContextKey.self] = newValue }
    }
}

/// SwiftUI view modifier for navigation context
public struct NavigationContextModifier: ViewModifier {
    let context: NavigationContext
    
    public func body(content: Content) -> some View {
        content
            .environment(\.navigationContext, context)
            .onAppear {
                Task {
                    await context.restoreNavigationState()
                }
            }
            .onDisappear {
                Task {
                    await context.saveNavigationState()
                }
            }
    }
}

public extension View {
    /// Apply navigation context to a view
    func navigationContext(_ context: NavigationContext = .shared) -> some View {
        modifier(NavigationContextModifier(context: context))
    }
}

// MARK: - Navigation Context DSL

/// DSL for declarative navigation context configuration
@resultBuilder
public struct NavigationContextBuilder {
    public static func buildBlock(_ components: any NavigationContextComponent...) -> [any NavigationContextComponent] {
        components
    }
}

/// Component for navigation context configuration
public protocol NavigationContextComponent {
    func apply(to context: NavigationContext) async
}

/// Configure navigation context using DSL
public extension NavigationContext {
    func configure(@NavigationContextBuilder _ builder: () -> [any NavigationContextComponent]) async {
        let components = builder()
        for component in components {
            await component.apply(to: self)
        }
    }
}

/// Route registration component
public struct RouteRegistrationComponent: NavigationContextComponent {
    let routes: [any AxiomTypeSafeRoute]
    
    public init(routes: [any AxiomTypeSafeRoute]) {
        self.routes = routes
    }
    
    public func apply(to context: NavigationContext) async {
        // Register routes with the route resolver
        // Implementation would depend on specific route registration needs
    }
}

/// Deep link handler registration component  
public struct DeepLinkHandlerComponent: NavigationContextComponent {
    let patterns: [String]
    
    public init(patterns: [String]) {
        self.patterns = patterns
    }
    
    public func apply(to context: NavigationContext) async {
        // Register deep link patterns
        // Implementation would integrate with DeepLinkHandler
    }
}