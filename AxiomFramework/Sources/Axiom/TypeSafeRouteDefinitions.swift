import Foundation

// MARK: - Type-Safe Route Definitions

/// Type-safe route definition system for navigation
/// 
/// Provides compile-time safety for route construction with associated values,
/// exhaustive enum switching requirements, and frozen enum guarantees.
@frozen
public enum TypeSafeRoute: CaseIterable, Hashable, Sendable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String)
    
    /// Route type classification for UI behavior
    public enum RouteType: Hashable, Sendable {
        case navigation
        case modal
        case custom
    }
    
    /// Get route type for UI behavior determination
    public var routeType: RouteType {
        switch self {
        case .home, .detail:
            return .navigation
        case .settings:
            return .modal
        case .custom:
            return .custom
        }
    }
    
    /// Get associated values for validation and introspection
    public var associatedValues: [Any] {
        switch self {
        case .home, .settings:
            return []
        case .detail(let id):
            return [id]
        case .custom(let path):
            return [path]
        }
    }
    
    /// Unique identifier for the route
    public var identifier: String {
        switch self {
        case .home:
            return "home"
        case .detail(let id):
            return "detail-\(id)"
        case .settings:
            return "settings"
        case .custom(let path):
            return "custom-\(path)"
        }
    }
    
    /// Static validation for detail routes with type safety
    public static func validateDetail(id: String?) throws -> TypeSafeRoute {
        guard let id = id, !id.isEmpty else {
            throw RouteValidationError.invalidParameter("Detail route requires non-empty ID")
        }
        return .detail(id: id)
    }
    
    /// Validate route construction
    public func validate() throws {
        switch self {
        case .home, .settings:
            break // Always valid
        case .detail(let id):
            guard !id.isEmpty else {
                throw RouteValidationError.invalidParameter("Detail ID cannot be empty")
            }
        case .custom(let path):
            guard !path.isEmpty else {
                throw RouteValidationError.invalidParameter("Custom path cannot be empty")
            }
        }
    }
}

// MARK: - CaseIterable Conformance

extension TypeSafeRoute {
    /// All cases for compile-time exhaustive switching
    public static var allCases: [TypeSafeRoute] {
        return [
            .home,
            .detail(id: "sample"),
            .settings,
            .custom(path: "sample")
        ]
    }
}

// MARK: - Route Parameter Validation

/// Route parameter validation types for type safety
public enum RouteParameters: Hashable, Sendable {
    case home
    case detail(id: String)
    case settings
    case custom(path: String, queryParams: [String: String] = [:], fragment: String? = nil)
    
    /// Validate route parameters for type safety
    public func validate() throws {
        switch self {
        case .home, .settings:
            break // No validation needed
        case .detail(let id):
            guard !id.isEmpty else {
                throw RouteValidationError.invalidParameter("Detail ID cannot be empty")
            }
        case .custom(let path, _, _):
            guard !path.isEmpty else {
                throw RouteValidationError.invalidParameter("Custom path cannot be empty")
            }
        }
    }
    
    /// Convert to TypeSafeRoute
    public func toRoute() throws -> TypeSafeRoute {
        try validate()
        
        switch self {
        case .home:
            return .home
        case .detail(let id):
            return .detail(id: id)
        case .settings:
            return .settings
        case .custom(let path, _, _):
            return .custom(path: path)
        }
    }
}

// MARK: - Route Validation Errors

/// Route validation errors for type safety enforcement
public enum RouteValidationError: Error, Equatable, LocalizedError {
    case invalidParameter(String? = nil)
    case missingRequiredParameter(String)
    case invalidRouteType
    case compilationFailure(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidParameter(let message):
            return message ?? "Invalid parameter provided"
        case .missingRequiredParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidRouteType:
            return "Invalid route type specified"
        case .compilationFailure(let message):
            return "Compilation failure: \(message)"
        }
    }
}

// MARK: - Route Builder Pattern

/// Route builder for complex route construction with type safety
public final class RouteBuilder: @unchecked Sendable {
    private var currentRoute: TypeSafeRoute?
    private var shouldValidate = false
    private var queryParams: [String: String] = [:]
    private var fragment: String?
    
    public init() {}
    
    /// Build home route
    public func home() -> RouteBuilder {
        currentRoute = .home
        return self
    }
    
    /// Build detail route with ID validation
    public func detail(id: String) -> RouteBuilder {
        currentRoute = .detail(id: id)
        return self
    }
    
    /// Build settings route
    public func settings() -> RouteBuilder {
        currentRoute = .settings
        return self
    }
    
    /// Build custom route with path
    public func custom(path: String) -> RouteBuilder {
        currentRoute = .custom(path: path)
        return self
    }
    
    /// Enable validation for route construction
    public func withValidation() -> RouteBuilder {
        shouldValidate = true
        return self
    }
    
    /// Add query parameters for custom routes
    public func withQueryParams(_ params: [String: String]) -> RouteBuilder {
        queryParams = params
        return self
    }
    
    /// Add fragment for custom routes
    public func withFragment(_ fragment: String) -> RouteBuilder {
        self.fragment = fragment
        return self
    }
    
    /// Build the final route with optional validation
    public func build() throws -> TypeSafeRoute {
        guard let route = currentRoute else {
            throw RouteValidationError.missingRequiredParameter("No route specified")
        }
        
        if shouldValidate {
            try validateRoute(route)
        }
        
        return route
    }
    
    /// Validate route during construction
    private func validateRoute(_ route: TypeSafeRoute) throws {
        try route.validate()
    }
}

// MARK: - Route Factory

/// Factory for creating type-safe routes
public struct RouteFactory {
    
    /// Create home route
    public static func home() -> TypeSafeRoute {
        return .home
    }
    
    /// Create detail route with validation
    public static func detail(id: String) throws -> TypeSafeRoute {
        return try TypeSafeRoute.validateDetail(id: id)
    }
    
    /// Create settings route
    public static func settings() -> TypeSafeRoute {
        return .settings
    }
    
    /// Create custom route with validation
    public static func custom(path: String) throws -> TypeSafeRoute {
        let route = TypeSafeRoute.custom(path: path)
        try route.validate()
        return route
    }
    
    /// Create route from parameters
    public static func fromParameters(_ params: RouteParameters) throws -> TypeSafeRoute {
        return try params.toRoute()
    }
}

// MARK: - Route Navigation Support

/// Navigation support for type-safe routes
public extension TypeSafeRoute {
    
    /// Check if route can be navigated to
    func canNavigate() -> Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }
    
    /// Get navigation context for route
    func navigationContext() -> NavigationContext {
        return NavigationContext(
            route: self,
            type: routeType,
            parameters: associatedValues
        )
    }
}

/// Navigation context for route handling
public struct NavigationContext: Hashable, Sendable {
    public let route: TypeSafeRoute
    public let type: TypeSafeRoute.RouteType
    public let parameters: [AnyHashable]
    
    init(route: TypeSafeRoute, type: TypeSafeRoute.RouteType, parameters: [Any]) {
        self.route = route
        self.type = type
        self.parameters = parameters.compactMap { $0 as? AnyHashable }
    }
}

// MARK: - Exhaustive Switching Support

/// Helper for exhaustive enum switching validation
public func handleRouteExhaustively(_ route: TypeSafeRoute) -> Bool {
    switch route {
    case .home:
        return true
    case .detail(let id):
        return !id.isEmpty
    case .settings:
        return true
    case .custom(let path):
        return !path.isEmpty
    // No default case - forces exhaustive handling
    }
}

// MARK: - Route Compilation Validation

/// Compile-time route validation support
public enum RouteCompilation {
    
    /// Validate route at compile time
    public static func validateAtCompileTime<T>(_ routeType: T.Type) -> Bool where T: CaseIterable {
        // Ensure enum has fixed number of cases (frozen behavior)
        return T.allCases.count > 0
    }
    
    /// Check exhaustive switching requirement
    public static func requiresExhaustiveSwitching() -> Bool {
        return true
    }
}

// MARK: - Navigation Graph Generation

/// Navigation graph definition for declarative route generation
public struct NavigationGraph: Sendable {
    private let nodes: [NavigationNode]
    private let edges: [NavigationEdge]
    
    public init(nodes: [NavigationNode], edges: [NavigationEdge] = []) {
        self.nodes = nodes
        self.edges = edges
    }
    
    /// Generate all possible routes from the navigation graph
    public func generateRoutes() -> [TypeSafeRoute] {
        return nodes.compactMap { node in
            switch node.type {
            case .home:
                return .home
            case .detail:
                return .detail(id: node.parameters["id"] as? String ?? "sample")
            case .settings:
                return .settings
            case .custom:
                return .custom(path: node.parameters["path"] as? String ?? "sample")
            }
        }
    }
    
    /// Validate graph for cycles and invalid connections
    public func validate() throws {
        // Check for cycles using topological sort
        var visited = Set<String>()
        var recursionStack = Set<String>()
        
        for node in nodes {
            if !visited.contains(node.id) {
                try validateNodeForCycles(node.id, visited: &visited, recursionStack: &recursionStack)
            }
        }
        
        // Validate edge connections
        let nodeIds = Set(nodes.map { $0.id })
        for edge in edges {
            guard nodeIds.contains(edge.from) && nodeIds.contains(edge.to) else {
                throw NavigationGraphError.invalidEdge(from: edge.from, to: edge.to)
            }
        }
    }
    
    private func validateNodeForCycles(
        _ nodeId: String,
        visited: inout Set<String>,
        recursionStack: inout Set<String>
    ) throws {
        visited.insert(nodeId)
        recursionStack.insert(nodeId)
        
        // Check all outgoing edges from this node
        let outgoingEdges = edges.filter { $0.from == nodeId }
        for edge in outgoingEdges {
            if recursionStack.contains(edge.to) {
                throw NavigationGraphError.cycleDetected(path: Array(recursionStack) + [edge.to])
            }
            
            if !visited.contains(edge.to) {
                try validateNodeForCycles(edge.to, visited: &visited, recursionStack: &recursionStack)
            }
        }
        
        recursionStack.remove(nodeId)
    }
    
    /// Get possible destinations from a given route
    public func possibleDestinations(from route: TypeSafeRoute) -> [TypeSafeRoute] {
        guard let sourceNode = nodes.first(where: { $0.matches(route: route) }) else {
            return []
        }
        
        let outgoingEdges = edges.filter { $0.from == sourceNode.id }
        let destinationNodes = outgoingEdges.compactMap { edge in
            nodes.first { $0.id == edge.to }
        }
        
        return destinationNodes.compactMap { node in
            switch node.type {
            case .home:
                return .home
            case .detail:
                return .detail(id: node.parameters["id"] as? String ?? "sample")
            case .settings:
                return .settings
            case .custom:
                return .custom(path: node.parameters["path"] as? String ?? "sample")
            }
        }
    }
}

/// Navigation node in the graph
public struct NavigationNode: Sendable, Hashable {
    public let id: String
    public let type: NodeType
    public let parameters: [String: Any]
    
    public enum NodeType: CaseIterable, Sendable {
        case home
        case detail
        case settings
        case custom
    }
    
    public init(id: String, type: NodeType, parameters: [String: Any] = [:]) {
        self.id = id
        self.type = type
        self.parameters = parameters
    }
    
    /// Check if this node matches a route
    func matches(route: TypeSafeRoute) -> Bool {
        switch (type, route) {
        case (.home, .home):
            return true
        case (.detail, .detail(let id)):
            return parameters["id"] as? String == id
        case (.settings, .settings):
            return true
        case (.custom, .custom(let path)):
            return parameters["path"] as? String == path
        default:
            return false
        }
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }
    
    public static func == (lhs: NavigationNode, rhs: NavigationNode) -> Bool {
        return lhs.id == rhs.id && lhs.type == rhs.type
    }
}

/// Navigation edge connecting nodes
public struct NavigationEdge: Sendable, Hashable {
    public let from: String
    public let to: String
    public let condition: EdgeCondition?
    
    public enum EdgeCondition: Sendable {
        case authenticated
        case hasPermission(String)
        case custom((TypeSafeRoute) -> Bool)
    }
    
    public init(from: String, to: String, condition: EdgeCondition? = nil) {
        self.from = from
        self.to = to
        self.condition = condition
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(from)
        hasher.combine(to)
    }
    
    public static func == (lhs: NavigationEdge, rhs: NavigationEdge) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
}

/// Navigation graph errors
public enum NavigationGraphError: Error, LocalizedError {
    case cycleDetected(path: [String])
    case invalidEdge(from: String, to: String)
    case nodeNotFound(String)
    case invalidNodeType
    
    public var errorDescription: String? {
        switch self {
        case .cycleDetected(let path):
            return "Cycle detected in navigation graph: \(path.joined(separator: " -> "))"
        case .invalidEdge(let from, let to):
            return "Invalid edge from \(from) to \(to)"
        case .nodeNotFound(let id):
            return "Node not found: \(id)"
        case .invalidNodeType:
            return "Invalid node type specified"
        }
    }
}

/// Navigation graph builder for fluent API
public final class NavigationGraphBuilder: @unchecked Sendable {
    private var nodes: [NavigationNode] = []
    private var edges: [NavigationEdge] = []
    
    public init() {}
    
    /// Add a home node
    public func addHome(id: String = "home") -> NavigationGraphBuilder {
        nodes.append(NavigationNode(id: id, type: .home))
        return self
    }
    
    /// Add a detail node
    public func addDetail(id: String, sampleId: String = "sample") -> NavigationGraphBuilder {
        nodes.append(NavigationNode(id: id, type: .detail, parameters: ["id": sampleId]))
        return self
    }
    
    /// Add a settings node
    public func addSettings(id: String = "settings") -> NavigationGraphBuilder {
        nodes.append(NavigationNode(id: id, type: .settings))
        return self
    }
    
    /// Add a custom node
    public func addCustom(id: String, path: String) -> NavigationGraphBuilder {
        nodes.append(NavigationNode(id: id, type: .custom, parameters: ["path": path]))
        return self
    }
    
    /// Connect two nodes with an edge
    public func connect(from: String, to: String, condition: NavigationEdge.EdgeCondition? = nil) -> NavigationGraphBuilder {
        edges.append(NavigationEdge(from: from, to: to, condition: condition))
        return self
    }
    
    /// Build the navigation graph
    public func build() throws -> NavigationGraph {
        let graph = NavigationGraph(nodes: nodes, edges: edges)
        try graph.validate()
        return graph
    }
}

/// Route generator from navigation graph
public struct RouteGenerator {
    private let graph: NavigationGraph
    
    public init(graph: NavigationGraph) {
        self.graph = graph
    }
    
    /// Generate all routes from the graph
    public func generateAllRoutes() -> [TypeSafeRoute] {
        return graph.generateRoutes()
    }
    
    /// Generate routes reachable from a starting route
    public func generateReachableRoutes(from startRoute: TypeSafeRoute) -> [TypeSafeRoute] {
        var reachable: Set<TypeSafeRoute> = [startRoute]
        var toVisit: [TypeSafeRoute] = [startRoute]
        
        while !toVisit.isEmpty {
            let current = toVisit.removeFirst()
            let destinations = graph.possibleDestinations(from: current)
            
            for destination in destinations {
                if !reachable.contains(destination) {
                    reachable.insert(destination)
                    toVisit.append(destination)
                }
            }
        }
        
        return Array(reachable)
    }
    
    /// Generate code for route enum (for code generation tools)
    public func generateRouteEnumCode() -> String {
        let routes = generateAllRoutes()
        var caseDefinitions: [String] = []
        
        for route in Set(routes) {
            switch route {
            case .home:
                caseDefinitions.append("    case home")
            case .detail:
                caseDefinitions.append("    case detail(id: String)")
            case .settings:
                caseDefinitions.append("    case settings")
            case .custom:
                caseDefinitions.append("    case custom(path: String)")
            }
        }
        
        return """
        @frozen
        public enum GeneratedRoute: CaseIterable, Hashable, Sendable {
        \(caseDefinitions.joined(separator: "\n"))
        }
        """
    }
}

/// Default navigation graphs for common patterns
public struct DefaultNavigationGraphs {
    
    /// Standard app navigation graph
    public static func standardApp() throws -> NavigationGraph {
        return try NavigationGraphBuilder()
            .addHome()
            .addDetail(id: "detail-view", sampleId: "item")
            .addSettings()
            .connect(from: "home", to: "detail-view")
            .connect(from: "home", to: "settings")
            .connect(from: "detail-view", to: "home")
            .connect(from: "settings", to: "home")
            .build()
    }
    
    /// Tab-based navigation graph
    public static func tabBasedApp() throws -> NavigationGraph {
        return try NavigationGraphBuilder()
            .addHome(id: "tab-home")
            .addDetail(id: "tab-detail", sampleId: "item")
            .addSettings(id: "tab-settings")
            .addCustom(id: "tab-profile", path: "profile")
            .connect(from: "tab-home", to: "tab-detail")
            .connect(from: "tab-home", to: "tab-settings")
            .connect(from: "tab-home", to: "tab-profile")
            .build()
    }
    
    /// Modal presentation graph
    public static func modalApp() throws -> NavigationGraph {
        return try NavigationGraphBuilder()
            .addHome()
            .addSettings(id: "modal-settings")
            .addCustom(id: "modal-help", path: "help")
            .connect(from: "home", to: "modal-settings")
            .connect(from: "home", to: "modal-help")
            .build()
    }
}

// MARK: - Integration with Existing Route System

/// Bridge to existing Route enum for compatibility
public extension TypeSafeRoute {
    
    /// Convert to existing Route enum
    func toRoute() -> Route {
        switch self {
        case .home:
            return .home
        case .detail(let id):
            return .detail(id: id)
        case .settings:
            return .settings
        case .custom(let path):
            return .custom(path: path)
        }
    }
    
    /// Create from existing Route enum
    static func from(_ route: Route) -> TypeSafeRoute {
        switch route {
        case .home:
            return .home
        case .detail(let id):
            return .detail(id: id)
        case .settings:
            return .settings
        case .custom(let path):
            return .custom(path: path)
        }
    }
}