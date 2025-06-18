import Foundation
import QuartzCore
import CoreGraphics
import UIKit
import AxiomCore
import AxiomCapabilities

// MARK: - Core Animation Capability Configuration

/// Configuration for Core Animation capability
public struct CoreAnimationCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableCoreAnimation: Bool
    public let enablePerformanceOptimization: Bool
    public let enableDebugMode: Bool
    public let enableHardwareAcceleration: Bool
    public let enableAnimationCaching: Bool
    public let enableTimelineRecording: Bool
    public let maxConcurrentAnimations: Int
    public let animationTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let animationQuality: AnimationQuality
    public let renderingEngine: RenderingEngine
    public let performanceMode: PerformanceMode
    public let frameRate: FrameRate
    
    public enum AnimationQuality: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case ultra = "ultra"
    }
    
    public enum RenderingEngine: String, Codable, CaseIterable {
        case coreAnimation = "coreAnimation"
        case metal = "metal"
        case openGL = "openGL"
        case software = "software"
    }
    
    public enum PerformanceMode: String, Codable, CaseIterable {
        case powerSaving = "powerSaving"
        case balanced = "balanced"
        case performance = "performance"
        case adaptive = "adaptive"
    }
    
    public enum FrameRate: String, Codable, CaseIterable {
        case fps24 = "fps24"
        case fps30 = "fps30"
        case fps60 = "fps60"
        case fps120 = "fps120"
        case adaptive = "adaptive"
    }
    
    public init(
        enableCoreAnimation: Bool = true,
        enablePerformanceOptimization: Bool = true,
        enableDebugMode: Bool = false,
        enableHardwareAcceleration: Bool = true,
        enableAnimationCaching: Bool = true,
        enableTimelineRecording: Bool = false,
        maxConcurrentAnimations: Int = 20,
        animationTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        animationQuality: AnimationQuality = .high,
        renderingEngine: RenderingEngine = .coreAnimation,
        performanceMode: PerformanceMode = .balanced,
        frameRate: FrameRate = .fps60
    ) {
        self.enableCoreAnimation = enableCoreAnimation
        self.enablePerformanceOptimization = enablePerformanceOptimization
        self.enableDebugMode = enableDebugMode
        self.enableHardwareAcceleration = enableHardwareAcceleration
        self.enableAnimationCaching = enableAnimationCaching
        self.enableTimelineRecording = enableTimelineRecording
        self.maxConcurrentAnimations = maxConcurrentAnimations
        self.animationTimeout = animationTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.animationQuality = animationQuality
        self.renderingEngine = renderingEngine
        self.performanceMode = performanceMode
        self.frameRate = frameRate
    }
    
    public var isValid: Bool {
        maxConcurrentAnimations > 0 &&
        animationTimeout > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: CoreAnimationCapabilityConfiguration) -> CoreAnimationCapabilityConfiguration {
        CoreAnimationCapabilityConfiguration(
            enableCoreAnimation: other.enableCoreAnimation,
            enablePerformanceOptimization: other.enablePerformanceOptimization,
            enableDebugMode: other.enableDebugMode,
            enableHardwareAcceleration: other.enableHardwareAcceleration,
            enableAnimationCaching: other.enableAnimationCaching,
            enableTimelineRecording: other.enableTimelineRecording,
            maxConcurrentAnimations: other.maxConcurrentAnimations,
            animationTimeout: other.animationTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            animationQuality: other.animationQuality,
            renderingEngine: other.renderingEngine,
            performanceMode: other.performanceMode,
            frameRate: other.frameRate
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> CoreAnimationCapabilityConfiguration {
        var adjustedTimeout = animationTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentAnimations = maxConcurrentAnimations
        var adjustedCacheSize = cacheSize
        var adjustedAnimationQuality = animationQuality
        var adjustedDebugMode = enableDebugMode
        var adjustedPerformanceMode = performanceMode
        var adjustedFrameRate = frameRate
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(animationTimeout, 15.0)
            adjustedConcurrentAnimations = min(maxConcurrentAnimations, 8)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedAnimationQuality = .low
            adjustedPerformanceMode = .powerSaving
            adjustedFrameRate = .fps30
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedDebugMode = true
        }
        
        return CoreAnimationCapabilityConfiguration(
            enableCoreAnimation: enableCoreAnimation,
            enablePerformanceOptimization: enablePerformanceOptimization,
            enableDebugMode: adjustedDebugMode,
            enableHardwareAcceleration: enableHardwareAcceleration,
            enableAnimationCaching: enableAnimationCaching,
            enableTimelineRecording: enableTimelineRecording,
            maxConcurrentAnimations: adjustedConcurrentAnimations,
            animationTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            animationQuality: adjustedAnimationQuality,
            renderingEngine: renderingEngine,
            performanceMode: adjustedPerformanceMode,
            frameRate: adjustedFrameRate
        )
    }
}

// MARK: - Core Animation Types

/// Core Animation request
public struct CoreAnimationRequest: Sendable, Identifiable {
    public let id: UUID
    public let animation: AnimationDescriptor
    public let options: AnimationOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct AnimationDescriptor: Sendable {
        public let animationType: AnimationType
        public let targetLayer: LayerDescriptor
        public let properties: AnimationProperties
        public let timeline: Timeline
        public let easing: EasingFunction
        public let repeatConfiguration: RepeatConfiguration
        
        public enum AnimationType: String, Sendable, CaseIterable {
            case basic = "basic"
            case keyframe = "keyframe"
            case group = "group"
            case transition = "transition"
            case spring = "spring"
            case path = "path"
            case shape = "shape"
            case particle = "particle"
            case transform3D = "transform3D"
            case custom = "custom"
        }
        
        public struct LayerDescriptor: Sendable {
            public let layerId: String
            public let layerType: LayerType
            public let frame: CGRect
            public let bounds: CGRect
            public let position: CGPoint
            public let anchorPoint: CGPoint
            public let transform: CATransform3D
            public let opacity: Float
            public let backgroundColor: CGColor?
            public let cornerRadius: CGFloat
            public let borderWidth: CGFloat
            public let borderColor: CGColor?
            public let shadowOffset: CGSize
            public let shadowRadius: CGFloat
            public let shadowOpacity: Float
            public let shadowColor: CGColor?
            public let masksToBounds: Bool
            
            public enum LayerType: String, Sendable, CaseIterable {
                case layer = "layer"
                case shapeLayer = "shapeLayer"
                case textLayer = "textLayer"
                case gradientLayer = "gradientLayer"
                case emitterLayer = "emitterLayer"
                case scrollLayer = "scrollLayer"
                case tiledLayer = "tiledLayer"
                case transformLayer = "transformLayer"
                case replicatorLayer = "replicatorLayer"
                case metalLayer = "metalLayer"
            }
            
            public init(layerId: String, layerType: LayerType = .layer, frame: CGRect = .zero, bounds: CGRect = .zero, position: CGPoint = .zero, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5), transform: CATransform3D = CATransform3DIdentity, opacity: Float = 1.0, backgroundColor: CGColor? = nil, cornerRadius: CGFloat = 0, borderWidth: CGFloat = 0, borderColor: CGColor? = nil, shadowOffset: CGSize = .zero, shadowRadius: CGFloat = 0, shadowOpacity: Float = 0, shadowColor: CGColor? = nil, masksToBounds: Bool = false) {
                self.layerId = layerId
                self.layerType = layerType
                self.frame = frame
                self.bounds = bounds
                self.position = position
                self.anchorPoint = anchorPoint
                self.transform = transform
                self.opacity = opacity
                self.backgroundColor = backgroundColor
                self.cornerRadius = cornerRadius
                self.borderWidth = borderWidth
                self.borderColor = borderColor
                self.shadowOffset = shadowOffset
                self.shadowRadius = shadowRadius
                self.shadowOpacity = shadowOpacity
                self.shadowColor = shadowColor
                self.masksToBounds = masksToBounds
            }
        }
        
        public struct AnimationProperties: Sendable {
            public let animatedProperties: [AnimatedProperty]
            public let fromValues: [String: PropertyValue]
            public let toValues: [String: PropertyValue]
            public let byValues: [String: PropertyValue]
            public let keyframes: [Keyframe]
            
            public struct AnimatedProperty: Sendable {
                public let keyPath: String
                public let propertyType: PropertyType
                public let isAdditive: Bool
                public let isCumulative: Bool
                
                public enum PropertyType: String, Sendable, CaseIterable {
                    case position = "position"
                    case bounds = "bounds"
                    case frame = "frame"
                    case opacity = "opacity"
                    case backgroundColor = "backgroundColor"
                    case cornerRadius = "cornerRadius"
                    case borderWidth = "borderWidth"
                    case transform = "transform"
                    case shadowOffset = "shadowOffset"
                    case shadowRadius = "shadowRadius"
                    case shadowOpacity = "shadowOpacity"
                    case strokeStart = "strokeStart"
                    case strokeEnd = "strokeEnd"
                    case lineWidth = "lineWidth"
                    case fillColor = "fillColor"
                    case strokeColor = "strokeColor"
                    case path = "path"
                    case custom = "custom"
                }
                
                public init(keyPath: String, propertyType: PropertyType, isAdditive: Bool = false, isCumulative: Bool = false) {
                    self.keyPath = keyPath
                    self.propertyType = propertyType
                    self.isAdditive = isAdditive
                    self.isCumulative = isCumulative
                }
            }
            
            public struct PropertyValue: Sendable, Codable {
                public let value: ValueType
                
                public enum ValueType: Sendable, Codable {
                    case number(Double)
                    case point(CGPoint)
                    case size(CGSize)
                    case rect(CGRect)
                    case color(ColorValue)
                    case transform(TransformValue)
                    case path(PathValue)
                    case array([Double])
                    
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
                    
                    public struct TransformValue: Sendable, Codable {
                        public let m11: Double
                        public let m12: Double
                        public let m13: Double
                        public let m14: Double
                        public let m21: Double
                        public let m22: Double
                        public let m23: Double
                        public let m24: Double
                        public let m31: Double
                        public let m32: Double
                        public let m33: Double
                        public let m34: Double
                        public let m41: Double
                        public let m42: Double
                        public let m43: Double
                        public let m44: Double
                        
                        public init(transform: CATransform3D) {
                            self.m11 = Double(transform.m11)
                            self.m12 = Double(transform.m12)
                            self.m13 = Double(transform.m13)
                            self.m14 = Double(transform.m14)
                            self.m21 = Double(transform.m21)
                            self.m22 = Double(transform.m22)
                            self.m23 = Double(transform.m23)
                            self.m24 = Double(transform.m24)
                            self.m31 = Double(transform.m31)
                            self.m32 = Double(transform.m32)
                            self.m33 = Double(transform.m33)
                            self.m34 = Double(transform.m34)
                            self.m41 = Double(transform.m41)
                            self.m42 = Double(transform.m42)
                            self.m43 = Double(transform.m43)
                            self.m44 = Double(transform.m44)
                        }
                    }
                    
                    public struct PathValue: Sendable, Codable {
                        public let pathData: String
                        public let pathBounds: CGRect
                        
                        public init(pathData: String, pathBounds: CGRect) {
                            self.pathData = pathData
                            self.pathBounds = pathBounds
                        }
                    }
                }
                
                public init(value: ValueType) {
                    self.value = value
                }
            }
            
            public struct Keyframe: Sendable {
                public let time: Double
                public let value: PropertyValue
                public let timingFunction: EasingFunction
                
                public init(time: Double, value: PropertyValue, timingFunction: EasingFunction = .linear) {
                    self.time = time
                    self.value = value
                    self.timingFunction = timingFunction
                }
            }
            
            public init(animatedProperties: [AnimatedProperty], fromValues: [String: PropertyValue] = [:], toValues: [String: PropertyValue] = [:], byValues: [String: PropertyValue] = [:], keyframes: [Keyframe] = []) {
                self.animatedProperties = animatedProperties
                self.fromValues = fromValues
                self.toValues = toValues
                self.byValues = byValues
                self.keyframes = keyframes
            }
        }
        
        public struct Timeline: Sendable {
            public let duration: TimeInterval
            public let delay: TimeInterval
            public let beginTime: CFTimeInterval
            public let timeOffset: CFTimeInterval
            public let fillMode: FillMode
            public let removedOnCompletion: Bool
            
            public enum FillMode: String, Sendable, CaseIterable {
                case removed = "removed"
                case forwards = "forwards"
                case backwards = "backwards"
                case both = "both"
            }
            
            public init(duration: TimeInterval, delay: TimeInterval = 0, beginTime: CFTimeInterval = 0, timeOffset: CFTimeInterval = 0, fillMode: FillMode = .removed, removedOnCompletion: Bool = true) {
                self.duration = duration
                self.delay = delay
                self.beginTime = beginTime
                self.timeOffset = timeOffset
                self.fillMode = fillMode
                self.removedOnCompletion = removedOnCompletion
            }
        }
        
        public struct RepeatConfiguration: Sendable {
            public let repeatCount: Float
            public let repeatDuration: CFTimeInterval
            public let autoreverses: Bool
            
            public init(repeatCount: Float = 1.0, repeatDuration: CFTimeInterval = 0, autoreverses: Bool = false) {
                self.repeatCount = repeatCount
                self.repeatDuration = repeatDuration
                self.autoreverses = autoreverses
            }
        }
        
        public init(animationType: AnimationType, targetLayer: LayerDescriptor, properties: AnimationProperties, timeline: Timeline, easing: EasingFunction = .linear, repeatConfiguration: RepeatConfiguration = RepeatConfiguration()) {
            self.animationType = animationType
            self.targetLayer = targetLayer
            self.properties = properties
            self.timeline = timeline
            self.easing = easing
            self.repeatConfiguration = repeatConfiguration
        }
    }
    
    public enum EasingFunction: String, Sendable, CaseIterable {
        case linear = "linear"
        case easeIn = "easeIn"
        case easeOut = "easeOut"
        case easeInOut = "easeInOut"
        case easeInQuad = "easeInQuad"
        case easeOutQuad = "easeOutQuad"
        case easeInOutQuad = "easeInOutQuad"
        case easeInCubic = "easeInCubic"
        case easeOutCubic = "easeOutCubic"
        case easeInOutCubic = "easeInOutCubic"
        case easeInQuart = "easeInQuart"
        case easeOutQuart = "easeOutQuart"
        case easeInOutQuart = "easeInOutQuart"
        case easeInQuint = "easeInQuint"
        case easeOutQuint = "easeOutQuint"
        case easeInOutQuint = "easeInOutQuint"
        case easeInSine = "easeInSine"
        case easeOutSine = "easeOutSine"
        case easeInOutSine = "easeInOutSine"
        case easeInExpo = "easeInExpo"
        case easeOutExpo = "easeOutExpo"
        case easeInOutExpo = "easeInOutExpo"
        case easeInCirc = "easeInCirc"
        case easeOutCirc = "easeOutCirc"
        case easeInOutCirc = "easeInOutCirc"
        case easeInBack = "easeInBack"
        case easeOutBack = "easeOutBack"
        case easeInOutBack = "easeInOutBack"
        case easeInElastic = "easeInElastic"
        case easeOutElastic = "easeOutElastic"
        case easeInOutElastic = "easeInOutElastic"
        case easeInBounce = "easeInBounce"
        case easeOutBounce = "easeOutBounce"
        case easeInOutBounce = "easeInOutBounce"
        case spring = "spring"
        case custom = "custom"
    }
    
    public struct AnimationOptions: Sendable {
        public let enableHardwareAcceleration: Bool
        public let enableDebugging: Bool
        public let enablePerformanceMetrics: Bool
        public let animationQuality: CoreAnimationCapabilityConfiguration.AnimationQuality
        public let renderingEngine: CoreAnimationCapabilityConfiguration.RenderingEngine
        public let frameRate: CoreAnimationCapabilityConfiguration.FrameRate
        public let enableTimelineRecording: Bool
        public let enableAnimationCaching: Bool
        public let customProperties: [String: String]
        
        public init(enableHardwareAcceleration: Bool = true, enableDebugging: Bool = false, enablePerformanceMetrics: Bool = true, animationQuality: CoreAnimationCapabilityConfiguration.AnimationQuality = .high, renderingEngine: CoreAnimationCapabilityConfiguration.RenderingEngine = .coreAnimation, frameRate: CoreAnimationCapabilityConfiguration.FrameRate = .fps60, enableTimelineRecording: Bool = false, enableAnimationCaching: Bool = true, customProperties: [String: String] = [:]) {
            self.enableHardwareAcceleration = enableHardwareAcceleration
            self.enableDebugging = enableDebugging
            self.enablePerformanceMetrics = enablePerformanceMetrics
            self.animationQuality = animationQuality
            self.renderingEngine = renderingEngine
            self.frameRate = frameRate
            self.enableTimelineRecording = enableTimelineRecording
            self.enableAnimationCaching = enableAnimationCaching
            self.customProperties = customProperties
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(animation: AnimationDescriptor, options: AnimationOptions = AnimationOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.animation = animation
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Core Animation result
public struct CoreAnimationResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let animationData: AnimationData
    public let performanceMetrics: PerformanceMetrics
    public let timeline: TimelineData
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: CoreAnimationError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct AnimationData: Sendable {
        public let animationId: String
        public let animationType: String
        public let layerId: String
        public let duration: TimeInterval
        public let frameCount: Int
        public let keyframeData: [KeyframeData]
        public let finalState: LayerState
        public let animationCurve: [AnimationSample]
        
        public struct KeyframeData: Sendable {
            public let time: Double
            public let frame: Int
            public let layerState: LayerState
            public let interpolatedValues: [String: Double]
            
            public init(time: Double, frame: Int, layerState: LayerState, interpolatedValues: [String: Double]) {
                self.time = time
                self.frame = frame
                self.layerState = layerState
                self.interpolatedValues = interpolatedValues
            }
        }
        
        public struct LayerState: Sendable {
            public let position: CGPoint
            public let bounds: CGRect
            public let opacity: Float
            public let transform: CATransform3D
            public let cornerRadius: CGFloat
            public let backgroundColor: CGColor?
            public let borderWidth: CGFloat
            public let borderColor: CGColor?
            public let shadowOpacity: Float
            public let shadowOffset: CGSize
            public let shadowRadius: CGFloat
            
            public init(position: CGPoint, bounds: CGRect, opacity: Float, transform: CATransform3D, cornerRadius: CGFloat, backgroundColor: CGColor?, borderWidth: CGFloat, borderColor: CGColor?, shadowOpacity: Float, shadowOffset: CGSize, shadowRadius: CGFloat) {
                self.position = position
                self.bounds = bounds
                self.opacity = opacity
                self.transform = transform
                self.cornerRadius = cornerRadius
                self.backgroundColor = backgroundColor
                self.borderWidth = borderWidth
                self.borderColor = borderColor
                self.shadowOpacity = shadowOpacity
                self.shadowOffset = shadowOffset
                self.shadowRadius = shadowRadius
            }
        }
        
        public struct AnimationSample: Sendable {
            public let time: Double
            public let value: Double
            public let velocity: Double
            public let acceleration: Double
            
            public init(time: Double, value: Double, velocity: Double = 0, acceleration: Double = 0) {
                self.time = time
                self.value = value
                self.velocity = velocity
                self.acceleration = acceleration
            }
        }
        
        public init(animationId: String, animationType: String, layerId: String, duration: TimeInterval, frameCount: Int, keyframeData: [KeyframeData], finalState: LayerState, animationCurve: [AnimationSample]) {
            self.animationId = animationId
            self.animationType = animationType
            self.layerId = layerId
            self.duration = duration
            self.frameCount = frameCount
            self.keyframeData = keyframeData
            self.finalState = finalState
            self.animationCurve = animationCurve
        }
    }
    
    public struct PerformanceMetrics: Sendable {
        public let totalAnimationTime: TimeInterval
        public let setupTime: TimeInterval
        public let renderTime: TimeInterval
        public let commitTime: TimeInterval
        public let frameRate: Double
        public let droppedFrames: Int
        public let averageFrameTime: TimeInterval
        public let peakMemoryUsage: Int
        public let gpuUtilization: Float
        public let cpuUtilization: Float
        public let powerConsumption: Float
        public let thermalState: ThermalState
        
        public enum ThermalState: String, Sendable, CaseIterable {
            case nominal = "nominal"
            case fair = "fair"
            case serious = "serious"
            case critical = "critical"
        }
        
        public init(totalAnimationTime: TimeInterval, setupTime: TimeInterval, renderTime: TimeInterval, commitTime: TimeInterval, frameRate: Double, droppedFrames: Int, averageFrameTime: TimeInterval, peakMemoryUsage: Int, gpuUtilization: Float, cpuUtilization: Float, powerConsumption: Float, thermalState: ThermalState) {
            self.totalAnimationTime = totalAnimationTime
            self.setupTime = setupTime
            self.renderTime = renderTime
            self.commitTime = commitTime
            self.frameRate = frameRate
            self.droppedFrames = droppedFrames
            self.averageFrameTime = averageFrameTime
            self.peakMemoryUsage = peakMemoryUsage
            self.gpuUtilization = gpuUtilization
            self.cpuUtilization = cpuUtilization
            self.powerConsumption = powerConsumption
            self.thermalState = thermalState
        }
    }
    
    public struct TimelineData: Sendable {
        public let startTime: CFTimeInterval
        public let endTime: CFTimeInterval
        public let actualDuration: TimeInterval
        public let scheduledDuration: TimeInterval
        public let delay: TimeInterval
        public let timelineEvents: [TimelineEvent]
        
        public struct TimelineEvent: Sendable {
            public let time: CFTimeInterval
            public let eventType: EventType
            public let description: String
            public let data: [String: String]
            
            public enum EventType: String, Sendable, CaseIterable {
                case animationStart = "animationStart"
                case animationEnd = "animationEnd"
                case keyframe = "keyframe"
                case propertyChange = "propertyChange"
                case layerUpdate = "layerUpdate"
                case renderFrame = "renderFrame"
                case performanceWarning = "performanceWarning"
                case error = "error"
            }
            
            public init(time: CFTimeInterval, eventType: EventType, description: String, data: [String: String] = [:]) {
                self.time = time
                self.eventType = eventType
                self.description = description
                self.data = data
            }
        }
        
        public init(startTime: CFTimeInterval, endTime: CFTimeInterval, actualDuration: TimeInterval, scheduledDuration: TimeInterval, delay: TimeInterval, timelineEvents: [TimelineEvent]) {
            self.startTime = startTime
            self.endTime = endTime
            self.actualDuration = actualDuration
            self.scheduledDuration = scheduledDuration
            self.delay = delay
            self.timelineEvents = timelineEvents
        }
    }
    
    public init(requestId: UUID, animationData: AnimationData, performanceMetrics: PerformanceMetrics, timeline: TimelineData, processingTime: TimeInterval, success: Bool, error: CoreAnimationError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.animationData = animationData
        self.performanceMetrics = performanceMetrics
        self.timeline = timeline
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var isPerformant: Bool {
        performanceMetrics.frameRate >= 30.0 && performanceMetrics.droppedFrames == 0
    }
    
    public var animationEfficiency: Double {
        guard timeline.scheduledDuration > 0 else { return 0.0 }
        return 1.0 - abs(timeline.actualDuration - timeline.scheduledDuration) / timeline.scheduledDuration
    }
    
    public var frameRateStability: Double {
        guard performanceMetrics.frameRate > 0 else { return 0.0 }
        let targetFrameRate = 60.0 // Assuming 60 FPS target
        return min(1.0, performanceMetrics.frameRate / targetFrameRate)
    }
}

/// Core Animation metrics
public struct CoreAnimationMetrics: Sendable {
    public let totalAnimationRequests: Int
    public let successfulAnimations: Int
    public let failedAnimations: Int
    public let averageProcessingTime: TimeInterval
    public let animationsByType: [String: Int]
    public let animationsByDuration: [String: Int]
    public let errorsByType: [String: Int]
    public let cacheHitRate: Double
    public let averageFrameRate: Double
    public let averageAnimationDuration: TimeInterval
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    public let hardwareStats: HardwareStats
    
    public struct PerformanceStats: Sendable {
        public let bestFrameRate: Double
        public let worstFrameRate: Double
        public let averageSetupTime: TimeInterval
        public let averageRenderTime: TimeInterval
        public let totalDroppedFrames: Int
        public let averageMemoryUsage: Int
        public let peakMemoryUsage: Int
        
        public init(bestFrameRate: Double = 0, worstFrameRate: Double = 0, averageSetupTime: TimeInterval = 0, averageRenderTime: TimeInterval = 0, totalDroppedFrames: Int = 0, averageMemoryUsage: Int = 0, peakMemoryUsage: Int = 0) {
            self.bestFrameRate = bestFrameRate
            self.worstFrameRate = worstFrameRate
            self.averageSetupTime = averageSetupTime
            self.averageRenderTime = averageRenderTime
            self.totalDroppedFrames = totalDroppedFrames
            self.averageMemoryUsage = averageMemoryUsage
            self.peakMemoryUsage = peakMemoryUsage
        }
    }
    
    public struct HardwareStats: Sendable {
        public let hardwareAcceleratedAnimations: Int
        public let softwareRenderedAnimations: Int
        public let averageGPUUtilization: Double
        public let averageCPUUtilization: Double
        public let thermalThrottlingEvents: Int
        public let powerOptimizationEvents: Int
        
        public init(hardwareAcceleratedAnimations: Int = 0, softwareRenderedAnimations: Int = 0, averageGPUUtilization: Double = 0, averageCPUUtilization: Double = 0, thermalThrottlingEvents: Int = 0, powerOptimizationEvents: Int = 0) {
            self.hardwareAcceleratedAnimations = hardwareAcceleratedAnimations
            self.softwareRenderedAnimations = softwareRenderedAnimations
            self.averageGPUUtilization = averageGPUUtilization
            self.averageCPUUtilization = averageCPUUtilization
            self.thermalThrottlingEvents = thermalThrottlingEvents
            self.powerOptimizationEvents = powerOptimizationEvents
        }
    }
    
    public init(totalAnimationRequests: Int = 0, successfulAnimations: Int = 0, failedAnimations: Int = 0, averageProcessingTime: TimeInterval = 0, animationsByType: [String: Int] = [:], animationsByDuration: [String: Int] = [:], errorsByType: [String: Int] = [:], cacheHitRate: Double = 0, averageFrameRate: Double = 0, averageAnimationDuration: TimeInterval = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats(), hardwareStats: HardwareStats = HardwareStats()) {
        self.totalAnimationRequests = totalAnimationRequests
        self.successfulAnimations = successfulAnimations
        self.failedAnimations = failedAnimations
        self.averageProcessingTime = averageProcessingTime
        self.animationsByType = animationsByType
        self.animationsByDuration = animationsByDuration
        self.errorsByType = errorsByType
        self.cacheHitRate = cacheHitRate
        self.averageFrameRate = averageFrameRate
        self.averageAnimationDuration = averageAnimationDuration
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalAnimationRequests) / averageProcessingTime : 0
        self.performanceStats = performanceStats
        self.hardwareStats = hardwareStats
    }
    
    public var successRate: Double {
        totalAnimationRequests > 0 ? Double(successfulAnimations) / Double(totalAnimationRequests) : 0
    }
}

// MARK: - Core Animation Resource

/// Core Animation resource management
@available(iOS 13.0, macOS 10.15, *)
public actor CoreAnimationCapabilityResource: AxiomCapabilityResource {
    private let configuration: CoreAnimationCapabilityConfiguration
    private var activeAnimations: [UUID: CoreAnimationRequest] = [:]
    private var animationQueue: [CoreAnimationRequest] = []
    private var animationHistory: [CoreAnimationResult] = []
    private var resultCache: [String: CoreAnimationResult] = [:]
    private var animationLayers: [String: CALayer] = [:]
    private var animationEngine: AnimationEngine = AnimationEngine()
    private var timelineRecorder: TimelineRecorder = TimelineRecorder()
    private var metrics: CoreAnimationMetrics = CoreAnimationMetrics()
    private var resultStreamContinuation: AsyncStream<CoreAnimationResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    // Helper classes for Core Animation simulation
    private class AnimationEngine {
        func createAnimation(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CAAnimation {
            switch descriptor.animationType {
            case .basic:
                return createBasicAnimation(from: descriptor)
            case .keyframe:
                return createKeyframeAnimation(from: descriptor)
            case .group:
                return createAnimationGroup(from: descriptor)
            case .spring:
                return createSpringAnimation(from: descriptor)
            case .path:
                return createPathAnimation(from: descriptor)
            default:
                return createBasicAnimation(from: descriptor)
            }
        }
        
        private func createBasicAnimation(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CABasicAnimation {
            let animation = CABasicAnimation()
            
            if let firstProperty = descriptor.properties.animatedProperties.first {
                animation.keyPath = firstProperty.keyPath
                animation.isAdditive = firstProperty.isAdditive
                animation.isCumulative = firstProperty.isCumulative
            }
            
            // Set timeline properties
            animation.duration = descriptor.timeline.duration
            animation.beginTime = descriptor.timeline.beginTime
            animation.timeOffset = descriptor.timeline.timeOffset
            animation.repeatCount = descriptor.repeatConfiguration.repeatCount
            animation.autoreverses = descriptor.repeatConfiguration.autoreverses
            animation.isRemovedOnCompletion = descriptor.timeline.removedOnCompletion
            
            // Set timing function based on easing
            animation.timingFunction = createTimingFunction(for: descriptor.easing)
            
            // Set fill mode
            switch descriptor.timeline.fillMode {
            case .removed:
                animation.fillMode = .removed
            case .forwards:
                animation.fillMode = .forwards
            case .backwards:
                animation.fillMode = .backwards
            case .both:
                animation.fillMode = .both
            }
            
            return animation
        }
        
        private func createKeyframeAnimation(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation()
            
            if let firstProperty = descriptor.properties.animatedProperties.first {
                animation.keyPath = firstProperty.keyPath
            }
            
            // Configure keyframes
            let keyframes = descriptor.properties.keyframes
            if !keyframes.isEmpty {
                animation.values = keyframes.map { convertPropertyValueToAny($0.value) }
                animation.keyTimes = keyframes.map { NSNumber(value: $0.time) }
                animation.timingFunctions = keyframes.map { createTimingFunction(for: $0.timingFunction) }
            }
            
            // Set timeline properties
            animation.duration = descriptor.timeline.duration
            animation.beginTime = descriptor.timeline.beginTime
            animation.repeatCount = descriptor.repeatConfiguration.repeatCount
            animation.autoreverses = descriptor.repeatConfiguration.autoreverses
            animation.isRemovedOnCompletion = descriptor.timeline.removedOnCompletion
            
            return animation
        }
        
        private func createAnimationGroup(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CAAnimationGroup {
            let group = CAAnimationGroup()
            
            // Create individual animations for each property
            var animations: [CAAnimation] = []
            for property in descriptor.properties.animatedProperties {
                let basicAnimation = CABasicAnimation(keyPath: property.keyPath)
                basicAnimation.duration = descriptor.timeline.duration
                basicAnimation.timingFunction = createTimingFunction(for: descriptor.easing)
                animations.append(basicAnimation)
            }
            
            group.animations = animations
            group.duration = descriptor.timeline.duration
            group.beginTime = descriptor.timeline.beginTime
            group.repeatCount = descriptor.repeatConfiguration.repeatCount
            group.autoreverses = descriptor.repeatConfiguration.autoreverses
            group.isRemovedOnCompletion = descriptor.timeline.removedOnCompletion
            
            return group
        }
        
        private func createSpringAnimation(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CASpringAnimation {
            let animation = CASpringAnimation()
            
            if let firstProperty = descriptor.properties.animatedProperties.first {
                animation.keyPath = firstProperty.keyPath
            }
            
            // Spring parameters (simplified)
            animation.mass = 1.0
            animation.stiffness = 100.0
            animation.damping = 10.0
            animation.initialVelocity = 0.0
            
            animation.duration = descriptor.timeline.duration
            animation.beginTime = descriptor.timeline.beginTime
            animation.repeatCount = descriptor.repeatConfiguration.repeatCount
            animation.autoreverses = descriptor.repeatConfiguration.autoreverses
            animation.isRemovedOnCompletion = descriptor.timeline.removedOnCompletion
            
            return animation
        }
        
        private func createPathAnimation(from descriptor: CoreAnimationRequest.AnimationDescriptor) -> CAKeyframeAnimation {
            let animation = CAKeyframeAnimation(keyPath: "position")
            
            // Create a simple path (in real implementation, this would use the path data)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 100, y: 100))
            animation.path = path.cgPath
            
            animation.duration = descriptor.timeline.duration
            animation.beginTime = descriptor.timeline.beginTime
            animation.repeatCount = descriptor.repeatConfiguration.repeatCount
            animation.autoreverses = descriptor.repeatConfiguration.autoreverses
            animation.isRemovedOnCompletion = descriptor.timeline.removedOnCompletion
            
            return animation
        }
        
        private func createTimingFunction(for easing: CoreAnimationRequest.EasingFunction) -> CAMediaTimingFunction {
            switch easing {
            case .linear:
                return CAMediaTimingFunction(name: .linear)
            case .easeIn:
                return CAMediaTimingFunction(name: .easeIn)
            case .easeOut:
                return CAMediaTimingFunction(name: .easeOut)
            case .easeInOut:
                return CAMediaTimingFunction(name: .easeInEaseOut)
            case .spring:
                return CAMediaTimingFunction(controlPoints: 0.5, 1.2, 0.5, 1.0)
            default:
                return CAMediaTimingFunction(name: .default)
            }
        }
        
        private func convertPropertyValueToAny(_ value: CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue) -> Any {
            switch value.value {
            case .number(let num):
                return NSNumber(value: num)
            case .point(let point):
                return NSValue(cgPoint: point)
            case .size(let size):
                return NSValue(cgSize: size)
            case .rect(let rect):
                return NSValue(cgRect: rect)
            case .color(let colorValue):
                return UIColor(red: colorValue.red, green: colorValue.green, blue: colorValue.blue, alpha: colorValue.alpha).cgColor
            case .transform(let transformValue):
                return NSValue(caTransform3D: CATransform3DIdentity) // Simplified
            case .path(_):
                return UIBezierPath().cgPath
            case .array(let array):
                return array.map { NSNumber(value: $0) }
            }
        }
    }
    
    private class TimelineRecorder {
        private var events: [CoreAnimationResult.TimelineData.TimelineEvent] = []
        
        func startRecording() {
            events.removeAll()
            recordEvent(.animationStart, description: "Animation recording started")
        }
        
        func recordEvent(_ type: CoreAnimationResult.TimelineData.TimelineEvent.EventType, description: String, data: [String: String] = [:]) {
            let event = CoreAnimationResult.TimelineData.TimelineEvent(
                time: CACurrentMediaTime(),
                eventType: type,
                description: description,
                data: data
            )
            events.append(event)
        }
        
        func stopRecording() -> [CoreAnimationResult.TimelineData.TimelineEvent] {
            recordEvent(.animationEnd, description: "Animation recording stopped")
            return events
        }
    }
    
    public init(configuration: CoreAnimationCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 600_000_000, // 600MB for Core Animation
            cpu: 4.0, // High CPU usage for animation processing
            bandwidth: 0,
            storage: 300_000_000 // 300MB for animation and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let animationMemory = activeAnimations.count * 30_000_000 // ~30MB per active animation
            let cacheMemory = resultCache.count * 200_000 // ~200KB per cached result
            let layerMemory = animationLayers.count * 100_000 // ~100KB per cached layer
            let historyMemory = animationHistory.count * 50_000
            let coreAnimationMemory = 100_000_000 // Core Animation system overhead
            
            return ResourceUsage(
                memory: animationMemory + cacheMemory + layerMemory + historyMemory + coreAnimationMemory,
                cpu: activeAnimations.isEmpty ? 0.5 : 3.5,
                bandwidth: 0,
                storage: resultCache.count * 100_000 + animationLayers.count * 50_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Core Animation is available on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return configuration.enableCoreAnimation
        }
        return false
    }
    
    public func release() async {
        activeAnimations.removeAll()
        animationQueue.removeAll()
        animationHistory.removeAll()
        resultCache.removeAll()
        animationLayers.removeAll()
        
        animationEngine = AnimationEngine()
        timelineRecorder = TimelineRecorder()
        
        resultStreamContinuation?.finish()
        
        metrics = CoreAnimationMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize Core Animation components
        animationEngine = AnimationEngine()
        timelineRecorder = TimelineRecorder()
        
        if configuration.enablePerformanceOptimization {
            await optimizePerformance()
        }
        
        if configuration.enableLogging {
            print("[CoreAnimation] 🚀 Core Animation capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: CoreAnimationCapabilityConfiguration) async throws {
        // Update Core Animation configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<CoreAnimationResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Core Animation
    
    public func animate(_ request: CoreAnimationRequest) async throws -> CoreAnimationResult {
        guard configuration.enableCoreAnimation else {
            throw CoreAnimationError.animationDisabled
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
        if activeAnimations.count >= configuration.maxConcurrentAnimations {
            animationQueue.append(request)
            throw CoreAnimationError.animationQueued(request.id)
        }
        
        let startTime = Date()
        activeAnimations[request.id] = request
        
        do {
            // Start timeline recording if enabled
            if configuration.enableTimelineRecording {
                timelineRecorder.startRecording()
            }
            
            // Perform Core Animation
            let result = try await performCoreAnimation(
                request: request,
                startTime: startTime
            )
            
            activeAnimations.removeValue(forKey: request.id)
            animationHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logAnimation(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processAnimationQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = CoreAnimationResult(
                requestId: request.id,
                animationData: CoreAnimationResult.AnimationData(
                    animationId: "error",
                    animationType: "error",
                    layerId: "error",
                    duration: 0,
                    frameCount: 0,
                    keyframeData: [],
                    finalState: CoreAnimationResult.AnimationData.LayerState(
                        position: .zero,
                        bounds: .zero,
                        opacity: 0,
                        transform: CATransform3DIdentity,
                        cornerRadius: 0,
                        backgroundColor: nil,
                        borderWidth: 0,
                        borderColor: nil,
                        shadowOpacity: 0,
                        shadowOffset: .zero,
                        shadowRadius: 0
                    ),
                    animationCurve: []
                ),
                performanceMetrics: CoreAnimationResult.PerformanceMetrics(
                    totalAnimationTime: processingTime,
                    setupTime: 0,
                    renderTime: 0,
                    commitTime: 0,
                    frameRate: 0,
                    droppedFrames: 0,
                    averageFrameTime: 0,
                    peakMemoryUsage: 0,
                    gpuUtilization: 0,
                    cpuUtilization: 0,
                    powerConsumption: 0,
                    thermalState: .nominal
                ),
                timeline: CoreAnimationResult.TimelineData(
                    startTime: CACurrentMediaTime(),
                    endTime: CACurrentMediaTime(),
                    actualDuration: 0,
                    scheduledDuration: 0,
                    delay: 0,
                    timelineEvents: []
                ),
                processingTime: processingTime,
                success: false,
                error: error as? CoreAnimationError ?? CoreAnimationError.animationError(error.localizedDescription)
            )
            
            activeAnimations.removeValue(forKey: request.id)
            animationHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logAnimation(result)
            }
            
            throw error
        }
    }
    
    public func cancelAnimation(_ requestId: UUID) async {
        activeAnimations.removeValue(forKey: requestId)
        animationQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[CoreAnimation] 🚫 Cancelled animation: \(requestId)")
        }
    }
    
    public func getActiveAnimations() async -> [CoreAnimationRequest] {
        return Array(activeAnimations.values)
    }
    
    public func getAnimationHistory(since: Date? = nil) async -> [CoreAnimationResult] {
        if let since = since {
            return animationHistory.filter { $0.timestamp >= since }
        }
        return animationHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> CoreAnimationMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = CoreAnimationMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
        animationLayers.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func optimizePerformance() async {
        if configuration.enableLogging {
            print("[CoreAnimation] ⚡ Performance optimization enabled")
        }
    }
    
    private func performCoreAnimation(
        request: CoreAnimationRequest,
        startTime: Date
    ) async throws -> CoreAnimationResult {
        
        // Create the Core Animation object
        let animation = animationEngine.createAnimation(from: request.animation)
        
        // Simulate animation execution
        let frameRate = getFrameRateValue(for: configuration.frameRate)
        let duration = request.animation.timeline.duration
        let frameCount = Int(duration * frameRate)
        
        // Generate keyframe data
        var keyframeData: [CoreAnimationResult.AnimationData.KeyframeData] = []
        for frame in 0..<frameCount {
            let time = Double(frame) / frameRate
            let progress = time / duration
            
            let layerState = interpolateLayerState(
                from: request.animation.targetLayer,
                progress: progress,
                easing: request.animation.easing
            )
            
            let keyframe = CoreAnimationResult.AnimationData.KeyframeData(
                time: time,
                frame: frame,
                layerState: layerState,
                interpolatedValues: [
                    "progress": progress,
                    "opacity": Double(layerState.opacity),
                    "positionX": Double(layerState.position.x),
                    "positionY": Double(layerState.position.y)
                ]
            )
            keyframeData.append(keyframe)
        }
        
        // Generate animation curve
        var animationCurve: [CoreAnimationResult.AnimationData.AnimationSample] = []
        for frame in 0..<frameCount {
            let time = Double(frame) / frameRate
            let progress = time / duration
            let easedProgress = applyEasing(progress, easing: request.animation.easing)
            
            let sample = CoreAnimationResult.AnimationData.AnimationSample(
                time: time,
                value: easedProgress,
                velocity: calculateVelocity(time: time, easing: request.animation.easing),
                acceleration: calculateAcceleration(time: time, easing: request.animation.easing)
            )
            animationCurve.append(sample)
        }
        
        // Calculate final state
        let finalState = interpolateLayerState(
            from: request.animation.targetLayer,
            progress: 1.0,
            easing: request.animation.easing
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Create performance metrics
        let performanceMetrics = CoreAnimationResult.PerformanceMetrics(
            totalAnimationTime: processingTime,
            setupTime: processingTime * 0.1,
            renderTime: processingTime * 0.7,
            commitTime: processingTime * 0.2,
            frameRate: frameRate,
            droppedFrames: 0, // Simulated - no dropped frames
            averageFrameTime: 1.0 / frameRate,
            peakMemoryUsage: frameCount * 1000, // 1KB per frame simulation
            gpuUtilization: request.options.enableHardwareAcceleration ? 0.4 : 0.0,
            cpuUtilization: 0.3,
            powerConsumption: 2.5, // 2.5W simulation
            thermalState: .nominal
        )
        
        // Create timeline data
        let timelineEvents = configuration.enableTimelineRecording ? timelineRecorder.stopRecording() : []
        let timeline = CoreAnimationResult.TimelineData(
            startTime: CACurrentMediaTime(),
            endTime: CACurrentMediaTime() + duration,
            actualDuration: duration,
            scheduledDuration: duration,
            delay: request.animation.timeline.delay,
            timelineEvents: timelineEvents
        )
        
        let animationData = CoreAnimationResult.AnimationData(
            animationId: request.id.uuidString,
            animationType: request.animation.animationType.rawValue,
            layerId: request.animation.targetLayer.layerId,
            duration: duration,
            frameCount: frameCount,
            keyframeData: keyframeData,
            finalState: finalState,
            animationCurve: animationCurve
        )
        
        return CoreAnimationResult(
            requestId: request.id,
            animationData: animationData,
            performanceMetrics: performanceMetrics,
            timeline: timeline,
            processingTime: processingTime,
            success: true,
            metadata: request.metadata
        )
    }
    
    private func getFrameRateValue(for frameRate: CoreAnimationCapabilityConfiguration.FrameRate) -> Double {
        switch frameRate {
        case .fps24: return 24.0
        case .fps30: return 30.0
        case .fps60: return 60.0
        case .fps120: return 120.0
        case .adaptive: return 60.0 // Default to 60 for adaptive
        }
    }
    
    private func interpolateLayerState(
        from layerDescriptor: CoreAnimationRequest.AnimationDescriptor.LayerDescriptor,
        progress: Double,
        easing: CoreAnimationRequest.EasingFunction
    ) -> CoreAnimationResult.AnimationData.LayerState {
        
        let easedProgress = applyEasing(progress, easing: easing)
        
        // Simplified interpolation - in real implementation would be more sophisticated
        let interpolatedOpacity = Float(Double(layerDescriptor.opacity) * easedProgress)
        let interpolatedX = layerDescriptor.position.x + CGFloat(100.0 * easedProgress) // Simulate movement
        let interpolatedY = layerDescriptor.position.y + CGFloat(50.0 * easedProgress)
        
        return CoreAnimationResult.AnimationData.LayerState(
            position: CGPoint(x: interpolatedX, y: interpolatedY),
            bounds: layerDescriptor.bounds,
            opacity: interpolatedOpacity,
            transform: layerDescriptor.transform,
            cornerRadius: layerDescriptor.cornerRadius,
            backgroundColor: layerDescriptor.backgroundColor,
            borderWidth: layerDescriptor.borderWidth,
            borderColor: layerDescriptor.borderColor,
            shadowOpacity: layerDescriptor.shadowOpacity,
            shadowOffset: layerDescriptor.shadowOffset,
            shadowRadius: layerDescriptor.shadowRadius
        )
    }
    
    private func applyEasing(_ progress: Double, easing: CoreAnimationRequest.EasingFunction) -> Double {
        switch easing {
        case .linear:
            return progress
        case .easeIn:
            return progress * progress
        case .easeOut:
            return 1.0 - pow(1.0 - progress, 2)
        case .easeInOut:
            return progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
        case .easeInQuad:
            return progress * progress
        case .easeOutQuad:
            return 1 - (1 - progress) * (1 - progress)
        case .easeInOutQuad:
            return progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
        case .spring:
            // Simplified spring easing
            let damping = 0.7
            let frequency = 1.5
            return 1 - pow(2.71828, -damping * progress) * cos(frequency * progress)
        default:
            return progress // Fallback to linear
        }
    }
    
    private func calculateVelocity(time: Double, easing: CoreAnimationRequest.EasingFunction) -> Double {
        // Simplified velocity calculation
        switch easing {
        case .linear:
            return 1.0
        case .easeIn:
            return 2.0 * time
        case .easeOut:
            return 2.0 * (1.0 - time)
        case .spring:
            return sin(time * .pi * 2) * 0.5
        default:
            return 1.0
        }
    }
    
    private func calculateAcceleration(time: Double, easing: CoreAnimationRequest.EasingFunction) -> Double {
        // Simplified acceleration calculation
        switch easing {
        case .linear:
            return 0.0
        case .easeIn:
            return 2.0
        case .easeOut:
            return -2.0
        case .spring:
            return cos(time * .pi * 2) * .pi
        default:
            return 0.0
        }
    }
    
    private func processAnimationQueue() async {
        guard !isProcessingQueue && !animationQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        animationQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !animationQueue.isEmpty && activeAnimations.count < configuration.maxConcurrentAnimations {
            let request = animationQueue.removeFirst()
            
            do {
                _ = try await animate(request)
            } catch {
                if configuration.enableLogging {
                    print("[CoreAnimation] ⚠️ Queued animation failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: CoreAnimationRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: CoreAnimationRequest) -> String {
        let animationHash = String(describing: request.animation).hashValue
        let optionsHash = String(describing: request.options).hashValue
        let qualityHash = configuration.animationQuality.rawValue.hashValue
        
        return "\(animationHash)_\(optionsHash)_\(qualityHash)"
    }
    
    private func updateCacheHitMetrics() async {
        let cacheHits = (metrics.cacheHitRate * Double(metrics.totalAnimationRequests)) + 1
        let totalRequests = metrics.totalAnimationRequests + 1
        let newCacheHitRate = cacheHits / Double(totalRequests)
        
        metrics = CoreAnimationMetrics(
            totalAnimationRequests: totalRequests,
            successfulAnimations: metrics.successfulAnimations + 1,
            failedAnimations: metrics.failedAnimations,
            averageProcessingTime: metrics.averageProcessingTime,
            animationsByType: metrics.animationsByType,
            animationsByDuration: metrics.animationsByDuration,
            errorsByType: metrics.errorsByType,
            cacheHitRate: newCacheHitRate,
            averageFrameRate: metrics.averageFrameRate,
            averageAnimationDuration: metrics.averageAnimationDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats,
            hardwareStats: metrics.hardwareStats
        )
    }
    
    private func updateSuccessMetrics(_ result: CoreAnimationResult) async {
        let totalRequests = metrics.totalAnimationRequests + 1
        let successfulAnimations = metrics.successfulAnimations + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalAnimationRequests)) + result.processingTime) / Double(totalRequests)
        
        var animationsByType = metrics.animationsByType
        animationsByType[result.animationData.animationType, default: 0] += 1
        
        var animationsByDuration = metrics.animationsByDuration
        let durationKey = getDurationKey(duration: result.animationData.duration)
        animationsByDuration[durationKey, default: 0] += 1
        
        let newAverageFrameRate = ((metrics.averageFrameRate * Double(metrics.successfulAnimations)) + result.performanceMetrics.frameRate) / Double(successfulAnimations)
        
        let newAverageAnimationDuration = ((metrics.averageAnimationDuration * Double(metrics.successfulAnimations)) + result.animationData.duration) / Double(successfulAnimations)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestFrameRate = max(performanceStats.bestFrameRate, result.performanceMetrics.frameRate)
        let worstFrameRate = min(performanceStats.worstFrameRate == 0 ? result.performanceMetrics.frameRate : performanceStats.worstFrameRate, result.performanceMetrics.frameRate)
        let newAverageSetupTime = ((performanceStats.averageSetupTime * Double(metrics.successfulAnimations)) + result.performanceMetrics.setupTime) / Double(successfulAnimations)
        let newAverageRenderTime = ((performanceStats.averageRenderTime * Double(metrics.successfulAnimations)) + result.performanceMetrics.renderTime) / Double(successfulAnimations)
        let totalDroppedFrames = performanceStats.totalDroppedFrames + result.performanceMetrics.droppedFrames
        let newAverageMemoryUsage = Int(((Double(performanceStats.averageMemoryUsage) * Double(metrics.successfulAnimations)) + Double(result.performanceMetrics.peakMemoryUsage)) / Double(successfulAnimations))
        let peakMemoryUsage = max(performanceStats.peakMemoryUsage, result.performanceMetrics.peakMemoryUsage)
        
        performanceStats = CoreAnimationMetrics.PerformanceStats(
            bestFrameRate: bestFrameRate,
            worstFrameRate: worstFrameRate,
            averageSetupTime: newAverageSetupTime,
            averageRenderTime: newAverageRenderTime,
            totalDroppedFrames: totalDroppedFrames,
            averageMemoryUsage: newAverageMemoryUsage,
            peakMemoryUsage: peakMemoryUsage
        )
        
        // Update hardware stats
        var hardwareStats = metrics.hardwareStats
        let hardwareAccelerated = hardwareStats.hardwareAcceleratedAnimations + (result.performanceMetrics.gpuUtilization > 0 ? 1 : 0)
        let softwareRendered = hardwareStats.softwareRenderedAnimations + (result.performanceMetrics.gpuUtilization == 0 ? 1 : 0)
        let newAverageGPUUtilization = ((hardwareStats.averageGPUUtilization * Double(metrics.successfulAnimations)) + Double(result.performanceMetrics.gpuUtilization)) / Double(successfulAnimations)
        let newAverageCPUUtilization = ((hardwareStats.averageCPUUtilization * Double(metrics.successfulAnimations)) + Double(result.performanceMetrics.cpuUtilization)) / Double(successfulAnimations)
        
        hardwareStats = CoreAnimationMetrics.HardwareStats(
            hardwareAcceleratedAnimations: hardwareAccelerated,
            softwareRenderedAnimations: softwareRendered,
            averageGPUUtilization: newAverageGPUUtilization,
            averageCPUUtilization: newAverageCPUUtilization,
            thermalThrottlingEvents: hardwareStats.thermalThrottlingEvents,
            powerOptimizationEvents: hardwareStats.powerOptimizationEvents
        )
        
        metrics = CoreAnimationMetrics(
            totalAnimationRequests: totalRequests,
            successfulAnimations: successfulAnimations,
            failedAnimations: metrics.failedAnimations,
            averageProcessingTime: newAverageProcessingTime,
            animationsByType: animationsByType,
            animationsByDuration: animationsByDuration,
            errorsByType: metrics.errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageFrameRate: newAverageFrameRate,
            averageAnimationDuration: newAverageAnimationDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats,
            hardwareStats: hardwareStats
        )
    }
    
    private func updateFailureMetrics(_ result: CoreAnimationResult) async {
        let totalRequests = metrics.totalAnimationRequests + 1
        let failedAnimations = metrics.failedAnimations + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = CoreAnimationMetrics(
            totalAnimationRequests: totalRequests,
            successfulAnimations: metrics.successfulAnimations,
            failedAnimations: failedAnimations,
            averageProcessingTime: metrics.averageProcessingTime,
            animationsByType: metrics.animationsByType,
            animationsByDuration: metrics.animationsByDuration,
            errorsByType: errorsByType,
            cacheHitRate: metrics.cacheHitRate,
            averageFrameRate: metrics.averageFrameRate,
            averageAnimationDuration: metrics.averageAnimationDuration,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats,
            hardwareStats: metrics.hardwareStats
        )
    }
    
    private func getDurationKey(duration: TimeInterval) -> String {
        switch duration {
        case 0..<0.5: return "short"
        case 0.5..<2.0: return "medium"
        case 2.0..<5.0: return "long"
        default: return "very-long"
        }
    }
    
    private func logAnimation(_ result: CoreAnimationResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let frameRate = String(format: "%.1f", result.performanceMetrics.frameRate)
        let frameCount = result.animationData.frameCount
        let animationType = result.animationData.animationType
        let duration = String(format: "%.3f", result.animationData.duration)
        let efficiency = String(format: "%.1f", result.animationEfficiency * 100)
        
        print("[CoreAnimation] \(statusIcon) Animation: \(animationType), \(frameCount) frames, \(frameRate) FPS, duration: \(duration)s, efficiency: \(efficiency)% (\(timeStr)s)")
        
        if let error = result.error {
            print("[CoreAnimation] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Core Animation Capability Implementation

/// Core Animation capability providing advanced animation features
@available(iOS 13.0, macOS 10.15, *)
public actor CoreAnimationCapability: DomainCapability {
    public typealias ConfigurationType = CoreAnimationCapabilityConfiguration
    public typealias ResourceType = CoreAnimationCapabilityResource
    
    private var _configuration: CoreAnimationCapabilityConfiguration
    private var _resources: CoreAnimationCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "core-animation-capability" }
    
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
    
    public var configuration: CoreAnimationCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: CoreAnimationCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: CoreAnimationCapabilityConfiguration = CoreAnimationCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = CoreAnimationCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: CoreAnimationCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Core Animation configuration")
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
        // Core Animation is supported on iOS 13+, macOS 10.15+
        if #available(iOS 13.0, macOS 10.15, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Core Animation doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Core Animation Operations
    
    /// Create and execute animations
    public func animate(_ request: CoreAnimationRequest) async throws -> CoreAnimationResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        return try await _resources.animate(request)
    }
    
    /// Cancel animation
    public func cancelAnimation(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        await _resources.cancelAnimation(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<CoreAnimationResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active animations
    public func getActiveAnimations() async throws -> [CoreAnimationRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        return await _resources.getActiveAnimations()
    }
    
    /// Get animation history
    public func getAnimationHistory(since: Date? = nil) async throws -> [CoreAnimationResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        return await _resources.getAnimationHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> CoreAnimationMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Core Animation capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create basic position animation
    public func createPositionAnimation(from startPosition: CGPoint, to endPosition: CGPoint, duration: TimeInterval, easing: CoreAnimationRequest.EasingFunction = .easeInOut) -> CoreAnimationRequest {
        let layerDescriptor = CoreAnimationRequest.AnimationDescriptor.LayerDescriptor(
            layerId: UUID().uuidString,
            position: startPosition
        )
        
        let animatedProperty = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.AnimatedProperty(
            keyPath: "position",
            propertyType: .position
        )
        
        let fromValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .point(startPosition)
        )
        
        let toValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .point(endPosition)
        )
        
        let properties = CoreAnimationRequest.AnimationDescriptor.AnimationProperties(
            animatedProperties: [animatedProperty],
            fromValues: ["position": fromValue],
            toValues: ["position": toValue]
        )
        
        let timeline = CoreAnimationRequest.AnimationDescriptor.Timeline(duration: duration)
        
        let animationDescriptor = CoreAnimationRequest.AnimationDescriptor(
            animationType: .basic,
            targetLayer: layerDescriptor,
            properties: properties,
            timeline: timeline,
            easing: easing
        )
        
        return CoreAnimationRequest(animation: animationDescriptor)
    }
    
    /// Create opacity fade animation
    public func createFadeAnimation(from startOpacity: Float, to endOpacity: Float, duration: TimeInterval, easing: CoreAnimationRequest.EasingFunction = .easeInOut) -> CoreAnimationRequest {
        let layerDescriptor = CoreAnimationRequest.AnimationDescriptor.LayerDescriptor(
            layerId: UUID().uuidString,
            opacity: startOpacity
        )
        
        let animatedProperty = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.AnimatedProperty(
            keyPath: "opacity",
            propertyType: .opacity
        )
        
        let fromValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .number(Double(startOpacity))
        )
        
        let toValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .number(Double(endOpacity))
        )
        
        let properties = CoreAnimationRequest.AnimationDescriptor.AnimationProperties(
            animatedProperties: [animatedProperty],
            fromValues: ["opacity": fromValue],
            toValues: ["opacity": toValue]
        )
        
        let timeline = CoreAnimationRequest.AnimationDescriptor.Timeline(duration: duration)
        
        let animationDescriptor = CoreAnimationRequest.AnimationDescriptor(
            animationType: .basic,
            targetLayer: layerDescriptor,
            properties: properties,
            timeline: timeline,
            easing: easing
        )
        
        return CoreAnimationRequest(animation: animationDescriptor)
    }
    
    /// Create spring animation
    public func createSpringAnimation(from startPosition: CGPoint, to endPosition: CGPoint, duration: TimeInterval) -> CoreAnimationRequest {
        let layerDescriptor = CoreAnimationRequest.AnimationDescriptor.LayerDescriptor(
            layerId: UUID().uuidString,
            position: startPosition
        )
        
        let animatedProperty = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.AnimatedProperty(
            keyPath: "position",
            propertyType: .position
        )
        
        let fromValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .point(startPosition)
        )
        
        let toValue = CoreAnimationRequest.AnimationDescriptor.AnimationProperties.PropertyValue(
            value: .point(endPosition)
        )
        
        let properties = CoreAnimationRequest.AnimationDescriptor.AnimationProperties(
            animatedProperties: [animatedProperty],
            fromValues: ["position": fromValue],
            toValues: ["position": toValue]
        )
        
        let timeline = CoreAnimationRequest.AnimationDescriptor.Timeline(duration: duration)
        
        let animationDescriptor = CoreAnimationRequest.AnimationDescriptor(
            animationType: .spring,
            targetLayer: layerDescriptor,
            properties: properties,
            timeline: timeline,
            easing: .spring
        )
        
        return CoreAnimationRequest(animation: animationDescriptor)
    }
    
    /// Check if animations are active
    public func hasActiveAnimations() async throws -> Bool {
        let activeAnimations = try await getActiveAnimations()
        return !activeAnimations.isEmpty
    }
    
    /// Get average frame rate
    public func getAverageFrameRate() async throws -> Double {
        let metrics = try await getMetrics()
        return metrics.averageFrameRate
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Core Animation specific errors
public enum CoreAnimationError: Error, LocalizedError {
    case animationDisabled
    case invalidAnimationDescriptor
    case layerCreationFailed
    case animationError(String)
    case animationQueued(UUID)
    case animationTimeout(UUID)
    case unsupportedAnimationType(String)
    case timingFunctionError
    case performanceThresholdExceeded
    case hardwareAccelerationFailed
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .animationDisabled:
            return "Core Animation is disabled"
        case .invalidAnimationDescriptor:
            return "Invalid animation descriptor provided"
        case .layerCreationFailed:
            return "Layer creation failed"
        case .animationError(let reason):
            return "Core Animation failed: \(reason)"
        case .animationQueued(let id):
            return "Animation queued: \(id)"
        case .animationTimeout(let id):
            return "Animation timeout: \(id)"
        case .unsupportedAnimationType(let type):
            return "Unsupported animation type: \(type)"
        case .timingFunctionError:
            return "Timing function configuration failed"
        case .performanceThresholdExceeded:
            return "Performance threshold exceeded"
        case .hardwareAccelerationFailed:
            return "Hardware acceleration failed"
        case .configurationError(let reason):
            return "Core Animation configuration error: \(reason)"
        }
    }
}