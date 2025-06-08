import XCTest
import Axiom
@testable import TaskManager

final class CategoryTests: XCTestCase {
    
    // MARK: - RED Phase: Category Model Tests
    
    func testCategoryStateProtocol() async {
        // Testing Category conforms to State protocol
        // Framework insight: How to model related entities as State?
        let category = Category(
            id: UUID(),
            name: "Work",
            color: "#FF5733",
            icon: "briefcase"
        )
        
        // Should conform to State protocol requirements
        XCTAssertNotNil(category as any State)
        
        // Should be Equatable
        let sameCat = Category(
            id: category.id, 
            name: "Work", 
            color: "#FF5733", 
            icon: "briefcase",
            createdAt: category.createdAt,
            updatedAt: category.updatedAt
        )
        XCTAssertEqual(category, sameCat)
        
        // Should be Hashable
        var set = Set<TaskManager.Category>()
        set.insert(category)
        XCTAssertEqual(set.count, 1)
        
        // Should be Sendable (for actor boundaries)
        await MainActor.run {
            let _ = category // Should compile without warnings
        }
    }
    
    func testCategoryValidation() async {
        // Test category validation rules
        // Framework insight: Where should validation live for sub-models?
        
        // Valid category
        let validCategory = Category(name: "Work", color: "#FF5733")
        XCTAssertFalse(validCategory.name.isEmpty)
        XCTAssertTrue(validCategory.color.hasPrefix("#"))
        
        // Test color validation
        XCTAssertTrue(Category.isValidColor("#FF5733"))
        XCTAssertTrue(Category.isValidColor("#000000"))
        XCTAssertFalse(Category.isValidColor("FF5733")) // Missing #
        XCTAssertFalse(Category.isValidColor("#GG5733")) // Invalid hex
        XCTAssertFalse(Category.isValidColor("#FF573")) // Too short
    }
    
    func testTaskCategoryAssignment() async {
        // Test adding category reference to tasks
        // Framework insight: How to handle relationships in State?
        let category = Category(name: "Work", color: "#FF5733")
        let task = TaskItem(
            title: "Complete project",
            categoryId: category.id
        )
        
        XCTAssertEqual(task.categoryId, category.id)
        
        // Task should be immutable (State requirement)
        // Can't modify categoryId after creation
        let newCat = Category(name: "Personal", color: "#00FF00")
        let updatedTask = TaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            categoryId: newCat.id, // Changed category
            isCompleted: task.isCompleted,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        XCTAssertNotEqual(task.categoryId, updatedTask.categoryId)
        XCTAssertEqual(updatedTask.categoryId, newCat.id)
    }
    
    func testCategoryCollection() async {
        // Test managing categories in state
        // Framework insight: How to model collections of related entities?
        let categories = [
            Category(name: "Work", color: "#FF5733"),
            Category(name: "Personal", color: "#00FF00"),
            Category(name: "Shopping", color: "#0000FF")
        ]
        
        // Should be able to find category by ID
        let workCat = categories.first { $0.name == "Work" }!
        let found = categories.first { $0.id == workCat.id }
        XCTAssertEqual(found?.name, "Work")
        
        // Should maintain uniqueness by ID
        let uniqueIds = Set(categories.map { $0.id })
        XCTAssertEqual(uniqueIds.count, categories.count)
    }
    
    func testDefaultCategories() async {
        // Test pre-defined default categories
        // Framework insight: How to handle initial data?
        let defaults = Category.defaultCategories
        
        XCTAssertFalse(defaults.isEmpty)
        XCTAssertTrue(defaults.contains { $0.name == "Personal" })
        XCTAssertTrue(defaults.contains { $0.name == "Work" })
        
        // All defaults should be valid
        for category in defaults {
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertTrue(Category.isValidColor(category.color))
        }
    }
}