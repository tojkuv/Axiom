import SwiftUI
import Combine

public protocol ContextInspectorDelegate: AnyObject {
    func inspector(_ inspector: ContextInspector, didAnalyzeContext analysis: ContextAnalysisResult)
    func inspector(_ inspector: ContextInspector, didDetectContextIssue issue: ContextIssue)
    func inspector(_ inspector: ContextInspector, didEncounterError error: Error)
}

@MainActor
public final class ContextInspector: ObservableObject {
    
    public weak var delegate: ContextInspectorDelegate?
    
    @Published public private(set) var contextRelationships: ContextGraph?
    @Published public private(set) var currentAnalysis: ContextAnalysisResult?
    @Published public private(set) var isInspecting = false
    
    private let configuration: ContextInspectorConfiguration
    private var contextRegistry: [String: ContextInfo] = [:]
    private var relationshipTracking: [String: Set<String>] = [:]
    private var stateObservations: [String: StateObservation] = [:]
    
    public init(configuration: ContextInspectorConfiguration = ContextInspectorConfiguration()) {
        self.configuration = configuration
    }
    
    public func analyzeContextRelationships() -> ContextGraph {
        var nodes: [ContextNode] = []
        var edges: [ContextEdge] = []
        
        // Build nodes from registered contexts
        for (_, context) in contextRegistry {
            let node = ContextNode(
                id: context.id,
                name: context.name,
                type: determineContextType(context),
                properties: context.properties
            )
            nodes.append(node)
        }
        
        // Build edges from relationship tracking
        for (fromId, toIds) in relationshipTracking {
            for toId in toIds {
                let relationship = determineRelationshipType(from: fromId, to: toId)
                let edge = ContextEdge(
                    from: fromId,
                    to: toId,
                    relationship: relationship
                )
                edges.append(edge)
            }
        }
        
        let graph = ContextGraph(nodes: nodes, edges: edges)
        self.contextRelationships = graph
        
        return graph
    }
    
    public func inspectContext(_ contextId: String) async throws -> ContextInspectionResult {
        isInspecting = true
        defer { isInspecting = false }
        
        guard let context = contextRegistry[contextId] else {
            let error = ContextInspectionError.contextNotFound(contextId)
            delegate?.inspector(self, didEncounterError: error)
            throw error
        }
        
        let stateSnapshot = await captureContextState(context)
        let performanceMetrics = await analyzeContextPerformance(context)
        let dependencies = analyzeDependencies(contextId)
        let memoryUsage = await analyzeContextMemoryUsage(context)
        let issues = detectContextIssues(context, stateSnapshot: stateSnapshot, performanceMetrics: performanceMetrics)
        
        let inspectionResult = ContextInspectionResult(
            context: context,
            stateSnapshot: stateSnapshot,
            performanceMetrics: performanceMetrics,
            dependencies: dependencies,
            memoryUsage: memoryUsage,
            issues: issues,
            timestamp: Date()
        )
        
        // Report issues
        for issue in issues {
            delegate?.inspector(self, didDetectContextIssue: issue)
        }
        
        return inspectionResult
    }
    
    public func performComprehensiveAnalysis() async -> ContextAnalysisResult {
        isInspecting = true
        defer { isInspecting = false }
        
        let relationships = analyzeContextRelationships()
        let architecturalIssues = await detectArchitecturalIssues()
        let performanceSummary = await generatePerformanceSummary()
        let memoryAnalysis = await analyzeOverallMemoryUsage()
        let recommendations = generateRecommendations(
            relationships: relationships,
            architecturalIssues: architecturalIssues,
            performanceSummary: performanceSummary
        )
        
        let analysisResult = ContextAnalysisResult(
            relationships: relationships,
            architecturalIssues: architecturalIssues,
            performanceSummary: performanceSummary,
            memoryAnalysis: memoryAnalysis,
            recommendations: recommendations,
            totalContexts: contextRegistry.count,
            analysisTimestamp: Date()
        )
        
        self.currentAnalysis = analysisResult
        delegate?.inspector(self, didAnalyzeContext: analysisResult)
        
        return analysisResult
    }
    
    public func registerContext(_ context: ContextInfo) {
        contextRegistry[context.id] = context
        
        // Track parent-child relationships
        if let parentId = context.parentId {
            relationshipTracking[parentId, default: Set()].insert(context.id)
        }
        
        // Initialize state observation
        stateObservations[context.id] = StateObservation(
            contextId: context.id,
            lastSnapshot: context.properties,
            changeHistory: [],
            observationStartTime: Date()
        )
    }
    
    public func updateContextState(_ contextId: String, key: String, oldValue: Any?, newValue: Any?) {
        guard var observation = stateObservations[contextId] else { return }
        
        let change = StateChange(
            key: key,
            oldValue: String(describing: oldValue),
            newValue: String(describing: newValue),
            timestamp: Date()
        )
        
        observation.changeHistory.append(change)
        
        // Update snapshot
        var snapshot = observation.lastSnapshot
        snapshot[key] = String(describing: newValue)
        observation.lastSnapshot = snapshot
        
        stateObservations[contextId] = observation
        
        // Check for state-related issues
        if observation.changeHistory.count > configuration.maxStateChangesThreshold {
            let issue = ContextIssue(
                contextId: contextId,
                type: .excessiveStateChanges,
                severity: .medium,
                description: "Context has \(observation.changeHistory.count) state changes",
                suggestedFix: "Consider reducing state mutation frequency"
            )
            delegate?.inspector(self, didDetectContextIssue: issue)
        }
    }
    
    public func trackContextDependency(from fromContextId: String, to toContextId: String, type: DependencyType) {
        relationshipTracking[fromContextId, default: Set()].insert(toContextId)
        
        // Check for circular dependencies
        if hasCircularDependency(starting: fromContextId, target: toContextId) {
            let issue = ContextIssue(
                contextId: fromContextId,
                type: .circularDependency,
                severity: .high,
                description: "Circular dependency detected between \(fromContextId) and \(toContextId)",
                suggestedFix: "Restructure context relationships to eliminate cycle"
            )
            delegate?.inspector(self, didDetectContextIssue: issue)
        }
    }
    
    public func getContextPerformanceHistory(_ contextId: String) -> [ContextPerformanceSnapshot] {
        // In a real implementation, this would return historical performance data
        return []
    }
    
    public func getContextStateHistory(_ contextId: String) -> [ContextStateSnapshot] {
        guard let observation = stateObservations[contextId] else { return [] }
        
        return observation.changeHistory.map { change in
            ContextStateSnapshot(
                contextId: contextId,
                state: [change.key: change.newValue],
                timestamp: change.timestamp,
                changeReason: "State update"
            )
        }
    }
    
    private func captureContextState(_ context: ContextInfo) async -> ContextStateSnapshot {
        return ContextStateSnapshot(
            contextId: context.id,
            state: context.properties,
            timestamp: Date(),
            changeReason: "Manual capture"
        )
    }
    
    private func analyzeContextPerformance(_ context: ContextInfo) async -> ContextPerformanceMetrics {
        // Simulate performance analysis
        let updateCount = context.performanceMetrics.updateCount
        let averageUpdateTime = context.performanceMetrics.averageUpdateTime
        let cpuUsage = Double.random(in: 1...15) // 1-15% CPU usage for context
        let memoryFootprint = Int64.random(in: 10000...100000) // 10KB-100KB
        
        return ContextPerformanceMetrics(
            updateCount: updateCount,
            averageUpdateTime: averageUpdateTime,
            cpuUsage: cpuUsage,
            memoryFootprint: memoryFootprint,
            lastUpdateTime: Date()
        )
    }
    
    private func analyzeDependencies(_ contextId: String) -> ContextDependencyAnalysis {
        let directDependencies = relationshipTracking[contextId] ?? Set()
        let dependents = relationshipTracking.compactMap { (key, value) in
            value.contains(contextId) ? key : nil
        }
        
        let dependencyDepth = calculateDependencyDepth(contextId)
        let dependencyComplexity = calculateDependencyComplexity(contextId)
        
        return ContextDependencyAnalysis(
            directDependencies: Array(directDependencies),
            dependents: dependents,
            dependencyDepth: dependencyDepth,
            dependencyComplexity: dependencyComplexity,
            hasCycles: hasCircularDependency(starting: contextId, target: contextId)
        )
    }
    
    private func analyzeContextMemoryUsage(_ context: ContextInfo) async -> ContextMemoryUsage {
        // Simulate memory analysis
        let totalMemory = Int64.random(in: 50000...500000) // 50KB-500KB
        let stateMemory = Int64.random(in: 1000...50000) // 1KB-50KB
        let observerMemory = Int64.random(in: 500...10000) // 500B-10KB
        let cacheMemory = Int64.random(in: 0...100000) // 0-100KB
        
        return ContextMemoryUsage(
            totalMemory: totalMemory,
            stateMemory: stateMemory,
            observerMemory: observerMemory,
            cacheMemory: cacheMemory,
            leakSuspicion: totalMemory > 300000 // Flag if over 300KB
        )
    }
    
    private func detectContextIssues(
        _ context: ContextInfo,
        stateSnapshot: ContextStateSnapshot,
        performanceMetrics: ContextPerformanceMetrics
    ) -> [ContextIssue] {
        var issues: [ContextIssue] = []
        
        // Performance issues
        if performanceMetrics.averageUpdateTime > 50 { // 50ms threshold
            issues.append(ContextIssue(
                contextId: context.id,
                type: .slowUpdates,
                severity: .medium,
                description: "Context updates are slow (\(String(format: "%.2f", performanceMetrics.averageUpdateTime))ms average)",
                suggestedFix: "Optimize context update logic"
            ))
        }
        
        // Memory issues
        if performanceMetrics.memoryFootprint > 200000 { // 200KB threshold
            issues.append(ContextIssue(
                contextId: context.id,
                type: .highMemoryUsage,
                severity: .medium,
                description: "High memory usage: \(performanceMetrics.memoryFootprint) bytes",
                suggestedFix: "Review memory allocations and potential leaks"
            ))
        }
        
        // State complexity issues
        if stateSnapshot.state.count > 20 {
            issues.append(ContextIssue(
                contextId: context.id,
                type: .complexState,
                severity: .low,
                description: "Context has too many state properties (\(stateSnapshot.state.count))",
                suggestedFix: "Consider breaking context into smaller, focused contexts"
            ))
        }
        
        // Dependency issues
        let dependencies = analyzeDependencies(context.id)
        if dependencies.dependencyDepth > 5 {
            issues.append(ContextIssue(
                contextId: context.id,
                type: .deepDependency,
                severity: .medium,
                description: "Context has deep dependency chain (depth: \(dependencies.dependencyDepth))",
                suggestedFix: "Flatten dependency hierarchy"
            ))
        }
        
        return issues
    }
    
    private func detectArchitecturalIssues() async -> [ArchitecturalIssue] {
        var issues: [ArchitecturalIssue] = []
        
        // Check for orphaned contexts
        let orphanedContexts = contextRegistry.values.filter { context in
            if let parentId = context.parentId {
                return !contextRegistry.keys.contains(parentId)
            }
            return false
        }
        
        for orphaned in orphanedContexts {
            issues.append(ArchitecturalIssue(
                type: .orphanedContext,
                affectedContexts: [orphaned.id],
                severity: .high,
                description: "Context '\(orphaned.name)' references non-existent parent",
                recommendation: "Ensure parent context exists or restructure hierarchy"
            ))
        }
        
        // Check for too many root contexts
        let rootContexts = contextRegistry.values.filter { $0.parentId == nil }
        if rootContexts.count > 3 {
            issues.append(ArchitecturalIssue(
                type: .tooManyRoots,
                affectedContexts: rootContexts.map { $0.id },
                severity: .medium,
                description: "Too many root contexts (\(rootContexts.count))",
                recommendation: "Consider consolidating under a single root context"
            ))
        }
        
        // Check for circular dependencies
        for contextId in contextRegistry.keys {
            if hasCircularDependency(starting: contextId, target: contextId) {
                issues.append(ArchitecturalIssue(
                    type: .circularDependency,
                    affectedContexts: [contextId],
                    severity: .high,
                    description: "Circular dependency involving context '\(contextId)'",
                    recommendation: "Restructure dependencies to eliminate cycles"
                ))
            }
        }
        
        return issues
    }
    
    private func generatePerformanceSummary() async -> ContextPerformanceSummary {
        let allContexts = Array(contextRegistry.values)
        
        let totalUpdates = allContexts.map { $0.performanceMetrics.updateCount }.reduce(0, +)
        let averageUpdateTime = allContexts.map { $0.performanceMetrics.averageUpdateTime }.reduce(0, +) / Double(allContexts.count)
        let slowestContext = allContexts.max { $0.performanceMetrics.averageUpdateTime < $1.performanceMetrics.averageUpdateTime }
        let mostActiveContext = allContexts.max { $0.performanceMetrics.updateCount < $1.performanceMetrics.updateCount }
        
        return ContextPerformanceSummary(
            totalContexts: allContexts.count,
            totalUpdates: totalUpdates,
            averageUpdateTime: averageUpdateTime,
            slowestContextId: slowestContext?.id,
            mostActiveContextId: mostActiveContext?.id,
            performanceScore: calculateOverallPerformanceScore(allContexts)
        )
    }
    
    private func analyzeOverallMemoryUsage() async -> ContextMemoryAnalysis {
        let totalMemory = contextRegistry.values.reduce(Int64(0)) { total, context in
            // Simulate memory calculation
            return total + Int64.random(in: 10000...100000)
        }
        
        let averageMemoryPerContext = totalMemory / Int64(max(1, contextRegistry.count))
        let memoryDistribution = contextRegistry.mapValues { _ in Int64.random(in: 10000...100000) }
        
        return ContextMemoryAnalysis(
            totalMemoryUsage: totalMemory,
            averageMemoryPerContext: averageMemoryPerContext,
            memoryDistribution: memoryDistribution,
            potentialLeaks: memoryDistribution.filter { $0.value > 200000 }.map { $0.key }
        )
    }
    
    private func generateRecommendations(
        relationships: ContextGraph,
        architecturalIssues: [ArchitecturalIssue],
        performanceSummary: ContextPerformanceSummary
    ) -> [ContextRecommendation] {
        var recommendations: [ContextRecommendation] = []
        
        // Architecture recommendations
        if !architecturalIssues.isEmpty {
            let highSeverityIssues = architecturalIssues.filter { $0.severity == .high }
            if !highSeverityIssues.isEmpty {
                recommendations.append(ContextRecommendation(
                    type: .architecture,
                    priority: .high,
                    description: "Address critical architectural issues",
                    actionItems: highSeverityIssues.map { $0.recommendation }
                ))
            }
        }
        
        // Performance recommendations
        if performanceSummary.performanceScore < 70 {
            recommendations.append(ContextRecommendation(
                type: .performance,
                priority: .high,
                description: "Improve context performance",
                actionItems: [
                    "Optimize slow contexts",
                    "Reduce state complexity",
                    "Consider context splitting"
                ]
            ))
        }
        
        // Complexity recommendations
        if relationships.nodes.count > 15 {
            recommendations.append(ContextRecommendation(
                type: .complexity,
                priority: .medium,
                description: "Reduce context complexity",
                actionItems: [
                    "Consider consolidating similar contexts",
                    "Simplify dependency relationships",
                    "Break down large contexts"
                ]
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func determineContextType(_ context: ContextInfo) -> ContextType {
        if context.parentId == nil {
            return .root
        } else if relationshipTracking[context.id]?.isEmpty ?? true {
            return .leaf
        } else {
            return .child
        }
    }
    
    private func determineRelationshipType(from: String, to: String) -> RelationshipType {
        // In a real implementation, this would analyze the actual relationship
        return .parentChild
    }
    
    private func hasCircularDependency(starting: String, target: String, visited: Set<String> = Set()) -> Bool {
        if visited.contains(starting) && starting == target {
            return true
        }
        
        var newVisited = visited
        newVisited.insert(starting)
        
        let dependencies = relationshipTracking[starting] ?? Set()
        for dependency in dependencies {
            if hasCircularDependency(starting: dependency, target: target, visited: newVisited) {
                return true
            }
        }
        
        return false
    }
    
    private func calculateDependencyDepth(_ contextId: String, depth: Int = 0) -> Int {
        let dependencies = relationshipTracking[contextId] ?? Set()
        if dependencies.isEmpty {
            return depth
        }
        
        return dependencies.map { calculateDependencyDepth($0, depth: depth + 1) }.max() ?? depth
    }
    
    private func calculateDependencyComplexity(_ contextId: String) -> Double {
        let dependencies = relationshipTracking[contextId] ?? Set()
        let dependents = relationshipTracking.filter { $0.value.contains(contextId) }.count
        
        return Double(dependencies.count + dependents) / 2.0
    }
    
    private func calculateOverallPerformanceScore(_ contexts: [ContextInfo]) -> Double {
        guard !contexts.isEmpty else { return 100.0 }
        
        let averageUpdateTime = contexts.map { $0.performanceMetrics.averageUpdateTime }.reduce(0, +) / Double(contexts.count)
        let score = max(0, 100 - (averageUpdateTime - 10) * 2) // Penalty after 10ms
        
        return score
    }
}

// MARK: - Supporting Types

public struct ContextInspectorConfiguration {
    public var enableRealTimeTracking: Bool = true
    public var maxStateChangesThreshold: Int = 100
    public var performanceAnalysisInterval: TimeInterval = 30.0
    public var memoryAnalysisEnabled: Bool = true
    
    public init() {}
}

public enum ContextInspectionError: Error, LocalizedError {
    case contextNotFound(String)
    case inspectionTimeout
    case analysisFailure
    
    public var errorDescription: String? {
        switch self {
        case .contextNotFound(let id):
            return "Context not found: \(id)"
        case .inspectionTimeout:
            return "Context inspection timed out"
        case .analysisFailure:
            return "Context analysis failed"
        }
    }
}

// MARK: - Data Models

public struct ContextInspectionResult: Codable {
    public let context: ContextInfo
    public let stateSnapshot: ContextStateSnapshot
    public let performanceMetrics: ContextPerformanceMetrics
    public let dependencies: ContextDependencyAnalysis
    public let memoryUsage: ContextMemoryUsage
    public let issues: [ContextIssue]
    public let timestamp: Date
    
    public init(context: ContextInfo, stateSnapshot: ContextStateSnapshot, performanceMetrics: ContextPerformanceMetrics, dependencies: ContextDependencyAnalysis, memoryUsage: ContextMemoryUsage, issues: [ContextIssue], timestamp: Date) {
        self.context = context
        self.stateSnapshot = stateSnapshot
        self.performanceMetrics = performanceMetrics
        self.dependencies = dependencies
        self.memoryUsage = memoryUsage
        self.issues = issues
        self.timestamp = timestamp
    }
}

public struct ContextAnalysisResult: Codable {
    public let relationships: ContextGraph
    public let architecturalIssues: [ArchitecturalIssue]
    public let performanceSummary: ContextPerformanceSummary
    public let memoryAnalysis: ContextMemoryAnalysis
    public let recommendations: [ContextRecommendation]
    public let totalContexts: Int
    public let analysisTimestamp: Date
    
    public init(relationships: ContextGraph, architecturalIssues: [ArchitecturalIssue], performanceSummary: ContextPerformanceSummary, memoryAnalysis: ContextMemoryAnalysis, recommendations: [ContextRecommendation], totalContexts: Int, analysisTimestamp: Date) {
        self.relationships = relationships
        self.architecturalIssues = architecturalIssues
        self.performanceSummary = performanceSummary
        self.memoryAnalysis = memoryAnalysis
        self.recommendations = recommendations
        self.totalContexts = totalContexts
        self.analysisTimestamp = analysisTimestamp
    }
}

public struct StateObservation {
    public let contextId: String
    public var lastSnapshot: [String: String]
    public var changeHistory: [StateChange]
    public let observationStartTime: Date
    
    public init(contextId: String, lastSnapshot: [String: String], changeHistory: [StateChange], observationStartTime: Date) {
        self.contextId = contextId
        self.lastSnapshot = lastSnapshot
        self.changeHistory = changeHistory
        self.observationStartTime = observationStartTime
    }
}

public struct StateChange {
    public let key: String
    public let oldValue: String
    public let newValue: String
    public let timestamp: Date
    
    public init(key: String, oldValue: String, newValue: String, timestamp: Date) {
        self.key = key
        self.oldValue = oldValue
        self.newValue = newValue
        self.timestamp = timestamp
    }
}

public struct ContextStateSnapshot: Codable {
    public let contextId: String
    public let state: [String: String]
    public let timestamp: Date
    public let changeReason: String
    
    public init(contextId: String, state: [String: String], timestamp: Date, changeReason: String) {
        self.contextId = contextId
        self.state = state
        self.timestamp = timestamp
        self.changeReason = changeReason
    }
}


public struct ContextDependencyAnalysis: Codable {
    public let directDependencies: [String]
    public let dependents: [String]
    public let dependencyDepth: Int
    public let dependencyComplexity: Double
    public let hasCycles: Bool
    
    public init(directDependencies: [String], dependents: [String], dependencyDepth: Int, dependencyComplexity: Double, hasCycles: Bool) {
        self.directDependencies = directDependencies
        self.dependents = dependents
        self.dependencyDepth = dependencyDepth
        self.dependencyComplexity = dependencyComplexity
        self.hasCycles = hasCycles
    }
}

public struct ContextMemoryUsage: Codable {
    public let totalMemory: Int64
    public let stateMemory: Int64
    public let observerMemory: Int64
    public let cacheMemory: Int64
    public let leakSuspicion: Bool
    
    public init(totalMemory: Int64, stateMemory: Int64, observerMemory: Int64, cacheMemory: Int64, leakSuspicion: Bool) {
        self.totalMemory = totalMemory
        self.stateMemory = stateMemory
        self.observerMemory = observerMemory
        self.cacheMemory = cacheMemory
        self.leakSuspicion = leakSuspicion
    }
}

public struct ContextIssue: Codable {
    public let contextId: String
    public let type: ContextIssueType
    public let severity: Severity
    public let description: String
    public let suggestedFix: String
    
    public init(contextId: String, type: ContextIssueType, severity: Severity, description: String, suggestedFix: String) {
        self.contextId = contextId
        self.type = type
        self.severity = severity
        self.description = description
        self.suggestedFix = suggestedFix
    }
}

public enum ContextIssueType: String, Codable {
    case slowUpdates
    case highMemoryUsage
    case complexState
    case deepDependency
    case circularDependency
    case excessiveStateChanges
    case orphanedContext
}

public struct ArchitecturalIssue: Codable {
    public let type: ArchitecturalIssueType
    public let affectedContexts: [String]
    public let severity: Severity
    public let description: String
    public let recommendation: String
    
    public init(type: ArchitecturalIssueType, affectedContexts: [String], severity: Severity, description: String, recommendation: String) {
        self.type = type
        self.affectedContexts = affectedContexts
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }
}

public enum ArchitecturalIssueType: String, Codable {
    case orphanedContext
    case circularDependency
    case tooManyRoots
    case deepHierarchy
    case complexDependencies
}

public struct ContextPerformanceSummary: Codable {
    public let totalContexts: Int
    public let totalUpdates: Int
    public let averageUpdateTime: Double
    public let slowestContextId: String?
    public let mostActiveContextId: String?
    public let performanceScore: Double
    
    public init(totalContexts: Int, totalUpdates: Int, averageUpdateTime: Double, slowestContextId: String?, mostActiveContextId: String?, performanceScore: Double) {
        self.totalContexts = totalContexts
        self.totalUpdates = totalUpdates
        self.averageUpdateTime = averageUpdateTime
        self.slowestContextId = slowestContextId
        self.mostActiveContextId = mostActiveContextId
        self.performanceScore = performanceScore
    }
}

public struct ContextMemoryAnalysis: Codable {
    public let totalMemoryUsage: Int64
    public let averageMemoryPerContext: Int64
    public let memoryDistribution: [String: Int64]
    public let potentialLeaks: [String]
    
    public init(totalMemoryUsage: Int64, averageMemoryPerContext: Int64, memoryDistribution: [String: Int64], potentialLeaks: [String]) {
        self.totalMemoryUsage = totalMemoryUsage
        self.averageMemoryPerContext = averageMemoryPerContext
        self.memoryDistribution = memoryDistribution
        self.potentialLeaks = potentialLeaks
    }
}

public struct ContextRecommendation: Codable {
    public let type: ContextRecommendationType
    public let priority: Priority
    public let description: String
    public let actionItems: [String]
    
    public init(type: ContextRecommendationType, priority: Priority, description: String, actionItems: [String]) {
        self.type = type
        self.priority = priority
        self.description = description
        self.actionItems = actionItems
    }
}

public enum ContextRecommendationType: String, Codable {
    case architecture
    case performance
    case memory
    case complexity
    case dependencies
}

public struct ContextPerformanceSnapshot: Codable {
    public let contextId: String
    public let timestamp: Date
    public let metrics: ContextPerformanceMetrics
    
    public init(contextId: String, timestamp: Date, metrics: ContextPerformanceMetrics) {
        self.contextId = contextId
        self.timestamp = timestamp
        self.metrics = metrics
    }
}

public enum DependencyType: String, Codable {
    case parentChild
    case communication
    case stateSharing
    case eventBased
    case service
}