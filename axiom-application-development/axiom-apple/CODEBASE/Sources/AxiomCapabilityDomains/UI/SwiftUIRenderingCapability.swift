import Foundation
import SwiftUI
import Combine
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - SwiftUI Rendering Capability Configuration

/// Configuration for SwiftUI Rendering capability
public struct SwiftUIRenderingCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableSwiftUIRendering: Bool
    public let enablePerformanceOptimization: Bool
    public let enableDebugMode: Bool
    public let enableAccessibilitySupport: Bool
    public let enableAnimations: Bool
    public let enableDynamicType: Bool
    public let maxConcurrentRenders: Int
    public let renderTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let renderQuality: RenderQuality
    public let updateStrategy: UpdateStrategy
    public let colorScheme: ColorScheme
    public let layoutDirection: LayoutDirection
    public let sizeCategory: SizeCategory
    
    public enum RenderQuality: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case adaptive = "adaptive"
    }
    
    public enum UpdateStrategy: String, Codable, CaseIterable {
        case immediate = "immediate"
        case batched = "batched"
        case optimized = "optimized"
        case manual = "manual"
    }
    
    public enum ColorScheme: String, Codable, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
    }
    
    public enum LayoutDirection: String, Codable, CaseIterable {
        case leftToRight = "leftToRight"
        case rightToLeft = "rightToLeft"
        case auto = "auto"
    }
    
    public enum SizeCategory: String, Codable, CaseIterable {
        case extraSmall = "extraSmall"
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
        case extraExtraLarge = "extraExtraLarge"
        case extraExtraExtraLarge = "extraExtraExtraLarge"
        case accessibilityMedium = "accessibilityMedium"
        case accessibilityLarge = "accessibilityLarge"
        case accessibilityExtraLarge = "accessibilityExtraLarge"
        case accessibilityExtraExtraLarge = "accessibilityExtraExtraLarge"
        case accessibilityExtraExtraExtraLarge = "accessibilityExtraExtraExtraLarge"
    }
    
    public init(
        enableSwiftUIRendering: Bool = true,
        enablePerformanceOptimization: Bool = true,
        enableDebugMode: Bool = false,
        enableAccessibilitySupport: Bool = true,
        enableAnimations: Bool = true,
        enableDynamicType: Bool = true,
        maxConcurrentRenders: Int = 8,
        renderTimeout: TimeInterval = 10.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 150,
        renderQuality: RenderQuality = .high,
        updateStrategy: UpdateStrategy = .optimized,
        colorScheme: ColorScheme = .auto,
        layoutDirection: LayoutDirection = .auto,
        sizeCategory: SizeCategory = .large
    ) {
        self.enableSwiftUIRendering = enableSwiftUIRendering
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.enableDebugMode = enableDebugMode
        self.enableAccessibilitySupport = enableAccessibilitySupport
        self.enableAnimations = enableAnimations
        self.enableDynamicType = enableDynamicType
        self.maxConcurrentRenders = maxConcurrentRenders
        self.renderTimeout = renderTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.renderQuality = renderQuality
        self.updateStrategy = updateStrategy
        self.colorScheme = colorScheme
        self.layoutDirection = layoutDirection
        self.sizeCategory = sizeCategory
    }
    
    public var isValid: Bool {
        maxConcurrentRenders > 0 &&
        renderTimeout > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: SwiftUIRenderingCapabilityConfiguration) -> SwiftUIRenderingCapabilityConfiguration {
        SwiftUIRenderingCapabilityConfiguration(
            enableSwiftUIRendering: other.enableSwiftUIRendering,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            enableDebugMode: other.enableDebugMode,
            enableAccessibilitySupport: other.enableAccessibilitySupport,
            enableAnimations: other.enableAnimations,
            enableDynamicType: other.enableDynamicType,
            maxConcurrentRenders: other.maxConcurrentRenders,
            renderTimeout: other.renderTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            renderQuality: other.renderQuality,
            updateStrategy: other.updateStrategy,
            colorScheme: other.colorScheme,
            layoutDirection: other.layoutDirection,
            sizeCategory: other.sizeCategory
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> SwiftUIRenderingCapabilityConfiguration {
        var adjustedTimeout = renderTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentRenders = maxConcurrentRenders
        var adjustedCacheSize = cacheSize
        var adjustedRenderQuality = renderQuality
        var adjustedDebugMode = enableDebugMode
        var adjustedAnimations = enableAnimations
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(renderTimeout, 5.0)
            adjustedConcurrentRenders = min(maxConcurrentRenders, 3)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedRenderQuality = .low
            adjustedAnimations = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedDebugMode = true
        }
        
        return SwiftUIRenderingCapabilityConfiguration(
            enableSwiftUIRendering: enableSwiftUIRendering,
            enablePerformanceOptimization: enablePerformanceOptimization,
            enableDebugMode: adjustedDebugMode,
            enableAccessibilitySupport: enableAccessibilitySupport,
            enableAnimations: adjustedAnimations,
            enableDynamicType: enableDynamicType,
            maxConcurrentRenders: adjustedConcurrentRenders,
            renderTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            renderQuality: adjustedRenderQuality,
            updateStrategy: updateStrategy,
            colorScheme: colorScheme,
            layoutDirection: layoutDirection,
            sizeCategory: sizeCategory
        )
    }
}

// MARK: - SwiftUI Rendering Types

/// SwiftUI render request
public struct SwiftUIRenderRequest: Sendable, Identifiable {
    public let id: UUID
    public let viewDescription: ViewDescription
    public let options: RenderOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct ViewDescription: Sendable {
        public let viewType: ViewType
        public let properties: [String: ViewProperty]
        public let children: [ViewDescription]
        public let modifiers: [ViewModifier]
        public let constraints: LayoutConstraints
        
        public enum ViewType: String, Sendable, CaseIterable {
            case text = "text"
            case image = "image"
            case button = "button"
            case vStack = "vStack"
            case hStack = "hStack"
            case zStack = "zStack"
            case list = "list"
            case scrollView = "scrollView"
            case navigationView = "navigationView"
            case tabView = "tabView"
            case form = "form"
            case group = "group"
            case section = "section"
            case custom = "custom"
        }
        
        public struct ViewProperty: Sendable, Codable {
            public let key: String
            public let value: PropertyValue
            public let type: PropertyType
            
            public enum PropertyValue: Sendable, Codable {
                case string(String)
                case number(Double)
                case bool(Bool)
                case color(ColorValue)
                case font(FontValue)
                case image(ImageValue)
                
                public struct ColorValue: Sendable, Codable {
                    public let red: Double
                    public let green: Double
                    public let blue: Double
                    public let alpha: Double
                    
                    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
                        self.red = red
                        self.green = green
                        self.blue = blue
                        self.alpha = alpha
                    }
                }
                
                public struct FontValue: Sendable, Codable {
                    public let name: String
                    public let size: Double
                    public let weight: String
                    public let design: String
                    
                    public init(name: String = "system", size: Double = 17.0, weight: String = "regular", design: String = "default") {
                        self.name = name
                        self.size = size
                        self.weight = weight
                        self.design = design
                    }
                }
                
                public struct ImageValue: Sendable, Codable {
                    public let name: String
                    public let bundle: String?
                    public let systemName: String?
                    public let width: Double?
                    public let height: Double?
                    
                    public init(name: String, bundle: String? = nil, systemName: String? = nil, width: Double? = nil, height: Double? = nil) {
                        self.name = name
                        self.bundle = bundle
                        self.systemName = systemName
                        self.width = width
                        self.height = height
                    }
                }
            }
            
            public enum PropertyType: String, Sendable, CaseIterable {
                case content = "content"
                case style = "style"
                case behavior = "behavior"
                case accessibility = "accessibility"
                case layout = "layout"
            }
            
            public init(key: String, value: PropertyValue, type: PropertyType) {
                self.key = key
                self.value = value
                self.type = type
            }
        }
        
        public struct ViewModifier: Sendable {
            public let name: String
            public let parameters: [String: String]
            public let order: Int
            
            public init(name: String, parameters: [String: String] = [:], order: Int = 0) {
                self.name = name
                self.parameters = parameters
                self.order = order
            }
        }
        
        public struct LayoutConstraints: Sendable {
            public let width: ConstraintValue?
            public let height: ConstraintValue?
            public let minWidth: ConstraintValue?
            public let maxWidth: ConstraintValue?
            public let minHeight: ConstraintValue?
            public let maxHeight: ConstraintValue?
            public let aspectRatio: Double?
            public let priority: Double
            
            public enum ConstraintValue: Sendable {
                case fixed(Double)
                case flexible(min: Double?, max: Double?)
                case infinity
            }
            
            public init(width: ConstraintValue? = nil, height: ConstraintValue? = nil, minWidth: ConstraintValue? = nil, maxWidth: ConstraintValue? = nil, minHeight: ConstraintValue? = nil, maxHeight: ConstraintValue? = nil, aspectRatio: Double? = nil, priority: Double = 1.0) {
                self.width = width
                self.height = height
                self.minWidth = minWidth
                self.maxWidth = maxWidth
                self.minHeight = minHeight
                self.maxHeight = maxHeight
                self.aspectRatio = aspectRatio
                self.priority = priority
            }
        }
        
        public init(viewType: ViewType, properties: [String: ViewProperty] = [:], children: [ViewDescription] = [], modifiers: [ViewModifier] = [], constraints: LayoutConstraints = LayoutConstraints()) {
            self.viewType = viewType
            self.properties = properties
            self.children = children
            self.modifiers = modifiers
            self.constraints = constraints
        }
    }
    
    public struct RenderOptions: Sendable {
        public let enableAnimations: Bool
        public let animationDuration: TimeInterval
        public let enableAccessibility: Bool
        public let enableDynamicType: Bool
        public let colorScheme: SwiftUIRenderingCapabilityConfiguration.ColorScheme
        public let layoutDirection: SwiftUIRenderingCapabilityConfiguration.LayoutDirection
        public let sizeCategory: SwiftUIRenderingCapabilityConfiguration.SizeCategory
        public let renderingMode: RenderingMode
        public let previewMode: Bool
        public let containerSize: CGSize?
        
        public enum RenderingMode: String, Sendable, CaseIterable {
            case immediate = "immediate"
            case deferred = "deferred"
            case lazy = "lazy"
            case optimized = "optimized"
        }
        
        public init(enableAnimations: Bool = true, animationDuration: TimeInterval = 0.25, enableAccessibility: Bool = true, enableDynamicType: Bool = true, colorScheme: SwiftUIRenderingCapabilityConfiguration.ColorScheme = .auto, layoutDirection: SwiftUIRenderingCapabilityConfiguration.LayoutDirection = .auto, sizeCategory: SwiftUIRenderingCapabilityConfiguration.SizeCategory = .large, renderingMode: RenderingMode = .optimized, previewMode: Bool = false, containerSize: CGSize? = nil) {
            self.enableAnimations = enableAnimations
            self.animationDuration = animationDuration
            self.enableAccessibility = enableAccessibility
            self.enableDynamicType = enableDynamicType
            self.colorScheme = colorScheme
            self.layoutDirection = layoutDirection
            self.sizeCategory = sizeCategory
            self.renderingMode = renderingMode
            self.previewMode = previewMode
            self.containerSize = containerSize
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(viewDescription: ViewDescription, options: RenderOptions = RenderOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.viewDescription = viewDescription
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// SwiftUI render result
public struct SwiftUIRenderResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let renderTree: RenderTree
    public let layoutMetrics: LayoutMetrics
    public let performanceMetrics: PerformanceMetrics
    public let accessibilityInfo: AccessibilityInfo
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: SwiftUIRenderingError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct RenderTree: Sendable {
        public let rootNode: RenderNode
        public let totalNodes: Int
        public let maxDepth: Int
        public let renderPasses: Int
        
        public struct RenderNode: Sendable {
            public let id: String
            public let type: String
            public let frame: CGRect
            public let bounds: CGRect
            public let children: [RenderNode]
            public let properties: [String: String]
            public let renderTime: TimeInterval
            public let layoutTime: TimeInterval
            
            public init(id: String, type: String, frame: CGRect, bounds: CGRect, children: [RenderNode], properties: [String: String], renderTime: TimeInterval, layoutTime: TimeInterval) {
                self.id = id
                self.type = type
                self.frame = frame
                self.bounds = bounds
                self.children = children
                self.properties = properties
                self.renderTime = renderTime
                self.layoutTime = layoutTime
            }
        }
        
        public init(rootNode: RenderNode, totalNodes: Int, maxDepth: Int, renderPasses: Int) {
            self.rootNode = rootNode
            self.totalNodes = totalNodes
            self.maxDepth = maxDepth
            self.renderPasses = renderPasses
        }
    }
    
    public struct LayoutMetrics: Sendable {
        public let totalLayoutTime: TimeInterval
        public let layoutPasses: Int
        public let constraintSolutions: Int
        public let layoutInvalidations: Int
        public let sizeThatFitsCalculations: Int
        public let intrinsicContentSizeCalculations: Int
        public let geometryUpdates: Int
        public let boundsChanges: Int
        
        public init(totalLayoutTime: TimeInterval, layoutPasses: Int, constraintSolutions: Int, layoutInvalidations: Int, sizeThatFitsCalculations: Int, intrinsicContentSizeCalculations: Int, geometryUpdates: Int, boundsChanges: Int) {
            self.totalLayoutTime = totalLayoutTime
            self.layoutPasses = layoutPasses
            self.constraintSolutions = constraintSolutions
            self.layoutInvalidations = layoutInvalidations
            self.sizeThatFitsCalculations = sizeThatFitsCalculations
            self.intrinsicContentSizeCalculations = intrinsicContentSizeCalculations
            self.geometryUpdates = geometryUpdates
            self.boundsChanges = boundsChanges
        }
    }
    
    public struct PerformanceMetrics: Sendable {
        public let totalRenderTime: TimeInterval
        public let updateTime: TimeInterval
        public let diffTime: TimeInterval
        public let commitTime: TimeInterval
        public let bodyEvaluations: Int
        public let stateUpdates: Int
        public let viewRedraws: Int
        public let memoryUsage: Int
        public let cpuUsage: Double
        
        public init(totalRenderTime: TimeInterval, updateTime: TimeInterval, diffTime: TimeInterval, commitTime: TimeInterval, bodyEvaluations: Int, stateUpdates: Int, viewRedraws: Int, memoryUsage: Int, cpuUsage: Double) {
            self.totalRenderTime = totalRenderTime
            self.updateTime = updateTime
            self.diffTime = diffTime
            self.commitTime = commitTime
            self.bodyEvaluations = bodyEvaluations
            self.stateUpdates = stateUpdates
            self.viewRedraws = viewRedraws
            self.memoryUsage = memoryUsage
            self.cpuUsage = cpuUsage
        }
    }
    
    public struct AccessibilityInfo: Sendable {
        public let accessibleElements: Int
        public let accessibilityLabels: [String]
        public let accessibilityHints: [String]
        public let accessibilityTraits: [String]
        public let accessibilityActions: [String]
        public let dynamicTypeSupport: Bool
        public let voiceOverSupport: Bool
        public let switchControlSupport: Bool
        
        public init(accessibleElements: Int, accessibilityLabels: [String], accessibilityHints: [String], accessibilityTraits: [String], accessibilityActions: [String], dynamicTypeSupport: Bool, voiceOverSupport: Bool, switchControlSupport: Bool) {
            self.accessibleElements = accessibleElements
            self.accessibilityLabels = accessibilityLabels
            self.accessibilityHints = accessibilityHints
            self.accessibilityTraits = accessibilityTraits
            self.accessibilityActions = accessibilityActions
            self.dynamicTypeSupport = dynamicTypeSupport
            self.voiceOverSupport = voiceOverSupport
            self.switchControlSupport = switchControlSupport
        }
    }
    
    public init(requestId: UUID, renderTree: RenderTree, layoutMetrics: LayoutMetrics, performanceMetrics: PerformanceMetrics, accessibilityInfo: AccessibilityInfo, processingTime: TimeInterval, success: Bool, error: SwiftUIRenderingError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.renderTree = renderTree
        self.layoutMetrics = layoutMetrics
        self.performanceMetrics = performanceMetrics
        self.accessibilityInfo = accessibilityInfo
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var isPerformant: Bool {
        performanceMetrics.totalRenderTime < 0.016 // 60 FPS target
    }
    
    public var accessibilityCompliance: Double {
        guard renderTree.totalNodes > 0 else { return 0.0 }
        return Double(accessibilityInfo.accessibleElements) / Double(renderTree.totalNodes)
    }
    
    public var averageRenderTimePerNode: TimeInterval {
        guard renderTree.totalNodes > 0 else { return 0.0 }
        return performanceMetrics.totalRenderTime / Double(renderTree.totalNodes)
    }
}

/// SwiftUI rendering metrics
public struct SwiftUIRenderingMetrics: Sendable {
    public let totalRenderRequests: Int
    public let successfulRenders: Int
    public let failedRenders: Int
    public let averageProcessingTime: TimeInterval
    public let rendersByViewType: [String: Int]
    public let rendersByComplexity: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageRenderTime: TimeInterval
    public let averageLayoutTime: TimeInterval
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    public let accessibilityStats: AccessibilityStats
    
    public struct PerformanceStats: Sendable {
        public let bestRenderTime: TimeInterval
        public let worstRenderTime: TimeInterval
        public let averageNodesPerRender: Double
        public let averageDepthPerRender: Double
        public let totalBodyEvaluations: Int
        public let totalStateUpdates: Int
        public let averageMemoryUsage: Int
        
        public init(bestRenderTime: TimeInterval = 0, worstRenderTime: TimeInterval = 0, averageNodesPerRender: Double = 0, averageDepthPerRender: Double = 0, totalBodyEvaluations: Int = 0, totalStateUpdates: Int = 0, averageMemoryUsage: Int = 0) {
            self.bestRenderTime = bestRenderTime
            self.worstRenderTime = worstRenderTime
            self.averageNodesPerRender = averageNodesPerRender
            self.averageDepthPerRender = averageDepthPerRender
            self.totalBodyEvaluations = totalBodyEvaluations
            self.totalStateUpdates = totalStateUpdates
            self.averageMemoryUsage = averageMemoryUsage
        }
    }
    
    public struct AccessibilityStats: Sendable {
        public let totalAccessibleElements: Int
        public let averageAccessibilityCompliance: Double
        public let viewsWithLabels: Int
        public let viewsWithHints: Int
        public let viewsWithActions: Int
        public let dynamicTypeCompatible: Int
        
        public init(totalAccessibleElements: Int = 0, averageAccessibilityCompliance: Double = 0, viewsWithLabels: Int = 0, viewsWithHints: Int = 0, viewsWithActions: Int = 0, dynamicTypeCompatible: Int = 0) {
            self.totalAccessibleElements = totalAccessibleElements
            self.averageAccessibilityCompliance = averageAccessibilityCompliance
            self.viewsWithLabels = viewsWithLabels
            self.viewsWithHints = viewsWithHints
            self.viewsWithActions = viewsWithActions
            self.dynamicTypeCompatible = dynamicTypeCompatible
        }
    }
    
    public init(totalRenderRequests: Int = 0, successfulRenders: Int = 0, failedRenders: Int = 0, averageProcessingTime: TimeInterval = 0, rendersByViewType: [String: Int] = [:], rendersByComplexity: [String: Int] = [:], errorsByType: [String: Int] = [:], cacheHitRate: Double = 0, averageRenderTime: TimeInterval = 0, averageLayoutTime: TimeInterval = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats(), accessibilityStats: AccessibilityStats = AccessibilityStats()) {
        self.totalRenderRequests = totalRenderRequests
        self.successfulRenders = successfulRenders
        self.failedRenders = failedRenders
        self.averageProcessingTime = averageProcessingTime
        self.rendersByViewType = rendersByViewType
        self.rendersByComplexity = rendersByComplexity
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageRenderTime = averageRenderTime
        self.averageLayoutTime = averageLayoutTime
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRenderRequests) / averageProcessingTime : 0
        self.performanceStats = performanceStats
        self.accessibilityStats = accessibilityStats
    }
    
    public var successRate: Double {
        totalRenderRequests > 0 ? Double(successfulRenders) / Double(totalRenderRequests) : 0
    }
}

// MARK: - SwiftUI Rendering Resource

/// SwiftUI rendering resource management
@available(iOS 13.0, macOS 10.15, *)
public actor SwiftUIRenderingCapabilityResource: AxiomCapabilityResource {
    private let configuration: SwiftUIRenderingCapabilityConfiguration
    private var activeRenders: [UUID: SwiftUIRenderRequest] = [:]
    private var renderQueue: [SwiftUIRenderRequest] = []
    private var renderHistory: [SwiftUIRenderResult] = []
    private var resultCache: [String: SwiftUIRenderResult] = [:]
    private var viewStateManager: ViewStateManager = ViewStateManager()
    private var layoutEngine: LayoutEngine = LayoutEngine()
    private var accessibilityProcessor: AccessibilityProcessor = AccessibilityProcessor()
    private var metrics: SwiftUIRenderingMetrics = SwiftUIRenderingMetrics()
    private var resultStreamContinuation: AsyncStream<SwiftUIRenderResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    // Helper classes for SwiftUI rendering simulation
    private class ViewStateManager {
        private var stateUpdates: Int = 0
        private var bodyEvaluations: Int = 0
        
        func recordStateUpdate() {
            stateUpdates += 1
        }
        
        func recordBodyEvaluation() {
            bodyEvaluations += 1
        }
        
        func getStateUpdates() -> Int { stateUpdates }
        func getBodyEvaluations() -> Int { bodyEvaluations }
        
        func reset() {
            stateUpdates = 0
            bodyEvaluations = 0
        }
    }
    
    private class LayoutEngine {
        func calculateLayout(for viewDescription: SwiftUIRenderRequest.ViewDescription, containerSize: CGSize) -> SwiftUIRenderResult.RenderTree {
            // Simulate layout calculation
            let rootNode = createRenderNode(from: viewDescription, parentFrame: CGRect(origin: .zero, size: containerSize))
            let totalNodes = countNodes(rootNode)
            let maxDepth = calculateDepth(rootNode)
            
            return SwiftUIRenderResult.RenderTree(
                rootNode: rootNode,
                totalNodes: totalNodes,
                maxDepth: maxDepth,
                renderPasses: 1
            )
        }
        
        private func createRenderNode(from viewDescription: SwiftUIRenderRequest.ViewDescription, parentFrame: CGRect) -> SwiftUIRenderResult.RenderTree.RenderNode {
            // Simulate view rendering
            let nodeFrame = calculateFrame(for: viewDescription, in: parentFrame)
            let children = viewDescription.children.map { child in
                createRenderNode(from: child, parentFrame: nodeFrame)
            }
            
            return SwiftUIRenderResult.RenderTree.RenderNode(
                id: UUID().uuidString,
                type: viewDescription.viewType.rawValue,
                frame: nodeFrame,
                bounds: CGRect(origin: .zero, size: nodeFrame.size),
                children: children,
                properties: viewDescription.properties.mapValues { $0.key },
                renderTime: 0.001, // 1ms simulation
                layoutTime: 0.0005 // 0.5ms simulation
            )
        }
        
        private func calculateFrame(for viewDescription: SwiftUIRenderRequest.ViewDescription, in parentFrame: CGRect) -> CGRect {
            // Simplified frame calculation
            let constraints = viewDescription.constraints
            
            var width: CGFloat = parentFrame.width
            var height: CGFloat = parentFrame.height
            
            // Apply constraints
            if let widthConstraint = constraints.width {
                switch widthConstraint {
                case .fixed(let value):
                    width = CGFloat(value)
                case .flexible(let min, let max):
                    width = min(max ?? parentFrame.width, max(min ?? 0, parentFrame.width))
                case .infinity:
                    width = parentFrame.width
                }
            }
            
            if let heightConstraint = constraints.height {
                switch heightConstraint {
                case .fixed(let value):
                    height = CGFloat(value)
                case .flexible(let min, let max):
                    height = min(max ?? parentFrame.height, max(min ?? 0, parentFrame.height))
                case .infinity:
                    height = parentFrame.height
                }
            }
            
            // Apply aspect ratio if specified
            if let aspectRatio = constraints.aspectRatio {
                if width / height > CGFloat(aspectRatio) {
                    width = height * CGFloat(aspectRatio)
                } else {
                    height = width / CGFloat(aspectRatio)
                }
            }
            
            return CGRect(
                x: parentFrame.origin.x,
                y: parentFrame.origin.y,
                width: width,
                height: height
            )
        }
        
        private func countNodes(_ node: SwiftUIRenderResult.RenderTree.RenderNode) -> Int {
            return 1 + node.children.reduce(0) { count, child in
                count + countNodes(child)
            }
        }
        
        private func calculateDepth(_ node: SwiftUIRenderResult.RenderTree.RenderNode) -> Int {
            guard !node.children.isEmpty else { return 1 }
            return 1 + node.children.map(calculateDepth).max()!
        }
    }
    
    private class AccessibilityProcessor {
        func processAccessibility(for renderTree: SwiftUIRenderResult.RenderTree, options: SwiftUIRenderRequest.RenderOptions) -> SwiftUIRenderResult.AccessibilityInfo {
            let accessibleElements = countAccessibleElements(renderTree.rootNode)
            
            return SwiftUIRenderResult.AccessibilityInfo(
                accessibleElements: accessibleElements,
                accessibilityLabels: extractAccessibilityLabels(renderTree.rootNode),
                accessibilityHints: [],
                accessibilityTraits: [],
                accessibilityActions: [],
                dynamicTypeSupport: options.enableDynamicType,
                voiceOverSupport: options.enableAccessibility,
                switchControlSupport: options.enableAccessibility
            )
        }
        
        private func countAccessibleElements(_ node: SwiftUIRenderResult.RenderTree.RenderNode) -> Int {
            let isAccessible = !["group", "section"].contains(node.type)
            let childrenCount = node.children.reduce(0) { count, child in
                count + countAccessibleElements(child)
            }
            return (isAccessible ? 1 : 0) + childrenCount
        }
        
        private func extractAccessibilityLabels(_ node: SwiftUIRenderResult.RenderTree.RenderNode) -> [String] {
            var labels: [String] = []
            
            if node.type == "text", let content = node.properties["content"] {
                labels.append(content)
            }
            
            for child in node.children {
                labels.append(contentsOf: extractAccessibilityLabels(child))
            }
            
            return labels
        }
    }
    
    public init(configuration: SwiftUIRenderingCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 500_000_000, // 500MB for SwiftUI rendering
            cpu: 3.5, // High CPU usage for UI rendering
            bandwidth: 0,
            storage: 100_000_000 // 100MB for view and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let renderMemory = activeRenders.count * 50_000_000 // ~50MB per active render
            let cacheMemory = resultCache.count * 100_000 // ~100KB per cached result
            let historyMemory = renderHistory.count * 30_000
            let systemMemory = 100_000_000 // SwiftUI system overhead
            
            return ResourceUsage(
                memory: renderMemory + cacheMemory + historyMemory + systemMemory,
                cpu: activeRenders.isEmpty ? 0.5 : 3.0,
                bandwidth: 0,
                storage: resultCache.count * 50_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // SwiftUI rendering is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableSwiftUIRendering
        }
        return false
    }
    
    public func release() async {
        activeRenders.removeAll()
        renderQueue.removeAll()
        renderHistory.removeAll()
        resultCache.removeAll()
        
        viewStateManager.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = SwiftUIRenderingMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize SwiftUI rendering components
        viewStateManager = ViewStateManager()
        layoutEngine = LayoutEngine()
        accessibilityProcessor = AccessibilityProcessor()
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[SwiftUIRendering] 🚀 SwiftUI Rendering capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: SwiftUIRenderingCapabilityConfiguration) async throws {
        // Update SwiftUI rendering configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<SwiftUIRenderResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - SwiftUI Rendering
    
    public func render(_ request: SwiftUIRenderRequest) async throws -> SwiftUIRenderResult {
        guard configuration.enableSwiftUIRendering else {
            throw SwiftUIRenderingError.renderingDisabled
        }
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(for: request)
            if let cachedResult = resultCache[cacheKey] {
                await updateCacheHitMetrics()
                return cachedResult
            }
        }
        
        // Check if we're at capacity
        if activeRenders.count >= configuration.maxConcurrentRenders {
            renderQueue.append(request)
            throw SwiftUIRenderingError.renderQueued(request.id)
        }
        
        let startTime = Date()
        activeRenders[request.id] = request
        
        do {
            // Perform SwiftUI rendering
            let result = try await performSwiftUIRendering(
                request: request,
                startTime: startTime
            )
            
            activeRenders.removeValue(forKey: request.id)
            renderHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logRender(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processRenderQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = SwiftUIRenderResult(
                requestId: request.id,
                renderTree: SwiftUIRenderResult.RenderTree(
                    rootNode: SwiftUIRenderResult.RenderTree.RenderNode(
                        id: "error",
                        type: "error",
                        frame: .zero,
                        bounds: .zero,
                        children: [],
                        properties: [:],
                        renderTime: 0,
                        layoutTime: 0
                    ),
                    totalNodes: 0,
                    maxDepth: 0,
                    renderPasses: 0
                ),
                layoutMetrics: SwiftUIRenderResult.LayoutMetrics(
                    totalLayoutTime: 0,
                    layoutPasses: 0,
                    constraintSolutions: 0,
                    layoutInvalidations: 0,
                    sizeThatFitsCalculations: 0,
                    intrinsicContentSizeCalculations: 0,
                    geometryUpdates: 0,
                    boundsChanges: 0
                ),
                performanceMetrics: SwiftUIRenderResult.PerformanceMetrics(
                    totalRenderTime: processingTime,
                    updateTime: 0,
                    diffTime: 0,
                    commitTime: 0,
                    bodyEvaluations: 0,
                    stateUpdates: 0,
                    viewRedraws: 0,
                    memoryUsage: 0,
                    cpuUsage: 0
                ),
                accessibilityInfo: SwiftUIRenderResult.AccessibilityInfo(
                    accessibleElements: 0,
                    accessibilityLabels: [],
                    accessibilityHints: [],
                    accessibilityTraits: [],
                    accessibilityActions: [],
                    dynamicTypeSupport: false,
                    voiceOverSupport: false,
                    switchControlSupport: false
                ),
                processingTime: processingTime,
                success: false,
                error: error as? SwiftUIRenderingError ?? SwiftUIRenderingError.renderingError(error.localizedDescription)
            )
            
            activeRenders.removeValue(forKey: request.id)
            renderHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logRender(result)
            }
            
            throw error
        }
    }
    
    public func cancelRender(_ requestId: UUID) async {
        activeRenders.removeValue(forKey: requestId)
        renderQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[SwiftUIRendering] 🚫 Cancelled render: \(requestId)")
        }
    }
    
    public func getActiveRenders() async -> [SwiftUIRenderRequest] {
        return Array(activeRenders.values)
    }
    
    public func getRenderHistory(since: Date? = nil) async -> [SwiftUIRenderResult] {
        if let since = since {
            return renderHistory.filter { $0.timestamp >= since }
        }
        return renderHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> SwiftUIRenderingMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = SwiftUIRenderingMetrics()
        viewStateManager.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[SwiftUIRendering] ⚡ Performance optimization enabled")
        }
    }
    
    private func performSwiftUIRendering(
        request: SwiftUIRenderRequest,
        startTime: Date
    ) async throws -> SwiftUIRenderResult {
        
        // Simulate view state updates
        viewStateManager.recordBodyEvaluation()
        
        // Calculate layout
        let containerSize = request.options.containerSize ?? CGSize(width: 375, height: 667) // iPhone default
        let renderTree = layoutEngine.calculateLayout(for: request.viewDescription, containerSize: containerSize)
        
        // Calculate layout metrics
        let layoutMetrics = SwiftUIRenderResult.LayoutMetrics(
            totalLayoutTime: 0.005, // 5ms simulation
            layoutPasses: 1,
            constraintSolutions: renderTree.totalNodes,
            layoutInvalidations: 0,
            sizeThatFitsCalculations: renderTree.totalNodes,
            intrinsicContentSizeCalculations: renderTree.totalNodes,
            geometryUpdates: renderTree.totalNodes,
            boundsChanges: 0
        )
        
        // Calculate performance metrics
        let processingTime = Date().timeIntervalSince(startTime)
        let performanceMetrics = SwiftUIRenderResult.PerformanceMetrics(
            totalRenderTime: processingTime,
            updateTime: processingTime * 0.3,
            diffTime: processingTime * 0.2,
            commitTime: processingTime * 0.5,
            bodyEvaluations: viewStateManager.getBodyEvaluations(),
            stateUpdates: viewStateManager.getStateUpdates(),
            viewRedraws: 1,
            memoryUsage: renderTree.totalNodes * 1000, // 1KB per node simulation
            cpuUsage: 0.3 // 30% CPU simulation
        )
        
        // Process accessibility
        let accessibilityInfo = accessibilityProcessor.processAccessibility(
            for: renderTree,
            options: request.options
        )
        
        return SwiftUIRenderResult(
            requestId: request.id,
            renderTree: renderTree,
            layoutMetrics: layoutMetrics,
            performanceMetrics: performanceMetrics,
            accessibilityInfo: accessibilityInfo,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func processRenderQueue() async {
        guard !isProcessingQueue && !renderQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        renderQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !renderQueue.isEmpty && activeRenders.count < configuration.maxConcurrentRenders {
            let request = renderQueue.removeFirst()
            
            do {
                _ = try await render(request)
            } catch {
                if configuration.enableLogging {
                    print("[SwiftUIRendering] ⚠️ Queued render failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: SwiftUIRenderRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: SwiftUIRenderRequest) -> String {
        let viewHash = String(describing: request.viewDescription).hashValue
        let optionsHash = String(describing: request.options).hashValue
        
        return "\(viewHash)_\(optionsHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalRenderRequests)) + 1
        let totalRequests = metrics.totalRenderRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = SwiftUIRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: metrics.successfulRenders + 1,
            failedRenders: metrics.failedRenders,
            averageProcessingTime: metrics.averageProcessingTime,
            rendersByViewType: metrics.rendersByViewType,
            rendersByComplexity: metrics.rendersByComplexity,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageRenderTime: metrics.averageRenderTime,
            averageLayoutTime: metrics.averageLayoutTime,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats,
            accessibilityStats: metrics.accessibilityStats
        )
    }
    
    private func updateSuccessMetrics(_ result: SwiftUIRenderResult) async {
        let totalRequests = metrics.totalRenderRequests + 1
        let successfulRenders = metrics.successfulRenders + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRenderRequests)) + result.processingTime) / Double(totalRequests)
        
        var rendersByViewType = metrics.rendersByViewType
        rendersByViewType[result.renderTree.rootNode.type, default: 0] += 1
        
        var rendersByComplexity = metrics.rendersByComplexity
        let complexityKey = getComplexityKey(nodeCount: result.renderTree.totalNodes)
        rendersByComplexity[complexityKey, default: 0] += 1
        
        let newAverageRenderTime = ((metrics.averageRenderTime * Double(metrics.successfulRenders)) + result.performanceMetrics.totalRenderTime) / Double(successfulRenders)
        
        let newAverageLayoutTime = ((metrics.averageLayoutTime * Double(metrics.successfulRenders)) + result.layoutMetrics.totalLayoutTime) / Double(successfulRenders)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestRenderTime = metrics.successfulRenders == 0 ? result.performanceMetrics.totalRenderTime : min(performanceStats.bestRenderTime, result.performanceMetrics.totalRenderTime)
        let worstRenderTime = max(performanceStats.worstRenderTime, result.performanceMetrics.totalRenderTime)
        let newAverageNodesPerRender = ((performanceStats.averageNodesPerRender * Double(metrics.successfulRenders)) + Double(result.renderTree.totalNodes)) / Double(successfulRenders)
        let newAverageDepthPerRender = ((performanceStats.averageDepthPerRender * Double(metrics.successfulRenders)) + Double(result.renderTree.maxDepth)) / Double(successfulRenders)
        let totalBodyEvaluations = performanceStats.totalBodyEvaluations + result.performanceMetrics.bodyEvaluations
        let totalStateUpdates = performanceStats.totalStateUpdates + result.performanceMetrics.stateUpdates
        let newAverageMemoryUsage = Int(((Double(performanceStats.averageMemoryUsage) * Double(metrics.successfulRenders)) + Double(result.performanceMetrics.memoryUsage)) / Double(successfulRenders))
        
        performanceStats = SwiftUIRenderingMetrics.PerformanceStats(
            bestRenderTime: bestRenderTime,
            worstRenderTime: worstRenderTime,
            averageNodesPerRender: newAverageNodesPerRender,
            averageDepthPerRender: newAverageDepthPerRender,
            totalBodyEvaluations: totalBodyEvaluations,
            totalStateUpdates: totalStateUpdates,
            averageMemoryUsage: newAverageMemoryUsage
        )
        
        // Update accessibility stats
        var accessibilityStats = metrics.accessibilityStats
        let totalAccessibleElements = accessibilityStats.totalAccessibleElements + result.accessibilityInfo.accessibleElements
        let newAvgCompliance = ((accessibilityStats.averageAccessibilityCompliance * Double(metrics.successfulRenders)) + result.accessibilityCompliance) / Double(successfulRenders)
        let viewsWithLabels = accessibilityStats.viewsWithLabels + (result.accessibilityInfo.accessibilityLabels.isEmpty ? 0 : 1)
        let dynamicTypeCompatible = accessibilityStats.dynamicTypeCompatible + (result.accessibilityInfo.dynamicTypeSupport ? 1 : 0)
        
        accessibilityStats = SwiftUIRenderingMetrics.AccessibilityStats(
            totalAccessibleElements: totalAccessibleElements,
            averageAccessibilityCompliance: newAvgCompliance,
            viewsWithLabels: viewsWithLabels,
            viewsWithHints: accessibilityStats.viewsWithHints,
            viewsWithActions: accessibilityStats.viewsWithActions,
            dynamicTypeCompatible: dynamicTypeCompatible
        )
        
        metrics = SwiftUIRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: successfulRenders,
            failedRenders: metrics.failedRenders,
            averageProcessingTime: newAverageProcessingTime,
            rendersByViewType: rendersByViewType,
            rendersByComplexity: rendersByComplexity,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageRenderTime: newAverageRenderTime,
            averageLayoutTime: newAverageLayoutTime,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats,
            accessibilityStats: accessibilityStats
        )
    }
    
    private func updateFailureMetrics(_ result: SwiftUIRenderResult) async {
        let totalRequests = metrics.totalRenderRequests + 1
        let failedRenders = metrics.failedRenders + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = SwiftUIRenderingMetrics(
            totalRenderRequests: totalRequests,
            successfulRenders: metrics.successfulRenders,
            failedRenders: failedRenders,
            averageProcessingTime: metrics.averageProcessingTime,
            rendersByViewType: metrics.rendersByViewType,
            rendersByComplexity: metrics.rendersByComplexity,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageRenderTime: metrics.averageRenderTime,
            averageLayoutTime: metrics.averageLayoutTime,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats,
            accessibilityStats: metrics.accessibilityStats
        )
    }
    
    private func getComplexityKey(nodeCount: Int) -> String {
        switch nodeCount {
        case 0...10: return "simple"
        case 11...50: return "moderate"
        case 51...200: return "complex"
        default: return "very-complex"
        }
    }
    
    private func logRender(_ result: SwiftUIRenderResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let nodeCount = result.renderTree.totalNodes
        let viewType = result.renderTree.rootNode.type
        let performant = result.isPerformant ? "performant" : "slow"
        let accessibilityScore = String(format: "%.1f", result.accessibilityCompliance * 100)
        
        print("[SwiftUIRendering] \(statusIcon) Render: \(nodeCount) nodes, \(viewType), \(performant), A11Y: \(accessibilityScore)% (\(timeStr)s)")
        
        if let error = result.error {
            print("[SwiftUIRendering] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - SwiftUI Rendering Capability Implementation

/// SwiftUI Rendering capability providing declarative UI rendering
@available(iOS 13.0, macOS 10.15, *)
public actor SwiftUIRenderingCapability: LocalCapability {
    public typealias ConfigurationType = SwiftUIRenderingCapabilityConfiguration
    public typealias ResourceType = SwiftUIRenderingCapabilityResource
    
    private var _configuration: SwiftUIRenderingCapabilityConfiguration
    private var _resources: SwiftUIRenderingCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "swiftui-rendering-capability" }
    
    public var isAvailable: Bool {
        get async { _state == .available }
    }
    
    public var state: AxiomCapabilityState {
        get async { _state }
    }
    
    public var stateStream: AsyncStream<AxiomCapabilityState> {
        AsyncStream { [weak self] continuation in
            Task { [weak self] in
                await self?.setStreamContinuation(continuation)
                if let currentState = await self?._state {
                    continuation.yield(currentState)
                }
            }
        }
    }
    
    public var activationTimeout: Duration {
        get async { _activationTimeout }
    }
    
    public var configuration: SwiftUIRenderingCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: SwiftUIRenderingCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: SwiftUIRenderingCapabilityConfiguration = SwiftUIRenderingCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = SwiftUIRenderingCapabilityResource(configuration: self._configuration)
        self._environment = environment
    }
    
    private func setStreamContinuation(_ continuation: AsyncStream<AxiomCapabilityState>.Continuation) {
        self.stateStreamContinuation = continuation
    }
    
    // MARK: - AxiomCapability Protocol
    
    public func activate() async throws {
        await transitionTo(.initializing)
        
        do {
            try await _resources.allocate()
            await transitionTo(.available)
        } catch {
            await transitionTo(.unavailable)
            throw error
        }
    }
    
    public func deactivate() async {
        await transitionTo(.terminating)
        await _resources.release()
        await transitionTo(.unavailable)
        stateStreamContinuation?.finish()
    }
    
    // MARK: - DomainCapability Protocol
    
    public func updateConfiguration(_ configuration: SwiftUIRenderingCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid SwiftUI Rendering configuration")
        }
        
        _configuration = configuration.adjusted(for: _environment)
        try await _resources.updateConfiguration(_configuration)
    }
    
    public func handleEnvironmentChange(_ environment: AxiomCapabilityEnvironment) async {
        _environment = environment
        let adjusted = _configuration.adjusted(for: environment)
        try? await updateConfiguration(adjusted)
    }
    
    public func isSupported() async -> Bool {
        // SwiftUI rendering is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // SwiftUI rendering doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - SwiftUI Rendering Operations
    
    /// Render SwiftUI views
    public func render(_ request: SwiftUIRenderRequest) async throws -> SwiftUIRenderResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        return try await _resources.render(request)
    }
    
    /// Cancel rendering
    public func cancelRender(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        await _resources.cancelRender(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<SwiftUIRenderResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active renders
    public func getActiveRenders() async throws -> [SwiftUIRenderRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        return await _resources.getActiveRenders()
    }
    
    /// Get render history
    public func getRenderHistory(since: Date? = nil) async throws -> [SwiftUIRenderResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        return await _resources.getRenderHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> SwiftUIRenderingMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("SwiftUI Rendering capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple text view request
    public func createTextViewRequest(_ text: String, fontSize: Double = 17.0) -> SwiftUIRenderRequest {
        let textProperty = SwiftUIRenderRequest.ViewDescription.ViewProperty(
            key: "content",
            value: .string(text),
            type: .content
        )
        
        let fontProperty = SwiftUIRenderRequest.ViewDescription.ViewProperty(
            key: "font",
            value: .font(SwiftUIRenderRequest.ViewDescription.ViewProperty.PropertyValue.FontValue(size: fontSize)),
            type: .style
        )
        
        let viewDescription = SwiftUIRenderRequest.ViewDescription(
            viewType: .text,
            properties: ["content": textProperty, "font": fontProperty]
        )
        
        return SwiftUIRenderRequest(viewDescription: viewDescription)
    }
    
    /// Create button view request
    public func createButtonViewRequest(_ title: String, action: String = "default") -> SwiftUIRenderRequest {
        let titleProperty = SwiftUIRenderRequest.ViewDescription.ViewProperty(
            key: "title",
            value: .string(title),
            type: .content
        )
        
        let actionProperty = SwiftUIRenderRequest.ViewDescription.ViewProperty(
            key: "action",
            value: .string(action),
            type: .behavior
        )
        
        let viewDescription = SwiftUIRenderRequest.ViewDescription(
            viewType: .button,
            properties: ["title": titleProperty, "action": actionProperty]
        )
        
        return SwiftUIRenderRequest(viewDescription: viewDescription)
    }
    
    /// Check if rendering is active
    public func hasActiveRenders() async throws -> Bool {
        let activeRenders = try await getActiveRenders()
        return !activeRenders.isEmpty
    }
    
    /// Get average render performance
    public func getAverageRenderTime() async throws -> TimeInterval {
        let metrics = try await getMetrics()
        return metrics.averageRenderTime
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// SwiftUI Rendering specific errors
public enum SwiftUIRenderingError: Error, LocalizedError {
    case renderingDisabled
    case invalidViewDescription
    case layoutCalculationFailed
    case renderingError(String)
    case renderQueued(UUID)
    case renderTimeout(UUID)
    case unsupportedViewType(String)
    case accessibilityValidationFailed
    case performanceThresholdExceeded
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .renderingDisabled:
            return "SwiftUI rendering is disabled"
        case .invalidViewDescription:
            return "Invalid view description provided"
        case .layoutCalculationFailed:
            return "Layout calculation failed"
        case .renderingError(let reason):
            return "SwiftUI rendering failed: \(reason)"
        case .renderQueued(let id):
            return "Render queued: \(id)"
        case .renderTimeout(let id):
            return "Render timeout: \(id)"
        case .unsupportedViewType(let type):
            return "Unsupported view type: \(type)"
        case .accessibilityValidationFailed:
            return "Accessibility validation failed"
        case .performanceThresholdExceeded:
            return "Performance threshold exceeded"
        case .configurationError(let reason):
            return "SwiftUI rendering configuration error: \(reason)"
        }
    }
}