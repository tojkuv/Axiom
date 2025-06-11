import Foundation
import SwiftUI

// MARK: - Navigation Component Protocol (W-04-003)

/// Protocol for components that participate in the navigation system
public protocol NavigationComponent: AnyObject, Sendable {
    /// Handle navigation events
    func handleNavigationEvent(_ event: NavigationEvent) async throws
    
    /// Component identifier
    var componentID: String { get }
}

/// Navigation events that components can handle
public enum NavigationEvent: Sendable {
    case routeChanged(from: (any TypeSafeRoute)?, to: any TypeSafeRoute)
    case deepLinkReceived(URL)
    case flowStarted(String)
    case flowCompleted(String)
    case stateRestored
}

// MARK: - Navigation State Store (W-04-003)

/// Centralized state management for navigation
public actor NavigationStateStore {
    public private(set) var currentRoute: (any TypeSafeRoute)?
    public private(set) var navigationStack: [any TypeSafeRoute] = []
    public private(set) var activeFlows: Set<String> = []
    private var observers: [String: NavigationStateObserver] = [:]
    
    public init() {}
    
    /// Update current route
    public func setCurrentRoute(_ route: any TypeSafeRoute) async {
        let previousRoute = currentRoute
        currentRoute = route
        navigationStack.append(route)
        
        // Notify observers
        for observer in observers.values {
            await observer.onRouteChanged(from: previousRoute, to: route)
        }
    }
    
    /// Pop route from stack
    public func popRoute() async -> (any TypeSafeRoute)? {
        guard !navigationStack.isEmpty else { return nil }
        let popped = navigationStack.removeLast()
        currentRoute = navigationStack.last
        return popped
    }
    
    /// Add flow to active flows
    public func startFlow(_ flowID: String) {
        activeFlows.insert(flowID)
    }
    
    /// Remove flow from active flows
    public func completeFlow(_ flowID: String) {
        activeFlows.remove(flowID)
    }
    
    /// Register observer
    public func addObserver(_ observer: NavigationStateObserver) {
        observers[observer.id] = observer
    }
    
    /// Remove observer
    public func removeObserver(_ observerID: String) {
        observers.removeValue(forKey: observerID)
    }
}

/// Protocol for observing navigation state changes
public protocol NavigationStateObserver: AnyObject {
    var id: String { get }
    func onRouteChanged(from: (any TypeSafeRoute)?, to: any TypeSafeRoute) async
}

// MARK: - Navigation Core (W-04-003)

/// Core navigation stack management
public final class NavigationCore: NavigationComponent {
    public let componentID = "navigation-core"
    private let stateStore: NavigationStateStore
    
    public init(stateStore: NavigationStateStore = NavigationStateStore()) {
        self.stateStore = stateStore
    }
    
    /// Navigate to a route
    public func navigate<T: TypeSafeRoute>(to route: T) async throws {
        await stateStore.setCurrentRoute(route)
        
        // Handle navigation event
        try await handleNavigationEvent(.routeChanged(from: nil, to: route))
    }
    
    /// Navigate back
    public func navigateBack() async throws -> (any TypeSafeRoute)? {
        return await stateStore.popRoute()
    }
    
    /// Get current route
    public func getCurrentRoute() async -> (any TypeSafeRoute)? {
        return await stateStore.currentRoute
    }
    
    /// NavigationComponent conformance
    public func handleNavigationEvent(_ event: NavigationEvent) async throws {
        // Core handles its own navigation events
        switch event {
        case .stateRestored:
            // Handle state restoration
            break
        default:
            // Other events are handled by specific components
            break
        }
    }
}

// MARK: - Navigation Deep Link Handler (W-04-003)

/// Handles deep link parsing and routing
public final class NavigationDeepLinkHandler: NavigationComponent {
    public let componentID = "deep-link-handler"
    public weak var navigationCore: NavigationCore?
    private var linkHandlers: [String: DeepLinkHandler] = [:]
    
    public typealias DeepLinkHandler = (URL) async throws -> (any TypeSafeRoute)?
    
    public init(navigationCore: NavigationCore? = nil) {
        self.navigationCore = navigationCore
    }
    
    /// Register a deep link handler
    public func registerHandler(for scheme: String, handler: @escaping DeepLinkHandler) {
        linkHandlers[scheme] = handler
    }
    
    /// Handle deep link
    public func handleDeepLink(_ url: URL) async throws -> Bool {
        guard let scheme = url.scheme,
              let handler = linkHandlers[scheme],
              let route = try await handler(url) else {
            return false
        }
        
        try await navigationCore?.navigate(to: route)
        return true
    }
    
    /// NavigationComponent conformance
    public func handleNavigationEvent(_ event: NavigationEvent) async throws {
        switch event {
        case .deepLinkReceived(let url):
            _ = try await handleDeepLink(url)
        default:
            break
        }
    }
}

// MARK: - Navigation Flow Manager (W-04-003)

/// Manages multi-step navigation flows
public final class NavigationFlowManager: NavigationComponent {
    public let componentID = "flow-manager"
    public weak var navigationCore: NavigationCore?
    private let stateStore: NavigationStateStore
    private var activeFlows: [String: NavigationFlowInstance] = [:]
    
    public init(navigationCore: NavigationCore? = nil, stateStore: NavigationStateStore = NavigationStateStore()) {
        self.navigationCore = navigationCore
        self.stateStore = stateStore
    }
    
    /// Start a flow
    public func startFlow(_ flow: BusinessNavigationFlow) async throws {
        let flowID = flow.identifier
        let instance = NavigationFlowInstance(flow: flow, currentStepIndex: 0)
        activeFlows[flowID] = instance
        await stateStore.startFlow(flowID)
        
        // Navigate to first step
        if let firstStep = flow.steps.first,
           let route = firstStep.route {
            try await navigationCore?.navigate(to: route)
        }
    }
    
    /// Complete current step and move to next
    public func completeCurrentStep(in flowID: String) async throws -> Bool {
        guard var instance = activeFlows[flowID] else { return false }
        
        instance.currentStepIndex += 1
        
        if instance.currentStepIndex < instance.flow.steps.count {
            // Move to next step
            let nextStep = instance.flow.steps[instance.currentStepIndex]
            activeFlows[flowID] = instance
            
            if let route = nextStep.route {
                try await navigationCore?.navigate(to: route)
            }
            return true
        } else {
            // Flow completed
            await completeFlow(flowID)
            return false
        }
    }
    
    /// Complete a flow
    public func completeFlow(_ flowID: String) async {
        activeFlows.removeValue(forKey: flowID)
        await stateStore.completeFlow(flowID)
    }
    
    /// NavigationComponent conformance
    public func handleNavigationEvent(_ event: NavigationEvent) async throws {
        switch event {
        case .flowStarted(let flowID):
            // Handle flow started event
            break
        case .flowCompleted(let flowID):
            await completeFlow(flowID)
        default:
            break
        }
    }
}

/// Flow instance tracking
private struct NavigationFlowInstance {
    let flow: BusinessNavigationFlow
    var currentStepIndex: Int
}

// MARK: - Navigation Service Builder (W-04-003)

/// Factory for building modular navigation service
public class NavigationServiceBuilder {
    private var stateStore: NavigationStateStore?
    private var patternHandler: DeepLinkPatternHandler?
    private var plugins: [NavigationPlugin] = []
    private var middleware: [NavigationMiddleware] = []
    
    public init() {}
    
    /// Set custom state store
    @discardableResult
    public func withStateStore(_ store: NavigationStateStore) -> Self {
        self.stateStore = store
        return self
    }
    
    /// Set custom pattern handler
    @discardableResult
    public func withPatternHandler(_ handler: DeepLinkPatternHandler) -> Self {
        self.patternHandler = handler
        return self
    }
    
    /// Add plugin
    @discardableResult
    public func withPlugin(_ plugin: NavigationPlugin) -> Self {
        self.plugins.append(plugin)
        return self
    }
    
    /// Add middleware
    @discardableResult
    public func withMiddleware(_ middleware: NavigationMiddleware) -> Self {
        self.middleware.append(middleware)
        return self
    }
    
    /// Build navigation service
    public func build() -> ModularNavigationService {
        let store = stateStore ?? NavigationStateStore()
        let pattern = patternHandler ?? DeepLinkPatternHandler()
        let core = NavigationCore(stateStore: store)
        let deepLinkHandler = NavigationDeepLinkHandler(navigationCore: core)
        let flowManager = NavigationFlowManager(navigationCore: core, stateStore: store)
        
        let service = ModularNavigationService(
            navigationCore: core,
            deepLinkHandler: deepLinkHandler,
            flowManager: flowManager,
            stateStore: store,
            patternHandler: pattern,
            plugins: plugins,
            middleware: middleware
        )
        
        return service
    }
}

// MARK: - Navigation Service (W-04-003)

/// Unified navigation service facade
public class ModularNavigationService: ObservableObject {
    public let navigationCore: NavigationCore
    public let deepLinkHandler: NavigationDeepLinkHandler
    public let flowManager: NavigationFlowManager
    public let stateStore: NavigationStateStore
    
    /// Deep linking framework integration (W-04-004)
    public let patternHandler: DeepLinkPatternHandler
    
    private let plugins: [NavigationPlugin]
    private let middleware: [NavigationMiddleware]
    
    /// Support flags for testing
    public let supportsModularArchitecture = true
    public let supportsPluginSystem = true
    
    public init(
        navigationCore: NavigationCore,
        deepLinkHandler: NavigationDeepLinkHandler,
        flowManager: NavigationFlowManager,
        stateStore: NavigationStateStore,
        patternHandler: DeepLinkPatternHandler = DeepLinkPatternHandler(),
        plugins: [NavigationPlugin] = [],
        middleware: [NavigationMiddleware] = []
    ) {
        self.navigationCore = navigationCore
        self.deepLinkHandler = deepLinkHandler
        self.flowManager = flowManager
        self.stateStore = stateStore
        self.patternHandler = patternHandler
        self.plugins = plugins
        self.middleware = middleware
        
        // Configure components
        deepLinkHandler.navigationCore = navigationCore
        flowManager.navigationCore = navigationCore
        
        // Initialize plugins
        for plugin in plugins {
            plugin.initialize(with: self)
        }
    }
    
    /// Convenience initializer
    public convenience init() {
        let builder = NavigationServiceBuilder()
        let built = builder.build()
        self.init(
            navigationCore: built.navigationCore,
            deepLinkHandler: built.deepLinkHandler,
            flowManager: built.flowManager,
            stateStore: built.stateStore,
            patternHandler: built.patternHandler,
            plugins: [],
            middleware: []
        )
    }
    
    /// Navigate to route with middleware processing
    public func navigate<T: TypeSafeRoute>(to route: T) async throws {
        var processedRoute: any TypeSafeRoute = route
        
        // Process through middleware
        for mw in middleware {
            processedRoute = try await mw.process(route: processedRoute, in: self)
        }
        
        // Perform navigation
        try await navigationCore.navigate(to: processedRoute)
        
        // Notify plugins
        for plugin in plugins {
            await plugin.didNavigate(to: processedRoute)
        }
    }
    
    /// Handle deep link (integrated with pattern handler from DeepLinkingFramework.swift)
    public func handleDeepLink(_ url: URL) async -> Bool {
        let result = patternHandler.resolve(url)
        
        switch result {
        case .resolved(let route):
            do {
                try await navigationCore.navigate(to: route)
                return true
            } catch {
                return false
            }
        case .redirect(let redirectURL):
            let redirectResult = patternHandler.resolve(redirectURL)
            if case .resolved(let redirectRoute) = redirectResult {
                do {
                    try await navigationCore.navigate(to: redirectRoute)
                    return true
                } catch {
                    return false
                }
            }
            return false
        case .fallback(let fallbackRoute):
            do {
                try await navigationCore.navigate(to: fallbackRoute)
                return true
            } catch {
                return false
            }
        case .invalid:
            return false
        }
    }
    
    /// Start navigation flow
    public func startFlow(_ flow: BusinessNavigationFlow) async throws {
        try await flowManager.startFlow(flow)
    }
}

// MARK: - Plugin System (W-04-003)

/// Protocol for navigation plugins
public protocol NavigationPlugin: AnyObject {
    /// Initialize plugin with navigation service
    func initialize(with service: ModularNavigationService)
    
    /// Called after navigation completes
    func didNavigate(to route: any TypeSafeRoute) async
}

/// Protocol for navigation middleware
public protocol NavigationMiddleware: AnyObject {
    /// Process route before navigation
    func process(route: any TypeSafeRoute, in service: ModularNavigationService) async throws -> any TypeSafeRoute
}

// MARK: - Pattern Implementations (W-04-003)

/// Command pattern for navigation operations
public struct NavigationCommand {
    public let execute: () async throws -> Void
    public let undo: () async throws -> Void
    
    public init(
        execute: @escaping () async throws -> Void,
        undo: @escaping () async throws -> Void
    ) {
        self.execute = execute
        self.undo = undo
    }
}

/// Observer pattern implementation
public protocol NavigationObserver: AnyObject {
    func navigationDidChange(from: (any TypeSafeRoute)?, to: any TypeSafeRoute)
}

/// Strategy pattern for route resolution
public protocol RouteResolutionStrategy {
    func resolve(from input: Any) async throws -> (any TypeSafeRoute)?
}