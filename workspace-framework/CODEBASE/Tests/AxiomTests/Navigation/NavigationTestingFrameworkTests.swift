import XCTest
@testable import Axiom
@testable import AxiomTesting

/// Tests for the comprehensive Navigation Testing Framework
/// This validates that applications can easily test all aspects of navigation
final class NavigationTestingFrameworkTests: XCTestCase {
    
    // MARK: - Route Testing
    
    func testRouteDefinitionTesting() async throws {
        // RED Test: Should easily test route definitions and parameters
        let route = TaskRoute.taskDetail(id: "task-123", mode: .edit)
        
        // Should be able to assert route components
        try NavigationTestHelpers.assertRoute(
            route,
            hasPath: "/tasks/task-123",
            hasParameters: ["mode": "edit"],
            description: "Task detail route should have correct path and parameters"
        )
        
        // Should be able to test route parsing
        let parsedRoute = try NavigationTestHelpers.parseRoute(
            from: "/tasks/task-123?mode=edit",
            as: TaskRoute.self
        )
        
        XCTAssertEqual(parsedRoute, route)
    }
    
    func testRouteValidation() async throws {
        // RED Test: Should validate route constraints and requirements
        
        // Should validate required parameters
        try await NavigationTestHelpers.assertRouteValidation(
            TaskRoute.taskDetail(id: "", mode: .view),
            fails: true,
            expectedError: .invalidParameter("id cannot be empty")
        )
        
        // Should validate parameter types
        try await NavigationTestHelpers.assertRouteValidation(
            TaskRoute.taskList(page: -1),
            fails: true,
            expectedError: .invalidParameter("page must be positive")
        )
        
        // Should pass valid routes
        try await NavigationTestHelpers.assertRouteValidation(
            TaskRoute.taskDetail(id: "valid-id", mode: .view),
            fails: false
        )
    }
    
    // MARK: - Navigation Flow Testing
    
    func testNavigationFlowSequence() async throws {
        // RED Test: Should test complex navigation flows
        let navigator = TestNavigationService()
        
        // Should be able to test navigation sequences
        try await NavigationTestHelpers.assertNavigationFlow(
            using: navigator,
            sequence: [
                .navigate(to: TaskRoute.taskList(page: 1)),
                .navigate(to: TaskRoute.taskDetail(id: "task-1", mode: .view)),
                .navigate(to: TaskRoute.taskDetail(id: "task-1", mode: .edit)),
                .goBack(),
                .goBack()
            ],
            expectedStack: [
                TaskRoute.taskList(page: 1)
            ]
        )
    }
    
    func testNavigationStateTracking() async throws {
        // RED Test: Should track navigation state changes
        let navigator = TestNavigationService()
        let tracker = NavigationTestHelpers.trackNavigation(in: navigator)
        
        await navigator.navigate(to: TaskRoute.taskList(page: 1))
        await navigator.navigate(to: TaskRoute.taskDetail(id: "task-1", mode: .view))
        await navigator.goBack()
        
        // Should assert navigation events
        try await tracker.assertNavigationSequence([
            .navigated(to: TaskRoute.taskList(page: 1)),
            .navigated(to: TaskRoute.taskDetail(id: "task-1", mode: .view)),
            .navigatedBack(to: TaskRoute.taskList(page: 1))
        ])
        
        // Should assert current state
        try await tracker.assertCurrentRoute(TaskRoute.taskList(page: 1))
        try await tracker.assertStackDepth(1)
    }
    
    // MARK: - Deep Link Testing
    
    func testDeepLinkHandling() async throws {
        // RED Test: Should test deep link processing and routing
        let deepLinkHandler = TestDeepLinkHandler()
        
        // Should handle valid deep links
        let validURL = URL(string: "myapp://tasks/task-123?mode=edit")!
        let route = try await NavigationTestHelpers.assertDeepLinkHandling(
            url: validURL,
            handler: deepLinkHandler,
            expectedRoute: TaskRoute.taskDetail(id: "task-123", mode: .edit)
        )
        
        XCTAssertEqual(route, TaskRoute.taskDetail(id: "task-123", mode: .edit))
        
        // Should reject invalid deep links
        let invalidURL = URL(string: "myapp://invalid/path")!
        try await NavigationTestHelpers.assertDeepLinkHandling(
            url: invalidURL,
            handler: deepLinkHandler,
            expectedFailure: .unsupportedURL
        )
    }
    
    func testDeepLinkStateRestoration() async throws {
        // RED Test: Should test state restoration from deep links
        let deepLinkHandler = TestDeepLinkHandler()
        let navigator = TestNavigationService()
        
        // Should restore navigation state from deep link
        let deepLinkURL = URL(string: "myapp://tasks/task-123/comments/comment-456?edit=true")!
        
        try await NavigationTestHelpers.assertDeepLinkRestoration(
            url: deepLinkURL,
            handler: deepLinkHandler,
            navigator: navigator,
            expectedStack: [
                TaskRoute.taskList(page: 1),
                TaskRoute.taskDetail(id: "task-123", mode: .view),
                TaskRoute.commentDetail(taskId: "task-123", commentId: "comment-456", editing: true)
            ]
        )
    }
    
    // MARK: - Navigation Guard Testing
    
    func testNavigationGuards() async throws {
        // RED Test: Should test navigation guards and permissions
        let navigator = TestNavigationService()
        let guard = TestNavigationGuard()
        
        // Should test permission-based navigation
        guard.setPermission(for: TaskRoute.adminPanel, allowed: false)
        
        try await NavigationTestHelpers.assertNavigationBlocked(
            navigator: navigator,
            route: TaskRoute.adminPanel,
            guard: guard,
            expectedReason: .insufficientPermissions
        )
        
        // Should test conditional navigation
        guard.setCondition(for: TaskRoute.taskDetail(id: "task-1", mode: .edit)) { route in
            // Only allow edit if task exists
            return TaskDatabase.shared.taskExists(id: "task-1")
        }
        
        try await NavigationTestHelpers.assertNavigationConditional(
            navigator: navigator,
            route: TaskRoute.taskDetail(id: "task-1", mode: .edit),
            guard: guard,
            setupCondition: {
                TaskDatabase.shared.createTask(id: "task-1")
            }
        )
    }
    
    // MARK: - Navigation Context Integration Testing
    
    func testNavigationContextIntegration() async throws {
        // RED Test: Should test navigation with context state
        let navigator = TestNavigationService()
        let taskContext = TestTaskContext()
        
        // Should test context-aware navigation
        try await NavigationTestHelpers.assertContextNavigation(
            navigator: navigator,
            context: taskContext,
            action: .navigateToTaskDetail("task-1"),
            expectedRoute: TaskRoute.taskDetail(id: "task-1", mode: .view),
            expectedContextState: { context in
                context.selectedTaskId == "task-1"
            }
        )
        
        // Should test navigation state synchronization
        await navigator.navigate(to: TaskRoute.taskDetail(id: "task-2", mode: .edit))
        
        try await NavigationTestHelpers.assertContextSynchronization(
            navigator: navigator,
            context: taskContext,
            expectedState: { context in
                context.selectedTaskId == "task-2" && context.isEditing
            }
        )
    }
    
    // MARK: - Navigation Performance Testing
    
    func testNavigationPerformance() async throws {
        // RED Test: Should benchmark navigation operations
        let navigator = TestNavigationService()
        
        let benchmark = try await NavigationTestHelpers.benchmarkNavigation(
            navigator: navigator
        ) {
            // Simulate complex navigation scenario
            for i in 0..<100 {
                await navigator.navigate(to: TaskRoute.taskDetail(id: "task-\(i)", mode: .view))
                await navigator.goBack()
            }
        }
        
        // Should meet performance requirements
        XCTAssertLessThan(benchmark.averageNavigationTime, 0.1) // 100ms per navigation
        XCTAssertLessThan(benchmark.memoryGrowth, 1024 * 1024) // 1MB growth max
    }
    
    // MARK: - Navigation Error Testing
    
    func testNavigationErrorHandling() async throws {
        // RED Test: Should test navigation error scenarios
        let navigator = TestNavigationService()
        
        // Should handle navigation to non-existent routes
        try await NavigationTestHelpers.assertNavigationError(
            navigator: navigator,
            route: TaskRoute.taskDetail(id: "non-existent", mode: .view),
            expectedError: .routeNotFound
        )
        
        // Should handle navigation stack overflow
        navigator.setMaxStackDepth(5)
        
        for i in 0..<10 {
            await navigator.navigate(to: TaskRoute.taskDetail(id: "task-\(i)", mode: .view))
        }
        
        try await NavigationTestHelpers.assertNavigationState(
            navigator: navigator,
            stackDepth: 5, // Should not exceed max
            hasError: true,
            expectedError: .stackOverflow
        )
    }
}

// MARK: - Test Support Types

enum TaskRoute: Route, Equatable {
    case taskList(page: Int)
    case taskDetail(id: String, mode: TaskDetailMode)
    case commentDetail(taskId: String, commentId: String, editing: Bool)
    case adminPanel
    
    var path: String {
        switch self {
        case .taskList:
            return "/tasks"
        case .taskDetail(let id, _):
            return "/tasks/\(id)"
        case .commentDetail(let taskId, let commentId, _):
            return "/tasks/\(taskId)/comments/\(commentId)"
        case .adminPanel:
            return "/admin"
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case .taskList(let page):
            return ["page": "\(page)"]
        case .taskDetail(_, let mode):
            return ["mode": mode.rawValue]
        case .commentDetail(_, _, let editing):
            return ["edit": "\(editing)"]
        case .adminPanel:
            return [:]
        }
    }
}

enum TaskDetailMode: String, CaseIterable {
    case view
    case edit
}

// Test implementations
class TestNavigationService: NavigationService {
    private var navigationStack: [Route] = []
    private var maxStackDepth: Int = 100
    private var lastError: NavigationError?
    
    func navigate(to route: Route) async {
        if navigationStack.count >= maxStackDepth {
            lastError = .stackOverflow
            return
        }
        navigationStack.append(route)
    }
    
    func goBack() async {
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
    }
    
    func setMaxStackDepth(_ depth: Int) {
        maxStackDepth = depth
    }
    
    var currentRoute: Route? {
        navigationStack.last
    }
    
    var stackDepth: Int {
        navigationStack.count
    }
    
    var hasError: Bool {
        lastError != nil
    }
    
    var error: NavigationError? {
        lastError
    }
}

class TestDeepLinkHandler {
    func handle(_ url: URL) async throws -> Route {
        // Simplified deep link handling
        guard url.scheme == "myapp" else {
            throw DeepLinkError.unsupportedURL
        }
        
        let path = url.path
        if path.hasPrefix("/tasks/") {
            let components = path.components(separatedBy: "/")
            if components.count >= 3 {
                let taskId = components[2]
                if taskId.isEmpty {
                    throw DeepLinkError.invalidParameter("Task ID cannot be empty")
                }
                
                let mode = url.queryItems?.first { $0.name == "mode" }?.value ?? "view"
                return TaskRoute.taskDetail(
                    id: taskId,
                    mode: TaskDetailMode(rawValue: mode) ?? .view
                )
            }
        }
        
        throw DeepLinkError.unsupportedURL
    }
}

class TestNavigationGuard {
    private var permissions: [String: Bool] = [:]
    private var conditions: [String: (Route) -> Bool] = [:]
    
    func setPermission(for route: Route, allowed: Bool) {
        permissions[route.path] = allowed
    }
    
    func setCondition(for route: Route, condition: @escaping (Route) -> Bool) {
        conditions[route.path] = condition
    }
    
    func canNavigate(to route: Route) -> Bool {
        if let permission = permissions[route.path], !permission {
            return false
        }
        
        if let condition = conditions[route.path] {
            return condition(route)
        }
        
        return true
    }
}

@MainActor
class TestTaskContext: Context {
    @Published var selectedTaskId: String?
    @Published var isEditing = false
    
    enum Action {
        case navigateToTaskDetail(String)
    }
    
    func process(_ action: Action) async {
        switch action {
        case .navigateToTaskDetail(let id):
            selectedTaskId = id
        }
    }
    
    func onAppear() async {}
    func onDisappear() async {}
}

class TaskDatabase {
    static let shared = TaskDatabase()
    private var tasks: Set<String> = []
    
    func taskExists(id: String) -> Bool {
        tasks.contains(id)
    }
    
    func createTask(id: String) {
        tasks.insert(id)
    }
}

// Error types
enum NavigationError: Error {
    case routeNotFound
    case stackOverflow
    case invalidParameter(String)
    case insufficientPermissions
}

enum DeepLinkError: Error {
    case unsupportedURL
    case invalidParameter(String)
}

// Extensions for URL query items
extension URL {
    var queryItems: [URLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems
    }
}