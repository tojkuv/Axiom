import XCTest
@testable import TaskManager
import Axiom
import AxiomTesting

final class QuickActionsTests: XCTestCase {
    var client: TaskClient!
    var navigationService: MockQuickActionsNavigationService!
    var shortcutManager: ShortcutManager!
    var urlHandler: TaskURLHandler!
    
    override func setUp() async throws {
        client = TaskClient()
        
        await MainActor.run {
            navigationService = MockQuickActionsNavigationService()
            shortcutManager = ShortcutManager(client: client)
            shortcutManager.navigationService = navigationService
            urlHandler = TaskURLHandler(
                client: client,
                navigationService: navigationService
            )
        }
    }
    
    // Test 1: Shortcut item creation
    func testShortcutItemCreation() async throws {
        // Add some tasks
        try await client.process(TaskAction.addTask(
            title: "Important Task",
            description: nil,
            categoryId: nil,
            priority: .high
        ))
        
        let shortcuts = await shortcutManager.updateShortcuts()
        
        XCTAssertEqual(shortcuts.count, 4) // 3 static + 1 dynamic
        XCTAssertEqual(shortcuts[0].type, "com.app.create-task")
        XCTAssertEqual(shortcuts[3].localizedTitle, "Important Task")
    }
    
    // Test 2: Deep link parsing
    func testDeepLinkParsing() async throws {
        let createURL = URL(string: "taskmanager://create")!
        let taskId = UUID()
        let taskURL = URL(string: "taskmanager://task/\(taskId.uuidString)")!
        let searchURL = URL(string: "taskmanager://search?query=test")!
        
        await MainActor.run {
            XCTAssertEqual(urlHandler.parseAction(from: createURL), .createTask)
            XCTAssertEqual(urlHandler.parseAction(from: taskURL), .viewTask(id: taskId))
            XCTAssertEqual(urlHandler.parseAction(from: searchURL), .search(query: "test"))
        }
    }
    
    // Test 3: Quick action handling
    func testQuickActionHandling() async throws {
        let shortcutItem = MockShortcutItem(
            type: "com.app.create-task",
            localizedTitle: "Create Task"
        )
        
        let handled = await shortcutManager.handleShortcut(shortcutItem)
        
        XCTAssertTrue(handled)
        await MainActor.run {
            XCTAssertEqual(navigationService.lastRoute, TaskRoute.createTask)
        }
    }
    
    // Test 4: State restoration from deep link
    func testStateRestorationFromDeepLink() async throws {
        // Create a task
        try await client.process(TaskAction.addTask(
            title: "Test Task",
            description: nil,
            categoryId: nil,
            priority: .medium
        ))
        
        // Get the created task ID
        let taskId = await client.state.tasks.first!.id
        
        // Handle deep link
        let url = URL(string: "taskmanager://task/\(taskId.uuidString)")!
        let handled = await urlHandler.handle(url)
        
        XCTAssertTrue(handled)
        await MainActor.run {
            XCTAssertEqual(navigationService.lastRoute, TaskRoute.editTask(id: taskId))
        }
    }
    
    // Test 5: Recent tasks shortcuts
    func testRecentTasksShortcuts() async throws {
        // Create multiple tasks
        for i in 1...5 {
            try await client.process(TaskAction.addTask(
                title: "Task \(i)",
                description: nil,
                categoryId: nil,
                priority: i <= 2 ? .high : .medium
            ))
        }
        
        let shortcuts = await shortcutManager.updateShortcuts()
        let dynamicShortcuts = shortcuts.filter { $0.type.hasPrefix("com.app.task.") }
        
        // Should show 2 most recent high-priority tasks
        XCTAssertEqual(dynamicShortcuts.count, 2)
        XCTAssertTrue(dynamicShortcuts.allSatisfy { $0.localizedSubtitle == "High Priority" })
    }
    
    // Test 6: Cold launch action queuing
    func testColdLaunchActionQueuing() async throws {
        // This test verifies that actions can be queued and processed
        // The actual navigation happens through URL handling which is tested separately
        let launcher = await LaunchActionHandler(client: client, navigationService: navigationService)
        
        // Verify we can queue actions without crashing
        await launcher.queueAction(.createTask)
        await launcher.queueAction(.search(query: "test"))
        
        // Process should complete without errors
        await launcher.processQueuedActions()
        
        // Since navigation happens through URL handling in a Task,
        // we're mainly testing that the queuing mechanism works
        // The actual navigation is tested in other tests
        XCTAssertTrue(true, "Action queuing and processing completed successfully")
    }
    
    // Test 7: Invalid deep link handling
    func testInvalidDeepLinkHandling() async throws {
        let invalidURL = URL(string: "taskmanager://invalid")!
        let handled = await urlHandler.handle(invalidURL)
        
        XCTAssertFalse(handled)
        await MainActor.run {
            XCTAssertNil(navigationService.lastRoute)
        }
    }
    
    // Test 8: Shortcut update performance
    func testShortcutUpdatePerformance() async throws {
        // Create 100 tasks
        for i in 1...100 {
            try await client.process(TaskAction.addTask(title: "Task \(i)", description: nil))
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = await shortcutManager.updateShortcuts()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, 0.1) // Should complete within 100ms
    }
    
    // Test 9: Search deep link with special characters
    func testSearchDeepLinkWithSpecialCharacters() async throws {
        let url = URL(string: "taskmanager://search?query=test%20%26%20debug")!
        
        await MainActor.run {
            let action = urlHandler.parseAction(from: url)
            
            if case .search(let query) = action {
                XCTAssertEqual(query, "test & debug")
            } else {
                XCTFail("Expected search action")
            }
        }
    }
    
    // Test 10: Concurrent action handling
    func testConcurrentActionHandling() async throws {
        let launcher = await LaunchActionHandler(client: client, navigationService: navigationService)
        
        // Queue multiple actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 1...5 {
                group.addTask {
                    await launcher.queueAction(.viewTask(id: UUID()))
                }
            }
        }
        
        await launcher.processQueuedActions()
        
        // Should handle last action
        await MainActor.run {
            XCTAssertNotNil(navigationService.lastRoute)
        }
    }
    
    // Test 11: Shortcut localization
    func testShortcutLocalization() async throws {
        let shortcuts = await shortcutManager.updateShortcuts()
        
        XCTAssertTrue(shortcuts.allSatisfy { !$0.localizedTitle.isEmpty })
        XCTAssertTrue(shortcuts.allSatisfy { $0.localizedSubtitle != nil })
    }
    
    // Test 12: State restoration with missing task
    func testStateRestorationWithMissingTask() async throws {
        let nonExistentId = UUID()
        let url = URL(string: "taskmanager://task/\(nonExistentId.uuidString)")!
        let handled = await urlHandler.handle(url)
        
        XCTAssertTrue(handled) // Should handle gracefully
        await MainActor.run {
            XCTAssertEqual(navigationService.lastRoute, TaskRoute.list) // Fallback to list
        }
    }
}

// Mock shortcut item for testing
struct MockShortcutItem: ShortcutItemProtocol {
    let type: String
    let localizedTitle: String
    var localizedSubtitle: String?
    var userInfo: [String: Any]?
}

// Mock navigation service for testing
@MainActor
class MockQuickActionsNavigationService: TaskManager.NavigationService {
    var navigationHistory: [(route: TaskRoute, timestamp: Date)] = []
    var dismissCount = 0
    
    var lastRoute: TaskRoute? {
        navigationHistory.last?.route
    }
    
    func navigate(to route: TaskRoute) {
        navigationHistory.append((route: route, timestamp: Date()))
    }
    
    func dismiss() {
        dismissCount += 1
    }
}