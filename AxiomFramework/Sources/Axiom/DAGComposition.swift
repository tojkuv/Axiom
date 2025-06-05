import Foundation

// MARK: - Graph Types

/// Component graph type for DAG validation
public enum ComponentGraphType: String, CaseIterable {
    case capability
    case context
}

// MARK: - DAG Validator

/// Validates that component dependencies form Directed Acyclic Graphs (DAGs).
/// 
/// This validator ensures that both Capabilities and Contexts can have
/// dependencies on other components of the same type, but these dependencies
/// must not form cycles.
/// 
/// ## Performance Optimization
/// The validator caches validation results and topological sorts to avoid
/// redundant computations. Cache is invalidated when new dependencies are added.
public final class DAGValidator {
    // Adjacency lists for both graph types
    private var capabilityGraph: [String: Set<String>] = [:]
    private var contextGraph: [String: Set<String>] = [:]
    
    // Cached results for performance
    private var cachedValidation: DAGValidation?
    private var cachedTopologicalSort: [String]?
    private var cachedCapabilitySort: [String]?
    private var cachedContextSort: [String]?
    
    // Statistics for monitoring
    public private(set) var statistics = ValidationStatistics()
    
    public init() {}
    
    /// Adds a dependency between components.
    /// 
    /// - Parameters:
    ///   - from: The component that depends on another
    ///   - to: The component being depended upon
    ///   - type: The type of component graph
    public func addDependency(from: String, to: String, type: ComponentGraphType) {
        // Invalidate caches when graph changes
        invalidateCaches()
        
        switch type {
        case .capability:
            capabilityGraph[from, default: []].insert(to)
            // Ensure 'to' node exists
            if capabilityGraph[to] == nil {
                capabilityGraph[to] = []
            }
        case .context:
            contextGraph[from, default: []].insert(to)
            // Ensure 'to' node exists
            if contextGraph[to] == nil {
                contextGraph[to] = []
            }
        }
        
        statistics.dependencyCount += 1
    }
    
    /// Validates that all graphs are acyclic.
    /// 
    /// - Returns: Validation result with any detected cycles
    public func validate() -> DAGValidation {
        statistics.validationCount += 1
        
        // Return cached result if available
        if let cached = cachedValidation {
            statistics.cacheHits += 1
            return cached
        }
        
        var allCycles: [Cycle] = []
        
        // Check for self-dependencies first
        for (node, dependencies) in capabilityGraph {
            if dependencies.contains(node) {
                let result = DAGValidation(
                    isValid: false,
                    cycles: [Cycle(nodes: [node], type: .capability)],
                    errorMessage: "Self-dependency detected: \(node) depends on itself"
                )
                cachedValidation = result
                return result
            }
        }
        
        for (node, dependencies) in contextGraph {
            if dependencies.contains(node) {
                let result = DAGValidation(
                    isValid: false,
                    cycles: [Cycle(nodes: [node], type: .context)],
                    errorMessage: "Self-dependency detected: \(node) depends on itself"
                )
                cachedValidation = result
                return result
            }
        }
        
        // Validate capability graph
        let capabilityCycles = detectCycles(in: capabilityGraph, type: .capability)
        allCycles.append(contentsOf: capabilityCycles)
        
        // Validate context graph
        let contextCycles = detectCycles(in: contextGraph, type: .context)
        allCycles.append(contentsOf: contextCycles)
        
        let result: DAGValidation
        if allCycles.isEmpty {
            result = DAGValidation(isValid: true, cycles: [], errorMessage: nil)
        } else {
            let errorMessage = generateErrorMessage(for: allCycles)
            result = DAGValidation(isValid: false, cycles: allCycles, errorMessage: errorMessage)
        }
        
        cachedValidation = result
        return result
    }
    
    /// Performs topological sort on all graphs.
    /// 
    /// - Returns: Sorted nodes if graphs are acyclic, nil if cycles exist
    public func topologicalSort() -> [String]? {
        statistics.sortCount += 1
        
        // Return cached result if available
        if let cached = cachedTopologicalSort {
            statistics.cacheHits += 1
            return cached
        }
        
        // Combine both graphs for overall sort
        var combinedGraph: [String: Set<String>] = [:]
        
        for (node, deps) in capabilityGraph {
            combinedGraph[node, default: []].formUnion(deps)
        }
        
        for (node, deps) in contextGraph {
            combinedGraph[node, default: []].formUnion(deps)
        }
        
        let result = topologicalSort(graph: combinedGraph)
        cachedTopologicalSort = result
        return result
    }
    
    /// Performs topological sort on a specific graph type.
    /// 
    /// - Parameter type: The graph type to sort
    /// - Returns: Sorted nodes if graph is acyclic, nil if cycles exist
    public func topologicalSort(for type: ComponentGraphType) -> [String]? {
        statistics.sortCount += 1
        
        switch type {
        case .capability:
            if let cached = cachedCapabilitySort {
                statistics.cacheHits += 1
                return cached
            }
            let result = topologicalSort(graph: capabilityGraph)
            cachedCapabilitySort = result
            return result
            
        case .context:
            if let cached = cachedContextSort {
                statistics.cacheHits += 1
                return cached
            }
            let result = topologicalSort(graph: contextGraph)
            cachedContextSort = result
            return result
        }
    }
    
    // MARK: - Private Methods
    
    private func detectCycles(in graph: [String: Set<String>], type: ComponentGraphType) -> [Cycle] {
        var cycles: [Cycle] = []
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        var currentPath: [String] = []
        
        for node in graph.keys {
            if !visited.contains(node) {
                detectCyclesHelper(
                    node: node,
                    graph: graph,
                    visited: &visited,
                    recursionStack: &recursionStack,
                    currentPath: &currentPath,
                    cycles: &cycles,
                    type: type
                )
            }
        }
        
        return cycles
    }
    
    private func detectCyclesHelper(
        node: String,
        graph: [String: Set<String>],
        visited: inout Set<String>,
        recursionStack: inout Set<String>,
        currentPath: inout [String],
        cycles: inout [Cycle],
        type: ComponentGraphType
    ) {
        visited.insert(node)
        recursionStack.insert(node)
        currentPath.append(node)
        
        if let neighbors = graph[node] {
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    detectCyclesHelper(
                        node: neighbor,
                        graph: graph,
                        visited: &visited,
                        recursionStack: &recursionStack,
                        currentPath: &currentPath,
                        cycles: &cycles,
                        type: type
                    )
                } else if recursionStack.contains(neighbor) {
                    // Found a cycle
                    if let startIndex = currentPath.firstIndex(of: neighbor) {
                        let cycleNodes = Array(currentPath[startIndex...])
                        cycles.append(Cycle(nodes: cycleNodes, type: type))
                    }
                }
            }
        }
        
        recursionStack.remove(node)
        currentPath.removeLast()
    }
    
    private func topologicalSort(graph: [String: Set<String>]) -> [String]? {
        var inDegree: [String: Int] = [:]
        var queue: [String] = []
        var result: [String] = []
        
        // Initialize in-degrees
        for node in graph.keys {
            inDegree[node] = 0
        }
        
        // Calculate in-degrees
        for (_, neighbors) in graph {
            for neighbor in neighbors {
                inDegree[neighbor, default: 0] += 1
            }
        }
        
        // Find nodes with no incoming edges
        for (node, degree) in inDegree {
            if degree == 0 {
                queue.append(node)
            }
        }
        
        // Process queue
        while !queue.isEmpty {
            let node = queue.removeFirst()
            result.append(node)
            
            if let neighbors = graph[node] {
                for neighbor in neighbors {
                    inDegree[neighbor]! -= 1
                    if inDegree[neighbor]! == 0 {
                        queue.append(neighbor)
                    }
                }
            }
        }
        
        // If we processed all nodes, graph is acyclic
        // Reverse the result since test expects dependents before dependencies
        return result.count == graph.count ? Array(result.reversed()) : nil
    }
    
    private func generateErrorMessage(for cycles: [Cycle]) -> String {
        if cycles.count == 1 {
            let cycle = cycles[0]
            let typeStr = cycle.type == .capability ? "capabilities" : "contexts"
            var path = cycle.nodes.joined(separator: " -> ")
            // Add the first node again to show the complete cycle
            if cycle.nodes.count > 1 {
                path += " -> \(cycle.nodes[0])"
            }
            return "Circular dependency detected in \(typeStr): \(path)"
        } else {
            return "Multiple circular dependencies detected"
        }
    }
    
    // MARK: - Cache Management
    
    private func invalidateCaches() {
        cachedValidation = nil
        cachedTopologicalSort = nil
        cachedCapabilitySort = nil
        cachedContextSort = nil
    }
    
    /// Clears all cached results and resets statistics.
    public func reset() {
        capabilityGraph.removeAll()
        contextGraph.removeAll()
        invalidateCaches()
        statistics = ValidationStatistics()
    }
    
    // MARK: - Cycle Prevention
    
    /// Checks if adding a dependency would create a cycle.
    /// 
    /// - Parameters:
    ///   - from: The component that would depend on another
    ///   - to: The component being depended upon
    ///   - type: The type of component graph
    /// - Returns: true if adding the dependency would create a cycle
    public func wouldCreateCycle(from: String, to: String, in type: ComponentGraphType) -> Bool {
        let graph = type == .capability ? capabilityGraph : contextGraph
        
        // Check if 'to' can reach 'from' through existing dependencies
        var visited: Set<String> = []
        var queue: [String] = [to]
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            
            if current == from {
                return true // Would create a cycle
            }
            
            if visited.contains(current) {
                continue
            }
            visited.insert(current)
            
            if let neighbors = graph[current] {
                queue.append(contentsOf: neighbors)
            }
        }
        
        return false
    }
}

// MARK: - Supporting Types

/// Result of DAG validation
public struct DAGValidation {
    public let isValid: Bool
    public let cycles: [Cycle]
    public let errorMessage: String?
    
    init(isValid: Bool, cycles: [Cycle], errorMessage: String?) {
        self.isValid = isValid
        self.cycles = cycles
        self.errorMessage = errorMessage
    }
}

/// Represents a cycle in the dependency graph
public struct Cycle {
    public let nodes: [String]
    public let type: ComponentGraphType
    
    public var description: String {
        nodes.joined(separator: " -> ")
    }
}

/// Tracks validation and sorting statistics for performance monitoring
public struct ValidationStatistics {
    public var dependencyCount: Int = 0
    public var validationCount: Int = 0
    public var sortCount: Int = 0
    public var cacheHits: Int = 0
    
    public var cacheHitRate: Double {
        let totalOperations = validationCount + sortCount
        guard totalOperations > 0 else { return 0.0 }
        return Double(cacheHits) / Double(totalOperations)
    }
}