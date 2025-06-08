import XCTest
import Axiom
@testable import TaskManager

final class PriorityTests: XCTestCase {
    
    // MARK: - RED Phase: Priority Model Tests
    
    func testPriorityStateProtocol() async {
        // Testing Priority conforms to State protocol
        // Framework insight: How to model enum-based state?
        let priority = Priority.medium
        
        // Should conform to State protocol requirements
        XCTAssertNotNil(priority as any State)
        
        // Should be Equatable
        XCTAssertEqual(Priority.high, Priority.high)
        XCTAssertNotEqual(Priority.low, Priority.high)
        
        // Should be Hashable
        var set = Set<Priority>()
        set.insert(priority)
        XCTAssertEqual(set.count, 1)
        
        // Should be Sendable (for actor boundaries)
        await MainActor.run {
            let _ = priority // Should compile without warnings
        }
    }
    
    func testPriorityOrdering() async {
        // Test priority comparison and ordering
        // Framework insight: How to model ordered enums in State?
        
        // Test comparison operators
        XCTAssertTrue(Priority.critical > Priority.high)
        XCTAssertTrue(Priority.high > Priority.medium)
        XCTAssertTrue(Priority.medium > Priority.low)
        
        // Test sorting behavior
        let priorities: [Priority] = [.low, .critical, .medium, .high]
        let sorted = priorities.sorted()
        XCTAssertEqual(sorted, [.low, .medium, .high, .critical])
        
        // Test reverse sorting
        let reverseSorted = priorities.sorted(by: >)
        XCTAssertEqual(reverseSorted, [.critical, .high, .medium, .low])
    }
    
    func testPriorityDisplayProperties() async {
        // Test display properties for UI
        // Framework insight: How to handle display state vs logic state?
        
        XCTAssertEqual(Priority.low.displayName, "Low")
        XCTAssertEqual(Priority.medium.displayName, "Medium") 
        XCTAssertEqual(Priority.high.displayName, "High")
        XCTAssertEqual(Priority.critical.displayName, "Critical")
        
        // Test colors for UI
        XCTAssertFalse(Priority.low.color.isEmpty)
        XCTAssertFalse(Priority.medium.color.isEmpty)
        XCTAssertFalse(Priority.high.color.isEmpty)
        XCTAssertFalse(Priority.critical.color.isEmpty)
        
        // Test SF Symbol icons
        XCTAssertFalse(Priority.low.icon.isEmpty)
        XCTAssertFalse(Priority.medium.icon.isEmpty)
        XCTAssertFalse(Priority.high.icon.isEmpty)
        XCTAssertFalse(Priority.critical.icon.isEmpty)
    }
    
    func testTaskPriorityAssignment() async {
        // Test adding priority to tasks
        // Framework insight: How to handle optional vs required state fields?
        let task = TaskItem(
            title: "Priority task",
            priority: .high
        )
        
        XCTAssertEqual(task.priority, .high)
        
        // Task should be immutable (State requirement)
        let updatedTask = TaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: task.categoryId,
            priority: .critical, // Changed priority
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        XCTAssertNotEqual(task.priority, updatedTask.priority)
        XCTAssertEqual(updatedTask.priority, .critical)
    }
    
    func testPriorityDefaultBehavior() async {
        // Test default priority handling
        // Framework insight: How to handle defaults in State models?
        
        // Task without explicit priority should have default
        let taskWithoutPriority = TaskItem(title: "No priority task")
        XCTAssertEqual(taskWithoutPriority.priority, Priority.medium) // Should default to medium
        
        // Test all priorities are available
        let allPriorities = Priority.allCases
        XCTAssertEqual(allPriorities.count, 4)
        XCTAssertTrue(allPriorities.contains(.low))
        XCTAssertTrue(allPriorities.contains(.medium))
        XCTAssertTrue(allPriorities.contains(.high))
        XCTAssertTrue(allPriorities.contains(.critical))
    }
    
    func testPriorityFiltering() async {
        // Test filtering tasks by priority
        // Framework insight: How to combine filter criteria?
        let tasks = [
            TaskTestHelpers.makeTask(title: "Low task", priority: .low),
            TaskTestHelpers.makeTask(title: "High task", priority: .high),
            TaskTestHelpers.makeTask(title: "Critical task", priority: .critical),
            TaskTestHelpers.makeTask(title: "Medium task", priority: .medium)
        ]
        
        // Filter high priority and above
        let highPriorityTasks = tasks.filter { $0.priority >= .high }
        XCTAssertEqual(highPriorityTasks.count, 2)
        
        // Filter specific priority
        let criticalTasks = tasks.filter { $0.priority == .critical }
        XCTAssertEqual(criticalTasks.count, 1)
        XCTAssertEqual(criticalTasks.first?.title, "Critical task")
    }
}