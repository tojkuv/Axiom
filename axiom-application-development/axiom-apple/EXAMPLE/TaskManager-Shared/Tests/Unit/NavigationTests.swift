import XCTest
@testable import TaskManager_Shared
import Foundation

// MARK: - Navigation Tests

/// Unit tests for TaskManagerRoute and navigation-related functionality
final class NavigationTests: XCTestCase {
    
    // MARK: - Route Identifier Tests
    
    func testRouteIdentifiers() {
        let taskId = UUID()
        let date = Date()
        
        XCTAssertEqual(TaskManagerRoute.taskList.identifier, "task-list")
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: taskId).identifier, "task-detail-\(taskId.uuidString)")
        XCTAssertEqual(TaskManagerRoute.createTask.identifier, "create-task")
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: taskId).identifier, "edit-task-\(taskId.uuidString)")
        XCTAssertEqual(TaskManagerRoute.settings.identifier, "settings")
        XCTAssertEqual(TaskManagerRoute.statistics.identifier, "statistics")
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).identifier, "category-work")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).identifier, "priority-high")
        XCTAssertEqual(TaskManagerRoute.search(query: "test").identifier, "search-test")
        XCTAssertEqual(TaskManagerRoute.filters.identifier, "filters")
        XCTAssertEqual(TaskManagerRoute.export.identifier, "export")
        XCTAssertEqual(TaskManagerRoute.import.identifier, "import")
        XCTAssertEqual(TaskManagerRoute.about.identifier, "about")
    }
    
    // MARK: - Path Components Tests
    
    func testPathComponents() {
        let taskId = UUID()
        let date = Date()
        let iso8601Date = ISO8601DateFormatter().string(from: date)
        
        XCTAssertEqual(TaskManagerRoute.taskList.pathComponents, "/tasks")
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: taskId).pathComponents, "/tasks/\(taskId.uuidString)")
        XCTAssertEqual(TaskManagerRoute.createTask.pathComponents, "/tasks/create")
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: taskId).pathComponents, "/tasks/\(taskId.uuidString)/edit")
        XCTAssertEqual(TaskManagerRoute.settings.pathComponents, "/settings")
        XCTAssertEqual(TaskManagerRoute.statistics.pathComponents, "/statistics")
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).pathComponents, "/category/work")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).pathComponents, "/priority/high")
        XCTAssertEqual(TaskManagerRoute.dueDateView(date: date).pathComponents, "/due-date/\(iso8601Date)")
        XCTAssertEqual(TaskManagerRoute.search(query: "test query").pathComponents, "/search?q=test%20query")
        XCTAssertEqual(TaskManagerRoute.filters.pathComponents, "/filters")
        XCTAssertEqual(TaskManagerRoute.export.pathComponents, "/export")
        XCTAssertEqual(TaskManagerRoute.import.pathComponents, "/import")
        XCTAssertEqual(TaskManagerRoute.about.pathComponents, "/about")
    }
    
    // MARK: - Parameters Tests
    
    func testRouteParameters() {
        let taskId = UUID()
        let date = Date()
        let iso8601Date = ISO8601DateFormatter().string(from: date)
        
        XCTAssertTrue(TaskManagerRoute.taskList.parameters.isEmpty)
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: taskId).parameters["taskId"], taskId.uuidString)
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: taskId).parameters["taskId"], taskId.uuidString)
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).parameters["category"], "work")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).parameters["priority"], "high")
        XCTAssertEqual(TaskManagerRoute.dueDateView(date: date).parameters["date"], iso8601Date)
        XCTAssertEqual(TaskManagerRoute.search(query: "test").parameters["query"], "test")
        XCTAssertTrue(TaskManagerRoute.settings.parameters.isEmpty)
    }
    
    // MARK: - Display Names Tests
    
    func testDisplayNames() {
        XCTAssertEqual(TaskManagerRoute.taskList.displayName, "Tasks")
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: UUID()).displayName, "Task Details")
        XCTAssertEqual(TaskManagerRoute.createTask.displayName, "Create Task")
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: UUID()).displayName, "Edit Task")
        XCTAssertEqual(TaskManagerRoute.settings.displayName, "Settings")
        XCTAssertEqual(TaskManagerRoute.statistics.displayName, "Statistics")
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).displayName, "Work")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).displayName, "High Priority")
        XCTAssertEqual(TaskManagerRoute.dueDateView(date: Date()).displayName, "Due Tasks")
        XCTAssertEqual(TaskManagerRoute.search(query: "test").displayName, "Search Results")
        XCTAssertEqual(TaskManagerRoute.filters.displayName, "Filters")
        XCTAssertEqual(TaskManagerRoute.export.displayName, "Export")
        XCTAssertEqual(TaskManagerRoute.import.displayName, "Import")
        XCTAssertEqual(TaskManagerRoute.about.displayName, "About")
    }
    
    // MARK: - System Image Names Tests
    
    func testSystemImageNames() {
        XCTAssertEqual(TaskManagerRoute.taskList.systemImageName, "list.bullet")
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: UUID()).systemImageName, "doc.text")
        XCTAssertEqual(TaskManagerRoute.createTask.systemImageName, "plus.circle")
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: UUID()).systemImageName, "doc.text")
        XCTAssertEqual(TaskManagerRoute.settings.systemImageName, "gearshape")
        XCTAssertEqual(TaskManagerRoute.statistics.systemImageName, "chart.pie")
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).systemImageName, "briefcase")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).systemImageName, "arrow.up.circle")
        XCTAssertEqual(TaskManagerRoute.dueDateView(date: Date()).systemImageName, "calendar")
        XCTAssertEqual(TaskManagerRoute.search(query: "test").systemImageName, "magnifyingglass")
        XCTAssertEqual(TaskManagerRoute.filters.systemImageName, "line.horizontal.3.decrease.circle")
        XCTAssertEqual(TaskManagerRoute.export.systemImageName, "square.and.arrow.up")
        XCTAssertEqual(TaskManagerRoute.import.systemImageName, "square.and.arrow.down")
        XCTAssertEqual(TaskManagerRoute.about.systemImageName, "info.circle")
    }
    
    // MARK: - Route Properties Tests
    
    func testRequiresTask() {
        XCTAssertFalse(TaskManagerRoute.taskList.requiresTask)
        XCTAssertTrue(TaskManagerRoute.taskDetail(taskId: UUID()).requiresTask)
        XCTAssertFalse(TaskManagerRoute.createTask.requiresTask)
        XCTAssertTrue(TaskManagerRoute.editTask(taskId: UUID()).requiresTask)
        XCTAssertFalse(TaskManagerRoute.settings.requiresTask)
        XCTAssertFalse(TaskManagerRoute.statistics.requiresTask)
    }
    
    func testIsBookmarkable() {
        XCTAssertTrue(TaskManagerRoute.taskList.isBookmarkable)
        XCTAssertTrue(TaskManagerRoute.taskDetail(taskId: UUID()).isBookmarkable)
        XCTAssertFalse(TaskManagerRoute.createTask.isBookmarkable)
        XCTAssertFalse(TaskManagerRoute.editTask(taskId: UUID()).isBookmarkable)
        XCTAssertFalse(TaskManagerRoute.settings.isBookmarkable)
        XCTAssertTrue(TaskManagerRoute.statistics.isBookmarkable)
        XCTAssertTrue(TaskManagerRoute.categoryView(category: .work).isBookmarkable)
        XCTAssertTrue(TaskManagerRoute.priorityView(priority: .high).isBookmarkable)
        XCTAssertTrue(TaskManagerRoute.about.isBookmarkable)
    }
    
    func testShouldTrackAnalytics() {
        XCTAssertTrue(TaskManagerRoute.taskList.shouldTrackAnalytics)
        XCTAssertFalse(TaskManagerRoute.taskDetail(taskId: UUID()).shouldTrackAnalytics)
        XCTAssertTrue(TaskManagerRoute.createTask.shouldTrackAnalytics)
        XCTAssertFalse(TaskManagerRoute.editTask(taskId: UUID()).shouldTrackAnalytics)
        XCTAssertTrue(TaskManagerRoute.settings.shouldTrackAnalytics)
        XCTAssertTrue(TaskManagerRoute.statistics.shouldTrackAnalytics)
    }
    
    func testNavigationLevel() {
        XCTAssertEqual(TaskManagerRoute.taskList.navigationLevel, 0)
        XCTAssertEqual(TaskManagerRoute.statistics.navigationLevel, 0)
        XCTAssertEqual(TaskManagerRoute.settings.navigationLevel, 0)
        XCTAssertEqual(TaskManagerRoute.about.navigationLevel, 0)
        
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).navigationLevel, 1)
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).navigationLevel, 1)
        XCTAssertEqual(TaskManagerRoute.search(query: "test").navigationLevel, 1)
        XCTAssertEqual(TaskManagerRoute.filters.navigationLevel, 1)
        
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: UUID()).navigationLevel, 2)
        XCTAssertEqual(TaskManagerRoute.createTask.navigationLevel, 2)
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: UUID()).navigationLevel, 2)
        XCTAssertEqual(TaskManagerRoute.export.navigationLevel, 2)
        XCTAssertEqual(TaskManagerRoute.import.navigationLevel, 2)
    }
    
    func testParentRoute() {
        XCTAssertNil(TaskManagerRoute.taskList.parentRoute)
        XCTAssertNil(TaskManagerRoute.statistics.parentRoute)
        XCTAssertNil(TaskManagerRoute.settings.parentRoute)
        XCTAssertNil(TaskManagerRoute.about.parentRoute)
        
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: UUID()).parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.createTask.parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.editTask(taskId: UUID()).parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.search(query: "test").parentRoute, .taskList)
        XCTAssertEqual(TaskManagerRoute.filters.parentRoute, .taskList)
        
        XCTAssertEqual(TaskManagerRoute.export.parentRoute, .settings)
        XCTAssertEqual(TaskManagerRoute.import.parentRoute, .settings)
    }
    
    func testChildRoutes() {
        let taskListChildren = TaskManagerRoute.taskList.childRoutes
        XCTAssertTrue(taskListChildren.contains(.createTask))
        XCTAssertTrue(taskListChildren.contains(.filters))
        XCTAssertTrue(taskListChildren.contains { route in
            if case .search(let query) = route, query.isEmpty {
                return true
            }
            return false
        })
        
        let settingsChildren = TaskManagerRoute.settings.childRoutes
        XCTAssertTrue(settingsChildren.contains(.export))
        XCTAssertTrue(settingsChildren.contains(.import))
        
        XCTAssertTrue(TaskManagerRoute.taskDetail(taskId: UUID()).childRoutes.isEmpty)
        XCTAssertTrue(TaskManagerRoute.about.childRoutes.isEmpty)
    }
    
    // MARK: - URL Generation Tests
    
    func testShareableURL() {
        let baseURL = "https://taskmanager.app"
        
        XCTAssertEqual(
            TaskManagerRoute.taskList.shareableURL(baseURL: baseURL),
            URL(string: "\(baseURL)/tasks")
        )
        
        XCTAssertEqual(
            TaskManagerRoute.statistics.shareableURL(baseURL: baseURL),
            URL(string: "\(baseURL)/statistics")
        )
        
        XCTAssertEqual(
            TaskManagerRoute.categoryView(category: .work).shareableURL(baseURL: baseURL),
            URL(string: "\(baseURL)/category/work")
        )
        
        // Non-bookmarkable routes should return nil
        XCTAssertNil(TaskManagerRoute.createTask.shareableURL(baseURL: baseURL))
        XCTAssertNil(TaskManagerRoute.editTask(taskId: UUID()).shareableURL(baseURL: baseURL))
    }
    
    func testDeepLinkURL() {
        let scheme = "taskmanager"
        
        XCTAssertEqual(
            TaskManagerRoute.taskList.deepLinkURL(scheme: scheme),
            URL(string: "\(scheme)://tasks")
        )
        
        let taskId = UUID()
        XCTAssertEqual(
            TaskManagerRoute.taskDetail(taskId: taskId).deepLinkURL(scheme: scheme),
            URL(string: "\(scheme)://tasks/\(taskId.uuidString)")
        )
        
        XCTAssertEqual(
            TaskManagerRoute.settings.deepLinkURL(scheme: scheme),
            URL(string: "\(scheme)://settings")
        )
    }
    
    // MARK: - Route Matching Tests
    
    func testRouteFromPath() {
        XCTAssertEqual(TaskManagerRoute.from(path: "/tasks"), .taskList)
        XCTAssertEqual(TaskManagerRoute.from(path: "/tasks/create"), .createTask)
        XCTAssertEqual(TaskManagerRoute.from(path: "/settings"), .settings)
        XCTAssertEqual(TaskManagerRoute.from(path: "/statistics"), .statistics)
        XCTAssertEqual(TaskManagerRoute.from(path: "/category/work"), .categoryView(category: .work))
        XCTAssertEqual(TaskManagerRoute.from(path: "/priority/high"), .priorityView(priority: .high))
        XCTAssertEqual(TaskManagerRoute.from(path: "/filters"), .filters)
        XCTAssertEqual(TaskManagerRoute.from(path: "/export"), .export)
        XCTAssertEqual(TaskManagerRoute.from(path: "/import"), .import)
        XCTAssertEqual(TaskManagerRoute.from(path: "/about"), .about)
        
        // Test with task ID
        let taskId = UUID()
        XCTAssertEqual(
            TaskManagerRoute.from(path: "/tasks/\(taskId.uuidString)"),
            .taskDetail(taskId: taskId)
        )
        XCTAssertEqual(
            TaskManagerRoute.from(path: "/tasks/\(taskId.uuidString)/edit"),
            .editTask(taskId: taskId)
        )
        
        // Test search with query
        if let searchRoute = TaskManagerRoute.from(path: "/search?q=test%20query"),
           case .search(let query) = searchRoute {
            XCTAssertEqual(query, "test query")
        } else {
            XCTFail("Failed to parse search route")
        }
        
        // Test invalid paths
        XCTAssertNil(TaskManagerRoute.from(path: "/invalid"))
        XCTAssertNil(TaskManagerRoute.from(path: "/tasks/invalid-uuid"))
        XCTAssertNil(TaskManagerRoute.from(path: "/category/invalid"))
        XCTAssertNil(TaskManagerRoute.from(path: "/priority/invalid"))
    }
    
    func testRouteFromURL() {
        let baseURL = "https://taskmanager.app"
        
        XCTAssertEqual(
            TaskManagerRoute.from(url: URL(string: "\(baseURL)/tasks")!),
            .taskList
        )
        
        XCTAssertEqual(
            TaskManagerRoute.from(url: URL(string: "\(baseURL)/settings")!),
            .settings
        )
        
        let taskId = UUID()
        XCTAssertEqual(
            TaskManagerRoute.from(url: URL(string: "\(baseURL)/tasks/\(taskId.uuidString)")!),
            .taskDetail(taskId: taskId)
        )
    }
    
    // MARK: - Breadcrumb Tests
    
    func testBreadcrumbs() {
        let taskId = UUID()
        
        // Root level routes
        XCTAssertEqual(TaskManagerRoute.taskList.breadcrumbs, [.taskList])
        XCTAssertEqual(TaskManagerRoute.settings.breadcrumbs, [.settings])
        
        // Level 1 routes
        let categoryBreadcrumbs = TaskManagerRoute.categoryView(category: .work).breadcrumbs
        XCTAssertEqual(categoryBreadcrumbs, [.taskList, .categoryView(category: .work)])
        
        // Level 2 routes
        let taskDetailBreadcrumbs = TaskManagerRoute.taskDetail(taskId: taskId).breadcrumbs
        XCTAssertEqual(taskDetailBreadcrumbs, [.taskList, .taskDetail(taskId: taskId)])
        
        let exportBreadcrumbs = TaskManagerRoute.export.breadcrumbs
        XCTAssertEqual(exportBreadcrumbs, [.settings, .export])
    }
    
    func testBreadcrumbNames() {
        let taskId = UUID()
        
        let taskDetailBreadcrumbs = TaskManagerRoute.taskDetail(taskId: taskId).breadcrumbNames
        XCTAssertEqual(taskDetailBreadcrumbs, ["Tasks", "Task Details"])
        
        let exportBreadcrumbs = TaskManagerRoute.export.breadcrumbNames
        XCTAssertEqual(exportBreadcrumbs, ["Settings", "Export"])
        
        let categoryBreadcrumbs = TaskManagerRoute.categoryView(category: .work).breadcrumbNames
        XCTAssertEqual(categoryBreadcrumbs, ["Tasks", "Work"])
    }
    
    // MARK: - Navigation Validation Tests
    
    func testCanNavigateFrom() {
        let taskId = UUID()
        
        // Most routes should allow navigation from anywhere
        XCTAssertTrue(TaskManagerRoute.taskList.canNavigateFrom(.settings))
        XCTAssertTrue(TaskManagerRoute.settings.canNavigateFrom(.taskList))
        XCTAssertTrue(TaskManagerRoute.createTask.canNavigateFrom(.taskList))
        
        // Routes requiring tasks should validate task ID (mock validation)
        XCTAssertTrue(TaskManagerRoute.taskDetail(taskId: taskId).canNavigateFrom(.taskList))
        XCTAssertTrue(TaskManagerRoute.editTask(taskId: taskId).canNavigateFrom(.taskList))
        
        // Test invalid task ID (using UUID() which creates new ID each time)
        XCTAssertTrue(TaskManagerRoute.taskDetail(taskId: UUID()).canNavigateFrom(.taskList))
    }
    
    func testTransitionAnimation() {
        // Test push animation (going deeper)
        XCTAssertEqual(
            TaskManagerRoute.taskDetail(taskId: UUID()).transitionAnimation(from: .taskList),
            .push
        )
        
        XCTAssertEqual(
            TaskManagerRoute.createTask.transitionAnimation(from: .taskList),
            .push
        )
        
        // Test pop animation (going back)
        XCTAssertEqual(
            TaskManagerRoute.taskList.transitionAnimation(from: .taskDetail(taskId: UUID())),
            .pop
        )
        
        // Test replace animation (same level)
        XCTAssertEqual(
            TaskManagerRoute.settings.transitionAnimation(from: .taskList),
            .replace
        )
        
        XCTAssertEqual(
            TaskManagerRoute.categoryView(category: .work).transitionAnimation(from: .priorityView(priority: .high)),
            .replace
        )
    }
    
    // MARK: - Context Requirements Tests
    
    func testRequiredContextType() {
        XCTAssertEqual(TaskManagerRoute.taskList.requiredContextType, "TaskListContext")
        XCTAssertEqual(TaskManagerRoute.taskDetail(taskId: UUID()).requiredContextType, "TaskDetailContext")
        XCTAssertEqual(TaskManagerRoute.createTask.requiredContextType, "CreateTaskContext")
        XCTAssertEqual(TaskManagerRoute.settings.requiredContextType, "TaskSettingsContext")
        XCTAssertEqual(TaskManagerRoute.statistics.requiredContextType, "TaskStatisticsContext")
        XCTAssertEqual(TaskManagerRoute.categoryView(category: .work).requiredContextType, "TaskListContext")
        XCTAssertEqual(TaskManagerRoute.priorityView(priority: .high).requiredContextType, "TaskListContext")
        XCTAssertEqual(TaskManagerRoute.search(query: "test").requiredContextType, "TaskListContext")
        XCTAssertEqual(TaskManagerRoute.filters.requiredContextType, "TaskListContext")
        XCTAssertEqual(TaskManagerRoute.export.requiredContextType, "TaskSettingsContext")
        XCTAssertEqual(TaskManagerRoute.import.requiredContextType, "TaskSettingsContext")
        XCTAssertEqual(TaskManagerRoute.about.requiredContextType, "AboutContext")
    }
    
    func testContextParameters() {
        let taskId = UUID()
        let date = Date()
        
        XCTAssertTrue(TaskManagerRoute.taskList.contextParameters.isEmpty)
        
        let taskDetailParams = TaskManagerRoute.taskDetail(taskId: taskId).contextParameters
        XCTAssertEqual(taskDetailParams["taskId"] as? UUID, taskId)
        
        let editTaskParams = TaskManagerRoute.editTask(taskId: taskId).contextParameters
        XCTAssertEqual(editTaskParams["taskId"] as? UUID, taskId)
        
        let categoryParams = TaskManagerRoute.categoryView(category: .work).contextParameters
        XCTAssertEqual(categoryParams["category"] as? Category, .work)
        
        let priorityParams = TaskManagerRoute.priorityView(priority: .high).contextParameters
        XCTAssertEqual(priorityParams["priority"] as? Priority, .high)
        
        let dueDateParams = TaskManagerRoute.dueDateView(date: date).contextParameters
        XCTAssertEqual(dueDateParams["date"] as? Date, date)
        
        let searchParams = TaskManagerRoute.search(query: "test").contextParameters
        XCTAssertEqual(searchParams["query"] as? String, "test")
    }
    
    // MARK: - Hashable and Equatable Tests
    
    func testRouteEquality() {
        let taskId = UUID()
        let sameTaskId = taskId
        let differentTaskId = UUID()
        
        // Same routes should be equal
        XCTAssertEqual(TaskManagerRoute.taskList, TaskManagerRoute.taskList)
        XCTAssertEqual(TaskManagerRoute.settings, TaskManagerRoute.settings)
        XCTAssertEqual(
            TaskManagerRoute.taskDetail(taskId: taskId),
            TaskManagerRoute.taskDetail(taskId: sameTaskId)
        )
        
        // Different routes should not be equal
        XCTAssertNotEqual(TaskManagerRoute.taskList, TaskManagerRoute.settings)
        XCTAssertNotEqual(
            TaskManagerRoute.taskDetail(taskId: taskId),
            TaskManagerRoute.taskDetail(taskId: differentTaskId)
        )
        XCTAssertNotEqual(
            TaskManagerRoute.categoryView(category: .work),
            TaskManagerRoute.categoryView(category: .personal)
        )
    }
    
    func testRouteHashable() {
        let taskId = UUID()
        
        let routes: Set<TaskManagerRoute> = [
            .taskList,
            .taskDetail(taskId: taskId),
            .createTask,
            .settings,
            .categoryView(category: .work),
            .priorityView(priority: .high)
        ]
        
        XCTAssertEqual(routes.count, 6)
        XCTAssertTrue(routes.contains(.taskList))
        XCTAssertTrue(routes.contains(.taskDetail(taskId: taskId)))
        XCTAssertTrue(routes.contains(.createTask))
        XCTAssertTrue(routes.contains(.settings))
        XCTAssertTrue(routes.contains(.categoryView(category: .work)))
        XCTAssertTrue(routes.contains(.priorityView(priority: .high)))
    }
}

// MARK: - Route Matcher Tests

final class RouteMatcherTests: XCTestCase {
    
    var routeMatcher: RouteMatcher<TaskManagerRoute>!
    
    override func setUp() {
        super.setUp()
        routeMatcher = RouteMatcher<TaskManagerRoute>()
        
        // Register patterns
        routeMatcher.register(pattern: "/tasks") { _ in
            return .taskList
        }
        
        routeMatcher.register(pattern: "/tasks/:taskId") { parameters in
            guard let taskIdString = parameters["taskId"],
                  let taskId = UUID(uuidString: taskIdString) else {
                return nil
            }
            return .taskDetail(taskId: taskId)
        }
        
        routeMatcher.register(pattern: "/tasks/create") { _ in
            return .createTask
        }
        
        routeMatcher.register(pattern: "/settings") { _ in
            return .settings
        }
        
        routeMatcher.register(pattern: "/category/:category") { parameters in
            guard let categoryString = parameters["category"],
                  let category = Category(rawValue: categoryString) else {
                return nil
            }
            return .categoryView(category: category)
        }
    }
    
    func testRouteMatcherBasicMatching() {
        XCTAssertEqual(routeMatcher.match(path: "/tasks"), .taskList)
        XCTAssertEqual(routeMatcher.match(path: "/tasks/create"), .createTask)
        XCTAssertEqual(routeMatcher.match(path: "/settings"), .settings)
        
        // Test parameter matching
        let taskId = UUID()
        XCTAssertEqual(
            routeMatcher.match(path: "/tasks/\(taskId.uuidString)"),
            .taskDetail(taskId: taskId)
        )
        
        XCTAssertEqual(
            routeMatcher.match(path: "/category/work"),
            .categoryView(category: .work)
        )
    }
    
    func testRouteMatcherInvalidPaths() {
        XCTAssertNil(routeMatcher.match(path: "/invalid"))
        XCTAssertNil(routeMatcher.match(path: "/tasks/invalid-uuid"))
        XCTAssertNil(routeMatcher.match(path: "/category/invalid"))
        XCTAssertNil(routeMatcher.match(path: ""))
    }
    
    func testRouteMatcherURLMatching() {
        let baseURL = "https://taskmanager.app"
        
        XCTAssertEqual(
            routeMatcher.match(url: URL(string: "\(baseURL)/tasks")!),
            .taskList
        )
        
        XCTAssertEqual(
            routeMatcher.match(url: URL(string: "\(baseURL)/settings")!),
            .settings
        )
        
        let taskId = UUID()
        XCTAssertEqual(
            routeMatcher.match(url: URL(string: "\(baseURL)/tasks/\(taskId.uuidString)")!),
            .taskDetail(taskId: taskId)
        )
    }
}

// MARK: - Route History Tests

final class RouteHistoryTests: XCTestCase {
    
    var routeHistory: RouteHistory!
    
    override func setUp() {
        super.setUp()
        routeHistory = RouteHistory()
    }
    
    func testEmptyHistory() {
        XCTAssertNil(routeHistory.currentRoute)
        XCTAssertFalse(routeHistory.canGoBack)
        XCTAssertFalse(routeHistory.canGoForward)
        XCTAssertEqual(routeHistory.history.count, 0)
        XCTAssertEqual(routeHistory.currentIndex, -1)
    }
    
    func testPushRoute() {
        routeHistory.push(.taskList)
        
        XCTAssertEqual(routeHistory.currentRoute, .taskList)
        XCTAssertEqual(routeHistory.history.count, 1)
        XCTAssertEqual(routeHistory.currentIndex, 0)
        XCTAssertFalse(routeHistory.canGoBack)
        XCTAssertFalse(routeHistory.canGoForward)
    }
    
    func testMultiplePushes() {
        routeHistory.push(.taskList)
        routeHistory.push(.createTask)
        routeHistory.push(.taskDetail(taskId: UUID()))
        
        XCTAssertEqual(routeHistory.history.count, 3)
        XCTAssertEqual(routeHistory.currentIndex, 2)
        XCTAssertTrue(routeHistory.canGoBack)
        XCTAssertFalse(routeHistory.canGoForward)
        
        if case .taskDetail = routeHistory.currentRoute! {
            // Expected
        } else {
            XCTFail("Current route should be task detail")
        }
    }
    
    func testGoBack() {
        let taskId = UUID()
        routeHistory.push(.taskList)
        routeHistory.push(.createTask)
        routeHistory.push(.taskDetail(taskId: taskId))
        
        let previousRoute = routeHistory.goBack()
        XCTAssertEqual(previousRoute, .createTask)
        XCTAssertEqual(routeHistory.currentRoute, .createTask)
        XCTAssertEqual(routeHistory.currentIndex, 1)
        XCTAssertTrue(routeHistory.canGoBack)
        XCTAssertTrue(routeHistory.canGoForward)
        
        let earlierRoute = routeHistory.goBack()
        XCTAssertEqual(earlierRoute, .taskList)
        XCTAssertEqual(routeHistory.currentRoute, .taskList)
        XCTAssertEqual(routeHistory.currentIndex, 0)
        XCTAssertFalse(routeHistory.canGoBack)
        XCTAssertTrue(routeHistory.canGoForward)
        
        // Can't go back further
        let noRoute = routeHistory.goBack()
        XCTAssertNil(noRoute)
        XCTAssertEqual(routeHistory.currentIndex, 0)
    }
    
    func testGoForward() {
        let taskId = UUID()
        routeHistory.push(.taskList)
        routeHistory.push(.createTask)
        routeHistory.push(.taskDetail(taskId: taskId))
        
        // Go back twice
        routeHistory.goBack()
        routeHistory.goBack()
        
        // Now go forward
        let forwardRoute = routeHistory.goForward()
        XCTAssertEqual(forwardRoute, .createTask)
        XCTAssertEqual(routeHistory.currentRoute, .createTask)
        XCTAssertEqual(routeHistory.currentIndex, 1)
        
        let nextForwardRoute = routeHistory.goForward()
        XCTAssertEqual(nextForwardRoute, .taskDetail(taskId: taskId))
        XCTAssertEqual(routeHistory.currentIndex, 2)
        XCTAssertFalse(routeHistory.canGoForward)
        
        // Can't go forward further
        let noRoute = routeHistory.goForward()
        XCTAssertNil(noRoute)
    }
    
    func testPushClearsForwardHistory() {
        let taskId = UUID()
        routeHistory.push(.taskList)
        routeHistory.push(.createTask)
        routeHistory.push(.taskDetail(taskId: taskId))
        
        // Go back
        routeHistory.goBack()
        XCTAssertTrue(routeHistory.canGoForward)
        
        // Push new route should clear forward history
        routeHistory.push(.settings)
        XCTAssertFalse(routeHistory.canGoForward)
        XCTAssertEqual(routeHistory.history.count, 3) // taskList, createTask, settings
        XCTAssertEqual(routeHistory.currentRoute, .settings)
    }
    
    func testHistoryLimit() {
        // Push more than 50 routes
        for i in 0..<60 {
            routeHistory.push(.search(query: "query\(i)"))
        }
        
        XCTAssertEqual(routeHistory.history.count, 50, "History should be limited to 50 items")
        XCTAssertEqual(routeHistory.currentIndex, 49)
        
        // The oldest routes should be removed
        if case .search(let query) = routeHistory.history.first!, query == "query10" {
            // Expected - first 10 routes were removed
        } else {
            XCTFail("Oldest routes should have been removed")
        }
    }
    
    func testClearHistory() {
        routeHistory.push(.taskList)
        routeHistory.push(.createTask)
        routeHistory.push(.settings)
        
        routeHistory.clear()
        
        XCTAssertNil(routeHistory.currentRoute)
        XCTAssertEqual(routeHistory.history.count, 0)
        XCTAssertEqual(routeHistory.currentIndex, -1)
        XCTAssertFalse(routeHistory.canGoBack)
        XCTAssertFalse(routeHistory.canGoForward)
    }
}