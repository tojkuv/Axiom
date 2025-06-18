import Foundation
import SwiftUI
import AxiomCore
import AxiomArchitecture

public final class StudioNavigationService: ObservableObject {
    @Published public private(set) var currentRoute: StudioRoute = .personalInfo
    @Published public private(set) var navigationStack: [StudioRoute] = []
    @Published public private(set) var deepLinkingContext: DeepLinkingContext?
    
    private var routeTransitions: [RouteTransition] = []
    private let maxTransitionHistory = 100
    
    public init() {}
    
    // MARK: - Navigation Methods
    
    public func navigate(to route: StudioRoute, parameters: [String: String] = [:]) {
        let transition = RouteTransition(
            fromRoute: currentRoute,
            toRoute: route,
            parameters: parameters
        )
        
        recordTransition(transition)
        
        // Add current route to stack if navigating to a detail view
        if shouldPushToStack(from: currentRoute, to: route) {
            navigationStack.append(currentRoute)
        }
        
        currentRoute = route
    }
    
    public func goBack() -> Bool {
        guard !navigationStack.isEmpty else { return false }
        
        let previousRoute = navigationStack.removeLast()
        let transition = RouteTransition(
            fromRoute: currentRoute,
            toRoute: previousRoute
        )
        
        recordTransition(transition)
        currentRoute = previousRoute
        return true
    }
    
    public func popToRoot() {
        guard !navigationStack.isEmpty else { return }
        
        let rootRoute = navigationStack.first ?? .personalInfo
        let transition = RouteTransition(
            fromRoute: currentRoute,
            toRoute: rootRoute
        )
        
        recordTransition(transition)
        navigationStack.removeAll()
        currentRoute = rootRoute
    }
    
    public func replace(with route: StudioRoute, parameters: [String: String] = [:]) {
        let transition = RouteTransition(
            fromRoute: currentRoute,
            toRoute: route,
            parameters: parameters
        )
        
        recordTransition(transition)
        currentRoute = route
        // Don't modify the navigation stack for replacements
    }
    
    // MARK: - Deep Linking
    
    public func handleDeepLink(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let route = parseRoute(from: components) else {
            return false
        }
        
        let parameters = parseParameters(from: components)
        let context = DeepLinkingContext(
            sourceURL: url,
            parameters: parameters,
            sourceApplication: nil
        )
        
        setDeepLinkingContext(context)
        navigate(to: route, parameters: parameters)
        return true
    }
    
    public func generateDeepLink(for route: StudioRoute, parameters: [String: String] = [:]) -> URL? {
        var components = URLComponents()
        components.scheme = "axiomstudio"
        components.host = "navigate"
        components.path = "/\(route.rawValue)"
        
        if !parameters.isEmpty {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components.url
    }
    
    private func parseRoute(from components: URLComponents) -> StudioRoute? {
        let pathComponents = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        guard let routeString = pathComponents.first else { return nil }
        
        return StudioRoute(rawValue: routeString)
    }
    
    private func parseParameters(from components: URLComponents) -> [String: String] {
        var parameters: [String: String] = [:]
        
        components.queryItems?.forEach { item in
            parameters[item.name] = item.value
        }
        
        return parameters
    }
    
    public func setDeepLinkingContext(_ context: DeepLinkingContext?) {
        deepLinkingContext = context
    }
    
    public func clearDeepLinkingContext() {
        deepLinkingContext = nil
    }
    
    // MARK: - Route Validation
    
    public func canNavigate(to route: StudioRoute) -> Bool {
        // Add any navigation restrictions here
        return true
    }
    
    public func validateRoute(_ route: StudioRoute) -> RouteValidationResult {
        if !canNavigate(to: route) {
            return .invalid(reason: "Navigation to \(route) is not allowed")
        }
        
        return .valid
    }
    
    // MARK: - Navigation Stack Management
    
    private func shouldPushToStack(from: StudioRoute, to: StudioRoute) -> Bool {
        // Push to stack when navigating from root routes to detail routes
        if from.isRootRoute && !to.isRootRoute && to.category == from.category {
            return true
        }
        
        // Push when navigating between detail views in the same category
        if !from.isRootRoute && !to.isRootRoute && from.category == to.category {
            return true
        }
        
        return false
    }
    
    // MARK: - History Management
    
    private func recordTransition(_ transition: RouteTransition) {
        routeTransitions.append(transition)
        
        if routeTransitions.count > maxTransitionHistory {
            routeTransitions.removeFirst()
        }
    }
    
    public func getNavigationHistory() -> [RouteTransition] {
        return routeTransitions
    }
    
    public func getRecentTransitions(limit: Int = 10) -> [RouteTransition] {
        return Array(routeTransitions.suffix(limit))
    }
    
    // MARK: - Analytics
    
    public func getNavigationAnalytics() -> NavigationAnalytics {
        let routeCounts = Dictionary(grouping: routeTransitions) { $0.toRoute }
            .mapValues { $0.count }
        
        let averageTransitionTime = routeTransitions
            .compactMap { $0.duration }
            .reduce(0, +) / Double(routeTransitions.count)
        
        let mostVisitedRoute = routeCounts.max { $0.value < $1.value }?.key
        
        return NavigationAnalytics(
            totalTransitions: routeTransitions.count,
            routeCounts: routeCounts,
            averageTransitionTime: averageTransitionTime,
            mostVisitedRoute: mostVisitedRoute
        )
    }
    
    // MARK: - State Restoration
    
    public func saveNavigationState() -> NavigationState {
        return NavigationState(
            currentRoute: currentRoute,
            navigationStack: navigationStack,
            deepLinkingContext: deepLinkingContext
        )
    }
    
    public func restoreNavigationState(_ state: NavigationState) {
        currentRoute = state.currentRoute
        navigationStack = state.navigationStack
        deepLinkingContext = state.deepLinkingContext
    }
    
    // MARK: - Platform-Specific Navigation
    
    #if os(iOS)
    public func presentModal(route: StudioRoute, parameters: [String: String] = [:]) {
        // iOS-specific modal presentation
        navigate(to: route, parameters: parameters)
    }
    
    public func pushToNavigationController(route: StudioRoute, parameters: [String: String] = [:]) {
        // iOS-specific navigation controller push
        navigate(to: route, parameters: parameters)
    }
    #endif
    
    #if os(macOS)
    public func openInNewWindow(route: StudioRoute, parameters: [String: String] = [:]) {
        // macOS-specific new window creation
        // This would typically integrate with NSWindowController
        navigate(to: route, parameters: parameters)
    }
    
    public func openInTab(route: StudioRoute, parameters: [String: String] = [:]) {
        // macOS-specific tab creation
        navigate(to: route, parameters: parameters)
    }
    #endif
}

// MARK: - Supporting Types

public enum RouteValidationResult {
    case valid
    case invalid(reason: String)
}

public struct NavigationAnalytics {
    public let totalTransitions: Int
    public let routeCounts: [StudioRoute: Int]
    public let averageTransitionTime: TimeInterval
    public let mostVisitedRoute: StudioRoute?
    
    public init(
        totalTransitions: Int,
        routeCounts: [StudioRoute: Int],
        averageTransitionTime: TimeInterval,
        mostVisitedRoute: StudioRoute?
    ) {
        self.totalTransitions = totalTransitions
        self.routeCounts = routeCounts
        self.averageTransitionTime = averageTransitionTime
        self.mostVisitedRoute = mostVisitedRoute
    }
}