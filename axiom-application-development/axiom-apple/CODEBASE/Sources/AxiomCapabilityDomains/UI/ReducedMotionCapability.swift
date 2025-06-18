import Foundation
import UIKit
import SwiftUI
import AxiomCore
import AxiomCapabilities

// MARK: - Reduced Motion Capability Configuration

/// Configuration for Reduced Motion capability
public struct ReducedMotionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableReducedMotionSupport: Bool
    public let enableAutomaticDetection: Bool
    public let enableSystemIntegration: Bool
    public let enableAnimationReduction: Bool
    public let enableParallaxReduction: Bool
    public let enableAutoPlayControl: Bool
    public let enableTransitionSimplification: Bool
    public let enableRealTimeMonitoring: Bool
    public let maxConcurrentAdjustments: Int
    public let adjustmentTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let motionSensitivity: MotionSensitivity
    public let reductionLevel: ReductionLevel
    public let animationDuration: TimeInterval
    public let transitionStyle: TransitionStyle
    public let scrollBehavior: ScrollBehavior
    public let supportedReductions: [MotionReduction]
    
    public enum MotionSensitivity: String, Codable, CaseIterable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case maximum = "maximum"
        case custom = "custom"
    }
    
    public enum ReductionLevel: String, Codable, CaseIterable {
        case minimal = "minimal"
        case moderate = "moderate"
        case significant = "significant"
        case complete = "complete"
        case adaptive = "adaptive"
    }
    
    public enum TransitionStyle: String, Codable, CaseIterable {
        case instant = "instant"
        case fade = "fade"
        case slide = "slide"
        case crossDissolve = "crossDissolve"
        case none = "none"
    }
    
    public enum ScrollBehavior: String, Codable, CaseIterable {
        case normal = "normal"
        case smooth = "smooth"
        case instant = "instant"
        case reduced = "reduced"
    }
    
    public enum MotionReduction: String, Codable, CaseIterable {
        case animations = "animations"
        case parallax = "parallax"
        case autoPlay = "autoPlay"
        case transitions = "transitions"
        case scrollEffects = "scrollEffects"
        case backgroundVideo = "backgroundVideo"
        case particleEffects = "particleEffects"
        case zoomEffects = "zoomEffects"
        case rotationEffects = "rotationEffects"
        case shakeEffects = "shakeEffects"
    }
    
    public init(
        enableReducedMotionSupport: Bool = true,
        enableAutomaticDetection: Bool = true,
        enableSystemIntegration: Bool = true,
        enableAnimationReduction: Bool = true,
        enableParallaxReduction: Bool = true,
        enableAutoPlayControl: Bool = true,
        enableTransitionSimplification: Bool = true,
        enableRealTimeMonitoring: Bool = true,
        maxConcurrentAdjustments: Int = 5,
        adjustmentTimeout: TimeInterval = 8.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 75,
        motionSensitivity: MotionSensitivity = .medium,
        reductionLevel: ReductionLevel = .moderate,
        animationDuration: TimeInterval = 0.1,
        transitionStyle: TransitionStyle = .fade,
        scrollBehavior: ScrollBehavior = .smooth,
        supportedReductions: [MotionReduction] = MotionReduction.allCases
    ) {
        self.enableReducedMotionSupport = enableReducedMotionSupport
        self.enableAutomaticDetection = enableAutomaticDetection
        self.enableSystemIntegration = enableSystemIntegration
        self.enableAnimationReduction = enableAnimationReduction
        self.enableParallaxReduction = enableParallaxReduction
        self.enableAutoPlayControl = enableAutoPlayControl
        self.enableTransitionSimplification = enableTransitionSimplification
        self.enableRealTimeMonitoring = enableRealTimeMonitoring
        self.maxConcurrentAdjustments = maxConcurrentAdjustments
        self.adjustmentTimeout = adjustmentTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.motionSensitivity = motionSensitivity
        self.reductionLevel = reductionLevel
        self.animationDuration = animationDuration
        self.transitionStyle = transitionStyle
        self.scrollBehavior = scrollBehavior
        self.supportedReductions = supportedReductions
    }
    
    public var isValid: Bool {
        maxConcurrentAdjustments > 0 &&
        adjustmentTimeout > 0 &&
        animationDuration >= 0 &&
        cacheSize >= 0 &&
        !supportedReductions.isEmpty
    }
    
    public func merged(with other: ReducedMotionCapabilityConfiguration) -> ReducedMotionCapabilityConfiguration {
        ReducedMotionCapabilityConfiguration(
            enableReducedMotionSupport: other.enableReducedMotionSupport,
            enableAutomaticDetection: other.enableAutomaticDetection,
            enableSystemIntegration: other.enableSystemIntegration,
            enableAnimationReduction: other.enableAnimationReduction,
            enableParallaxReduction: other.enableParallaxReduction,
            enableAutoPlayControl: other.enableAutoPlayControl,
            enableTransitionSimplification: other.enableTransitionSimplification,
            enableRealTimeMonitoring: other.enableRealTimeMonitoring,
            maxConcurrentAdjustments: other.maxConcurrentAdjustments,
            adjustmentTimeout: other.adjustmentTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            motionSensitivity: other.motionSensitivity,
            reductionLevel: other.reductionLevel,
            animationDuration: other.animationDuration,
            transitionStyle: other.transitionStyle,
            scrollBehavior: other.scrollBehavior,
            supportedReductions: other.supportedReductions
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ReducedMotionCapabilityConfiguration {
        var adjustedTimeout = adjustmentTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAdjustments = maxConcurrentAdjustments
        var adjustedCacheSize = cacheSize
        var adjustedRealTimeMonitoring = enableRealTimeMonitoring
        var adjustedReductionLevel = reductionLevel
        var adjustedAnimationDuration = animationDuration
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(adjustmentTimeout, 4.0)
            adjustedConcurrentAdjustments = min(maxConcurrentAdjustments, 2)
            adjustedCacheSize = min(cacheSize, 25)
            adjustedRealTimeMonitoring = false
            adjustedReductionLevel = .significant
            adjustedAnimationDuration = 0.05
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ReducedMotionCapabilityConfiguration(
            enableReducedMotionSupport: enableReducedMotionSupport,
            enableAutomaticDetection: enableAutomaticDetection,
            enableSystemIntegration: enableSystemIntegration,
            enableAnimationReduction: enableAnimationReduction,
            enableParallaxReduction: enableParallaxReduction,
            enableAutoPlayControl: enableAutoPlayControl,
            enableTransitionSimplification: enableTransitionSimplification,
            enableRealTimeMonitoring: adjustedRealTimeMonitoring,
            maxConcurrentAdjustments: adjustedConcurrentAdjustments,
            adjustmentTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            motionSensitivity: motionSensitivity,
            reductionLevel: adjustedReductionLevel,
            animationDuration: adjustedAnimationDuration,
            transitionStyle: transitionStyle,
            scrollBehavior: scrollBehavior,
            supportedReductions: supportedReductions
        )
    }
}

// MARK: - Reduced Motion Types

/// Motion reduction request
public struct MotionReductionRequest: Sendable, Identifiable {
    public let id: UUID
    public let target: ReductionTarget
    public let reductionType: ReductionType
    public let targetLevel: ReducedMotionCapabilityConfiguration.ReductionLevel
    public let options: ReductionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct ReductionTarget: Sendable {
        public let targetType: TargetType
        public let identifier: String
        public let animationElements: [AnimationElement]
        public let motionEffects: [MotionEffect]
        public let contentElements: [ContentElement]
        public let interactionElements: [InteractionElement]
        
        public enum TargetType: String, Sendable, CaseIterable {
            case singleAnimation = "singleAnimation"
            case animationGroup = "animationGroup"
            case viewController = "viewController"
            case application = "application"
            case userInterface = "userInterface"
            case customTarget = "customTarget"
        }
        
        public struct AnimationElement: Sendable {
            public let elementId: String
            public let animationType: AnimationType
            public let duration: TimeInterval
            public let properties: [AnimationProperty]
            public let timing: TimingFunction
            public let repeatCount: Int
            public let isAutoreversing: Bool
            public let canBeReduced: Bool
            
            public enum AnimationType: String, Sendable, CaseIterable {
                case fade = "fade"
                case slide = "slide"
                case scale = "scale"
                case rotate = "rotate"
                case bounce = "bounce"
                case spring = "spring"
                case keyframe = "keyframe"
                case transition = "transition"
                case transform = "transform"
                case custom = "custom"
            }
            
            public struct AnimationProperty: Sendable {
                public let propertyName: String
                public let fromValue: String
                public let toValue: String
                public let keyPath: String
                public let isReducible: Bool
                
                public init(propertyName: String, fromValue: String, toValue: String, keyPath: String, isReducible: Bool = true) {
                    self.propertyName = propertyName
                    self.fromValue = fromValue
                    self.toValue = toValue
                    self.keyPath = keyPath
                    self.isReducible = isReducible
                }
            }
            
            public enum TimingFunction: String, Sendable, CaseIterable {
                case linear = "linear"
                case easeIn = "easeIn"
                case easeOut = "easeOut"
                case easeInOut = "easeInOut"
                case spring = "spring"
                case custom = "custom"
            }
            
            public init(elementId: String, animationType: AnimationType, duration: TimeInterval, properties: [AnimationProperty], timing: TimingFunction = .linear, repeatCount: Int = 1, isAutoreversing: Bool = false, canBeReduced: Bool = true) {
                self.elementId = elementId
                self.animationType = animationType
                self.duration = duration
                self.properties = properties
                self.timing = timing
                self.repeatCount = repeatCount
                self.isAutoreversing = isAutoreversing
                self.canBeReduced = canBeReduced
            }
        }
        
        public struct MotionEffect: Sendable {
            public let effectId: String
            public let effectType: EffectType
            public let intensity: Double
            public let direction: MotionDirection
            public let triggerType: TriggerType
            public let affectedProperties: [String]
            public let canBeDisabled: Bool
            
            public enum EffectType: String, Sendable, CaseIterable {
                case parallax = "parallax"
                case tilt = "tilt"
                case shake = "shake"
                case vibration = "vibration"
                case scroll = "scroll"
                case gyroscope = "gyroscope"
                case accelerometer = "accelerometer"
                case magnetometer = "magnetometer"
                case custom = "custom"
            }
            
            public enum MotionDirection: String, Sendable, CaseIterable {
                case horizontal = "horizontal"
                case vertical = "vertical"
                case both = "both"
                case rotational = "rotational"
                case none = "none"
            }
            
            public enum TriggerType: String, Sendable, CaseIterable {
                case scroll = "scroll"
                case deviceMotion = "deviceMotion"
                case userInteraction = "userInteraction"
                case automatic = "automatic"
                case programmatic = "programmatic"
            }
            
            public init(effectId: String, effectType: EffectType, intensity: Double, direction: MotionDirection = .both, triggerType: TriggerType = .automatic, affectedProperties: [String] = [], canBeDisabled: Bool = true) {
                self.effectId = effectId
                self.effectType = effectType
                self.intensity = intensity
                self.direction = direction
                self.triggerType = triggerType
                self.affectedProperties = affectedProperties
                self.canBeDisabled = canBeDisabled
            }
        }
        
        public struct ContentElement: Sendable {
            public let elementId: String
            public let contentType: ContentType
            public let isAutoPlaying: Bool
            public let hasMotion: Bool
            public let motionIntensity: Double
            public let canBePaused: Bool
            public let alternativeAvailable: Bool
            
            public enum ContentType: String, Sendable, CaseIterable {
                case video = "video"
                case animation = "animation"
                case gif = "gif"
                case lottie = "lottie"
                case particles = "particles"
                case canvas = "canvas"
                case webGL = "webGL"
                case css = "css"
                case custom = "custom"
            }
            
            public init(elementId: String, contentType: ContentType, isAutoPlaying: Bool = false, hasMotion: Bool = false, motionIntensity: Double = 0.0, canBePaused: Bool = true, alternativeAvailable: Bool = false) {
                self.elementId = elementId
                self.contentType = contentType
                self.isAutoPlaying = isAutoPlaying
                self.hasMotion = hasMotion
                self.motionIntensity = motionIntensity
                self.canBePaused = canBePaused
                self.alternativeAvailable = alternativeAvailable
            }
        }
        
        public struct InteractionElement: Sendable {
            public let elementId: String
            public let interactionType: InteractionType
            public let hasAnimatedFeedback: Bool
            public let feedbackIntensity: Double
            public let canSimplifyFeedback: Bool
            public let alternativeFeedback: String?
            
            public enum InteractionType: String, Sendable, CaseIterable {
                case button = "button"
                case gesture = "gesture"
                case scroll = "scroll"
                case swipe = "swipe"
                case pinch = "pinch"
                case rotation = "rotation"
                case longPress = "longPress"
                case hover = "hover"
                case custom = "custom"
            }
            
            public init(elementId: String, interactionType: InteractionType, hasAnimatedFeedback: Bool = false, feedbackIntensity: Double = 0.5, canSimplifyFeedback: Bool = true, alternativeFeedback: String? = nil) {
                self.elementId = elementId
                self.interactionType = interactionType
                self.hasAnimatedFeedback = hasAnimatedFeedback
                self.feedbackIntensity = feedbackIntensity
                self.canSimplifyFeedback = canSimplifyFeedback
                self.alternativeFeedback = alternativeFeedback
            }
        }
        
        public init(targetType: TargetType, identifier: String, animationElements: [AnimationElement], motionEffects: [MotionEffect], contentElements: [ContentElement], interactionElements: [InteractionElement]) {
            self.targetType = targetType
            self.identifier = identifier
            self.animationElements = animationElements
            self.motionEffects = motionEffects
            self.contentElements = contentElements
            self.interactionElements = interactionElements
        }
    }
    
    public enum ReductionType: String, Sendable, CaseIterable {
        case reduceAnimations = "reduceAnimations"
        case disableParallax = "disableParallax"
        case pauseAutoPlay = "pauseAutoPlay"
        case simplifyTransitions = "simplifyTransitions"
        case reduceMotionEffects = "reduceMotionEffects"
        case disableShakeEffects = "disableShakeEffects"
        case fullReduction = "fullReduction"
        case customReduction = "customReduction"
        case preview = "preview"
        case restore = "restore"
    }
    
    public struct ReductionOptions: Sendable {
        public let preserveEssentialAnimations: Bool
        public let replaceWithStaticContent: Bool
        public let provideFallbackUI: Bool
        public let animateChanges: Bool
        public let animationDuration: TimeInterval
        public let respectUserPreferences: Bool
        public let enableProgressiveReduction: Bool
        public let customReductionLevel: Double?
        public let whitelistedAnimations: [String]
        
        public init(preserveEssentialAnimations: Bool = true, replaceWithStaticContent: Bool = true, provideFallbackUI: Bool = true, animateChanges: Bool = false, animationDuration: TimeInterval = 0.1, respectUserPreferences: Bool = true, enableProgressiveReduction: Bool = true, customReductionLevel: Double? = nil, whitelistedAnimations: [String] = []) {
            self.preserveEssentialAnimations = preserveEssentialAnimations
            self.replaceWithStaticContent = replaceWithStaticContent
            self.provideFallbackUI = provideFallbackUI
            self.animateChanges = animateChanges
            self.animationDuration = animationDuration
            self.respectUserPreferences = respectUserPreferences
            self.enableProgressiveReduction = enableProgressiveReduction
            self.customReductionLevel = customReductionLevel
            self.whitelistedAnimations = whitelistedAnimations
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(target: ReductionTarget, reductionType: ReductionType = .fullReduction, targetLevel: ReducedMotionCapabilityConfiguration.ReductionLevel, options: ReductionOptions = ReductionOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.target = target
        self.reductionType = reductionType
        self.targetLevel = targetLevel
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Motion reduction result
public struct MotionReductionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let reducedAnimations: [ReducedAnimation]
    public let disabledEffects: [DisabledEffect]
    public let modifiedContent: [ModifiedContent]
    public let adjustedInteractions: [AdjustedInteraction]
    public let reductionMetrics: ReductionMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ReducedMotionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ReducedAnimation: Sendable {
        public let originalAnimation: MotionReductionRequest.ReductionTarget.AnimationElement
        public let reducedAnimation: MotionReductionRequest.ReductionTarget.AnimationElement?
        public let reductionApplied: ReductionApplied
        public let originalDuration: TimeInterval
        public let newDuration: TimeInterval
        public let wasDisabled: Bool
        public let replacementStrategy: ReplacementStrategy
        
        public enum ReductionApplied: String, Sendable, CaseIterable {
            case durationReduced = "durationReduced"
            case timingSimplified = "timingSimplified"
            case propertiesReduced = "propertiesReduced"
            case disabled = "disabled"
            case replaced = "replaced"
            case none = "none"
        }
        
        public enum ReplacementStrategy: String, Sendable, CaseIterable {
            case instantChange = "instantChange"
            case simpleFade = "simpleFade"
            case staticState = "staticState"
            case alternativeAnimation = "alternativeAnimation"
            case none = "none"
        }
        
        public init(originalAnimation: MotionReductionRequest.ReductionTarget.AnimationElement, reducedAnimation: MotionReductionRequest.ReductionTarget.AnimationElement?, reductionApplied: ReductionApplied, originalDuration: TimeInterval, newDuration: TimeInterval, wasDisabled: Bool, replacementStrategy: ReplacementStrategy) {
            self.originalAnimation = originalAnimation
            self.reducedAnimation = reducedAnimation
            self.reductionApplied = reductionApplied
            self.originalDuration = originalDuration
            self.newDuration = newDuration
            self.wasDisabled = wasDisabled
            self.replacementStrategy = replacementStrategy
        }
    }
    
    public struct DisabledEffect: Sendable {
        public let originalEffect: MotionReductionRequest.ReductionTarget.MotionEffect
        public let disabledReason: DisabledReason
        public let alternativeProvided: Bool
        public let alternativeDescription: String?
        
        public enum DisabledReason: String, Sendable, CaseIterable {
            case motionSensitivity = "motionSensitivity"
            case userPreference = "userPreference"
            case accessibilityRequirement = "accessibilityRequirement"
            case performanceOptimization = "performanceOptimization"
            case systemSetting = "systemSetting"
        }
        
        public init(originalEffect: MotionReductionRequest.ReductionTarget.MotionEffect, disabledReason: DisabledReason, alternativeProvided: Bool, alternativeDescription: String?) {
            self.originalEffect = originalEffect
            self.disabledReason = disabledReason
            self.alternativeProvided = alternativeProvided
            self.alternativeDescription = alternativeDescription
        }
    }
    
    public struct ModifiedContent: Sendable {
        public let originalContent: MotionReductionRequest.ReductionTarget.ContentElement
        public let modifiedContent: MotionReductionRequest.ReductionTarget.ContentElement
        public let wasAutoPlayDisabled: Bool
        public let staticAlternativeProvided: Bool
        public let playControlsAdded: Bool
        public let userConsentRequired: Bool
        
        public init(originalContent: MotionReductionRequest.ReductionTarget.ContentElement, modifiedContent: MotionReductionRequest.ReductionTarget.ContentElement, wasAutoPlayDisabled: Bool, staticAlternativeProvided: Bool, playControlsAdded: Bool, userConsentRequired: Bool) {
            self.originalContent = originalContent
            self.modifiedContent = modifiedContent
            self.wasAutoPlayDisabled = wasAutoPlayDisabled
            self.staticAlternativeProvided = staticAlternativeProvided
            self.playControlsAdded = playControlsAdded
            self.userConsentRequired = userConsentRequired
        }
    }
    
    public struct AdjustedInteraction: Sendable {
        public let originalInteraction: MotionReductionRequest.ReductionTarget.InteractionElement
        public let adjustedInteraction: MotionReductionRequest.ReductionTarget.InteractionElement
        public let feedbackReduced: Bool
        public let alternativeFeedbackApplied: Bool
        public let improvementApplied: Double
        
        public init(originalInteraction: MotionReductionRequest.ReductionTarget.InteractionElement, adjustedInteraction: MotionReductionRequest.ReductionTarget.InteractionElement, feedbackReduced: Bool, alternativeFeedbackApplied: Bool, improvementApplied: Double) {
            self.originalInteraction = originalInteraction
            self.adjustedInteraction = adjustedInteraction
            self.feedbackReduced = feedbackReduced
            self.alternativeFeedbackApplied = alternativeFeedbackApplied
            self.improvementApplied = improvementApplied
        }
    }
    
    public struct ReductionMetrics: Sendable {
        public let totalElementsProcessed: Int
        public let animationsReduced: Int
        public let effectsDisabled: Int
        public let contentModified: Int
        public let interactionsAdjusted: Int
        public let overallReductionLevel: Double
        public let accessibilityImprovement: Double
        public let userExperienceScore: Double
        public let performanceGain: Double
        
        public init(totalElementsProcessed: Int, animationsReduced: Int, effectsDisabled: Int, contentModified: Int, interactionsAdjusted: Int, overallReductionLevel: Double, accessibilityImprovement: Double, userExperienceScore: Double, performanceGain: Double) {
            self.totalElementsProcessed = totalElementsProcessed
            self.animationsReduced = animationsReduced
            self.effectsDisabled = effectsDisabled
            self.contentModified = contentModified
            self.interactionsAdjusted = interactionsAdjusted
            self.overallReductionLevel = overallReductionLevel
            self.accessibilityImprovement = accessibilityImprovement
            self.userExperienceScore = userExperienceScore
            self.performanceGain = performanceGain
        }
    }
    
    public init(requestId: UUID, reducedAnimations: [ReducedAnimation], disabledEffects: [DisabledEffect], modifiedContent: [ModifiedContent], adjustedInteractions: [AdjustedInteraction], reductionMetrics: ReductionMetrics, processingTime: TimeInterval, success: Bool, error: ReducedMotionError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.reducedAnimations = reducedAnimations
        self.disabledEffects = disabledEffects
        self.modifiedContent = modifiedContent
        self.adjustedInteractions = adjustedInteractions
        self.reductionMetrics = reductionMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var reductionEffectiveness: Double {
        let totalReductions = reductionMetrics.animationsReduced + reductionMetrics.effectsDisabled + reductionMetrics.contentModified + reductionMetrics.interactionsAdjusted
        return reductionMetrics.totalElementsProcessed > 0 ? Double(totalReductions) / Double(reductionMetrics.totalElementsProcessed) : 0.0
    }
    
    public var hasSignificantReductions: Bool {
        reductionMetrics.overallReductionLevel >= 0.5 && (reductionMetrics.animationsReduced > 0 || reductionMetrics.effectsDisabled > 0)
    }
}

/// Reduced motion capability metrics
public struct ReducedMotionCapabilityMetrics: Sendable {
    public let totalReductions: Int
    public let successfulReductions: Int
    public let failedReductions: Int
    public let averageProcessingTime: TimeInterval
    public let reductionsByType: [String: Int]
    public let reductionsByLevel: [String: Int]
    public let averageReductionLevel: Double
    public let averageAccessibilityImprovement: Double
    public let errorsByType: [String: Int]
    public let throughputPerMinute: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let fastestReduction: TimeInterval
        public let slowestReduction: TimeInterval
        public let averageAnimationsPerReduction: Double
        public let averageEffectsPerReduction: Double
        public let totalAnimationsProcessed: Int
        public let totalEffectsDisabled: Int
        public let userSatisfactionRate: Double
        
        public init(fastestReduction: TimeInterval = 0, slowestReduction: TimeInterval = 0, averageAnimationsPerReduction: Double = 0, averageEffectsPerReduction: Double = 0, totalAnimationsProcessed: Int = 0, totalEffectsDisabled: Int = 0, userSatisfactionRate: Double = 0) {
            self.fastestReduction = fastestReduction
            self.slowestReduction = slowestReduction
            self.averageAnimationsPerReduction = averageAnimationsPerReduction
            self.averageEffectsPerReduction = averageEffectsPerReduction
            self.totalAnimationsProcessed = totalAnimationsProcessed
            self.totalEffectsDisabled = totalEffectsDisabled
            self.userSatisfactionRate = userSatisfactionRate
        }
    }
    
    public init(totalReductions: Int = 0, successfulReductions: Int = 0, failedReductions: Int = 0, averageProcessingTime: TimeInterval = 0, reductionsByType: [String: Int] = [:], reductionsByLevel: [String: Int] = [:], averageReductionLevel: Double = 0, averageAccessibilityImprovement: Double = 0, errorsByType: [String: Int] = [:], throughputPerMinute: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalReductions = totalReductions
        self.successfulReductions = successfulReductions
        self.failedReductions = failedReductions
        self.averageProcessingTime = averageProcessingTime
        self.reductionsByType = reductionsByType
        self.reductionsByLevel = reductionsByLevel
        self.averageReductionLevel = averageReductionLevel
        self.averageAccessibilityImprovement = averageAccessibilityImprovement
        self.errorsByType = errorsByType
        self.throughputPerMinute = averageProcessingTime > 0 ? 60.0 / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalReductions > 0 ? Double(successfulReductions) / Double(totalReductions) : 0
    }
}

// MARK: - Reduced Motion Resource

/// Reduced motion resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ReducedMotionCapabilityResource: AxiomCapabilityResource {
    private let configuration: ReducedMotionCapabilityConfiguration
    private var activeReductions: [UUID: MotionReductionRequest] = [:]
    private var reductionHistory: [MotionReductionResult] = []
    private var resultCache: [String: MotionReductionResult] = [:]
    private var motionAnalyzer: MotionAnalyzer = MotionAnalyzer()
    private var animationReducer: AnimationReducer = AnimationReducer()
    private var effectDisabler: EffectDisabler = EffectDisabler()
    private var contentModifier: ContentModifier = ContentModifier()
    private var metricsCalculator: ReductionMetricsCalculator = ReductionMetricsCalculator()
    private var metrics: ReducedMotionCapabilityMetrics = ReducedMotionCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<MotionReductionResult>.Continuation?
    
    // Helper classes for reduced motion processing
    private class MotionAnalyzer {
        func analyzeMotionSensitivity(
            animations: [MotionReductionRequest.ReductionTarget.AnimationElement],
            effects: [MotionReductionRequest.ReductionTarget.MotionEffect],
            sensitivity: ReducedMotionCapabilityConfiguration.MotionSensitivity
        ) -> Double {
            let animationScore = animations.reduce(0.0) { score, animation in
                score + analyzeAnimationImpact(animation)
            } / max(1.0, Double(animations.count))
            
            let effectScore = effects.reduce(0.0) { score, effect in
                score + analyzeEffectImpact(effect)
            } / max(1.0, Double(effects.count))
            
            let baseScore = (animationScore + effectScore) / 2.0
            
            switch sensitivity {
            case .none: return 0.0
            case .low: return baseScore * 0.3
            case .medium: return baseScore * 0.6
            case .high: return baseScore * 0.8
            case .maximum: return 1.0
            case .custom: return baseScore * 0.7
            }
        }
        
        private func analyzeAnimationImpact(_ animation: MotionReductionRequest.ReductionTarget.AnimationElement) -> Double {
            var impact = 0.0
            
            // Duration impact
            impact += min(1.0, animation.duration / 2.0) * 0.3
            
            // Animation type impact
            switch animation.animationType {
            case .bounce, .spring: impact += 0.8
            case .rotate, .scale: impact += 0.6
            case .slide, .fade: impact += 0.3
            case .transition: impact += 0.4
            default: impact += 0.5
            }
            
            // Repeat impact
            if animation.repeatCount > 1 {
                impact += min(1.0, Double(animation.repeatCount) / 10.0) * 0.2
            }
            
            return min(1.0, impact)
        }
        
        private func analyzeEffectImpact(_ effect: MotionReductionRequest.ReductionTarget.MotionEffect) -> Double {
            var impact = effect.intensity
            
            switch effect.effectType {
            case .parallax: impact *= 0.9
            case .shake, .vibration: impact *= 1.0
            case .tilt: impact *= 0.7
            case .gyroscope, .accelerometer: impact *= 0.8
            default: impact *= 0.6
            }
            
            return min(1.0, impact)
        }
    }
    
    private class AnimationReducer {
        func reduceAnimation(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            reductionLevel: ReducedMotionCapabilityConfiguration.ReductionLevel,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            
            switch reductionLevel {
            case .minimal:
                return applyMinimalReduction(animation, configuration: configuration)
            case .moderate:
                return applyModerateReduction(animation, configuration: configuration)
            case .significant:
                return applySignificantReduction(animation, configuration: configuration)
            case .complete:
                return applyCompleteReduction(animation, configuration: configuration)
            case .adaptive:
                return applyAdaptiveReduction(animation, configuration: configuration)
            }
        }
        
        private func applyMinimalReduction(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            let newDuration = animation.duration * 0.7
            
            let reducedAnimation = MotionReductionRequest.ReductionTarget.AnimationElement(
                elementId: animation.elementId,
                animationType: animation.animationType,
                duration: newDuration,
                properties: animation.properties,
                timing: .linear,
                repeatCount: min(animation.repeatCount, 3),
                isAutoreversing: false,
                canBeReduced: animation.canBeReduced
            )
            
            return MotionReductionResult.ReducedAnimation(
                originalAnimation: animation,
                reducedAnimation: reducedAnimation,
                reductionApplied: .durationReduced,
                originalDuration: animation.duration,
                newDuration: newDuration,
                wasDisabled: false,
                replacementStrategy: .none
            )
        }
        
        private func applyModerateReduction(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            let newDuration = configuration.animationDuration
            
            let reducedAnimation = MotionReductionRequest.ReductionTarget.AnimationElement(
                elementId: animation.elementId,
                animationType: .fade,
                duration: newDuration,
                properties: filterEssentialProperties(animation.properties),
                timing: .linear,
                repeatCount: 1,
                isAutoreversing: false,
                canBeReduced: animation.canBeReduced
            )
            
            return MotionReductionResult.ReducedAnimation(
                originalAnimation: animation,
                reducedAnimation: reducedAnimation,
                reductionApplied: .timingSimplified,
                originalDuration: animation.duration,
                newDuration: newDuration,
                wasDisabled: false,
                replacementStrategy: .simpleFade
            )
        }
        
        private func applySignificantReduction(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            return MotionReductionResult.ReducedAnimation(
                originalAnimation: animation,
                reducedAnimation: nil,
                reductionApplied: .replaced,
                originalDuration: animation.duration,
                newDuration: 0.0,
                wasDisabled: false,
                replacementStrategy: .instantChange
            )
        }
        
        private func applyCompleteReduction(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            return MotionReductionResult.ReducedAnimation(
                originalAnimation: animation,
                reducedAnimation: nil,
                reductionApplied: .disabled,
                originalDuration: animation.duration,
                newDuration: 0.0,
                wasDisabled: true,
                replacementStrategy: .staticState
            )
        }
        
        private func applyAdaptiveReduction(
            _ animation: MotionReductionRequest.ReductionTarget.AnimationElement,
            configuration: ReducedMotionCapabilityConfiguration
        ) -> MotionReductionResult.ReducedAnimation {
            // Analyze animation and apply appropriate reduction
            if animation.duration > 1.0 || animation.repeatCount > 2 {
                return applySignificantReduction(animation, configuration: configuration)
            } else {
                return applyModerateReduction(animation, configuration: configuration)
            }
        }
        
        private func filterEssentialProperties(_ properties: [MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty]) -> [MotionReductionRequest.ReductionTarget.AnimationElement.AnimationProperty] {
            return properties.filter { property in
                ["opacity", "alpha", "hidden"].contains(property.propertyName.lowercased())
            }
        }
    }
    
    private class EffectDisabler {
        func disableEffect(
            _ effect: MotionReductionRequest.ReductionTarget.MotionEffect,
            sensitivity: ReducedMotionCapabilityConfiguration.MotionSensitivity
        ) -> MotionReductionResult.DisabledEffect {
            
            let shouldDisable = shouldDisableEffect(effect, sensitivity: sensitivity)
            let reason: MotionReductionResult.DisabledEffect.DisabledReason
            
            if shouldDisable {
                reason = determineDisableReason(effect, sensitivity: sensitivity)
            } else {
                reason = .userPreference
            }
            
            let alternativeDescription = generateAlternativeDescription(for: effect)
            
            return MotionReductionResult.DisabledEffect(
                originalEffect: effect,
                disabledReason: reason,
                alternativeProvided: alternativeDescription != nil,
                alternativeDescription: alternativeDescription
            )
        }
        
        private func shouldDisableEffect(
            _ effect: MotionReductionRequest.ReductionTarget.MotionEffect,
            sensitivity: ReducedMotionCapabilityConfiguration.MotionSensitivity
        ) -> Bool {
            switch sensitivity {
            case .none: return false
            case .low: return effect.effectType == .shake || effect.effectType == .vibration
            case .medium: return effect.intensity > 0.7 || [.shake, .vibration, .parallax].contains(effect.effectType)
            case .high: return effect.intensity > 0.3 || effect.effectType != .scroll
            case .maximum: return true
            case .custom: return effect.intensity > 0.5
            }
        }
        
        private func determineDisableReason(
            _ effect: MotionReductionRequest.ReductionTarget.MotionEffect,
            sensitivity: ReducedMotionCapabilityConfiguration.MotionSensitivity
        ) -> MotionReductionResult.DisabledEffect.DisabledReason {
            switch effect.effectType {
            case .shake, .vibration:
                return .motionSensitivity
            case .parallax, .tilt:
                return .accessibilityRequirement
            case .gyroscope, .accelerometer:
                return .systemSetting
            default:
                return .userPreference
            }
        }
        
        private func generateAlternativeDescription(for effect: MotionReductionRequest.ReductionTarget.MotionEffect) -> String? {
            switch effect.effectType {
            case .parallax:
                return "Static background with subtle depth indication"
            case .shake:
                return "Color highlight to indicate action"
            case .tilt:
                return "Shadow effect to show interaction"
            case .vibration:
                return "Visual pulse feedback"
            default:
                return nil
            }
        }
    }
    
    private class ContentModifier {
        func modifyContent(
            _ content: MotionReductionRequest.ReductionTarget.ContentElement,
            options: MotionReductionRequest.ReductionOptions
        ) -> MotionReductionResult.ModifiedContent {
            
            var modifiedContent = content
            var wasAutoPlayDisabled = false
            var staticAlternativeProvided = false
            var playControlsAdded = false
            var userConsentRequired = false
            
            // Disable auto-play for motion-heavy content
            if content.isAutoPlaying && content.hasMotion {
                modifiedContent = MotionReductionRequest.ReductionTarget.ContentElement(
                    elementId: content.elementId,
                    contentType: content.contentType,
                    isAutoPlaying: false,
                    hasMotion: content.hasMotion,
                    motionIntensity: content.motionIntensity,
                    canBePaused: true,
                    alternativeAvailable: content.alternativeAvailable || options.replaceWithStaticContent
                )
                wasAutoPlayDisabled = true
                playControlsAdded = true
                userConsentRequired = content.motionIntensity > 0.5
            }
            
            // Provide static alternatives
            if options.replaceWithStaticContent && content.hasMotion {
                staticAlternativeProvided = true
            }
            
            return MotionReductionResult.ModifiedContent(
                originalContent: content,
                modifiedContent: modifiedContent,
                wasAutoPlayDisabled: wasAutoPlayDisabled,
                staticAlternativeProvided: staticAlternativeProvided,
                playControlsAdded: playControlsAdded,
                userConsentRequired: userConsentRequired
            )
        }
    }
    
    private class ReductionMetricsCalculator {
        func calculateMetrics(
            reducedAnimations: [MotionReductionResult.ReducedAnimation],
            disabledEffects: [MotionReductionResult.DisabledEffect],
            modifiedContent: [MotionReductionResult.ModifiedContent],
            adjustedInteractions: [MotionReductionResult.AdjustedInteraction]
        ) -> MotionReductionResult.ReductionMetrics {
            
            let totalElements = reducedAnimations.count + disabledEffects.count + modifiedContent.count + adjustedInteractions.count
            let animationsReduced = reducedAnimations.filter { $0.reductionApplied != .none }.count
            let effectsDisabled = disabledEffects.count
            let contentModified = modifiedContent.filter { $0.wasAutoPlayDisabled || $0.staticAlternativeProvided }.count
            let interactionsAdjusted = adjustedInteractions.filter { $0.feedbackReduced }.count
            
            let overallReduction = totalElements > 0 ? 
                Double(animationsReduced + effectsDisabled + contentModified + interactionsAdjusted) / Double(totalElements) : 0.0
            
            let accessibilityImprovement = calculateAccessibilityImprovement(
                reducedAnimations: reducedAnimations,
                disabledEffects: disabledEffects
            )
            
            let userExperienceScore = calculateUserExperienceScore(
                reducedAnimations: reducedAnimations,
                modifiedContent: modifiedContent
            )
            
            let performanceGain = calculatePerformanceGain(
                reducedAnimations: reducedAnimations,
                disabledEffects: disabledEffects
            )
            
            return MotionReductionResult.ReductionMetrics(
                totalElementsProcessed: totalElements,
                animationsReduced: animationsReduced,
                effectsDisabled: effectsDisabled,
                contentModified: contentModified,
                interactionsAdjusted: interactionsAdjusted,
                overallReductionLevel: overallReduction,
                accessibilityImprovement: accessibilityImprovement,
                userExperienceScore: userExperienceScore,
                performanceGain: performanceGain
            )
        }
        
        private func calculateAccessibilityImprovement(
            reducedAnimations: [MotionReductionResult.ReducedAnimation],
            disabledEffects: [MotionReductionResult.DisabledEffect]
        ) -> Double {
            let animationImprovements = reducedAnimations.filter { 
                $0.reductionApplied != .none && $0.originalDuration > 0.5 
            }.count
            
            let effectImprovements = disabledEffects.filter {
                $0.disabledReason == .accessibilityRequirement || $0.disabledReason == .motionSensitivity
            }.count
            
            let totalImprovements = animationImprovements + effectImprovements
            let totalElements = reducedAnimations.count + disabledEffects.count
            
            return totalElements > 0 ? Double(totalImprovements) / Double(totalElements) : 0.0
        }
        
        private func calculateUserExperienceScore(
            reducedAnimations: [MotionReductionResult.ReducedAnimation],
            modifiedContent: [MotionReductionResult.ModifiedContent]
        ) -> Double {
            let goodReductions = reducedAnimations.filter { 
                $0.replacementStrategy != .none || $0.newDuration < $0.originalDuration 
            }.count
            
            let goodContentMods = modifiedContent.filter { 
                $0.staticAlternativeProvided || $0.playControlsAdded 
            }.count
            
            let totalElements = reducedAnimations.count + modifiedContent.count
            
            return totalElements > 0 ? Double(goodReductions + goodContentMods) / Double(totalElements) : 0.0
        }
        
        private func calculatePerformanceGain(
            reducedAnimations: [MotionReductionResult.ReducedAnimation],
            disabledEffects: [MotionReductionResult.DisabledEffect]
        ) -> Double {
            let animationSavings = reducedAnimations.reduce(0.0) { savings, animation in
                savings + max(0.0, animation.originalDuration - animation.newDuration)
            }
            
            let effectSavings = Double(disabledEffects.count) * 0.1
            
            return min(1.0, (animationSavings + effectSavings) / 10.0)
        }
    }
    
    public init(configuration: ReducedMotionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 80_000_000, // 80MB for reduced motion processing
            cpu: 1.8, // Moderate CPU usage for motion analysis
            bandwidth: 0,
            storage: 25_000_000 // 25MB for motion profiles and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let reductionMemory = activeReductions.count * 8_000_000 // ~8MB per active reduction
            let cacheMemory = resultCache.count * 40_000 // ~40KB per cached result
            let historyMemory = reductionHistory.count * 20_000
            let motionMemory = 15_000_000 // Motion analysis engine overhead
            
            return ResourceUsage(
                memory: reductionMemory + cacheMemory + historyMemory + motionMemory,
                cpu: activeReductions.isEmpty ? 0.1 : 1.2,
                bandwidth: 0,
                storage: resultCache.count * 20_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Reduced motion is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableReducedMotionSupport
        }
        return false
    }
    
    public func release() async {
        activeReductions.removeAll()
        reductionHistory.removeAll()
        resultCache.removeAll()
        
        motionAnalyzer = MotionAnalyzer()
        animationReducer = AnimationReducer()
        effectDisabler = EffectDisabler()
        contentModifier = ContentModifier()
        metricsCalculator = ReductionMetricsCalculator()
        
        resultStreamContinuation?.finish()
        
        metrics = ReducedMotionCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        motionAnalyzer = MotionAnalyzer()
        animationReducer = AnimationReducer()
        effectDisabler = EffectDisabler()
        contentModifier = ContentModifier()
        metricsCalculator = ReductionMetricsCalculator()
        
        if configuration.enableLogging {
            print("[ReducedMotion] 🚀 Reduced Motion capability initialized")
            print("[ReducedMotion] 🎭 Reduction level: \(configuration.reductionLevel.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: ReducedMotionCapabilityConfiguration) async throws {
        // Update reduced motion configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<MotionReductionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Motion Reduction Processing
    
    public func performReduction(_ request: MotionReductionRequest) async throws -> MotionReductionResult {
        guard configuration.enableReducedMotionSupport else {
            throw ReducedMotionError.reducedMotionDisabled
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
        activeReductions[request.id] = request
        
        do {
            // Analyze motion sensitivity
            let sensitivityScore = motionAnalyzer.analyzeMotionSensitivity(
                animations: request.target.animationElements,
                effects: request.target.motionEffects,
                sensitivity: configuration.motionSensitivity
            )
            
            // Process animations
            let reducedAnimations = request.target.animationElements.map { animation in
                animationReducer.reduceAnimation(animation, reductionLevel: request.targetLevel, configuration: configuration)
            }
            
            // Process effects
            let disabledEffects = request.target.motionEffects.map { effect in
                effectDisabler.disableEffect(effect, sensitivity: configuration.motionSensitivity)
            }
            
            // Process content
            let modifiedContent = request.target.contentElements.map { content in
                contentModifier.modifyContent(content, options: request.options)
            }
            
            // Process interactions (simulate adjustment)
            let adjustedInteractions = request.target.interactionElements.map { interaction in
                adjustInteraction(interaction, options: request.options)
            }
            
            // Calculate metrics
            let reductionMetrics = metricsCalculator.calculateMetrics(
                reducedAnimations: reducedAnimations,
                disabledEffects: disabledEffects,
                modifiedContent: modifiedContent,
                adjustedInteractions: adjustedInteractions
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MotionReductionResult(
                requestId: request.id,
                reducedAnimations: reducedAnimations,
                disabledEffects: disabledEffects,
                modifiedContent: modifiedContent,
                adjustedInteractions: adjustedInteractions,
                reductionMetrics: reductionMetrics,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeReductions.removeValue(forKey: request.id)
            reductionHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logReduction(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = MotionReductionResult(
                requestId: request.id,
                reducedAnimations: [],
                disabledEffects: [],
                modifiedContent: [],
                adjustedInteractions: [],
                reductionMetrics: MotionReductionResult.ReductionMetrics(
                    totalElementsProcessed: 0,
                    animationsReduced: 0,
                    effectsDisabled: 0,
                    contentModified: 0,
                    interactionsAdjusted: 0,
                    overallReductionLevel: 0,
                    accessibilityImprovement: 0,
                    userExperienceScore: 0,
                    performanceGain: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? ReducedMotionError ?? ReducedMotionError.reductionFailed(error.localizedDescription)
            )
            
            activeReductions.removeValue(forKey: request.id)
            reductionHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logReduction(result)
            }
            
            throw error
        }
    }
    
    public func getActiveReductions() async -> [MotionReductionRequest] {
        return Array(activeReductions.values)
    }
    
    public func getReductionHistory(since: Date? = nil) async -> [MotionReductionResult] {
        if let since = since {
            return reductionHistory.filter { $0.timestamp >= since }
        }
        return reductionHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ReducedMotionCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ReducedMotionCapabilityMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func adjustInteraction(
        _ interaction: MotionReductionRequest.ReductionTarget.InteractionElement,
        options: MotionReductionRequest.ReductionOptions
    ) -> MotionReductionResult.AdjustedInteraction {
        
        var adjustedInteraction = interaction
        var feedbackReduced = false
        var alternativeFeedbackApplied = false
        var improvementApplied = 0.0
        
        if interaction.hasAnimatedFeedback && interaction.feedbackIntensity > 0.3 {
            adjustedInteraction = MotionReductionRequest.ReductionTarget.InteractionElement(
                elementId: interaction.elementId,
                interactionType: interaction.interactionType,
                hasAnimatedFeedback: false,
                feedbackIntensity: 0.1,
                canSimplifyFeedback: interaction.canSimplifyFeedback,
                alternativeFeedback: interaction.alternativeFeedback ?? "Simplified visual feedback"
            )
            feedbackReduced = true
            alternativeFeedbackApplied = interaction.alternativeFeedback != nil
            improvementApplied = interaction.feedbackIntensity - 0.1
        }
        
        return MotionReductionResult.AdjustedInteraction(
            originalInteraction: interaction,
            adjustedInteraction: adjustedInteraction,
            feedbackReduced: feedbackReduced,
            alternativeFeedbackApplied: alternativeFeedbackApplied,
            improvementApplied: improvementApplied
        )
    }
    
    private func generateCacheKey(for request: MotionReductionRequest) -> String {
        let targetHash = request.target.identifier.hashValue
        let levelHash = request.targetLevel.rawValue.hashValue
        let typeHash = request.reductionType.rawValue.hashValue
        
        return "\(targetHash)_\(levelHash)_\(typeHash)"
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit metrics
    }
    
    private func updateSuccessMetrics(_ result: MotionReductionResult) async {
        let totalReductions = metrics.totalReductions + 1
        let successfulReductions = metrics.successfulReductions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalReductions)) + result.processingTime) / Double(totalReductions)
        let newAverageReductionLevel = ((metrics.averageReductionLevel * Double(metrics.successfulReductions)) + result.reductionMetrics.overallReductionLevel) / Double(successfulReductions)
        let newAverageAccessibilityImprovement = ((metrics.averageAccessibilityImprovement * Double(metrics.successfulReductions)) + result.reductionMetrics.accessibilityImprovement) / Double(successfulReductions)
        
        var reductionsByType = metrics.reductionsByType
        reductionsByType["reducedMotion", default: 0] += 1
        
        var reductionsByLevel = metrics.reductionsByLevel
        reductionsByLevel["effective", default: 0] += 1
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let fastestReduction = metrics.successfulReductions == 0 ? result.processingTime : min(performanceStats.fastestReduction, result.processingTime)
        let slowestReduction = max(performanceStats.slowestReduction, result.processingTime)
        let newAverageAnimationsPerReduction = ((performanceStats.averageAnimationsPerReduction * Double(metrics.successfulReductions)) + Double(result.reducedAnimations.count)) / Double(successfulReductions)
        let newAverageEffectsPerReduction = ((performanceStats.averageEffectsPerReduction * Double(metrics.successfulReductions)) + Double(result.disabledEffects.count)) / Double(successfulReductions)
        let totalAnimationsProcessed = performanceStats.totalAnimationsProcessed + result.reductionMetrics.animationsReduced
        let totalEffectsDisabled = performanceStats.totalEffectsDisabled + result.reductionMetrics.effectsDisabled
        let newUserSatisfactionRate = ((performanceStats.userSatisfactionRate * Double(metrics.successfulReductions)) + result.reductionMetrics.userExperienceScore) / Double(successfulReductions)
        
        performanceStats = ReducedMotionCapabilityMetrics.PerformanceStats(
            fastestReduction: fastestReduction,
            slowestReduction: slowestReduction,
            averageAnimationsPerReduction: newAverageAnimationsPerReduction,
            averageEffectsPerReduction: newAverageEffectsPerReduction,
            totalAnimationsProcessed: totalAnimationsProcessed,
            totalEffectsDisabled: totalEffectsDisabled,
            userSatisfactionRate: newUserSatisfactionRate
        )
        
        metrics = ReducedMotionCapabilityMetrics(
            totalReductions: totalReductions,
            successfulReductions: successfulReductions,
            failedReductions: metrics.failedReductions,
            averageProcessingTime: newAverageProcessingTime,
            reductionsByType: reductionsByType,
            reductionsByLevel: reductionsByLevel,
            averageReductionLevel: newAverageReductionLevel,
            averageAccessibilityImprovement: newAverageAccessibilityImprovement,
            errorsByType: metrics.errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: MotionReductionResult) async {
        let totalReductions = metrics.totalReductions + 1
        let failedReductions = metrics.failedReductions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = ReducedMotionCapabilityMetrics(
            totalReductions: totalReductions,
            successfulReductions: metrics.successfulReductions,
            failedReductions: failedReductions,
            averageProcessingTime: metrics.averageProcessingTime,
            reductionsByType: metrics.reductionsByType,
            reductionsByLevel: metrics.reductionsByLevel,
            averageReductionLevel: metrics.averageReductionLevel,
            averageAccessibilityImprovement: metrics.averageAccessibilityImprovement,
            errorsByType: errorsByType,
            throughputPerMinute: metrics.throughputPerMinute,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logReduction(_ result: MotionReductionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let levelStr = String(format: "%.1f", result.reductionMetrics.overallReductionLevel * 100)
        let animationCount = result.reducedAnimations.count
        let effectCount = result.disabledEffects.count
        let effectivenessStr = String(format: "%.1f", result.reductionEffectiveness * 100)
        
        print("[ReducedMotion] \(statusIcon) Reduction: \(levelStr)% level, \(animationCount) animations, \(effectCount) effects, \(effectivenessStr)% effective (\(timeStr)s)")
        
        if let error = result.error {
            print("[ReducedMotion] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Reduced Motion Capability Implementation

/// Reduced Motion capability providing reduced motion UI adjustments
@available(iOS 13.0, macOS 10.15, *)
public actor ReducedMotionCapability: DomainCapability {
    public typealias ConfigurationType = ReducedMotionCapabilityConfiguration
    public typealias ResourceType = ReducedMotionCapabilityResource
    
    private var _configuration: ReducedMotionCapabilityConfiguration
    private var _resources: ReducedMotionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(6)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "reduced-motion-capability" }
    
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
    
    public var configuration: ReducedMotionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ReducedMotionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ReducedMotionCapabilityConfiguration = ReducedMotionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ReducedMotionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ReducedMotionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Reduced Motion configuration")
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
        // Reduced Motion is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Reduced Motion doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Reduced Motion Operations
    
    /// Perform motion reduction
    public func performReduction(_ request: MotionReductionRequest) async throws -> MotionReductionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        return try await _resources.performReduction(request)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<MotionReductionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active reductions
    public func getActiveReductions() async throws -> [MotionReductionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        return await _resources.getActiveReductions()
    }
    
    /// Get reduction history
    public func getReductionHistory(since: Date? = nil) async throws -> [MotionReductionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        return await _resources.getReductionHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ReducedMotionCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Reduced Motion capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create animation reduction request
    public func createAnimationReductionRequest(
        animationId: String,
        duration: TimeInterval,
        animationType: MotionReductionRequest.ReductionTarget.AnimationElement.AnimationType = .fade,
        targetLevel: ReducedMotionCapabilityConfiguration.ReductionLevel = .moderate
    ) -> MotionReductionRequest {
        let animationElement = MotionReductionRequest.ReductionTarget.AnimationElement(
            elementId: animationId,
            animationType: animationType,
            duration: duration,
            properties: []
        )
        
        let target = MotionReductionRequest.ReductionTarget(
            targetType: .singleAnimation,
            identifier: animationId,
            animationElements: [animationElement],
            motionEffects: [],
            contentElements: [],
            interactionElements: []
        )
        
        return MotionReductionRequest(
            target: target,
            reductionType: .reduceAnimations,
            targetLevel: targetLevel
        )
    }
    
    /// Create parallax effect disable request
    public func createParallaxDisableRequest(
        effectId: String,
        intensity: Double = 1.0
    ) -> MotionReductionRequest {
        let motionEffect = MotionReductionRequest.ReductionTarget.MotionEffect(
            effectId: effectId,
            effectType: .parallax,
            intensity: intensity
        )
        
        let target = MotionReductionRequest.ReductionTarget(
            targetType: .singleAnimation,
            identifier: effectId,
            animationElements: [],
            motionEffects: [motionEffect],
            contentElements: [],
            interactionElements: []
        )
        
        return MotionReductionRequest(
            target: target,
            reductionType: .disableParallax,
            targetLevel: .complete
        )
    }
    
    /// Create auto-play control request
    public func createAutoPlayControlRequest(
        contentId: String,
        contentType: MotionReductionRequest.ReductionTarget.ContentElement.ContentType = .video,
        hasMotion: Bool = true
    ) -> MotionReductionRequest {
        let contentElement = MotionReductionRequest.ReductionTarget.ContentElement(
            elementId: contentId,
            contentType: contentType,
            isAutoPlaying: true,
            hasMotion: hasMotion,
            motionIntensity: hasMotion ? 0.8 : 0.0
        )
        
        let target = MotionReductionRequest.ReductionTarget(
            targetType: .singleAnimation,
            identifier: contentId,
            animationElements: [],
            motionEffects: [],
            contentElements: [contentElement],
            interactionElements: []
        )
        
        return MotionReductionRequest(
            target: target,
            reductionType: .pauseAutoPlay,
            targetLevel: .moderate
        )
    }
    
    /// Check if system reduced motion is enabled
    public func isSystemReducedMotionEnabled() async throws -> Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    /// Get current motion sensitivity setting
    public func getCurrentMotionSensitivity() async throws -> ReducedMotionCapabilityConfiguration.MotionSensitivity {
        let systemReducedMotion = UIAccessibility.isReduceMotionEnabled
        
        if systemReducedMotion {
            return .high
        } else {
            return .medium
        }
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Reduced Motion specific errors
public enum ReducedMotionError: Error, LocalizedError {
    case reducedMotionDisabled
    case reductionFailed(String)
    case invalidMotionData
    case unsupportedAnimationType
    case effectDisableFailed
    case contentModificationFailed
    case systemIntegrationFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .reducedMotionDisabled:
            return "Reduced motion support is disabled"
        case .reductionFailed(let reason):
            return "Motion reduction failed: \(reason)"
        case .invalidMotionData:
            return "Invalid motion data provided"
        case .unsupportedAnimationType:
            return "Unsupported animation type"
        case .effectDisableFailed:
            return "Effect disable operation failed"
        case .contentModificationFailed:
            return "Content modification failed"
        case .systemIntegrationFailed:
            return "System integration failed"
        case .configurationError(let reason):
            return "Reduced motion configuration error: \(reason)"
        }
    }
}