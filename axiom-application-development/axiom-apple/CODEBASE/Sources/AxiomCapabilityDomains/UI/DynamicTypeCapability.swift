import Foundation
import UIKit
import SwiftUI
import AxiomCore
import AxiomCapabilities

// MARK: - Dynamic Type Capability Configuration

/// Configuration for Dynamic Type capability
public struct DynamicTypeCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableDynamicTypeSupport: Bool
    public let enableAutomaticAdjustment: Bool
    public let enableCustomSizing: Bool
    public let enableScaledMetrics: Bool
    public let enableAccessibilitySupport: Bool
    public let enableSwiftUISupport: Bool
    public let enableUIKitSupport: Bool
    public let enableRealTimeUpdates: Bool
    public let maxConcurrentAdjustments: Int
    public let adjustmentTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let scalingBehavior: ScalingBehavior
    public let minimumScaleFactor: Double
    public let maximumScaleFactor: Double
    public let preferredSizeCategory: ContentSizeCategory
    public let fontMetrics: FontMetrics
    public let supportedCategories: [ContentSizeCategory]
    
    public enum ScalingBehavior: String, Codable, CaseIterable {
        case linear = "linear"
        case logarithmic = "logarithmic"
        case stepwise = "stepwise"
        case adaptive = "adaptive"
        case custom = "custom"
    }
    
    public enum ContentSizeCategory: String, Codable, CaseIterable {
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
        case unspecified = "unspecified"
    }
    
    public struct FontMetrics: Codable {
        public let bodySize: Double
        public let headlineSize: Double
        public let subheadlineSize: Double
        public let footnoteSize: Double
        public let captionSize: Double
        public let largeTitle: Double
        public let title1: Double
        public let title2: Double
        public let title3: Double
        public let calloutSize: Double
        
        public init(
            bodySize: Double = 17.0,
            headlineSize: Double = 17.0,
            subheadlineSize: Double = 15.0,
            footnoteSize: Double = 13.0,
            captionSize: Double = 12.0,
            largeTitle: Double = 34.0,
            title1: Double = 28.0,
            title2: Double = 22.0,
            title3: Double = 20.0,
            calloutSize: Double = 16.0
        ) {
            self.bodySize = bodySize
            self.headlineSize = headlineSize
            self.subheadlineSize = subheadlineSize
            self.footnoteSize = footnoteSize
            self.captionSize = captionSize
            self.largeTitle = largeTitle
            self.title1 = title1
            self.title2 = title2
            self.title3 = title3
            self.calloutSize = calloutSize
        }
    }
    
    public init(
        enableDynamicTypeSupport: Bool = true,
        enableAutomaticAdjustment: Bool = true,
        enableCustomSizing: Bool = true,
        enableScaledMetrics: Bool = true,
        enableAccessibilitySupport: Bool = true,
        enableSwiftUISupport: Bool = true,
        enableUIKitSupport: Bool = true,
        enableRealTimeUpdates: Bool = true,
        maxConcurrentAdjustments: Int = 10,
        adjustmentTimeout: TimeInterval = 5.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 100,
        scalingBehavior: ScalingBehavior = .adaptive,
        minimumScaleFactor: Double = 0.75,
        maximumScaleFactor: Double = 3.0,
        preferredSizeCategory: ContentSizeCategory = .large,
        fontMetrics: FontMetrics = FontMetrics(),
        supportedCategories: [ContentSizeCategory] = ContentSizeCategory.allCases
    ) {
        self.enableDynamicTypeSupport = enableDynamicTypeSupport
        self.enableAutomaticAdjustment = enableAutomaticAdjustment
        self.enableCustomSizing = enableCustomSizing
        self.enableScaledMetrics = enableScaledMetrics
        self.enableAccessibilitySupport = enableAccessibilitySupport
        self.enableSwiftUISupport = enableSwiftUISupport
        self.enableUIKitSupport = enableUIKitSupport
        self.enableRealTimeUpdates = enableRealTimeUpdates
        self.maxConcurrentAdjustments = maxConcurrentAdjustments
        self.adjustmentTimeout = adjustmentTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.scalingBehavior = scalingBehavior
        self.minimumScaleFactor = minimumScaleFactor
        self.maximumScaleFactor = maximumScaleFactor
        self.preferredSizeCategory = preferredSizeCategory
        self.fontMetrics = fontMetrics
        self.supportedCategories = supportedCategories
    }
    
    public var isValid: Bool {
        maxConcurrentAdjustments > 0 &&
        adjustmentTimeout > 0 &&
        minimumScaleFactor > 0 &&
        maximumScaleFactor > minimumScaleFactor &&
        cacheSize >= 0 &&
        !supportedCategories.isEmpty
    }
    
    public func merged(with other: DynamicTypeCapabilityConfiguration) -> DynamicTypeCapabilityConfiguration {
        DynamicTypeCapabilityConfiguration(
            enableDynamicTypeSupport: other.enableDynamicTypeSupport,
            enableAutomaticAdjustment: other.enableAutomaticAdjustment,
            enableCustomSizing: other.enableCustomSizing,
            enableScaledMetrics: other.enableScaledMetrics,
            enableAccessibilitySupport: other.enableAccessibilitySupport,
            enableSwiftUISupport: other.enableSwiftUISupport,
            enableUIKitSupport: other.enableUIKitSupport,
            enableRealTimeUpdates: other.enableRealTimeUpdates,
            maxConcurrentAdjustments: other.maxConcurrentAdjustments,
            adjustmentTimeout: other.adjustmentTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            scalingBehavior: other.scalingBehavior,
            minimumScaleFactor: other.minimumScaleFactor,
            maximumScaleFactor: other.maximumScaleFactor,
            preferredSizeCategory: other.preferredSizeCategory,
            fontMetrics: other.fontMetrics,
            supportedCategories: other.supportedCategories
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> DynamicTypeCapabilityConfiguration {
        var adjustedTimeout = adjustmentTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAdjustments = maxConcurrentAdjustments
        var adjustedCacheSize = cacheSize
        var adjustedRealTimeUpdates = enableRealTimeUpdates
        var adjustedScalingBehavior = scalingBehavior
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(adjustmentTimeout, 2.0)
            adjustedConcurrentAdjustments = min(maxConcurrentAdjustments, 3)
            adjustedCacheSize = min(cacheSize, 25)
            adjustedRealTimeUpdates = false
            adjustedScalingBehavior = .linear
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return DynamicTypeCapabilityConfiguration(
            enableDynamicTypeSupport: enableDynamicTypeSupport,
            enableAutomaticAdjustment: enableAutomaticAdjustment,
            enableCustomSizing: enableCustomSizing,
            enableScaledMetrics: enableScaledMetrics,
            enableAccessibilitySupport: enableAccessibilitySupport,
            enableSwiftUISupport: enableSwiftUISupport,
            enableUIKitSupport: enableUIKitSupport,
            enableRealTimeUpdates: adjustedRealTimeUpdates,
            maxConcurrentAdjustments: adjustedConcurrentAdjustments,
            adjustmentTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            scalingBehavior: adjustedScalingBehavior,
            minimumScaleFactor: minimumScaleFactor,
            maximumScaleFactor: maximumScaleFactor,
            preferredSizeCategory: preferredSizeCategory,
            fontMetrics: fontMetrics,
            supportedCategories: supportedCategories
        )
    }
}

// MARK: - Dynamic Type Types

/// Dynamic type adjustment request
public struct DynamicTypeAdjustmentRequest: Sendable, Identifiable {
    public let id: UUID
    public let target: AdjustmentTarget
    public let adjustmentType: AdjustmentType
    public let targetCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory
    public let options: AdjustmentOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct AdjustmentTarget: Sendable {
        public let targetType: TargetType
        public let identifier: String
        public let fontDescriptors: [FontDescriptor]
        public let textElements: [TextElement]
        public let layoutConstraints: [ConstraintDescriptor]?
        
        public enum TargetType: String, Sendable, CaseIterable {
            case singleFont = "singleFont"
            case fontCollection = "fontCollection"
            case textElement = "textElement"
            case viewHierarchy = "viewHierarchy"
            case application = "application"
            case customElement = "customElement"
        }
        
        public struct FontDescriptor: Sendable {
            public let fontId: String
            public let familyName: String
            public let pointSize: Double
            public let weight: FontWeight
            public let design: FontDesign
            public let textStyle: TextStyle
            public let isScalable: Bool
            public let minimumSize: Double?
            public let maximumSize: Double?
            
            public enum FontWeight: String, Sendable, CaseIterable {
                case ultraLight = "ultraLight"
                case thin = "thin"
                case light = "light"
                case regular = "regular"
                case medium = "medium"
                case semibold = "semibold"
                case bold = "bold"
                case heavy = "heavy"
                case black = "black"
            }
            
            public enum FontDesign: String, Sendable, CaseIterable {
                case `default` = "default"
                case serif = "serif"
                case rounded = "rounded"
                case monospaced = "monospaced"
            }
            
            public enum TextStyle: String, Sendable, CaseIterable {
                case largeTitle = "largeTitle"
                case title1 = "title1"
                case title2 = "title2"
                case title3 = "title3"
                case headline = "headline"
                case subheadline = "subheadline"
                case body = "body"
                case callout = "callout"
                case footnote = "footnote"
                case caption1 = "caption1"
                case caption2 = "caption2"
                case custom = "custom"
            }
            
            public init(fontId: String, familyName: String, pointSize: Double, weight: FontWeight = .regular, design: FontDesign = .default, textStyle: TextStyle = .body, isScalable: Bool = true, minimumSize: Double? = nil, maximumSize: Double? = nil) {
                self.fontId = fontId
                self.familyName = familyName
                self.pointSize = pointSize
                self.weight = weight
                self.design = design
                self.textStyle = textStyle
                self.isScalable = isScalable
                self.minimumSize = minimumSize
                self.maximumSize = maximumSize
            }
        }
        
        public struct TextElement: Sendable {
            public let elementId: String
            public let elementType: ElementType
            public let currentFont: FontDescriptor
            public let text: String
            public let frame: CGRect
            public let numberOfLines: Int
            public let lineBreakMode: LineBreakMode
            public let alignment: TextAlignment
            public let truncationMode: TruncationMode
            
            public enum ElementType: String, Sendable, CaseIterable {
                case label = "label"
                case button = "button"
                case textField = "textField"
                case textView = "textView"
                case navigationTitle = "navigationTitle"
                case tabBarItem = "tabBarItem"
                case alertTitle = "alertTitle"
                case alertMessage = "alertMessage"
                case custom = "custom"
            }
            
            public enum LineBreakMode: String, Sendable, CaseIterable {
                case byWordWrapping = "byWordWrapping"
                case byCharWrapping = "byCharWrapping"
                case byClipping = "byClipping"
                case byTruncatingHead = "byTruncatingHead"
                case byTruncatingTail = "byTruncatingTail"
                case byTruncatingMiddle = "byTruncatingMiddle"
            }
            
            public enum TextAlignment: String, Sendable, CaseIterable {
                case leading = "leading"
                case center = "center"
                case trailing = "trailing"
                case justified = "justified"
                case natural = "natural"
            }
            
            public enum TruncationMode: String, Sendable, CaseIterable {
                case head = "head"
                case tail = "tail"
                case middle = "middle"
                case none = "none"
            }
            
            public init(elementId: String, elementType: ElementType, currentFont: FontDescriptor, text: String, frame: CGRect, numberOfLines: Int = 1, lineBreakMode: LineBreakMode = .byTruncatingTail, alignment: TextAlignment = .natural, truncationMode: TruncationMode = .tail) {
                self.elementId = elementId
                self.elementType = elementType
                self.currentFont = currentFont
                self.text = text
                self.frame = frame
                self.numberOfLines = numberOfLines
                self.lineBreakMode = lineBreakMode
                self.alignment = alignment
                self.truncationMode = truncationMode
            }
        }
        
        public struct ConstraintDescriptor: Sendable {
            public let constraintId: String
            public let constraintType: ConstraintType
            public let constant: Double
            public let multiplier: Double
            public let priority: Double
            public let isActive: Bool
            public let affectedByDynamicType: Bool
            
            public enum ConstraintType: String, Sendable, CaseIterable {
                case height = "height"
                case width = "width"
                case leading = "leading"
                case trailing = "trailing"
                case top = "top"
                case bottom = "bottom"
                case centerX = "centerX"
                case centerY = "centerY"
                case aspectRatio = "aspectRatio"
                case baseline = "baseline"
            }
            
            public init(constraintId: String, constraintType: ConstraintType, constant: Double, multiplier: Double = 1.0, priority: Double = 1000.0, isActive: Bool = true, affectedByDynamicType: Bool = false) {
                self.constraintId = constraintId
                self.constraintType = constraintType
                self.constant = constant
                self.multiplier = multiplier
                self.priority = priority
                self.isActive = isActive
                self.affectedByDynamicType = affectedByDynamicType
            }
        }
        
        public init(targetType: TargetType, identifier: String, fontDescriptors: [FontDescriptor], textElements: [TextElement], layoutConstraints: [ConstraintDescriptor]? = nil) {
            self.targetType = targetType
            self.identifier = identifier
            self.fontDescriptors = fontDescriptors
            self.textElements = textElements
            self.layoutConstraints = layoutConstraints
        }
    }
    
    public enum AdjustmentType: String, Sendable, CaseIterable {
        case scaleToCategory = "scaleToCategory"
        case scaleToSize = "scaleToSize"
        case applyMetrics = "applyMetrics"
        case updateConstraints = "updateConstraints"
        case fullAdjustment = "fullAdjustment"
        case preview = "preview"
        case restore = "restore"
    }
    
    public struct AdjustmentOptions: Sendable {
        public let preserveAspectRatio: Bool
        public let adjustConstraints: Bool
        public let animateChanges: Bool
        public let animationDuration: TimeInterval
        public let updateImmediate: Bool
        public let respectMinimumSizes: Bool
        public let respectMaximumSizes: Bool
        public let scalingBehavior: DynamicTypeCapabilityConfiguration.ScalingBehavior
        public let customScaleFactor: Double?
        
        public init(preserveAspectRatio: Bool = true, adjustConstraints: Bool = true, animateChanges: Bool = true, animationDuration: TimeInterval = 0.25, updateImmediate: Bool = false, respectMinimumSizes: Bool = true, respectMaximumSizes: Bool = true, scalingBehavior: DynamicTypeCapabilityConfiguration.ScalingBehavior = .adaptive, customScaleFactor: Double? = nil) {
            self.preserveAspectRatio = preserveAspectRatio
            self.adjustConstraints = adjustConstraints
            self.animateChanges = animateChanges
            self.animationDuration = animationDuration
            self.updateImmediate = updateImmediate
            self.respectMinimumSizes = respectMinimumSizes
            self.respectMaximumSizes = respectMaximumSizes
            self.scalingBehavior = scalingBehavior
            self.customScaleFactor = customScaleFactor
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(target: AdjustmentTarget, adjustmentType: AdjustmentType = .fullAdjustment, targetCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory, options: AdjustmentOptions = AdjustmentOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.target = target
        self.adjustmentType = adjustmentType
        self.targetCategory = targetCategory
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Dynamic type adjustment result
public struct DynamicTypeAdjustmentResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let adjustedFonts: [AdjustedFont]
    public let adjustedElements: [AdjustedElement]
    public let adjustedConstraints: [AdjustedConstraint]
    public let scalingMetrics: ScalingMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: DynamicTypeError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AdjustedFont: Sendable {
        public let originalFont: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor
        public let adjustedFont: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor
        public let scaleFactor: Double
        public let actualSize: Double
        public let wasConstrained: Bool
        public let adjustmentReason: AdjustmentReason
        
        public enum AdjustmentReason: String, Sendable, CaseIterable {
            case categoryChange = "categoryChange"
            case minimumSizeConstraint = "minimumSizeConstraint"
            case maximumSizeConstraint = "maximumSizeConstraint"
            case accessibilityRequirement = "accessibilityRequirement"
            case customScaling = "customScaling"
            case preserveReadability = "preserveReadability"
        }
        
        public init(originalFont: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor, adjustedFont: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor, scaleFactor: Double, actualSize: Double, wasConstrained: Bool, adjustmentReason: AdjustmentReason) {
            self.originalFont = originalFont
            self.adjustedFont = adjustedFont
            self.scaleFactor = scaleFactor
            self.actualSize = actualSize
            self.wasConstrained = wasConstrained
            self.adjustmentReason = adjustmentReason
        }
    }
    
    public struct AdjustedElement: Sendable {
        public let originalElement: DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement
        public let adjustedElement: DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement
        public let newFrame: CGRect
        public let contentDidFit: Bool
        public let requiredLines: Int
        public let truncationOccurred: Bool
        
        public init(originalElement: DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement, adjustedElement: DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement, newFrame: CGRect, contentDidFit: Bool, requiredLines: Int, truncationOccurred: Bool) {
            self.originalElement = originalElement
            self.adjustedElement = adjustedElement
            self.newFrame = newFrame
            self.contentDidFit = contentDidFit
            self.requiredLines = requiredLines
            self.truncationOccurred = truncationOccurred
        }
    }
    
    public struct AdjustedConstraint: Sendable {
        public let originalConstraint: DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor
        public let adjustedConstraint: DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor
        public let adjustmentApplied: Bool
        public let adjustmentRatio: Double
        
        public init(originalConstraint: DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor, adjustedConstraint: DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor, adjustmentApplied: Bool, adjustmentRatio: Double) {
            self.originalConstraint = originalConstraint
            self.adjustedConstraint = adjustedConstraint
            self.adjustmentApplied = adjustmentApplied
            self.adjustmentRatio = adjustmentRatio
        }
    }
    
    public struct ScalingMetrics: Sendable {
        public let overallScaleFactor: Double
        public let averageFontSizeIncrease: Double
        public let elementsFitted: Int
        public let elementsTruncated: Int
        public let constraintsAdjusted: Int
        public let accessibilityCompliance: Double
        public let readabilityScore: Double
        public let layoutStability: Double
        
        public init(overallScaleFactor: Double, averageFontSizeIncrease: Double, elementsFitted: Int, elementsTruncated: Int, constraintsAdjusted: Int, accessibilityCompliance: Double, readabilityScore: Double, layoutStability: Double) {
            self.overallScaleFactor = overallScaleFactor
            self.averageFontSizeIncrease = averageFontSizeIncrease
            self.elementsFitted = elementsFitted
            self.elementsTruncated = elementsTruncated
            self.constraintsAdjusted = constraintsAdjusted
            self.accessibilityCompliance = accessibilityCompliance
            self.readabilityScore = readabilityScore
            self.layoutStability = layoutStability
        }
    }
    
    public init(requestId: UUID, adjustedFonts: [AdjustedFont], adjustedElements: [AdjustedElement], adjustedConstraints: [AdjustedConstraint], scalingMetrics: ScalingMetrics, processingTime: TimeInterval, success: Bool, error: DynamicTypeError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.adjustedFonts = adjustedFonts
        self.adjustedElements = adjustedElements
        self.adjustedConstraints = adjustedConstraints
        self.scalingMetrics = scalingMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var adjustmentQuality: Double {
        let fittedRatio = scalingMetrics.elementsTruncated > 0 ? 
            Double(scalingMetrics.elementsFitted) / Double(scalingMetrics.elementsFitted + scalingMetrics.elementsTruncated) : 1.0
        return (fittedRatio + scalingMetrics.readabilityScore + scalingMetrics.layoutStability) / 3.0
    }
    
    public var hasSignificantChanges: Bool {
        scalingMetrics.overallScaleFactor > 1.1 || scalingMetrics.overallScaleFactor < 0.9
    }
}

/// Dynamic type capability metrics
public struct DynamicTypeCapabilityMetrics: Sendable {
    public let totalAdjustments: Int
    public let successfulAdjustments: Int
    public let failedAdjustments: Int
    public let averageProcessingTime: TimeInterval
    public let adjustmentsByCategory: [String: Int]
    public let adjustmentsByType: [String: Int]
    public let averageScaleFactor: Double
    public let averageReadabilityScore: Double
    public let errorsByType: [String: Int]
    public let throughputPerMinute: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let fastestAdjustment: TimeInterval
        public let slowestAdjustment: TimeInterval
        public let averageFontsPerAdjustment: Double
        public let averageElementsPerAdjustment: Double
        public let totalConstraintsAdjusted: Int
        public let accessibilityImprovementRate: Double
        
        public init(fastestAdjustment: TimeInterval = 0, slowestAdjustment: TimeInterval = 0, averageFontsPerAdjustment: Double = 0, averageElementsPerAdjustment: Double = 0, totalConstraintsAdjusted: Int = 0, accessibilityImprovementRate: Double = 0) {
            self.fastestAdjustment = fastestAdjustment
            self.slowestAdjustment = slowestAdjustment
            self.averageFontsPerAdjustment = averageFontsPerAdjustment
            self.averageElementsPerAdjustment = averageElementsPerAdjustment
            self.totalConstraintsAdjusted = totalConstraintsAdjusted
            self.accessibilityImprovementRate = accessibilityImprovementRate
        }
    }
    
    public init(totalAdjustments: Int = 0, successfulAdjustments: Int = 0, failedAdjustments: Int = 0, averageProcessingTime: TimeInterval = 0, adjustmentsByCategory: [String: Int] = [:], adjustmentsByType: [String: Int] = [:], averageScaleFactor: Double = 1.0, averageReadabilityScore: Double = 0, errorsByType: [String: Int] = [:], throughputPerMinute: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalAdjustments = totalAdjustments
        self.successfulAdjustments = successfulAdjustments
        self.failedAdjustments = failedAdjustments
        self.averageProcessingTime = averageProcessingTime
        self.adjustmentsByCategory = adjustmentsByCategory
        self.adjustmentsByType = adjustmentsByType
        self.averageScaleFactor = averageScaleFactor
        self.averageReadabilityScore = averageReadabilityScore
        self.errorsByType = errorsByType
        self.throughputPerMinute = averageProcessingTime > 0 ? 60.0 / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalAdjustments > 0 ? Double(successfulAdjustments) / Double(totalAdjustments) : 0
    }
}

// MARK: - Dynamic Type Resource

/// Dynamic type resource management
@available(iOS 13.0, macOS 10.15, *)
public actor DynamicTypeCapabilityResource: AxiomCapabilityResource {
    private let configuration: DynamicTypeCapabilityConfiguration
    private var activeAdjustments: [UUID: DynamicTypeAdjustmentRequest] = [:]
    private var adjustmentHistory: [DynamicTypeAdjustmentResult] = [:]
    private var resultCache: [String: DynamicTypeAdjustmentResult] = [:]
    private var scalingEngine: ScalingEngine = ScalingEngine()
    private var fontAdjuster: FontAdjuster = FontAdjuster()
    private var constraintAdjuster: ConstraintAdjuster = ConstraintAdjuster()
    private var metricsCalculator: MetricsCalculator = MetricsCalculator()
    private var metrics: DynamicTypeCapabilityMetrics = DynamicTypeCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<DynamicTypeAdjustmentResult>.Continuation?
    
    // Helper classes for dynamic type processing
    private class ScalingEngine {
        func calculateScaleFactor(
            from currentCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory,
            to targetCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory,
            behavior: DynamicTypeCapabilityConfiguration.ScalingBehavior
        ) -> Double {
            let currentValue = categoryScaleValue(currentCategory)
            let targetValue = categoryScaleValue(targetCategory)
            
            switch behavior {
            case .linear:
                return targetValue / currentValue
            case .logarithmic:
                return log(targetValue + 1) / log(currentValue + 1)
            case .stepwise:
                return stepwiseScale(from: currentValue, to: targetValue)
            case .adaptive:
                return adaptiveScale(from: currentValue, to: targetValue)
            case .custom:
                return targetValue / currentValue // Default to linear for custom
            }
        }
        
        private func categoryScaleValue(_ category: DynamicTypeCapabilityConfiguration.ContentSizeCategory) -> Double {
            switch category {
            case .extraSmall: return 0.8
            case .small: return 0.9
            case .medium: return 0.95
            case .large: return 1.0
            case .extraLarge: return 1.15
            case .extraExtraLarge: return 1.3
            case .extraExtraExtraLarge: return 1.5
            case .accessibilityMedium: return 1.7
            case .accessibilityLarge: return 2.0
            case .accessibilityExtraLarge: return 2.3
            case .accessibilityExtraExtraLarge: return 2.7
            case .accessibilityExtraExtraExtraLarge: return 3.0
            case .unspecified: return 1.0
            }
        }
        
        private func stepwiseScale(from current: Double, to target: Double) -> Double {
            let ratio = target / current
            if ratio <= 1.1 { return 1.0 }
            else if ratio <= 1.3 { return 1.2 }
            else if ratio <= 1.7 { return 1.5 }
            else if ratio <= 2.2 { return 2.0 }
            else { return 3.0 }
        }
        
        private func adaptiveScale(from current: Double, to target: Double) -> Double {
            let baseRatio = target / current
            
            // Apply smoothing for better readability
            if baseRatio > 1.0 {
                return 1.0 + (baseRatio - 1.0) * 0.85
            } else {
                return current - (current - target) * 0.9
            }
        }
    }
    
    private class FontAdjuster {
        func adjustFont(
            _ font: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor,
            scaleFactor: Double,
            configuration: DynamicTypeCapabilityConfiguration
        ) -> DynamicTypeAdjustmentResult.AdjustedFont {
            
            let targetSize = font.pointSize * scaleFactor
            
            // Apply constraints
            var finalSize = targetSize
            var wasConstrained = false
            var adjustmentReason: DynamicTypeAdjustmentResult.AdjustedFont.AdjustmentReason = .categoryChange
            
            if let minSize = font.minimumSize, finalSize < minSize {
                finalSize = minSize
                wasConstrained = true
                adjustmentReason = .minimumSizeConstraint
            }
            
            if let maxSize = font.maximumSize, finalSize > maxSize {
                finalSize = maxSize
                wasConstrained = true
                adjustmentReason = .maximumSizeConstraint
            }
            
            // Apply global constraints
            if finalSize < font.pointSize * configuration.minimumScaleFactor {
                finalSize = font.pointSize * configuration.minimumScaleFactor
                wasConstrained = true
                adjustmentReason = .minimumSizeConstraint
            }
            
            if finalSize > font.pointSize * configuration.maximumScaleFactor {
                finalSize = font.pointSize * configuration.maximumScaleFactor
                wasConstrained = true
                adjustmentReason = .maximumSizeConstraint
            }
            
            let adjustedFont = DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor(
                fontId: font.fontId,
                familyName: font.familyName,
                pointSize: finalSize,
                weight: font.weight,
                design: font.design,
                textStyle: font.textStyle,
                isScalable: font.isScalable,
                minimumSize: font.minimumSize,
                maximumSize: font.maximumSize
            )
            
            return DynamicTypeAdjustmentResult.AdjustedFont(
                originalFont: font,
                adjustedFont: adjustedFont,
                scaleFactor: finalSize / font.pointSize,
                actualSize: finalSize,
                wasConstrained: wasConstrained,
                adjustmentReason: adjustmentReason
            )
        }
    }
    
    private class ConstraintAdjuster {
        func adjustConstraints(
            _ constraints: [DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor],
            scaleFactor: Double,
            options: DynamicTypeAdjustmentRequest.AdjustmentOptions
        ) -> [DynamicTypeAdjustmentResult.AdjustedConstraint] {
            
            return constraints.map { constraint in
                var adjustedConstraint = constraint
                var adjustmentApplied = false
                var adjustmentRatio = 1.0
                
                if constraint.affectedByDynamicType && options.adjustConstraints {
                    switch constraint.constraintType {
                    case .height, .width:
                        adjustedConstraint = DynamicTypeAdjustmentRequest.AdjustmentTarget.ConstraintDescriptor(
                            constraintId: constraint.constraintId,
                            constraintType: constraint.constraintType,
                            constant: constraint.constant * scaleFactor,
                            multiplier: constraint.multiplier,
                            priority: constraint.priority,
                            isActive: constraint.isActive,
                            affectedByDynamicType: constraint.affectedByDynamicType
                        )
                        adjustmentApplied = true
                        adjustmentRatio = scaleFactor
                    default:
                        // Other constraints remain unchanged for now
                        break
                    }
                }
                
                return DynamicTypeAdjustmentResult.AdjustedConstraint(
                    originalConstraint: constraint,
                    adjustedConstraint: adjustedConstraint,
                    adjustmentApplied: adjustmentApplied,
                    adjustmentRatio: adjustmentRatio
                )
            }
        }
    }
    
    private class MetricsCalculator {
        func calculateMetrics(
            adjustedFonts: [DynamicTypeAdjustmentResult.AdjustedFont],
            adjustedElements: [DynamicTypeAdjustmentResult.AdjustedElement],
            adjustedConstraints: [DynamicTypeAdjustmentResult.AdjustedConstraint]
        ) -> DynamicTypeAdjustmentResult.ScalingMetrics {
            
            let overallScaleFactor = adjustedFonts.isEmpty ? 1.0 : 
                adjustedFonts.reduce(0) { $0 + $1.scaleFactor } / Double(adjustedFonts.count)
            
            let averageFontSizeIncrease = adjustedFonts.reduce(0) { sum, font in
                sum + (font.adjustedFont.pointSize - font.originalFont.pointSize)
            } / Double(max(adjustedFonts.count, 1))
            
            let elementsFitted = adjustedElements.filter { $0.contentDidFit }.count
            let elementsTruncated = adjustedElements.filter { $0.truncationOccurred }.count
            let constraintsAdjusted = adjustedConstraints.filter { $0.adjustmentApplied }.count
            
            // Calculate accessibility compliance (simplified)
            let accessibilityCompliance = calculateAccessibilityCompliance(adjustedFonts: adjustedFonts)
            
            // Calculate readability score
            let readabilityScore = calculateReadabilityScore(adjustedFonts: adjustedFonts, adjustedElements: adjustedElements)
            
            // Calculate layout stability
            let layoutStability = calculateLayoutStability(adjustedElements: adjustedElements, adjustedConstraints: adjustedConstraints)
            
            return DynamicTypeAdjustmentResult.ScalingMetrics(
                overallScaleFactor: overallScaleFactor,
                averageFontSizeIncrease: averageFontSizeIncrease,
                elementsFitted: elementsFitted,
                elementsTruncated: elementsTruncated,
                constraintsAdjusted: constraintsAdjusted,
                accessibilityCompliance: accessibilityCompliance,
                readabilityScore: readabilityScore,
                layoutStability: layoutStability
            )
        }
        
        private func calculateAccessibilityCompliance(adjustedFonts: [DynamicTypeAdjustmentResult.AdjustedFont]) -> Double {
            // Check if fonts meet accessibility guidelines
            let compliantFonts = adjustedFonts.filter { font in
                font.adjustedFont.pointSize >= 12.0 // Minimum readable size
            }
            
            return adjustedFonts.isEmpty ? 1.0 : Double(compliantFonts.count) / Double(adjustedFonts.count)
        }
        
        private func calculateReadabilityScore(
            adjustedFonts: [DynamicTypeAdjustmentResult.AdjustedFont],
            adjustedElements: [DynamicTypeAdjustmentResult.AdjustedElement]
        ) -> Double {
            // Simplified readability calculation based on font sizes and element fitting
            let fontReadability = adjustedFonts.reduce(0.0) { score, font in
                let sizeScore = min(1.0, font.adjustedFont.pointSize / 17.0) // 17pt is standard body size
                return score + sizeScore
            } / Double(max(adjustedFonts.count, 1))
            
            let elementReadability = adjustedElements.reduce(0.0) { score, element in
                return score + (element.contentDidFit ? 1.0 : 0.5)
            } / Double(max(adjustedElements.count, 1))
            
            return (fontReadability + elementReadability) / 2.0
        }
        
        private func calculateLayoutStability(
            adjustedElements: [DynamicTypeAdjustmentResult.AdjustedElement],
            adjustedConstraints: [DynamicTypeAdjustmentResult.AdjustedConstraint]
        ) -> Double {
            // Calculate how much the layout changed
            let elementStability = adjustedElements.reduce(0.0) { stability, element in
                let frameChange = abs(element.newFrame.height - element.originalElement.frame.height) / 
                    max(element.originalElement.frame.height, 1.0)
                return stability + max(0.0, 1.0 - frameChange)
            } / Double(max(adjustedElements.count, 1))
            
            let constraintStability = adjustedConstraints.reduce(0.0) { stability, constraint in
                return stability + (constraint.adjustmentApplied ? 0.8 : 1.0)
            } / Double(max(adjustedConstraints.count, 1))
            
            return (elementStability + constraintStability) / 2.0
        }
    }
    
    public init(configuration: DynamicTypeCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 100_000_000, // 100MB for dynamic type processing
            cpu: 2.0, // Moderate CPU usage for font and layout calculations
            bandwidth: 0,
            storage: 30_000_000 // 30MB for font metrics and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let adjustmentMemory = activeAdjustments.count * 10_000_000 // ~10MB per active adjustment
            let cacheMemory = resultCache.count * 50_000 // ~50KB per cached result
            let historyMemory = adjustmentHistory.count * 25_000
            let fontMemory = 20_000_000 // Font scaling engine overhead
            
            return ResourceUsage(
                memory: adjustmentMemory + cacheMemory + historyMemory + fontMemory,
                cpu: activeAdjustments.isEmpty ? 0.1 : 1.5,
                bandwidth: 0,
                storage: resultCache.count * 25_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Dynamic type is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableDynamicTypeSupport
        }
        return false
    }
    
    public func release() async {
        activeAdjustments.removeAll()
        adjustmentHistory.removeAll()
        resultCache.removeAll()
        
        scalingEngine = ScalingEngine()
        fontAdjuster = FontAdjuster()
        constraintAdjuster = ConstraintAdjuster()
        metricsCalculator = MetricsCalculator()
        
        resultStreamContinuation?.finish()
        
        metrics = DynamicTypeCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        scalingEngine = ScalingEngine()
        fontAdjuster = FontAdjuster()
        constraintAdjuster = ConstraintAdjuster()
        metricsCalculator = MetricsCalculator()
        
        if configuration.enableLogging {
            print("[DynamicType] 🚀 Dynamic Type capability initialized")
            print("[DynamicType] 📏 Scaling behavior: \(configuration.scalingBehavior.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: DynamicTypeCapabilityConfiguration) async throws {
        // Update dynamic type configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<DynamicTypeAdjustmentResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Dynamic Type Processing
    
    public func performAdjustment(_ request: DynamicTypeAdjustmentRequest) async throws -> DynamicTypeAdjustmentResult {
        guard configuration.enableDynamicTypeSupport else {
            throw DynamicTypeError.dynamicTypeDisabled
        }
        
        // Check cache first
        if configuration.enableCaching {
            let cacheKey = generateCacheKey(for: request)
            if let cachedResult = resultCache[cacheKey] {
                await updateCacheHitMetrics()
                return cachedResult
            }
        }
        
        let startTime = Date()
        activeAdjustments[request.id] = request
        
        do {
            // Calculate scale factor
            let scaleFactor = scalingEngine.calculateScaleFactor(
                from: configuration.preferredSizeCategory,
                to: request.targetCategory,
                behavior: configuration.scalingBehavior
            )
            
            // Adjust fonts
            let adjustedFonts = request.target.fontDescriptors.map { font in
                fontAdjuster.adjustFont(font, scaleFactor: scaleFactor, configuration: configuration)
            }
            
            // Adjust elements (simulate text layout)
            let adjustedElements = request.target.textElements.map { element in
                adjustElement(element, scaleFactor: scaleFactor, options: request.options)
            }
            
            // Adjust constraints
            let adjustedConstraints = request.target.layoutConstraints?.compactMap { constraints in
                constraintAdjuster.adjustConstraints(constraints, scaleFactor: scaleFactor, options: request.options)
            }.flatMap { $0 } ?? []
            
            // Calculate metrics
            let scalingMetrics = metricsCalculator.calculateMetrics(
                adjustedFonts: adjustedFonts,
                adjustedElements: adjustedElements,
                adjustedConstraints: adjustedConstraints
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = DynamicTypeAdjustmentResult(
                requestId: request.id,
                adjustedFonts: adjustedFonts,
                adjustedElements: adjustedElements,
                adjustedConstraints: adjustedConstraints,
                scalingMetrics: scalingMetrics,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeAdjustments.removeValue(forKey: request.id)
            adjustmentHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logAdjustment(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = DynamicTypeAdjustmentResult(
                requestId: request.id,
                adjustedFonts: [],
                adjustedElements: [],
                adjustedConstraints: [],
                scalingMetrics: DynamicTypeAdjustmentResult.ScalingMetrics(
                    overallScaleFactor: 1.0,
                    averageFontSizeIncrease: 0,
                    elementsFitted: 0,
                    elementsTruncated: 0,
                    constraintsAdjusted: 0,
                    accessibilityCompliance: 0,
                    readabilityScore: 0,
                    layoutStability: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? DynamicTypeError ?? DynamicTypeError.adjustmentFailed(error.localizedDescription)
            )
            
            activeAdjustments.removeValue(forKey: request.id)
            adjustmentHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logAdjustment(result)
            }
            
            throw error
        }
    }
    
    public func getActiveAdjustments() async -> [DynamicTypeAdjustmentRequest] {
        return Array(activeAdjustments.values)
    }
    
    public func getAdjustmentHistory(since: Date? = nil) async -> [DynamicTypeAdjustmentResult] {
        if let since = since {
            return adjustmentHistory.filter { $0.timestamp >= since }
        }
        return adjustmentHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> DynamicTypeCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = DynamicTypeCapabilityMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func adjustElement(
        _ element: DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement,
        scaleFactor: Double,
        options: DynamicTypeAdjustmentRequest.AdjustmentOptions
    ) -> DynamicTypeAdjustmentResult.AdjustedElement {
        
        // Adjust font
        let adjustedFont = fontAdjuster.adjustFont(element.currentFont, scaleFactor: scaleFactor, configuration: configuration)
        
        // Simulate text layout calculation
        let originalHeight = element.frame.height
        let estimatedNewHeight = originalHeight * scaleFactor
        let newFrame = CGRect(
            x: element.frame.origin.x,
            y: element.frame.origin.y,
            width: element.frame.width,
            height: estimatedNewHeight
        )
        
        // Estimate if content fits
        let contentDidFit = estimatedNewHeight <= originalHeight * 1.2 || element.numberOfLines == 0
        let requiredLines = max(1, Int(ceil(estimatedNewHeight / (adjustedFont.adjustedFont.pointSize * 1.2))))
        let truncationOccurred = !contentDidFit && element.numberOfLines > 0 && requiredLines > element.numberOfLines
        
        let adjustedElement = DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement(
            elementId: element.elementId,
            elementType: element.elementType,
            currentFont: adjustedFont.adjustedFont,
            text: element.text,
            frame: newFrame,
            numberOfLines: element.numberOfLines,
            lineBreakMode: element.lineBreakMode,
            alignment: element.alignment,
            truncationMode: element.truncationMode
        )
        
        return DynamicTypeAdjustmentResult.AdjustedElement(
            originalElement: element,
            adjustedElement: adjustedElement,
            newFrame: newFrame,
            contentDidFit: contentDidFit,
            requiredLines: requiredLines,
            truncationOccurred: truncationOccurred
        )
    }
    
    private func generateCacheKey(for request: DynamicTypeAdjustmentRequest) -> String {
        let targetHash = request.target.identifier.hashValue
        let categoryHash = request.targetCategory.rawValue.hashValue
        let typeHash = request.adjustmentType.rawValue.hashValue
        
        return "\(targetHash)_\(categoryHash)_\(typeHash)"
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit metrics
    }
    
    private func updateSuccessMetrics(_ result: DynamicTypeAdjustmentResult) async {
        let totalAdjustments = metrics.totalAdjustments + 1
        let successfulAdjustments = metrics.successfulAdjustments + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAdjustments)) + result.processingTime) / Double(totalAdjustments)
        let newAverageScaleFactor = ((metrics.averageScaleFactor * Double(metrics.successfulAdjustments)) + result.scalingMetrics.overallScaleFactor) / Double(successfulAdjustments)
        let newAverageReadabilityScore = ((metrics.averageReadabilityScore * Double(metrics.successfulAdjustments)) + result.scalingMetrics.readabilityScore) / Double(successfulAdjustments)
        
        var adjustmentsByCategory = metrics.adjustmentsByCategory
        adjustmentsByCategory["dynamicType", default: 0] += 1
        
        var adjustmentsByType = metrics.adjustmentsByType
        adjustmentsByType["fontScaling", default: 0] += 1
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let fastestAdjustment = metrics.successfulAdjustments == 0 ? result.processingTime : min(performanceStats.fastestAdjustment, result.processingTime)
        let slowestAdjustment = max(performanceStats.slowestAdjustment, result.processingTime)
        let newAverageFontsPerAdjustment = ((performanceStats.averageFontsPerAdjustment * Double(metrics.successfulAdjustments)) + Double(result.adjustedFonts.count)) / Double(successfulAdjustments)
        let newAverageElementsPerAdjustment = ((performanceStats.averageElementsPerAdjustment * Double(metrics.successfulAdjustments)) + Double(result.adjustedElements.count)) / Double(successfulAdjustments)
        let totalConstraintsAdjusted = performanceStats.totalConstraintsAdjusted + result.scalingMetrics.constraintsAdjusted
        let newAccessibilityImprovementRate = ((performanceStats.accessibilityImprovementRate * Double(metrics.successfulAdjustments)) + result.scalingMetrics.accessibilityCompliance) / Double(successfulAdjustments)
        
        performanceStats = DynamicTypeCapabilityMetrics.PerformanceStats(
            fastestAdjustment: fastestAdjustment,
            slowestAdjustment: slowestAdjustment,
            averageFontsPerAdjustment: newAverageFontsPerAdjustment,
            averageElementsPerAdjustment: newAverageElementsPerAdjustment,
            totalConstraintsAdjusted: totalConstraintsAdjusted,
            accessibilityImprovementRate: newAccessibilityImprovementRate
        )
        
        metrics = DynamicTypeCapabilityMetrics(
            totalAdjustments: totalAdjustments,
            successfulAdjustments: successfulAdjustments,
            failedAdjustments: metrics.failedAdjustments,
            averageProcessingTime: newAverageProcessingTime,
            adjustmentsByCategory: adjustmentsByCategory,
            adjustmentsByType: adjustmentsByType,
            averageScaleFactor: newAverageScaleFactor,
            averageReadabilityScore: newAverageReadabilityScore,
            errorsByType: metrics.errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: DynamicTypeAdjustmentResult) async {
        let totalAdjustments = metrics.totalAdjustments + 1
        let failedAdjustments = metrics.failedAdjustments + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = DynamicTypeCapabilityMetrics(
            totalAdjustments: totalAdjustments,
            successfulAdjustments: metrics.successfulAdjustments,
            failedAdjustments: failedAdjustments,
            averageProcessingTime: metrics.averageProcessingTime,
            adjustmentsByCategory: metrics.adjustmentsByCategory,
            adjustmentsByType: metrics.adjustmentsByType,
            averageScaleFactor: metrics.averageScaleFactor,
            averageReadabilityScore: metrics.averageReadabilityScore,
            errorsByType: errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logAdjustment(_ result: DynamicTypeAdjustmentResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let scaleStr = String(format: "%.2f", result.scalingMetrics.overallScaleFactor)
        let fontCount = result.adjustedFonts.count
        let elementCount = result.adjustedElements.count
        let qualityStr = String(format: "%.1f", result.adjustmentQuality * 100)
        
        print("[DynamicType] \(statusIcon) Adjustment: \(scaleStr)x scale, \(fontCount) fonts, \(elementCount) elements, \(qualityStr)% quality (\(timeStr)s)")
        
        if let error = result.error {
            print("[DynamicType] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Dynamic Type Capability Implementation

/// Dynamic Type capability providing dynamic font sizing support
@available(iOS 13.0, macOS 10.15, *)
public actor DynamicTypeCapability: DomainCapability {
    public typealias ConfigurationType = DynamicTypeCapabilityConfiguration
    public typealias ResourceType = DynamicTypeCapabilityResource
    
    private var _configuration: DynamicTypeCapabilityConfiguration
    private var _resources: DynamicTypeCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "dynamic-type-capability" }
    
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
    
    public var configuration: DynamicTypeCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: DynamicTypeCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: DynamicTypeCapabilityConfiguration = DynamicTypeCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = DynamicTypeCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: DynamicTypeCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Dynamic Type configuration")
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
        // Dynamic Type is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Dynamic Type doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Dynamic Type Operations
    
    /// Perform dynamic type adjustment
    public func performAdjustment(_ request: DynamicTypeAdjustmentRequest) async throws -> DynamicTypeAdjustmentResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        return try await _resources.performAdjustment(request)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<DynamicTypeAdjustmentResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active adjustments
    public func getActiveAdjustments() async throws -> [DynamicTypeAdjustmentRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        return await _resources.getActiveAdjustments()
    }
    
    /// Get adjustment history
    public func getAdjustmentHistory(since: Date? = nil) async throws -> [DynamicTypeAdjustmentResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        return await _resources.getAdjustmentHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> DynamicTypeCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Dynamic Type capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create font scaling request
    public func createFontScalingRequest(
        fontId: String,
        currentSize: Double,
        targetCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory
    ) -> DynamicTypeAdjustmentRequest {
        let fontDescriptor = DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor(
            fontId: fontId,
            familyName: "System",
            pointSize: currentSize
        )
        
        let target = DynamicTypeAdjustmentRequest.AdjustmentTarget(
            targetType: .singleFont,
            identifier: fontId,
            fontDescriptors: [fontDescriptor],
            textElements: []
        )
        
        return DynamicTypeAdjustmentRequest(
            target: target,
            adjustmentType: .scaleToCategory,
            targetCategory: targetCategory
        )
    }
    
    /// Create text element adjustment request
    public func createTextElementRequest(
        elementId: String,
        text: String,
        currentFont: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor,
        frame: CGRect,
        targetCategory: DynamicTypeCapabilityConfiguration.ContentSizeCategory
    ) -> DynamicTypeAdjustmentRequest {
        let textElement = DynamicTypeAdjustmentRequest.AdjustmentTarget.TextElement(
            elementId: elementId,
            elementType: .label,
            currentFont: currentFont,
            text: text,
            frame: frame
        )
        
        let target = DynamicTypeAdjustmentRequest.AdjustmentTarget(
            targetType: .textElement,
            identifier: elementId,
            fontDescriptors: [currentFont],
            textElements: [textElement]
        )
        
        return DynamicTypeAdjustmentRequest(
            target: target,
            adjustmentType: .fullAdjustment,
            targetCategory: targetCategory
        )
    }
    
    /// Get current system content size category
    public func getCurrentContentSizeCategory() async throws -> DynamicTypeCapabilityConfiguration.ContentSizeCategory {
        let systemCategory = UIApplication.shared.preferredContentSizeCategory
        
        switch systemCategory {
        case .extraSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .extraLarge
        case .extraExtraLarge: return .extraExtraLarge
        case .extraExtraExtraLarge: return .extraExtraExtraLarge
        case .accessibilityMedium: return .accessibilityMedium
        case .accessibilityLarge: return .accessibilityLarge
        case .accessibilityExtraLarge: return .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: return .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: return .accessibilityExtraExtraExtraLarge
        default: return .unspecified
        }
    }
    
    /// Check if accessibility sizes are being used
    public func isUsingAccessibilitySizes() async throws -> Bool {
        let category = try await getCurrentContentSizeCategory()
        return [.accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge].contains(category)
    }
    
    /// Get recommended font size for text style
    public func getRecommendedFontSize(for textStyle: DynamicTypeAdjustmentRequest.AdjustmentTarget.FontDescriptor.TextStyle, category: DynamicTypeCapabilityConfiguration.ContentSizeCategory) -> Double {
        let baseSize: Double
        switch textStyle {
        case .largeTitle: baseSize = 34.0
        case .title1: baseSize = 28.0
        case .title2: baseSize = 22.0
        case .title3: baseSize = 20.0
        case .headline: baseSize = 17.0
        case .subheadline: baseSize = 15.0
        case .body: baseSize = 17.0
        case .callout: baseSize = 16.0
        case .footnote: baseSize = 13.0
        case .caption1: baseSize = 12.0
        case .caption2: baseSize = 11.0
        case .custom: baseSize = 17.0
        }
        
        let scaleFactor: Double
        switch category {
        case .extraSmall: scaleFactor = 0.8
        case .small: scaleFactor = 0.9
        case .medium: scaleFactor = 0.95
        case .large: scaleFactor = 1.0
        case .extraLarge: scaleFactor = 1.15
        case .extraExtraLarge: scaleFactor = 1.3
        case .extraExtraExtraLarge: scaleFactor = 1.5
        case .accessibilityMedium: scaleFactor = 1.7
        case .accessibilityLarge: scaleFactor = 2.0
        case .accessibilityExtraLarge: scaleFactor = 2.3
        case .accessibilityExtraExtraLarge: scaleFactor = 2.7
        case .accessibilityExtraExtraExtraLarge: scaleFactor = 3.0
        case .unspecified: scaleFactor = 1.0
        }
        
        return baseSize * scaleFactor
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Dynamic Type specific errors
public enum DynamicTypeError: Error, LocalizedError {
    case dynamicTypeDisabled
    case adjustmentFailed(String)
    case invalidFontDescriptor
    case invalidTextElement
    case unsupportedScalingBehavior
    case constraintAdjustmentFailed
    case layoutCalculationFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .dynamicTypeDisabled:
            return "Dynamic Type support is disabled"
        case .adjustmentFailed(let reason):
            return "Dynamic Type adjustment failed: \(reason)"
        case .invalidFontDescriptor:
            return "Invalid font descriptor provided"
        case .invalidTextElement:
            return "Invalid text element provided"
        case .unsupportedScalingBehavior:
            return "Unsupported scaling behavior"
        case .constraintAdjustmentFailed:
            return "Constraint adjustment failed"
        case .layoutCalculationFailed:
            return "Layout calculation failed"
        case .configurationError(let reason):
            return "Dynamic Type configuration error: \(reason)"
        }
    }
}