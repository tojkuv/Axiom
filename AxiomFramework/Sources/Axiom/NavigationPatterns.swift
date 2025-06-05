import Foundation
import SwiftUI

// MARK: - Navigation Pattern Implementation

/// Navigation pattern protocol for extensible navigation strategies
public protocol NavigationPattern: Actor {
    /// Pattern type identifier
    var patternType: NavigationPatternType { get }
    
    /// Current navigation state
    var currentState: NavigationState { get async }
    
    /// Navigate to a route
    func navigate(to route: Route) async throws
    
    /// Can navigate to the given route
    func canNavigate(to route: Route) async -> Bool
    
    /// Validate navigation in context
    func validateInContext(_ context: NavigationPatternContext) async throws
}

/// Navigation pattern types
public enum NavigationPatternType: Equatable, Hashable, Sendable, CaseIterable {
    case stack
    case modal
    case tab
    case navigation // Basic navigation without pattern
    case custom(String)
    
    public static var allCases: [NavigationPatternType] {
        [.stack, .modal, .tab, .navigation, .custom("default")]
    }
}

/// Navigation state for patterns
public struct NavigationState: Sendable {
    public let currentRoute: Route?
    public let history: [Route]
    public let metadata: NavigationMetadata
    
    public init(currentRoute: Route? = nil, history: [Route] = [], metadata: NavigationMetadata = NavigationMetadata()) {
        self.currentRoute = currentRoute
        self.history = history
        self.metadata = metadata
    }
}

/// Navigation metadata that is Sendable
public struct NavigationMetadata: Sendable {
    public let depth: Int
    public let isPresented: Bool
    public let selectedTab: String
    public let tabCount: Int
    
    public init(depth: Int = 0, isPresented: Bool = false, selectedTab: String = "", tabCount: Int = 0) {
        self.depth = depth
        self.isPresented = isPresented
        self.selectedTab = selectedTab
        self.tabCount = tabCount
    }
}

/// Navigation pattern context for hierarchy management
@MainActor
public final class NavigationPatternContext: ObservableObject {
    public let pattern: NavigationPatternType
    public weak var parent: NavigationPatternContext?
    public let id = UUID()
    @Published public private(set) var children: [NavigationPatternContext] = []
    
    public init(pattern: NavigationPatternType, parent: NavigationPatternContext? = nil) {
        self.pattern = pattern
        self.parent = parent
    }
    
    public func addChild(_ child: NavigationPatternContext) {
        children.append(child)
    }
    
    public func removeChild(_ child: NavigationPatternContext) {
        children.removeAll { $0.id == child.id }
    }
}

// MARK: - Navigation Pattern Errors

/// Navigation pattern specific errors
public enum NavigationPatternError: Error, LocalizedError, Sendable {
    case patternConflict(String)
    case invalidContext(String)
    case circularNavigation([Route])
    case emptyStack
    case noModalPresented
    case tabNotFound(String)
    case invalidHierarchy(String)
    case depthLimitExceeded(Int)
    case missingPresentingRoute
    case tabsNotConfigured
    case insufficientTabs(Int)
    
    public var errorDescription: String? {
        switch self {
        case .patternConflict(let message):
            return "Navigation pattern conflict: \(message)"
        case .invalidContext(let message):
            return "Invalid navigation context: \(message)"
        case .circularNavigation(let routes):
            return "Circular navigation detected: \(routes.map { $0.identifier }.joined(separator: " -> "))"
        case .emptyStack:
            return "Cannot pop from empty navigation stack"
        case .noModalPresented:
            return "No modal is currently presented"
        case .tabNotFound(let tab):
            return "Tab not found: \(tab)"
        case .invalidHierarchy(let message):
            return "Invalid navigation hierarchy: \(message)"
        case .depthLimitExceeded(let limit):
            return "Navigation depth limit exceeded: \(limit)"
        case .missingPresentingRoute:
            return "Modal presentation requires a presenting route"
        case .tabsNotConfigured:
            return "Tabs must be configured before use"
        case .insufficientTabs(let count):
            return "Tab navigation requires at least 2 tabs, got \(count)"
        }
    }
}

// MARK: - Stack Navigation Pattern

/// Stack-based navigation pattern implementation
public actor StackNavigationPattern: NavigationPattern {
    public let patternType = NavigationPatternType.stack
    private var stack: [Route] = []
    private let maxDepth: Int
    
    public init(maxDepth: Int = Int.max) {
        self.maxDepth = maxDepth
    }
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: stack.last,
            history: stack,
            metadata: NavigationMetadata(depth: stack.count)
        )
    }
    
    public var currentRoute: Route? {
        stack.last
    }
    
    public func navigate(to route: Route) async throws {
        try push(route)
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        // Check for cycles
        if stack.contains(route) {
            return false
        }
        
        // Check depth limit
        if stack.count >= maxDepth {
            return false
        }
        
        return true
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Stack pattern is valid in most contexts
        let (pattern, parentPattern) = await MainActor.run {
            (context.pattern, context.parent?.pattern)
        }
        
        if pattern == .modal && parentPattern == .modal {
            throw NavigationPatternError.invalidContext("Stack navigation not allowed in nested modals")
        }
    }
    
    public func push(_ route: Route) throws {
        // Check for cycles
        if stack.contains(route) {
            throw NavigationPatternError.circularNavigation(stack + [route])
        }
        
        // Check depth limit
        if stack.count >= maxDepth {
            throw NavigationPatternError.depthLimitExceeded(maxDepth)
        }
        
        stack.append(route)
    }
    
    @discardableResult
    public func pop() throws -> Route {
        guard !stack.isEmpty else {
            throw NavigationPatternError.emptyStack
        }
        return stack.removeLast()
    }
    
    public func popToRoot() throws {
        guard !stack.isEmpty else {
            throw NavigationPatternError.emptyStack
        }
        let root = stack[0]
        stack = [root]
    }
    
    public func popTo(_ route: Route) throws {
        guard let index = stack.firstIndex(of: route) else {
            throw NavigationPatternError.invalidContext("Route not found in stack")
        }
        stack = Array(stack.prefix(index + 1))
    }
}

// MARK: - Modal Navigation Pattern

/// Modal presentation navigation pattern
public actor ModalNavigationPattern: NavigationPattern {
    public let patternType = NavigationPatternType.modal
    private var currentModal: Route?
    private var presentingRoute: Route?
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: currentModal,
            history: [presentingRoute, currentModal].compactMap { $0 },
            metadata: NavigationMetadata(isPresented: currentModal != nil)
        )
    }
    
    public var isModalPresented: Bool {
        currentModal != nil
    }
    
    public func navigate(to route: Route) async throws {
        guard let presenting = presentingRoute else {
            throw NavigationPatternError.missingPresentingRoute
        }
        try await present(route, over: presenting)
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        // Can't present modal over modal
        return currentModal == nil
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Modal can be presented in most contexts
        let pattern = await MainActor.run {
            context.pattern
        }
        
        if pattern == .modal {
            throw NavigationPatternError.invalidContext("Cannot present modal over modal")
        }
    }
    
    public func present(_ route: Route, over presenting: Route?) async throws {
        guard presenting != nil else {
            throw NavigationPatternError.missingPresentingRoute
        }
        
        guard currentModal == nil else {
            throw NavigationPatternError.patternConflict("Cannot present modal over existing modal")
        }
        
        currentModal = route
        presentingRoute = presenting
    }
    
    @discardableResult
    public func dismiss() async throws -> Route {
        guard let modal = currentModal else {
            throw NavigationPatternError.noModalPresented
        }
        
        currentModal = nil
        presentingRoute = nil
        return modal
    }
    
    public func setCurrentModal(_ route: Route) {
        currentModal = route
    }
    
    public func validateNavigation(to route: Route, from current: Route) throws {
        if currentModal != nil {
            throw NavigationPatternError.patternConflict("Cannot navigate while modal is presented")
        }
    }
}

// MARK: - Tab Navigation Pattern

/// Tab-based navigation pattern
public actor TabNavigationPattern: NavigationPattern {
    public let patternType = NavigationPatternType.tab
    private var tabs: [(identifier: String, route: Route)] = []
    private var selectedTab: String?
    private var tabStacks: [String: [Route]] = [:]
    
    public var currentState: NavigationState {
        NavigationState(
            currentRoute: currentRoute,
            history: getAllRoutes(),
            metadata: NavigationMetadata(
                selectedTab: selectedTab ?? "",
                tabCount: tabs.count
            )
        )
    }
    
    public var currentRoute: Route? {
        guard let selectedTab = selectedTab,
              let tab = tabs.first(where: { $0.identifier == selectedTab }) else {
            return nil
        }
        
        // Return top of stack for current tab, or tab's base route
        return tabStacks[selectedTab]?.last ?? tab.route
    }
    
    public func navigate(to route: Route) async throws {
        guard selectedTab != nil else {
            throw NavigationPatternError.tabsNotConfigured
        }
        try pushInCurrentTab(route)
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        return selectedTab != nil
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        let pattern = await MainActor.run {
            context.pattern
        }
        
        if pattern == .modal {
            throw NavigationPatternError.invalidContext("Tab navigation not allowed within modal context - tab patterns cannot be nested in modals")
        }
    }
    
    public func configureTabs(_ tabs: [(String, Route)]) throws {
        guard tabs.count >= 2 else {
            throw NavigationPatternError.insufficientTabs(tabs.count)
        }
        
        self.tabs = tabs
        self.selectedTab = tabs.first?.0
        
        // Initialize stacks for each tab
        for (identifier, route) in tabs {
            tabStacks[identifier] = [route]
        }
    }
    
    public func selectTab(_ identifier: String) throws {
        guard tabs.contains(where: { $0.identifier == identifier }) else {
            throw NavigationPatternError.tabNotFound(identifier)
        }
        selectedTab = identifier
    }
    
    public func pushInCurrentTab(_ route: Route) throws {
        guard let selectedTab = selectedTab else {
            throw NavigationPatternError.tabsNotConfigured
        }
        
        if tabStacks[selectedTab] == nil {
            tabStacks[selectedTab] = []
        }
        tabStacks[selectedTab]?.append(route)
    }
    
    public func popInCurrentTab() throws -> Route? {
        guard let selectedTab = selectedTab,
              var stack = tabStacks[selectedTab],
              stack.count > 1 else {
            return nil
        }
        
        let popped = stack.removeLast()
        tabStacks[selectedTab] = stack
        return popped
    }
    
    public func getStackForTab(_ identifier: String) -> [Route] {
        return tabStacks[identifier] ?? []
    }
    
    private func getAllRoutes() -> [Route] {
        var allRoutes: [Route] = []
        for (_, stack) in tabStacks {
            allRoutes.append(contentsOf: stack)
        }
        return allRoutes
    }
}

// MARK: - Navigation Hierarchy Manager

/// Manages navigation pattern hierarchy
@MainActor
public final class NavigationHierarchy: ObservableObject {
    @Published private var root: NavigationPatternContext?
    @Published private var activeContext: NavigationPatternContext?
    
    public var depth: Int {
        guard let root = root else { return 0 }
        return calculateDepth(from: root)
    }
    
    public var activeLeaf: NavigationPatternContext? {
        guard let root = root else { return nil }
        return findActiveLeaf(from: root)
    }
    
    public func setRoot(_ context: NavigationPatternContext) throws {
        guard context.parent == nil else {
            throw NavigationPatternError.invalidHierarchy("Root context cannot have parent")
        }
        root = context
        activeContext = context
    }
    
    public func addChild(_ child: NavigationPatternContext, to parent: NavigationPatternContext) throws {
        // Validate hierarchy rules
        try validateHierarchy(child: child, parent: parent)
        
        parent.addChild(child)
        activeContext = child
    }
    
    public func removeChild(_ child: NavigationPatternContext, from parent: NavigationPatternContext) {
        parent.removeChild(child)
        if activeContext?.id == child.id {
            activeContext = parent
        }
    }
    
    public func pathToRoot(from context: NavigationPatternContext) -> [NavigationPatternContext] {
        var path: [NavigationPatternContext] = [context]
        var current = context
        
        while let parent = current.parent {
            path.append(parent)
            current = parent
        }
        
        return path
    }
    
    private func calculateDepth(from context: NavigationPatternContext) -> Int {
        if context.children.isEmpty {
            return 1
        }
        
        return 1 + (context.children.map { calculateDepth(from: $0) }.max() ?? 0)
    }
    
    private func findActiveLeaf(from context: NavigationPatternContext) -> NavigationPatternContext {
        if context.children.isEmpty {
            return context
        }
        
        // Return the active child path
        if let active = context.children.first(where: { isInActivePath($0) }) {
            return findActiveLeaf(from: active)
        }
        
        // Fallback to last child
        return findActiveLeaf(from: context.children.last!)
    }
    
    private func isInActivePath(_ context: NavigationPatternContext) -> Bool {
        var current: NavigationPatternContext? = activeContext
        while let ctx = current {
            if ctx.id == context.id {
                return true
            }
            current = ctx.parent
        }
        return false
    }
    
    private func validateHierarchy(child: NavigationPatternContext, parent: NavigationPatternContext) throws {
        // Tab cannot be child of modal
        if parent.pattern == .modal && child.pattern == .tab {
            throw NavigationPatternError.invalidHierarchy("Tab navigation cannot be child of modal")
        }
        
        // Modal cannot be child of modal
        if parent.pattern == .modal && child.pattern == .modal {
            throw NavigationPatternError.invalidHierarchy("Modal cannot be presented over another modal")
        }
        
        // Tab cannot be child of tab
        if parent.pattern == .tab && child.pattern == .tab {
            throw NavigationPatternError.invalidHierarchy("Tab cannot be nested within another tab")
        }
    }
}

// MARK: - Navigation Coordinator

/// Coordinates multiple navigation patterns
public actor NavigationPatternCoordinator {
    private var rootPattern: NavigationPatternType?
    private var stackPattern: StackNavigationPattern?
    private var modalPattern: ModalNavigationPattern?
    private var tabPattern: TabNavigationPattern?
    private var hierarchy: NavigationHierarchy?
    
    public var currentRoute: Route? {
        get async {
            if let modal = modalPattern, await modal.isModalPresented {
                return await modal.currentState.currentRoute
            }
            
            switch rootPattern {
            case .stack:
                return await stackPattern?.currentRoute
            case .tab:
                return await tabPattern?.currentRoute
            default:
                return nil
            }
        }
    }
    
    public var isModalPresented: Bool {
        get async {
            await modalPattern?.isModalPresented ?? false
        }
    }
    
    public var modalPresentingRoute: Route? {
        get async {
            guard let modal = modalPattern,
                  await modal.isModalPresented else {
                return nil
            }
            return await modal.currentState.history.first
        }
    }
    
    public func setRootPattern(_ pattern: NavigationPatternType) async throws {
        rootPattern = pattern
        
        hierarchy = await MainActor.run {
            NavigationHierarchy()
        }
        
        switch pattern {
        case .stack:
            stackPattern = StackNavigationPattern()
        case .tab:
            tabPattern = TabNavigationPattern()
        case .modal:
            throw NavigationPatternError.invalidContext("Modal cannot be root pattern")
        default:
            break
        }
        
        // Create root context
        let rootContext = await MainActor.run {
            NavigationPatternContext(pattern: pattern)
        }
        
        if let hierarchy = hierarchy {
            try await MainActor.run {
                try hierarchy.setRoot(rootContext)
            }
        }
    }
    
    public func navigate(to route: Route, pattern: NavigationPatternType) async throws {
        switch pattern {
        case .stack:
            // If root pattern is tab, delegate to tab navigation
            if rootPattern == .tab, let tabs = tabPattern {
                try await tabs.navigate(to: route)
            } else if let stack = stackPattern {
                try await stack.push(route)
            } else {
                throw NavigationPatternError.invalidContext("Stack pattern not initialized")
            }
            
        case .modal:
            if modalPattern == nil {
                modalPattern = ModalNavigationPattern()
            }
            let presenting = await currentRoute ?? Route.home
            try await modalPattern?.present(route, over: presenting)
            
        default:
            throw NavigationPatternError.invalidContext("Pattern not supported: \(pattern)")
        }
    }
    
    public func dismissModal() async throws {
        guard let modal = modalPattern else {
            throw NavigationPatternError.noModalPresented
        }
        _ = try await modal.dismiss()
    }
    
    public func configureTabPattern(tabs: [(String, Route)]) async throws {
        guard rootPattern == .tab else {
            throw NavigationPatternError.invalidContext("Tab configuration requires tab root pattern")
        }
        try await tabPattern?.configureTabs(tabs)
    }
    
    public func selectTab(_ identifier: String) async throws {
        guard let tabs = tabPattern else {
            throw NavigationPatternError.tabsNotConfigured
        }
        try await tabs.selectTab(identifier)
    }
}

// MARK: - SwiftUI Integration

/// Navigation pattern environment key
struct NavigationPatternKey: EnvironmentKey {
    static let defaultValue: NavigationPatternType = .navigation
}

/// Navigation coordinator environment key
struct NavigationPatternCoordinatorKey: EnvironmentKey {
    typealias Value = NavigationPatternCoordinator?
    static let defaultValue: NavigationPatternCoordinator? = nil
}

public extension EnvironmentValues {
    var navigationPattern: NavigationPatternType {
        get { self[NavigationPatternKey.self] }
        set { self[NavigationPatternKey.self] = newValue }
    }
    
    var navigationCoordinator: NavigationPatternCoordinator? {
        get { self[NavigationPatternCoordinatorKey.self] }
        set { self[NavigationPatternCoordinatorKey.self] = newValue }
    }
}

// MARK: - Navigation Pattern Builders

/// Builder for creating navigation patterns
public struct NavigationPatternBuilder {
    private var patterns: [NavigationPatternType: any NavigationPattern] = [:]
    
    public init() {}
    
    public func withStackPattern(maxDepth: Int = Int.max) -> NavigationPatternBuilder {
        var builder = self
        builder.patterns[.stack] = StackNavigationPattern(maxDepth: maxDepth)
        return builder
    }
    
    public func withModalPattern() -> NavigationPatternBuilder {
        var builder = self
        builder.patterns[.modal] = ModalNavigationPattern()
        return builder
    }
    
    public func withTabPattern() -> NavigationPatternBuilder {
        var builder = self
        builder.patterns[.tab] = TabNavigationPattern()
        return builder
    }
    
    public func build() -> [NavigationPatternType: any NavigationPattern] {
        return patterns
    }
}

// MARK: - Pattern Composition Support

/// Composable navigation pattern supporting multiple strategies
public actor CompositeNavigationPattern: NavigationPattern {
    public let patternType = NavigationPatternType.custom("composite")
    private var patterns: [NavigationPatternType: any NavigationPattern] = [:]
    private var activePattern: NavigationPatternType = .navigation
    
    public var currentState: NavigationState {
        get async {
            guard let pattern = patterns[activePattern] else {
                return NavigationState()
            }
            return await pattern.currentState
        }
    }
    
    public func navigate(to route: Route) async throws {
        guard let pattern = patterns[activePattern] else {
            throw NavigationPatternError.invalidContext("No active pattern")
        }
        try await pattern.navigate(to: route)
    }
    
    public func canNavigate(to route: Route) async -> Bool {
        guard let pattern = patterns[activePattern] else {
            return false
        }
        return await pattern.canNavigate(to: route)
    }
    
    public func validateInContext(_ context: NavigationPatternContext) async throws {
        // Composite pattern adapts to context
    }
    
    public func addPattern(_ pattern: any NavigationPattern, for type: NavigationPatternType) {
        patterns[type] = pattern
    }
    
    public func switchToPattern(_ type: NavigationPatternType) throws {
        guard patterns[type] != nil else {
            throw NavigationPatternError.invalidContext("Pattern not registered: \(type)")
        }
        activePattern = type
    }
}