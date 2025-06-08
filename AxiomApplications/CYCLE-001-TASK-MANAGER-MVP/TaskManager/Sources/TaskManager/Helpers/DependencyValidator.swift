import Foundation

// MARK: - REQ-010 REFACTOR: Dependency Validation

/// Utilities for validating task dependencies and detecting circular references
enum DependencyValidator {
    
    // MARK: - Circular Dependency Detection
    
    /// Check if adding a dependency would create a circular reference
    /// - Parameters:
    ///   - prerequisiteId: Task that must be completed first
    ///   - dependentId: Task that depends on the prerequisite
    ///   - allTasks: All tasks in the system
    /// - Returns: Array of task IDs involved in the cycle, or nil if no cycle
    static func detectCircularDependency(
        adding prerequisiteId: UUID,
        to dependentId: UUID,
        in allTasks: [TaskItem]
    ) -> [UUID]? {
        // Check if prerequisiteId has a path to dependentId through its dependencies
        // If so, adding dependentId -> prerequisiteId would create a cycle
        
        func hasPathTo(from: UUID, to: UUID, visited: inout Set<UUID>) -> Bool {
            if from == to {
                return true
            }
            
            if visited.contains(from) {
                return false
            }
            
            visited.insert(from)
            
            // Get current dependencies for the task
            guard let task = TreeUtilities.findTask(id: from, in: allTasks) else {
                return false
            }
            
            // Check if any dependency has a path to the target
            for depId in task.dependencies {
                if hasPathTo(from: depId, to: to, visited: &visited) {
                    return true
                }
            }
            
            return false
        }
        
        var visited = Set<UUID>()
        
        // If prerequisiteId already has a path to dependentId, 
        // then adding dependentId -> prerequisiteId would create a cycle
        if hasPathTo(from: prerequisiteId, to: dependentId, visited: &visited) {
            // Return the cycle - collect all involved tasks
            return [dependentId, prerequisiteId] + Array(visited)
        }
        
        return nil
    }
    
    // MARK: - Dependency Validation
    
    /// Validate that all dependencies of a task are complete before allowing completion
    /// - Parameters:
    ///   - taskId: Task to validate
    ///   - allTasks: All tasks in the system
    /// - Returns: Array of incomplete prerequisite IDs, empty if all complete
    static func validatePrerequisites(for taskId: UUID, in allTasks: [TaskItem]) -> [UUID] {
        guard let task = TreeUtilities.findTask(id: taskId, in: allTasks) else {
            return []
        }
        
        return task.dependencies.filter { depId in
            guard let depTask = TreeUtilities.findTask(id: depId, in: allTasks) else {
                return true // Missing dependency is considered incomplete
            }
            return !depTask.isCompleted
        }
    }
    
    // MARK: - Dependency Graph Analysis
    
    /// Analyze the dependency graph for performance and complexity insights
    static func analyzeDependencyGraph(_ tasks: [TaskItem]) -> DependencyGraphAnalysis {
        let flatTasks = TreeUtilities.flattenTree(tasks)
        
        // Count dependencies
        let totalDependencies = flatTasks.reduce(0) { $0 + $1.dependencies.count }
        
        // Find tasks with most dependencies
        let maxDependencies = flatTasks.map { $0.dependencies.count }.max() ?? 0
        
        // Calculate dependency depth (longest chain)
        let maxDependencyChain = calculateMaxDependencyChain(in: flatTasks)
        
        // Find potential bottlenecks (tasks that many others depend on)
        let dependencyCounts = Dictionary(grouping: flatTasks.flatMap { $0.dependencies }) { $0 }
            .mapValues { $0.count }
        let maxDependents = dependencyCounts.values.max() ?? 0
        
        return DependencyGraphAnalysis(
            totalTasks: flatTasks.count,
            totalDependencies: totalDependencies,
            maxDependenciesPerTask: maxDependencies,
            maxDependencyChainLength: maxDependencyChain,
            maxDependentsPerTask: maxDependents,
            averageDependenciesPerTask: flatTasks.isEmpty ? 0.0 : Double(totalDependencies) / Double(flatTasks.count)
        )
    }
    
    private static func calculateMaxDependencyChain(in tasks: [TaskItem]) -> Int {
        var visited = Set<UUID>()
        var maxChain = 0
        
        func dfs(taskId: UUID, currentDepth: Int) -> Int {
            if visited.contains(taskId) {
                return currentDepth
            }
            
            visited.insert(taskId)
            
            guard let task = tasks.first(where: { $0.id == taskId }) else {
                return currentDepth
            }
            
            var maxFromHere = currentDepth
            for depId in task.dependencies {
                let chainLength = dfs(taskId: depId, currentDepth: currentDepth + 1)
                maxFromHere = max(maxFromHere, chainLength)
            }
            
            return maxFromHere
        }
        
        for task in tasks {
            let chainLength = dfs(taskId: task.id, currentDepth: 0)
            maxChain = max(maxChain, chainLength)
            visited.removeAll()
        }
        
        return maxChain
    }
    
    // MARK: - Performance Optimization Suggestions
    
    /// Get suggestions for optimizing dependency performance
    static func getOptimizationSuggestions(for analysis: DependencyGraphAnalysis) -> [String] {
        var suggestions: [String] = []
        
        if analysis.maxDependencyChainLength > 20 {
            suggestions.append("Consider breaking down long dependency chains (current: \(analysis.maxDependencyChainLength))")
        }
        
        if analysis.maxDependenciesPerTask > 10 {
            suggestions.append("Tasks with many dependencies (\(analysis.maxDependenciesPerTask)) may benefit from grouping")
        }
        
        if analysis.maxDependentsPerTask > 50 {
            suggestions.append("Bottleneck detected: \(analysis.maxDependentsPerTask) tasks depend on a single task")
        }
        
        if analysis.totalDependencies > analysis.totalTasks * 2 {
            suggestions.append("High dependency ratio may impact performance")
        }
        
        return suggestions
    }
}

// MARK: - Dependency Graph Analysis

struct DependencyGraphAnalysis {
    let totalTasks: Int
    let totalDependencies: Int
    let maxDependenciesPerTask: Int
    let maxDependencyChainLength: Int
    let maxDependentsPerTask: Int
    let averageDependenciesPerTask: Double
    
    /// Performance complexity assessment
    var complexityLevel: DependencyComplexity {
        let ratio = Double(totalDependencies) / Double(max(totalTasks, 1))
        
        if maxDependencyChainLength > 50 || maxDependentsPerTask > 100 || ratio > 5.0 {
            return .high
        } else if maxDependencyChainLength > 20 || maxDependentsPerTask > 50 || ratio > 2.0 {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Estimated validation time for circular dependency check
    var estimatedValidationTime: TimeInterval {
        // Rough estimate based on graph complexity
        let baseTime = 0.001 // 1ms base
        let complexityFactor = Double(totalDependencies) / 1000.0
        return baseTime * (1.0 + complexityFactor)
    }
}

enum DependencyComplexity {
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .low:
            return "Low complexity - optimal performance"
        case .medium:
            return "Medium complexity - monitor performance"
        case .high:
            return "High complexity - may impact performance"
        }
    }
    
    var maxRecommendedValidationTime: TimeInterval {
        switch self {
        case .low:
            return 0.001 // 1ms
        case .medium:
            return 0.005 // 5ms
        case .high:
            return 0.010 // 10ms
        }
    }
}