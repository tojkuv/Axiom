import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public protocol ViewHierarchyAnalyzerDelegate: AnyObject {
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didAnalyzeHierarchy analysis: ViewHierarchyAnalysis)
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didDetectPerformanceIssue issue: ViewPerformanceIssue)
    func analyzer(_ analyzer: ViewHierarchyAnalyzer, didEncounterError error: Error)
}

@MainActor
public final class ViewHierarchyAnalyzer: ObservableObject {
    
    public weak var delegate: ViewHierarchyAnalyzerDelegate?
    
    @Published public private(set) var currentHierarchy: ViewHierarchy?
    @Published public private(set) var analysisResults: ViewHierarchyAnalysis?
    @Published public private(set) var isAnalyzing = false
    
    private let configuration: ViewHierarchyAnalyzerConfiguration
    private var hierarchyCache: [String: ViewHierarchy] = [:]
    
    public init(configuration: ViewHierarchyAnalyzerConfiguration = ViewHierarchyAnalyzerConfiguration()) {
        self.configuration = configuration
    }
    
    public func analyzeCurrentHierarchy() async throws -> ViewHierarchyAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            let hierarchy = try await captureViewHierarchy()
            let analysis = await performHierarchyAnalysis(hierarchy)
            
            self.currentHierarchy = hierarchy
            self.analysisResults = analysis
            
            delegate?.analyzer(self, didAnalyzeHierarchy: analysis)
            
            // Check for performance issues
            for issue in analysis.performanceIssues {
                delegate?.analyzer(self, didDetectPerformanceIssue: issue)
            }
            
            return analysis
            
        } catch {
            delegate?.analyzer(self, didEncounterError: error)
            throw error
        }
    }
    
    public func captureViewHierarchy() async throws -> ViewHierarchy {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                #if os(iOS)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    continuation.resume(throwing: HierarchyAnalysisError.noWindowAvailable)
                    return
                }
                
                let rootNode = self.buildViewNode(from: window, depth: 0)
                let hierarchy = ViewHierarchy(
                    id: UUID().uuidString,
                    timestamp: Date(),
                    rootNode: rootNode,
                    totalNodes: self.countNodes(in: rootNode),
                    maxDepth: self.calculateMaxDepth(from: rootNode),
                    deviceInfo: DeviceInfo(
                        model: UIDevice.current.model,
                        screenSize: UIScreen.main.bounds.size,
                        orientation: self.getCurrentOrientation()
                    )
                )
                
                continuation.resume(returning: hierarchy)
                #else
                // On macOS, create a mock hierarchy since we don't have UIWindow
                let mockHierarchy = ViewHierarchy(
                    id: UUID().uuidString,
                    timestamp: Date(),
                    rootNode: ViewNode(
                        id: "mock-root",
                        viewType: "NSWindow",
                        depth: 0,
                        frame: CGRect(x: 0, y: 0, width: 800, height: 600),
                        properties: [:],
                        children: [],
                        performanceMetrics: ViewPerformanceMetrics(
                            renderTime: 1.0,
                            layoutTime: 0.5,
                            memoryUsage: 1024,
                            constraintCount: 0
                        ),
                        isSwiftUI: false
                    ),
                    totalNodes: 1,
                    maxDepth: 1,
                    deviceInfo: DeviceInfo(
                        model: "Mac",
                        screenSize: CGSize(width: 800, height: 600),
                        orientation: .portrait
                    )
                )
                continuation.resume(returning: mockHierarchy)
                #endif
            }
        }
    }
    
    public func compareHierarchies(_ hierarchy1: ViewHierarchy, _ hierarchy2: ViewHierarchy) -> HierarchyComparisonResult {
        let structuralChanges = findStructuralChanges(from: hierarchy1.rootNode, to: hierarchy2.rootNode)
        let performanceChanges = comparePerformanceMetrics(hierarchy1, hierarchy2)
        let complexityChanges = HierarchyComplexityComparison(
            nodeCountChange: hierarchy2.totalNodes - hierarchy1.totalNodes,
            depthChange: hierarchy2.maxDepth - hierarchy1.maxDepth,
            complexityTrend: calculateComplexityTrend(hierarchy1, hierarchy2)
        )
        
        return HierarchyComparisonResult(
            hierarchy1: hierarchy1,
            hierarchy2: hierarchy2,
            structuralChanges: structuralChanges,
            performanceChanges: performanceChanges,
            complexityChanges: complexityChanges,
            analysisTimestamp: Date()
        )
    }
    
    public func findViewsByType(_ viewType: String) -> [ViewNode] {
        guard let hierarchy = currentHierarchy else { return [] }
        
        var foundNodes: [ViewNode] = []
        findViewsByType(viewType, in: hierarchy.rootNode, results: &foundNodes)
        return foundNodes
    }
    
    public func findViewsByProperty(key: String, value: String) -> [ViewNode] {
        guard let hierarchy = currentHierarchy else { return [] }
        
        var foundNodes: [ViewNode] = []
        findViewsByProperty(key: key, value: value, in: hierarchy.rootNode, results: &foundNodes)
        return foundNodes
    }
    
    public func getViewPath(to viewId: String) -> [ViewNode]? {
        guard let hierarchy = currentHierarchy else { return nil }
        
        var path: [ViewNode] = []
        if findViewPath(to: viewId, in: hierarchy.rootNode, path: &path) {
            return path
        }
        return nil
    }
    
    #if os(iOS)
    private func buildViewNode(from view: UIView, depth: Int) -> ViewNode {
        let viewType = String(describing: type(of: view))
        let frame = view.frame
        let isHidden = view.isHidden
        let alpha = view.alpha
        
        var properties: [String: String] = [:]
        properties["isHidden"] = String(isHidden)
        properties["alpha"] = String(format: "%.2f", alpha)
        properties["backgroundColor"] = view.backgroundColor?.description ?? "nil"
        properties["frame"] = "(\(frame.origin.x), \(frame.origin.y), \(frame.size.width), \(frame.size.height))"
        
        // Add specific properties based on view type
        if let label = view as? UILabel {
            properties["text"] = label.text ?? ""
            properties["font"] = label.font.description
        } else if let button = view as? UIButton {
            properties["title"] = button.currentTitle ?? ""
            properties["isEnabled"] = String(button.isEnabled)
        } else if let textField = view as? UITextField {
            properties["text"] = textField.text ?? ""
            properties["placeholder"] = textField.placeholder ?? ""
        }
        
        let children = view.subviews.map { buildViewNode(from: $0, depth: depth + 1) }
        
        let performanceMetrics = ViewPerformanceMetrics(
            renderTime: Double.random(in: 0.1...5.0), // Mock data
            layoutTime: Double.random(in: 0.05...2.0),
            memoryUsage: Int64.random(in: 1000...10000),
            constraintCount: view.constraints.count
        )
        
        return ViewNode(
            id: UUID().uuidString,
            viewType: viewType,
            depth: depth,
            frame: frame,
            properties: properties,
            children: children,
            performanceMetrics: performanceMetrics,
            isSwiftUI: viewType.contains("HostingView") || viewType.contains("SwiftUI")
        )
    }
    #endif
    
    private func performHierarchyAnalysis(_ hierarchy: ViewHierarchy) async -> ViewHierarchyAnalysis {
        let complexityAnalysis = analyzeComplexity(hierarchy)
        let performanceIssues = detectPerformanceIssues(hierarchy)
        let layoutIssues = detectLayoutIssues(hierarchy)
        let accessibilityIssues = detectAccessibilityIssues(hierarchy)
        let recommendations = generateRecommendations(
            complexityAnalysis: complexityAnalysis,
            performanceIssues: performanceIssues,
            layoutIssues: layoutIssues
        )
        
        return ViewHierarchyAnalysis(
            hierarchy: hierarchy,
            complexityAnalysis: complexityAnalysis,
            performanceIssues: performanceIssues,
            layoutIssues: layoutIssues,
            accessibilityIssues: accessibilityIssues,
            recommendations: recommendations,
            analysisTimestamp: Date()
        )
    }
    
    private func analyzeComplexity(_ hierarchy: ViewHierarchy) -> HierarchyComplexityAnalysis {
        let totalNodes = countNodes(in: hierarchy.rootNode)
        let maxDepth = calculateMaxDepth(from: hierarchy.rootNode)
        let averageBranching = calculateAverageBranching(hierarchy.rootNode)
        let viewTypeDistribution = calculateViewTypeDistribution(hierarchy.rootNode)
        
        let complexityScore = calculateComplexityScore(
            totalNodes: totalNodes,
            maxDepth: maxDepth,
            averageBranching: averageBranching
        )
        
        return HierarchyComplexityAnalysis(
            totalNodes: totalNodes,
            maxDepth: maxDepth,
            averageBranching: averageBranching,
            complexityScore: complexityScore,
            viewTypeDistribution: viewTypeDistribution
        )
    }
    
    private func detectPerformanceIssues(_ hierarchy: ViewHierarchy) -> [ViewPerformanceIssue] {
        var issues: [ViewPerformanceIssue] = []
        
        findPerformanceIssues(in: hierarchy.rootNode, issues: &issues)
        
        return issues
    }
    
    private func detectLayoutIssues(_ hierarchy: ViewHierarchy) -> [ViewLayoutIssue] {
        var issues: [ViewLayoutIssue] = []
        
        findLayoutIssues(in: hierarchy.rootNode, issues: &issues)
        
        return issues
    }
    
    private func detectAccessibilityIssues(_ hierarchy: ViewHierarchy) -> [ViewAccessibilityIssue] {
        var issues: [ViewAccessibilityIssue] = []
        
        findAccessibilityIssues(in: hierarchy.rootNode, issues: &issues)
        
        return issues
    }
    
    private func findPerformanceIssues(in node: ViewNode, issues: inout [ViewPerformanceIssue]) {
        // Check for slow render times
        if node.performanceMetrics.renderTime > 16.67 { // 60fps threshold
            issues.append(ViewPerformanceIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: .slowRendering,
                severity: node.performanceMetrics.renderTime > 33.33 ? .high : .medium,
                description: "View renders in \(String(format: "%.2f", node.performanceMetrics.renderTime))ms",
                suggestedFix: "Optimize view rendering or reduce complexity"
            ))
        }
        
        // Check for excessive memory usage
        if node.performanceMetrics.memoryUsage > 5000 {
            issues.append(ViewPerformanceIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: .highMemoryUsage,
                severity: .medium,
                description: "High memory usage: \(node.performanceMetrics.memoryUsage) bytes",
                suggestedFix: "Review memory allocations and caching"
            ))
        }
        
        // Check for excessive constraints
        if node.performanceMetrics.constraintCount > 20 {
            issues.append(ViewPerformanceIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: .excessiveConstraints,
                severity: .low,
                description: "Too many constraints: \(node.performanceMetrics.constraintCount)",
                suggestedFix: "Simplify layout constraints"
            ))
        }
        
        // Recursively check children
        for child in node.children {
            findPerformanceIssues(in: child, issues: &issues)
        }
    }
    
    private func findLayoutIssues(in node: ViewNode, issues: inout [ViewLayoutIssue]) {
        // Check for views outside screen bounds
        #if os(iOS)
        let screenBounds = UIScreen.main.bounds
        #else
        let screenBounds = CGRect(x: 0, y: 0, width: 800, height: 600) // Default bounds for macOS
        #endif
        if !screenBounds.intersects(node.frame) && node.frame != .zero {
            issues.append(ViewLayoutIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: .viewOutsideScreen,
                severity: .medium,
                description: "View is outside screen bounds",
                affectedFrame: node.frame
            ))
        }
        
        // Check for zero-sized views (potential layout issue)
        if node.frame.size.width == 0 || node.frame.size.height == 0 {
            issues.append(ViewLayoutIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: .zeroSizedView,
                severity: .low,
                description: "View has zero width or height",
                affectedFrame: node.frame
            ))
        }
        
        // Recursively check children
        for child in node.children {
            findLayoutIssues(in: child, issues: &issues)
        }
    }
    
    private func findAccessibilityIssues(in node: ViewNode, issues: inout [ViewAccessibilityIssue]) {
        // Check for missing accessibility labels on interactive elements
        if (node.viewType.contains("Button") || node.viewType.contains("TextField")) &&
           !node.properties.keys.contains("accessibilityLabel") {
            issues.append(ViewAccessibilityIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: AccessibilityIssueType.missingAccessibilityLabel,
                severity: Severity.high,
                description: "Interactive element missing accessibility label"
            ))
        }
        
        // Check for small touch targets
        if node.viewType.contains("Button") && (node.frame.width < 44 || node.frame.height < 44) {
            issues.append(ViewAccessibilityIssue(
                viewId: node.id,
                viewType: node.viewType,
                issueType: AccessibilityIssueType.smallTouchTarget,
                severity: Severity.medium,
                description: "Touch target smaller than 44x44 points"
            ))
        }
        
        // Recursively check children
        for child in node.children {
            findAccessibilityIssues(in: child, issues: &issues)
        }
    }
    
    // MARK: - Helper Methods
    
    private func countNodes(in node: ViewNode) -> Int {
        return 1 + node.children.reduce(0) { $0 + countNodes(in: $1) }
    }
    
    private func calculateMaxDepth(from node: ViewNode) -> Int {
        guard !node.children.isEmpty else { return node.depth }
        
        return node.children.map { calculateMaxDepth(from: $0) }.max() ?? node.depth
    }
    
    private func calculateAverageBranching(_ node: ViewNode) -> Double {
        var totalBranching = 0
        var totalNodes = 0
        
        calculateBranchingRecursive(node, totalBranching: &totalBranching, totalNodes: &totalNodes)
        
        return totalNodes > 0 ? Double(totalBranching) / Double(totalNodes) : 0.0
    }
    
    private func calculateBranchingRecursive(_ node: ViewNode, totalBranching: inout Int, totalNodes: inout Int) {
        totalBranching += node.children.count
        totalNodes += 1
        
        for child in node.children {
            calculateBranchingRecursive(child, totalBranching: &totalBranching, totalNodes: &totalNodes)
        }
    }
    
    private func calculateViewTypeDistribution(_ node: ViewNode) -> [String: Int] {
        var distribution: [String: Int] = [:]
        
        calculateViewTypeDistributionRecursive(node, distribution: &distribution)
        
        return distribution
    }
    
    private func calculateViewTypeDistributionRecursive(_ node: ViewNode, distribution: inout [String: Int]) {
        distribution[node.viewType, default: 0] += 1
        
        for child in node.children {
            calculateViewTypeDistributionRecursive(child, distribution: &distribution)
        }
    }
    
    private func calculateComplexityScore(totalNodes: Int, maxDepth: Int, averageBranching: Double) -> Double {
        // Weighted complexity score (0-100)
        let nodeScore = min(Double(totalNodes) / 100.0, 1.0) * 40.0
        let depthScore = min(Double(maxDepth) / 20.0, 1.0) * 30.0
        let branchingScore = min(averageBranching / 10.0, 1.0) * 30.0
        
        return nodeScore + depthScore + branchingScore
    }
    
    private func findViewsByType(_ viewType: String, in node: ViewNode, results: inout [ViewNode]) {
        if node.viewType == viewType {
            results.append(node)
        }
        
        for child in node.children {
            findViewsByType(viewType, in: child, results: &results)
        }
    }
    
    private func findViewsByProperty(key: String, value: String, in node: ViewNode, results: inout [ViewNode]) {
        if node.properties[key] == value {
            results.append(node)
        }
        
        for child in node.children {
            findViewsByProperty(key: key, value: value, in: child, results: &results)
        }
    }
    
    private func findViewPath(to viewId: String, in node: ViewNode, path: inout [ViewNode]) -> Bool {
        path.append(node)
        
        if node.id == viewId {
            return true
        }
        
        for child in node.children {
            if findViewPath(to: viewId, in: child, path: &path) {
                return true
            }
        }
        
        path.removeLast()
        return false
    }
    
    private func generateRecommendations(
        complexityAnalysis: HierarchyComplexityAnalysis,
        performanceIssues: [ViewPerformanceIssue],
        layoutIssues: [ViewLayoutIssue]
    ) -> [HierarchyRecommendation] {
        var recommendations: [HierarchyRecommendation] = []
        
        if complexityAnalysis.complexityScore > 70 {
            recommendations.append(HierarchyRecommendation(
                type: RecommendationType.complexity,
                priority: Priority.high,
                description: "View hierarchy is too complex",
                suggestedAction: "Consider breaking down into smaller components"
            ))
        }
        
        if complexityAnalysis.maxDepth > 15 {
            recommendations.append(HierarchyRecommendation(
                type: RecommendationType.depth,
                priority: Priority.medium,
                description: "View hierarchy is too deep",
                suggestedAction: "Flatten the view hierarchy to improve performance"
            ))
        }
        
        if !performanceIssues.isEmpty {
            recommendations.append(HierarchyRecommendation(
                type: RecommendationType.performance,
                priority: Priority.high,
                description: "Performance issues detected",
                suggestedAction: "Address rendering and memory optimization"
            ))
        }
        
        return recommendations
    }
    
    private func findStructuralChanges(from node1: ViewNode, to node2: ViewNode) -> [StructuralChange] {
        // Simplified structural comparison
        var changes: [StructuralChange] = []
        
        if node1.viewType != node2.viewType {
            changes.append(StructuralChange(
                type: .typeChanged,
                location: node1.id,
                description: "View type changed from \(node1.viewType) to \(node2.viewType)"
            ))
        }
        
        if node1.children.count != node2.children.count {
            changes.append(StructuralChange(
                type: .childCountChanged,
                location: node1.id,
                description: "Child count changed from \(node1.children.count) to \(node2.children.count)"
            ))
        }
        
        return changes
    }
    
    private func comparePerformanceMetrics(_ hierarchy1: ViewHierarchy, _ hierarchy2: ViewHierarchy) -> [PerformanceChange] {
        // Simplified performance comparison
        return []
    }
    
    private func calculateComplexityTrend(_ hierarchy1: ViewHierarchy, _ hierarchy2: ViewHierarchy) -> ComplexityTrend {
        if hierarchy2.totalNodes > hierarchy1.totalNodes {
            return .increasing
        } else if hierarchy2.totalNodes < hierarchy1.totalNodes {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func getCurrentOrientation() -> DeviceOrientation {
        #if os(iOS)
        let orientation = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.interfaceOrientation
        
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            return .landscape
        default:
            return .portrait
        }
        #else
        // Default to portrait on macOS and other platforms
        return .portrait
        #endif
    }
}

// MARK: - Supporting Types

public struct ViewHierarchyAnalyzerConfiguration {
    public var enablePerformanceAnalysis: Bool = true
    public var enableLayoutAnalysis: Bool = true
    public var enableAccessibilityAnalysis: Bool = true
    public var maxAnalysisDepth: Int = 50
    public var cacheResults: Bool = true
    
    public init() {}
}

public enum HierarchyAnalysisError: Error, LocalizedError {
    case noWindowAvailable
    case analysisTimeout
    case invalidHierarchy
    
    public var errorDescription: String? {
        switch self {
        case .noWindowAvailable:
            return "No window available for hierarchy analysis"
        case .analysisTimeout:
            return "Hierarchy analysis timed out"
        case .invalidHierarchy:
            return "Invalid view hierarchy"
        }
    }
}

// MARK: - Data Models

public struct ViewHierarchy: Codable {
    public let id: String
    public let timestamp: Date
    public let rootNode: ViewNode
    public let totalNodes: Int
    public let maxDepth: Int
    public let deviceInfo: DeviceInfo
    
    public init(id: String, timestamp: Date, rootNode: ViewNode, totalNodes: Int, maxDepth: Int, deviceInfo: DeviceInfo) {
        self.id = id
        self.timestamp = timestamp
        self.rootNode = rootNode
        self.totalNodes = totalNodes
        self.maxDepth = maxDepth
        self.deviceInfo = deviceInfo
    }
}

public struct ViewNode: Codable {
    public let id: String
    public let viewType: String
    public let depth: Int
    public let frame: CGRect
    public let properties: [String: String]
    public let children: [ViewNode]
    public let performanceMetrics: ViewPerformanceMetrics
    public let isSwiftUI: Bool
    
    public init(id: String, viewType: String, depth: Int, frame: CGRect, properties: [String: String], children: [ViewNode], performanceMetrics: ViewPerformanceMetrics, isSwiftUI: Bool) {
        self.id = id
        self.viewType = viewType
        self.depth = depth
        self.frame = frame
        self.properties = properties
        self.children = children
        self.performanceMetrics = performanceMetrics
        self.isSwiftUI = isSwiftUI
    }
}

public struct ViewPerformanceMetrics: Codable {
    public let renderTime: Double
    public let layoutTime: Double
    public let memoryUsage: Int64
    public let constraintCount: Int
    
    public init(renderTime: Double, layoutTime: Double, memoryUsage: Int64, constraintCount: Int) {
        self.renderTime = renderTime
        self.layoutTime = layoutTime
        self.memoryUsage = memoryUsage
        self.constraintCount = constraintCount
    }
}

public struct ViewHierarchyAnalysis: Codable {
    public let hierarchy: ViewHierarchy
    public let complexityAnalysis: HierarchyComplexityAnalysis
    public let performanceIssues: [ViewPerformanceIssue]
    public let layoutIssues: [ViewLayoutIssue]
    public let accessibilityIssues: [ViewAccessibilityIssue]
    public let recommendations: [HierarchyRecommendation]
    public let analysisTimestamp: Date
    
    public init(hierarchy: ViewHierarchy, complexityAnalysis: HierarchyComplexityAnalysis, performanceIssues: [ViewPerformanceIssue], layoutIssues: [ViewLayoutIssue], accessibilityIssues: [ViewAccessibilityIssue], recommendations: [HierarchyRecommendation], analysisTimestamp: Date) {
        self.hierarchy = hierarchy
        self.complexityAnalysis = complexityAnalysis
        self.performanceIssues = performanceIssues
        self.layoutIssues = layoutIssues
        self.accessibilityIssues = accessibilityIssues
        self.recommendations = recommendations
        self.analysisTimestamp = analysisTimestamp
    }
}

public struct HierarchyComplexityAnalysis: Codable {
    public let totalNodes: Int
    public let maxDepth: Int
    public let averageBranching: Double
    public let complexityScore: Double
    public let viewTypeDistribution: [String: Int]
    
    public init(totalNodes: Int, maxDepth: Int, averageBranching: Double, complexityScore: Double, viewTypeDistribution: [String: Int]) {
        self.totalNodes = totalNodes
        self.maxDepth = maxDepth
        self.averageBranching = averageBranching
        self.complexityScore = complexityScore
        self.viewTypeDistribution = viewTypeDistribution
    }
}

public struct ViewPerformanceIssue: Codable {
    public let viewId: String
    public let viewType: String
    public let issueType: PerformanceIssueType
    public let severity: Severity
    public let description: String
    public let suggestedFix: String
    
    public init(viewId: String, viewType: String, issueType: PerformanceIssueType, severity: Severity, description: String, suggestedFix: String) {
        self.viewId = viewId
        self.viewType = viewType
        self.issueType = issueType
        self.severity = severity
        self.description = description
        self.suggestedFix = suggestedFix
    }
}

public enum PerformanceIssueType: String, Codable {
    case slowRendering
    case highMemoryUsage
    case excessiveConstraints
    case layoutThrashing
}

public struct ViewLayoutIssue: Codable {
    public let viewId: String
    public let viewType: String
    public let issueType: LayoutIssueType
    public let severity: Severity
    public let description: String
    public let affectedFrame: CGRect
    
    public init(viewId: String, viewType: String, issueType: LayoutIssueType, severity: Severity, description: String, affectedFrame: CGRect) {
        self.viewId = viewId
        self.viewType = viewType
        self.issueType = issueType
        self.severity = severity
        self.description = description
        self.affectedFrame = affectedFrame
    }
}

public enum LayoutIssueType: String, Codable {
    case viewOutsideScreen
    case zeroSizedView
    case overlappingViews
    case constraintConflict
}

public struct ViewAccessibilityIssue: Codable {
    public let viewId: String
    public let viewType: String
    public let issueType: AccessibilityIssueType
    public let severity: Severity
    public let description: String
    
    public init(viewId: String, viewType: String, issueType: AccessibilityIssueType, severity: Severity, description: String) {
        self.viewId = viewId
        self.viewType = viewType
        self.issueType = issueType
        self.severity = severity
        self.description = description
    }
}

public enum AccessibilityIssueType: String, Codable {
    case missingAccessibilityLabel
    case smallTouchTarget
    case lowContrast
    case missingSemanticInfo
}

public enum RecommendationType: String, Codable {
    case complexity
    case depth
    case performance
    case accessibility
    case layout
}

public enum Priority: String, Codable {
    case low
    case medium
    case high
    case critical
}

public enum Severity: String, Codable {
    case low
    case medium
    case high
    case critical
}

public enum DeviceOrientation: String, Codable {
    case portrait
    case landscape
}

public struct DeviceInfo: Codable {
    public let model: String
    public let screenSize: CGSize
    public let orientation: DeviceOrientation
    
    public init(model: String, screenSize: CGSize, orientation: DeviceOrientation) {
        self.model = model
        self.screenSize = screenSize
        self.orientation = orientation
    }
}

public struct HierarchyRecommendation: Codable {
    public let type: RecommendationType
    public let priority: Priority
    public let description: String
    public let suggestedAction: String
    
    public init(type: RecommendationType, priority: Priority, description: String, suggestedAction: String) {
        self.type = type
        self.priority = priority
        self.description = description
        self.suggestedAction = suggestedAction
    }
}

public struct HierarchyComparisonResult: Codable {
    public let hierarchy1: ViewHierarchy
    public let hierarchy2: ViewHierarchy
    public let structuralChanges: [StructuralChange]
    public let performanceChanges: [PerformanceChange]
    public let complexityChanges: HierarchyComplexityComparison
    public let analysisTimestamp: Date
    
    public init(hierarchy1: ViewHierarchy, hierarchy2: ViewHierarchy, structuralChanges: [StructuralChange], performanceChanges: [PerformanceChange], complexityChanges: HierarchyComplexityComparison, analysisTimestamp: Date) {
        self.hierarchy1 = hierarchy1
        self.hierarchy2 = hierarchy2
        self.structuralChanges = structuralChanges
        self.performanceChanges = performanceChanges
        self.complexityChanges = complexityChanges
        self.analysisTimestamp = analysisTimestamp
    }
}

public struct StructuralChange: Codable {
    public let type: StructuralChangeType
    public let location: String
    public let description: String
    
    public init(type: StructuralChangeType, location: String, description: String) {
        self.type = type
        self.location = location
        self.description = description
    }
}

public enum StructuralChangeType: String, Codable {
    case typeChanged
    case childCountChanged
    case propertyChanged
    case viewAdded
    case viewRemoved
}

public struct PerformanceChange: Codable {
    public let viewId: String
    public let metricType: String
    public let oldValue: Double
    public let newValue: Double
    public let percentageChange: Double
    
    public init(viewId: String, metricType: String, oldValue: Double, newValue: Double, percentageChange: Double) {
        self.viewId = viewId
        self.metricType = metricType
        self.oldValue = oldValue
        self.newValue = newValue
        self.percentageChange = percentageChange
    }
}

public struct HierarchyComplexityComparison: Codable {
    public let nodeCountChange: Int
    public let depthChange: Int
    public let complexityTrend: ComplexityTrend
    
    public init(nodeCountChange: Int, depthChange: Int, complexityTrend: ComplexityTrend) {
        self.nodeCountChange = nodeCountChange
        self.depthChange = depthChange
        self.complexityTrend = complexityTrend
    }
}

public enum ComplexityTrend: String, Codable {
    case increasing
    case decreasing
    case stable
}