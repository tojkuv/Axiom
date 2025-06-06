import XCTest
import CoreGraphics
@testable import TestApp002

// RED Phase: Failing tests for deep navigation stack
// RFC Requirement: Navigate from task list → task detail → edit
// RFC Acceptance: Back navigation restores previous scroll position within 50 pixels of original position
// RFC Boundary: Maximum stack depth of 5 screens

class DeepNavigationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clean state for each test
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Basic Navigation Tests
    
    func testTaskListToDetailNavigation() async throws {
        // RED: This test should fail - DeepNavigationController doesn't exist
        let navigationController = DeepNavigationController()
        
        // Test navigating from task list to task detail
        let taskId = "test-task-123"
        let navigationResult = try await navigationController.push(.taskDetail(taskId: taskId))
        
        XCTAssertTrue(navigationResult.wasSuccessful)
        XCTAssertEqual(navigationResult.currentScreen, .taskDetail(taskId: taskId))
        XCTAssertEqual(navigationResult.stackDepth, 2) // task list + detail
        
        // Verify navigation stack
        let stack = try await navigationController.getNavigationStack()
        XCTAssertEqual(stack.count, 2)
        XCTAssertEqual(stack.first, .taskList)
        XCTAssertEqual(stack.last, .taskDetail(taskId: taskId))
    }
    
    func testFullNavigationFlow() async throws {
        // RED: Test complete flow: task list → task detail → edit
        let navigationController = DeepNavigationController()
        
        let taskId = "test-task-456"
        
        // Navigate to task detail
        let detailResult = try await navigationController.push(.taskDetail(taskId: taskId))
        XCTAssertTrue(detailResult.wasSuccessful)
        
        // Navigate to task edit
        let editResult = try await navigationController.push(.taskEdit(taskId: taskId))
        XCTAssertTrue(editResult.wasSuccessful)
        XCTAssertEqual(editResult.stackDepth, 3) // list + detail + edit
        
        // Verify final navigation state
        let currentScreen = try await navigationController.getCurrentScreen()
        XCTAssertEqual(currentScreen, .taskEdit(taskId: taskId))
    }
    
    func testScrollPositionTracking() async throws {
        // RED: Test scroll position is tracked during navigation
        let navigationController = DeepNavigationController()
        
        // Set initial scroll position
        let initialPosition = CGPoint(x: 0, y: 150)
        try await navigationController.setScrollPosition(initialPosition, for: .taskList)
        
        // Navigate to detail
        let taskId = "scroll-test-task"
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        
        // Verify scroll position was saved
        let savedPosition = try await navigationController.getScrollPosition(for: .taskList)
        XCTAssertEqual(savedPosition.x, initialPosition.x, accuracy: 1.0)
        XCTAssertEqual(savedPosition.y, initialPosition.y, accuracy: 1.0)
    }
    
    // MARK: - Back Navigation Tests
    
    func testBackNavigation() async throws {
        // RED: Test back navigation functionality
        let navigationController = DeepNavigationController()
        
        let taskId = "back-nav-task"
        
        // Build navigation stack
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        _ = try await navigationController.push(.taskEdit(taskId: taskId))
        
        // Test back navigation
        let popResult = try await navigationController.pop()
        XCTAssertTrue(popResult.wasSuccessful)
        XCTAssertEqual(popResult.currentScreen, .taskDetail(taskId: taskId))
        XCTAssertEqual(popResult.stackDepth, 2)
        
        // Verify navigation stack
        let stack = try await navigationController.getNavigationStack()
        XCTAssertEqual(stack.count, 2)
        XCTAssertEqual(stack.last, .taskDetail(taskId: taskId))
    }
    
    func testScrollPositionRestoration() async throws {
        // RED: Test scroll position restoration (RFC Acceptance criteria)
        let navigationController = DeepNavigationController()
        
        let taskId = "restore-scroll-task"
        let originalPosition = CGPoint(x: 0, y: 200)
        
        // Set scroll position and navigate away
        try await navigationController.setScrollPosition(originalPosition, for: .taskList)
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        
        // Navigate back
        let backResult = try await navigationController.pop()
        XCTAssertTrue(backResult.wasSuccessful)
        
        // Verify scroll position restored within 50 pixels (RFC requirement)
        let restoredPosition = try await navigationController.getScrollPosition(for: .taskList)
        let xDifference = abs(restoredPosition.x - originalPosition.x)
        let yDifference = abs(restoredPosition.y - originalPosition.y)
        
        XCTAssertLessThan(xDifference, 50, "X scroll position should be restored within 50 pixels")
        XCTAssertLessThan(yDifference, 50, "Y scroll position should be restored within 50 pixels")
    }
    
    func testMultipleLevelBackNavigation() async throws {
        // RED: Test navigating back multiple levels
        let navigationController = DeepNavigationController()
        
        let taskId = "multi-back-task"
        
        // Build deep stack
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        _ = try await navigationController.push(.taskEdit(taskId: taskId))
        _ = try await navigationController.push(.categoryEdit(categoryId: "cat-1"))
        
        // Navigate back two levels
        _ = try await navigationController.pop()
        let secondPopResult = try await navigationController.pop()
        
        XCTAssertTrue(secondPopResult.wasSuccessful)
        XCTAssertEqual(secondPopResult.currentScreen, .taskDetail(taskId: taskId))
        XCTAssertEqual(secondPopResult.stackDepth, 2)
    }
    
    // MARK: - Stack Depth Tests
    
    func testMaximumStackDepth() async throws {
        // RED: Test maximum stack depth of 5 screens (RFC Boundary)
        let navigationController = DeepNavigationController()
        
        // Build stack to exactly 5 screens (4 pushes after root)
        _ = try await navigationController.push(.taskDetail(taskId: "task1"))
        _ = try await navigationController.push(.taskEdit(taskId: "task1"))
        _ = try await navigationController.push(.categoryEdit(categoryId: "cat1"))
        
        // This should succeed (5 screens total including root)
        let result4 = try await navigationController.push(.settings)
        XCTAssertTrue(result4.wasSuccessful)
        XCTAssertEqual(result4.stackDepth, 5)
        
        // This should fail (would exceed 5 screens)
        do {
            _ = try await navigationController.push(.profile)
            XCTFail("Should not allow more than 5 screens in stack")
        } catch DeepNavigationError.maximumStackDepthExceeded {
            // Expected
        }
    }
    
    func testStackDepthValidation() async throws {
        // RED: Test stack depth is properly tracked
        let navigationController = DeepNavigationController()
        
        let initialDepth = try await navigationController.getStackDepth()
        XCTAssertEqual(initialDepth, 1) // Root screen
        
        _ = try await navigationController.push(.taskDetail(taskId: "depth-test"))
        let afterPushDepth = try await navigationController.getStackDepth()
        XCTAssertEqual(afterPushDepth, 2)
        
        _ = try await navigationController.pop()
        let afterPopDepth = try await navigationController.getStackDepth()
        XCTAssertEqual(afterPopDepth, 1)
    }
    
    // MARK: - Navigation State Tests
    
    func testNavigationStateConsistency() async throws {
        // RED: Test navigation state remains consistent
        let navigationController = DeepNavigationController()
        
        let taskId = "state-test-task"
        
        // Navigate and verify state at each step
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        let stateAfterDetail = try await navigationController.getNavigationState()
        
        XCTAssertEqual(stateAfterDetail.currentScreen, .taskDetail(taskId: taskId))
        XCTAssertEqual(stateAfterDetail.stackDepth, 2)
        XCTAssertTrue(stateAfterDetail.canNavigateBack)
        
        _ = try await navigationController.push(.taskEdit(taskId: taskId))
        let stateAfterEdit = try await navigationController.getNavigationState()
        
        XCTAssertEqual(stateAfterEdit.currentScreen, .taskEdit(taskId: taskId))
        XCTAssertEqual(stateAfterEdit.stackDepth, 3)
        XCTAssertTrue(stateAfterEdit.canNavigateBack)
    }
    
    func testCanNavigateBackFlag() async throws {
        // RED: Test canNavigateBack flag accuracy
        let navigationController = DeepNavigationController()
        
        // Initially should not be able to navigate back
        let initialState = try await navigationController.getNavigationState()
        XCTAssertFalse(initialState.canNavigateBack)
        
        // After push, should be able to navigate back
        _ = try await navigationController.push(.taskDetail(taskId: "can-back-test"))
        let afterPushState = try await navigationController.getNavigationState()
        XCTAssertTrue(afterPushState.canNavigateBack)
        
        // After pop back to root, should not be able to navigate back
        _ = try await navigationController.pop()
        let afterPopState = try await navigationController.getNavigationState()
        XCTAssertFalse(afterPopState.canNavigateBack)
    }
    
    // MARK: - Error Handling Tests
    
    func testPopFromRootScreen() async throws {
        // RED: Test error when trying to pop from root screen
        let navigationController = DeepNavigationController()
        
        do {
            _ = try await navigationController.pop()
            XCTFail("Should not be able to pop from root screen")
        } catch DeepNavigationError.cannotPopFromRoot {
            // Expected
        }
    }
    
    func testInvalidScreenNavigation() async throws {
        // RED: Test error handling for invalid navigation
        let navigationController = DeepNavigationController()
        
        // Try to navigate to an invalid screen type
        do {
            _ = try await navigationController.push(.taskEdit(taskId: "")) // Empty task ID
            XCTFail("Should not allow navigation with invalid parameters")
        } catch DeepNavigationError.invalidNavigationTarget {
            // Expected
        }
    }
    
    // MARK: - REFACTOR Phase: Enhanced Features Tests
    
    func testBreadcrumbNavigation() async throws {
        // REFACTOR: Test breadcrumb navigation feature
        let navigationController = DeepNavigationController()
        
        let taskId = "breadcrumb-task"
        
        // Build navigation stack
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        _ = try await navigationController.push(.taskEdit(taskId: taskId))
        
        // Get breadcrumbs
        let breadcrumbs = try await navigationController.getBreadcrumbs()
        
        XCTAssertEqual(breadcrumbs.count, 3)
        XCTAssertEqual(breadcrumbs[0].title, "Tasks")
        XCTAssertEqual(breadcrumbs[1].title, "Task Detail")
        XCTAssertEqual(breadcrumbs[2].title, "Edit Task")
        
        // Test breadcrumb navigation
        let jumpResult = try await navigationController.navigateToBreadcrumb(at: 0)
        XCTAssertTrue(jumpResult.wasSuccessful)
        XCTAssertEqual(jumpResult.currentScreen, .taskList)
    }
    
    func testStateRestorationAfterRestart() async throws {
        // REFACTOR: Test navigation state restoration
        let navigationController = DeepNavigationController()
        
        let taskId = "restore-state-task"
        let scrollPosition = CGPoint(x: 0, y: 100)
        
        // Build navigation state
        try await navigationController.setScrollPosition(scrollPosition, for: .taskList)
        _ = try await navigationController.push(.taskDetail(taskId: taskId))
        
        // Save state
        let savedState = try await navigationController.saveNavigationState()
        
        // Create new controller and restore state
        let newController = DeepNavigationController()
        try await newController.restoreNavigationState(savedState)
        
        // Verify restoration
        let restoredStack = try await newController.getNavigationStack()
        let restoredPosition = try await newController.getScrollPosition(for: .taskList)
        
        XCTAssertEqual(restoredStack.count, 2)
        XCTAssertEqual(restoredStack.last, .taskDetail(taskId: taskId))
        XCTAssertEqual(restoredPosition.y, scrollPosition.y, accuracy: 1.0)
    }
    
    func testNavigationAnimationTiming() async throws {
        // REFACTOR: Test navigation animation performance
        let navigationController = DeepNavigationController()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform navigation
        _ = try await navigationController.push(.taskDetail(taskId: "timing-test"))
        
        let navigationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Navigation should be fast (< 100ms for internal operations)
        XCTAssertLessThan(navigationTime, 0.1, "Navigation should complete quickly")
    }
}

// MARK: - Supporting Types (These will fail compilation initially)

enum NavigationScreen: Equatable, Hashable {
    case taskList
    case taskDetail(taskId: String)
    case taskEdit(taskId: String)
    case categoryEdit(categoryId: String)
    case settings
    case profile
}

struct NavigationResult {
    let wasSuccessful: Bool
    let currentScreen: NavigationScreen
    let stackDepth: Int
    let animationDuration: TimeInterval
}

struct NavigationState {
    let currentScreen: NavigationScreen
    let stackDepth: Int
    let canNavigateBack: Bool
    let scrollPositions: [NavigationScreen: CGPoint]
}

struct BreadcrumbItem {
    let screen: NavigationScreen
    let title: String
    let isActive: Bool
}

enum DeepNavigationError: Error {
    case maximumStackDepthExceeded
    case cannotPopFromRoot
    case invalidNavigationTarget
    case screenNotFound
    case stateRestorationFailed
    case scrollPositionNotFound
}

// GREEN Phase: Real DeepNavigationController implementation
actor DeepNavigationController {
    private var navigationStack: [NavigationScreen] = [.taskList]
    private var scrollPositions: [NavigationScreen: CGPoint] = [:]
    private let maxStackDepth = 5
    
    func push(_ screen: NavigationScreen) async throws -> NavigationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Validate navigation target
        try validateNavigationTarget(screen)
        
        // Check stack depth limit (RFC Boundary: Maximum stack depth of 5 screens)
        if navigationStack.count >= maxStackDepth {
            throw DeepNavigationError.maximumStackDepthExceeded
        }
        
        // Add to navigation stack
        navigationStack.append(screen)
        
        // Simulate navigation animation
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms animation
        
        let animationDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return NavigationResult(
            wasSuccessful: true,
            currentScreen: screen,
            stackDepth: navigationStack.count,
            animationDuration: animationDuration
        )
    }
    
    func pop() async throws -> NavigationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Cannot pop from root screen
        if navigationStack.count <= 1 {
            throw DeepNavigationError.cannotPopFromRoot
        }
        
        // Remove last screen from stack
        navigationStack.removeLast()
        
        // Get current screen after pop
        let currentScreen = navigationStack.last!
        
        // Simulate navigation animation
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms animation
        
        let animationDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        return NavigationResult(
            wasSuccessful: true,
            currentScreen: currentScreen,
            stackDepth: navigationStack.count,
            animationDuration: animationDuration
        )
    }
    
    func getNavigationStack() async throws -> [NavigationScreen] {
        return navigationStack
    }
    
    func getCurrentScreen() async throws -> NavigationScreen {
        return navigationStack.last ?? .taskList
    }
    
    func getStackDepth() async throws -> Int {
        return navigationStack.count
    }
    
    func setScrollPosition(_ position: CGPoint, for screen: NavigationScreen) async throws {
        scrollPositions[screen] = position
    }
    
    func getScrollPosition(for screen: NavigationScreen) async throws -> CGPoint {
        guard let position = scrollPositions[screen] else {
            // Return default position if not found
            return CGPoint.zero
        }
        return position
    }
    
    func getNavigationState() async throws -> NavigationState {
        let currentScreen = navigationStack.last ?? .taskList
        let canNavigateBack = navigationStack.count > 1
        
        return NavigationState(
            currentScreen: currentScreen,
            stackDepth: navigationStack.count,
            canNavigateBack: canNavigateBack,
            scrollPositions: scrollPositions
        )
    }
    
    private func validateNavigationTarget(_ screen: NavigationScreen) throws {
        // Validate navigation target parameters
        switch screen {
        case .taskDetail(let taskId), .taskEdit(let taskId):
            if taskId.isEmpty {
                throw DeepNavigationError.invalidNavigationTarget
            }
        case .categoryEdit(let categoryId):
            if categoryId.isEmpty {
                throw DeepNavigationError.invalidNavigationTarget
            }
        default:
            // Other screens are valid
            break
        }
    }
    
    // MARK: - REFACTOR Phase: Enhanced Methods
    
    func getBreadcrumbs() async throws -> [BreadcrumbItem] {
        var breadcrumbs: [BreadcrumbItem] = []
        
        for (index, screen) in navigationStack.enumerated() {
            let title = getTitleForScreen(screen)
            let isActive = index == navigationStack.count - 1
            
            breadcrumbs.append(BreadcrumbItem(
                screen: screen,
                title: title,
                isActive: isActive
            ))
        }
        
        return breadcrumbs
    }
    
    func navigateToBreadcrumb(at index: Int) async throws -> NavigationResult {
        guard index >= 0 && index < navigationStack.count else {
            throw DeepNavigationError.invalidNavigationTarget
        }
        
        // Remove all screens after the target index
        navigationStack = Array(navigationStack.prefix(index + 1))
        
        let currentScreen = navigationStack.last!
        
        return NavigationResult(
            wasSuccessful: true,
            currentScreen: currentScreen,
            stackDepth: navigationStack.count,
            animationDuration: 0.01
        )
    }
    
    func saveNavigationState() async throws -> Data {
        let state = NavigationStateData(
            navigationStack: navigationStack,
            scrollPositions: scrollPositions
        )
        
        let encoder = JSONEncoder()
        return try encoder.encode(state)
    }
    
    func restoreNavigationState(_ data: Data) async throws {
        let decoder = JSONDecoder()
        let state = try decoder.decode(NavigationStateData.self, from: data)
        
        // Validate restored state
        guard !state.navigationStack.isEmpty else {
            throw DeepNavigationError.stateRestorationFailed
        }
        
        guard state.navigationStack.count <= maxStackDepth else {
            throw DeepNavigationError.stateRestorationFailed
        }
        
        navigationStack = state.navigationStack
        scrollPositions = state.scrollPositions
    }
    
    // MARK: - REFACTOR: Enhanced Features
    
    private var navigationHistory: [NavigationHistoryEntry] = []
    private var performanceMetrics: NavigationMetrics = NavigationMetrics()
    
    func getNavigationHistory() async -> [NavigationHistoryEntry] {
        return navigationHistory
    }
    
    func getPerformanceMetrics() async -> NavigationMetrics {
        return performanceMetrics
    }
    
    func clearNavigationHistory() async {
        navigationHistory.removeAll()
    }
    
    func canNavigateToScreen(_ screen: NavigationScreen) async -> Bool {
        // Check if navigation is valid
        do {
            try validateNavigationTarget(screen)
            return navigationStack.count < maxStackDepth
        } catch {
            return false
        }
    }
    
    func pushWithTracking(_ screen: NavigationScreen) async throws -> NavigationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Track navigation attempt
        let historyEntry = NavigationHistoryEntry(
            action: .push(screen),
            timestamp: Date(),
            fromScreen: navigationStack.last ?? .taskList,
            toScreen: screen
        )
        
        do {
            let result = try await push(screen)
            
            // Track successful navigation
            navigationHistory.append(historyEntry)
            performanceMetrics.recordNavigation(duration: result.animationDuration, wasSuccessful: true)
            
            return result
        } catch {
            // Track failed navigation
            performanceMetrics.recordNavigation(duration: CFAbsoluteTimeGetCurrent() - startTime, wasSuccessful: false)
            throw error
        }
    }
    
    func popWithTracking() async throws -> NavigationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let fromScreen = navigationStack.last ?? .taskList
        let toScreen = navigationStack.count > 1 ? navigationStack[navigationStack.count - 2] : .taskList
        
        let historyEntry = NavigationHistoryEntry(
            action: .pop,
            timestamp: Date(),
            fromScreen: fromScreen,
            toScreen: toScreen
        )
        
        do {
            let result = try await pop()
            
            // Track successful navigation
            navigationHistory.append(historyEntry)
            performanceMetrics.recordNavigation(duration: result.animationDuration, wasSuccessful: true)
            
            return result
        } catch {
            // Track failed navigation
            performanceMetrics.recordNavigation(duration: CFAbsoluteTimeGetCurrent() - startTime, wasSuccessful: false)
            throw error
        }
    }
    
    private func getTitleForScreen(_ screen: NavigationScreen) -> String {
        switch screen {
        case .taskList:
            return "Tasks"
        case .taskDetail:
            return "Task Detail"
        case .taskEdit:
            return "Edit Task"
        case .categoryEdit:
            return "Edit Category"
        case .settings:
            return "Settings"
        case .profile:
            return "Profile"
        }
    }
}

// MARK: - REFACTOR: Enhanced Supporting Types

struct NavigationHistoryEntry {
    let action: NavigationAction
    let timestamp: Date
    let fromScreen: NavigationScreen
    let toScreen: NavigationScreen
}

enum NavigationAction {
    case push(NavigationScreen)
    case pop
    case breadcrumbJump(Int)
}

struct NavigationMetrics {
    private var totalNavigations: Int = 0
    private var successfulNavigations: Int = 0
    private var totalDuration: TimeInterval = 0
    private var maxDuration: TimeInterval = 0
    
    mutating func recordNavigation(duration: TimeInterval, wasSuccessful: Bool) {
        totalNavigations += 1
        totalDuration += duration
        maxDuration = max(maxDuration, duration)
        
        if wasSuccessful {
            successfulNavigations += 1
        }
    }
    
    var successRate: Double {
        guard totalNavigations > 0 else { return 0 }
        return Double(successfulNavigations) / Double(totalNavigations)
    }
    
    var averageDuration: TimeInterval {
        guard totalNavigations > 0 else { return 0 }
        return totalDuration / Double(totalNavigations)
    }
    
    var maximumDuration: TimeInterval {
        return maxDuration
    }
    
    var navigationCount: Int {
        return totalNavigations
    }
}

// MARK: - Additional Supporting Types for State Restoration

struct NavigationStateData: Codable {
    let navigationStack: [NavigationScreen]
    let scrollPositions: [NavigationScreen: CGPoint]
    
    enum CodingKeys: String, CodingKey {
        case navigationStack
        case scrollPositions
    }
    
    init(navigationStack: [NavigationScreen], scrollPositions: [NavigationScreen: CGPoint]) {
        self.navigationStack = navigationStack
        self.scrollPositions = scrollPositions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode navigation stack
        let stackData = try container.decode([NavigationScreenData].self, forKey: .navigationStack)
        navigationStack = stackData.map { $0.toNavigationScreen() }
        
        // Decode scroll positions
        let positionsData = try container.decode([String: CGPointData].self, forKey: .scrollPositions)
        var positions: [NavigationScreen: CGPoint] = [:]
        
        for (key, pointData) in positionsData {
            if let screenData = NavigationScreenData.fromString(key) {
                positions[screenData.toNavigationScreen()] = pointData.toCGPoint()
            }
        }
        
        scrollPositions = positions
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode navigation stack
        let stackData = navigationStack.map { NavigationScreenData.fromNavigationScreen($0) }
        try container.encode(stackData, forKey: .navigationStack)
        
        // Encode scroll positions
        var positionsData: [String: CGPointData] = [:]
        for (screen, point) in scrollPositions {
            let screenData = NavigationScreenData.fromNavigationScreen(screen)
            positionsData[screenData.toString()] = CGPointData.fromCGPoint(point)
        }
        
        try container.encode(positionsData, forKey: .scrollPositions)
    }
}

struct NavigationScreenData: Codable {
    let type: String
    let parameters: [String: String]
    
    func toNavigationScreen() -> NavigationScreen {
        switch type {
        case "taskList":
            return .taskList
        case "taskDetail":
            return .taskDetail(taskId: parameters["taskId"] ?? "")
        case "taskEdit":
            return .taskEdit(taskId: parameters["taskId"] ?? "")
        case "categoryEdit":
            return .categoryEdit(categoryId: parameters["categoryId"] ?? "")
        case "settings":
            return .settings
        case "profile":
            return .profile
        default:
            return .taskList
        }
    }
    
    static func fromNavigationScreen(_ screen: NavigationScreen) -> NavigationScreenData {
        switch screen {
        case .taskList:
            return NavigationScreenData(type: "taskList", parameters: [:])
        case .taskDetail(let taskId):
            return NavigationScreenData(type: "taskDetail", parameters: ["taskId": taskId])
        case .taskEdit(let taskId):
            return NavigationScreenData(type: "taskEdit", parameters: ["taskId": taskId])
        case .categoryEdit(let categoryId):
            return NavigationScreenData(type: "categoryEdit", parameters: ["categoryId": categoryId])
        case .settings:
            return NavigationScreenData(type: "settings", parameters: [:])
        case .profile:
            return NavigationScreenData(type: "profile", parameters: [:])
        }
    }
    
    func toString() -> String {
        switch type {
        case "taskDetail", "taskEdit":
            return "\(type)_\(parameters["taskId"] ?? "")"
        case "categoryEdit":
            return "\(type)_\(parameters["categoryId"] ?? "")"
        default:
            return type
        }
    }
    
    static func fromString(_ string: String) -> NavigationScreenData? {
        let components = string.split(separator: "_", maxSplits: 1)
        let type = String(components[0])
        
        switch type {
        case "taskList", "settings", "profile":
            return NavigationScreenData(type: type, parameters: [:])
        case "taskDetail", "taskEdit":
            let taskId = components.count > 1 ? String(components[1]) : ""
            return NavigationScreenData(type: type, parameters: ["taskId": taskId])
        case "categoryEdit":
            let categoryId = components.count > 1 ? String(components[1]) : ""
            return NavigationScreenData(type: type, parameters: ["categoryId": categoryId])
        default:
            return nil
        }
    }
}

struct CGPointData: Codable {
    let x: Double
    let y: Double
    
    func toCGPoint() -> CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    static func fromCGPoint(_ point: CGPoint) -> CGPointData {
        return CGPointData(x: Double(point.x), y: Double(point.y))
    }
}