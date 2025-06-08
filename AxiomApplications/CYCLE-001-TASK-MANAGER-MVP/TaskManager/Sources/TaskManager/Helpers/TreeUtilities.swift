import Foundation

// MARK: - REQ-010 REFACTOR: Tree Utilities

/// Utilities for working with hierarchical task structures
enum TreeUtilities {
    
    // MARK: - Search Operations
    
    /// Find a task by ID in a tree structure
    static func findTask(id: UUID, in tasks: [TaskItem]) -> TaskItem? {
        for task in tasks {
            if task.id == id {
                return task
            }
            if let found = findTask(id: id, in: task.subtasks) {
                return found
            }
        }
        return nil
    }
    
    /// Find a subtask with its parent information
    static func findSubtaskWithParent(id: UUID, in tasks: [TaskItem]) -> (parentId: UUID, subtask: TaskItem)? {
        for task in tasks {
            // Check direct subtasks
            if let subtask = task.subtasks.first(where: { $0.id == id }) {
                return (task.id, subtask)
            }
            
            // Recursively check nested subtasks
            if let found = findSubtaskWithParent(id: id, in: task.subtasks) {
                return found
            }
        }
        return nil
    }
    
    // MARK: - Tree Modification Operations
    
    /// Remove a subtask recursively from tree
    static func removeSubtaskRecursively(id: UUID, from subtasks: [TaskItem]) -> [TaskItem] {
        return subtasks.compactMap { subtask in
            if subtask.id == id {
                return nil // Remove this subtask
            }
            
            // Recursively process nested subtasks
            let updatedSubtasks = removeSubtaskRecursively(id: id, from: subtask.subtasks)
            
            return TaskItem(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                categoryId: subtask.categoryId,
                priority: subtask.priority,
                isCompleted: subtask.isCompleted,
                createdAt: subtask.createdAt,
                updatedAt: subtask.updatedAt,
                dueDate: subtask.dueDate,
                parentId: subtask.parentId,
                subtasks: updatedSubtasks,
                dependencies: subtask.dependencies
            )
        }
    }
    
    /// Update a subtask recursively in tree
    static func updateSubtaskRecursively(
        id: UUID,
        in subtasks: [TaskItem],
        update: (TaskItem) -> TaskItem
    ) -> [TaskItem] {
        return subtasks.map { subtask in
            if subtask.id == id {
                return update(subtask)
            }
            
            // Recursively process nested subtasks
            let updatedSubtasks = updateSubtaskRecursively(id: id, in: subtask.subtasks, update: update)
            
            return TaskItem(
                id: subtask.id,
                title: subtask.title,
                description: subtask.description,
                categoryId: subtask.categoryId,
                priority: subtask.priority,
                isCompleted: subtask.isCompleted,
                createdAt: subtask.createdAt,
                updatedAt: subtask.updatedAt,
                dueDate: subtask.dueDate,
                parentId: subtask.parentId,
                subtasks: updatedSubtasks,
                dependencies: subtask.dependencies
            )
        }
    }
    
    // MARK: - Tree Analysis
    
    /// Get all tasks in a tree flattened to an array
    static func flattenTree(_ tasks: [TaskItem]) -> [TaskItem] {
        var result: [TaskItem] = []
        
        func collectTasks(_ tasks: [TaskItem]) {
            for task in tasks {
                result.append(task)
                collectTasks(task.subtasks)
            }
        }
        
        collectTasks(tasks)
        return result
    }
    
    /// Calculate maximum depth of a tree
    static func calculateMaxDepth(_ tasks: [TaskItem]) -> Int {
        guard !tasks.isEmpty else { return 0 }
        
        var maxDepth = 1
        for task in tasks {
            let subtaskDepth = calculateMaxDepth(task.subtasks)
            maxDepth = max(maxDepth, 1 + subtaskDepth)
        }
        
        return maxDepth
    }
    
    /// Count total number of tasks in tree
    static func countTotalTasks(_ tasks: [TaskItem]) -> Int {
        var count = tasks.count
        for task in tasks {
            count += countTotalTasks(task.subtasks)
        }
        return count
    }
    
    // MARK: - Performance Analysis
    
    /// Analyze tree complexity for performance implications
    static func analyzeTreeComplexity(_ tasks: [TaskItem]) -> TreeComplexity {
        let flattened = flattenTree(tasks)
        let totalTasks = flattened.count
        let maxDepth = calculateMaxDepth(tasks)
        
        // Calculate branching factor (average children per parent)
        let parentsWithChildren = flattened.filter { !$0.subtasks.isEmpty }
        let totalChildren = parentsWithChildren.reduce(0) { $0 + $1.subtasks.count }
        let avgBranchingFactor = parentsWithChildren.isEmpty ? 0.0 : Double(totalChildren) / Double(parentsWithChildren.count)
        
        return TreeComplexity(
            totalTasks: totalTasks,
            maxDepth: maxDepth,
            averageBranchingFactor: avgBranchingFactor
        )
    }
}

// MARK: - Tree Complexity Analysis

struct TreeComplexity {
    let totalTasks: Int
    let maxDepth: Int
    let averageBranchingFactor: Double
    
    /// Performance warning levels based on complexity
    var performanceLevel: PerformanceLevel {
        if totalTasks > 10000 || maxDepth > 100 {
            return .critical
        } else if totalTasks > 1000 || maxDepth > 50 {
            return .warning
        } else if totalTasks > 100 || maxDepth > 20 {
            return .attention
        } else {
            return .optimal
        }
    }
    
    /// Estimated operation complexity (Big O notation)
    var searchComplexity: String {
        // Tree search is O(n) in worst case for unbalanced trees
        return "O(\(totalTasks))"
    }
    
    var updateComplexity: String {
        // Update requires search + modification
        return "O(\(totalTasks))"
    }
}

enum PerformanceLevel {
    case optimal    // Green light
    case attention  // Monitor performance
    case warning    // May cause slowdowns
    case critical   // Likely performance issues
    
    var description: String {
        switch self {
        case .optimal:
            return "Optimal performance expected"
        case .attention:
            return "Monitor performance with this complexity"
        case .warning:
            return "May experience slowdowns"
        case .critical:
            return "High risk of performance issues"
        }
    }
}