import Foundation
import UIKit
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - Touch Input Capability Configuration

/// Configuration for Touch Input capability
public struct TouchInputCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableTouchInput: Bool
    public let enableMultiTouch: Bool
    public let enableGestureRecognition: Bool
    public let enableForceTouch: Bool
    public let enableTouchPrediction: Bool
    public let enableTouchSmoothing: Bool
    public let maxConcurrentTouches: Int
    public let touchTimeout: TimeInterval
    public let minimumTouchDuration: TimeInterval
    public let maximumTouchDuration: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let touchSensitivity: TouchSensitivity
    public let gestureThresholds: GestureThresholds
    public let enableDebugOverlay: Bool
    public let touchSamplingRate: Int
    
    public enum TouchSensitivity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case adaptive = "adaptive"
    }
    
    public struct GestureThresholds: Codable {
        public let tapMaxDistance: CGFloat
        public let tapMaxDuration: TimeInterval
        public let longPressMinDuration: TimeInterval
        public let swipeMinDistance: CGFloat
        public let swipeMinVelocity: CGFloat
        public let pinchMinScale: CGFloat
        public let rotationMinAngle: CGFloat
        
        public init(
            tapMaxDistance: CGFloat = 10.0,
            tapMaxDuration: TimeInterval = 0.5,
            longPressMinDuration: TimeInterval = 0.8,
            swipeMinDistance: CGFloat = 50.0,
            swipeMinVelocity: CGFloat = 100.0,
            pinchMinScale: CGFloat = 0.1,
            rotationMinAngle: CGFloat = 0.1
        ) {
            self.tapMaxDistance = tapMaxDistance
            self.tapMaxDuration = tapMaxDuration
            self.longPressMinDuration = longPressMinDuration
            self.swipeMinDistance = swipeMinDistance
            self.swipeMinVelocity = swipeMinVelocity
            self.pinchMinScale = pinchMinScale
            self.rotationMinAngle = rotationMinAngle
        }
    }
    
    public init(
        enableTouchInput: Bool = true,
        enableMultiTouch: Bool = true,
        enableGestureRecognition: Bool = true,
        enableForceTouch: Bool = true,
        enableTouchPrediction: Bool = true,
        enableTouchSmoothing: Bool = true,
        maxConcurrentTouches: Int = 10,
        touchTimeout: TimeInterval = 5.0,
        minimumTouchDuration: TimeInterval = 0.01,
        maximumTouchDuration: TimeInterval = 60.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        touchSensitivity: TouchSensitivity = .medium,
        gestureThresholds: GestureThresholds = GestureThresholds(),
        enableDebugOverlay: Bool = false,
        touchSamplingRate: Int = 120
    ) {
        self.enableTouchInput = enableTouchInput
        self.enableMultiTouch = enableMultiTouch
        self.enableGestureRecognition = enableGestureRecognition
        self.enableForceTouch = enableForceTouch
        self.enableTouchPrediction = enableTouchPrediction
        self.enableTouchSmoothing = enableTouchSmoothing
        self.maxConcurrentTouches = maxConcurrentTouches
        self.touchTimeout = touchTimeout
        self.minimumTouchDuration = minimumTouchDuration
        self.maximumTouchDuration = maximumTouchDuration
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.touchSensitivity = touchSensitivity
        self.gestureThresholds = gestureThresholds
        self.enableDebugOverlay = enableDebugOverlay
        self.touchSamplingRate = touchSamplingRate
    }
    
    public var isValid: Bool {
        maxConcurrentTouches > 0 &&
        touchTimeout > 0 &&
        minimumTouchDuration >= 0 &&
        maximumTouchDuration > minimumTouchDuration &&
        cacheSize >= 0 &&
        touchSamplingRate > 0
    }
    
    public func merged(with other: TouchInputCapabilityConfiguration) -> TouchInputCapabilityConfiguration {
        TouchInputCapabilityConfiguration(
            enableTouchInput: other.enableTouchInput,
            enableMultiTouch: other.enableMultiTouch,
            enableGestureRecognition: other.enableGestureRecognition,
            enableForceTouch: other.enableForceTouch,
            enableTouchPrediction: other.enableTouchPrediction,
            enableTouchSmoothing: other.enableTouchSmoothing,
            maxConcurrentTouches: other.maxConcurrentTouches,
            touchTimeout: other.touchTimeout,
            minimumTouchDuration: other.minimumTouchDuration,
            maximumTouchDuration: other.maximumTouchDuration,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            touchSensitivity: other.touchSensitivity,
            gestureThresholds: other.gestureThresholds,
            enableDebugOverlay: other.enableDebugOverlay,
            touchSamplingRate: other.touchSamplingRate
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> TouchInputCapabilityConfiguration {
        var adjustedTimeout = touchTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentTouches = maxConcurrentTouches
        var adjustedCacheSize = cacheSize
        var adjustedSensitivity = touchSensitivity
        var adjustedDebugOverlay = enableDebugOverlay
        var adjustedSamplingRate = touchSamplingRate
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(touchTimeout, 2.0)
            adjustedConcurrentTouches = min(maxConcurrentTouches, 5)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedSensitivity = .low
            adjustedSamplingRate = min(touchSamplingRate, 60)
        }
        
        if environment.isDebug {
            adjustedLogging = true
            adjustedDebugOverlay = true
        }
        
        return TouchInputCapabilityConfiguration(
            enableTouchInput: enableTouchInput,
            enableMultiTouch: enableMultiTouch,
            enableGestureRecognition: enableGestureRecognition,
            enableForceTouch: enableForceTouch,
            enableTouchPrediction: enableTouchPrediction,
            enableTouchSmoothing: enableTouchSmoothing,
            maxConcurrentTouches: adjustedConcurrentTouches,
            touchTimeout: adjustedTimeout,
            minimumTouchDuration: minimumTouchDuration,
            maximumTouchDuration: maximumTouchDuration,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            touchSensitivity: adjustedSensitivity,
            gestureThresholds: gestureThresholds,
            enableDebugOverlay: adjustedDebugOverlay,
            touchSamplingRate: adjustedSamplingRate
        )
    }
}

// MARK: - Touch Input Types

/// Touch input event
public struct TouchInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let touchData: TouchData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct TouchData: Sendable {
        public let touches: [Touch]
        public let eventType: TouchEventType
        public let view: ViewInfo?
        public let gesture: RecognizedGesture?
        
        public struct Touch: Sendable, Identifiable {
            public let id: UUID
            public let phase: TouchPhase
            public let location: CGPoint
            public let previousLocation: CGPoint
            public let force: CGFloat
            public let maximumPossibleForce: CGFloat
            public let radius: CGFloat
            public let timestamp: TimeInterval
            public let estimationUpdateIndex: NSNumber?
            public let estimatedProperties: TouchProperties
            public let velocity: CGPoint
            public let acceleration: CGPoint
            
            public enum TouchPhase: String, Sendable, CaseIterable {
                case began = "began"
                case moved = "moved"
                case stationary = "stationary"
                case ended = "ended"
                case cancelled = "cancelled"
                case regionEntered = "regionEntered"
                case regionMoved = "regionMoved"
                case regionExited = "regionExited"
            }
            
            public struct TouchProperties: OptionSet, Sendable {
                public let rawValue: UInt
                
                public init(rawValue: UInt) {
                    self.rawValue = rawValue
                }
                
                public static let location = TouchProperties(rawValue: 1 << 0)
                public static let force = TouchProperties(rawValue: 1 << 1)
                public static let azimuth = TouchProperties(rawValue: 1 << 2)
                public static let altitude = TouchProperties(rawValue: 1 << 3)
                public static let radius = TouchProperties(rawValue: 1 << 4)
            }
            
            public init(phase: TouchPhase, location: CGPoint, previousLocation: CGPoint = .zero, force: CGFloat = 0, maximumPossibleForce: CGFloat = 0, radius: CGFloat = 0, timestamp: TimeInterval = 0, estimationUpdateIndex: NSNumber? = nil, estimatedProperties: TouchProperties = [], velocity: CGPoint = .zero, acceleration: CGPoint = .zero) {
                self.id = UUID()
                self.phase = phase
                self.location = location
                self.previousLocation = previousLocation
                self.force = force
                self.maximumPossibleForce = maximumPossibleForce
                self.radius = radius
                self.timestamp = timestamp
                self.estimationUpdateIndex = estimationUpdateIndex
                self.estimatedProperties = estimatedProperties
                self.velocity = velocity
                self.acceleration = acceleration
            }
        }
        
        public struct ViewInfo: Sendable {
            public let viewId: String
            public let frame: CGRect
            public let bounds: CGRect
            public let center: CGPoint
            public let transform: CGAffineTransform
            
            public init(viewId: String, frame: CGRect, bounds: CGRect, center: CGPoint, transform: CGAffineTransform) {
                self.viewId = viewId
                self.frame = frame
                self.bounds = bounds
                self.center = center
                self.transform = transform
            }
        }
        
        public struct RecognizedGesture: Sendable {
            public let gestureType: GestureType
            public let state: GestureState
            public let location: CGPoint
            public let velocity: CGPoint
            public let scale: CGFloat
            public let rotation: CGFloat
            public let translation: CGPoint
            public let numberOfTouches: Int
            public let confidence: Float
            
            public enum GestureType: String, Sendable, CaseIterable {
                case tap = "tap"
                case doubleTap = "doubleTap"
                case longPress = "longPress"
                case pan = "pan"
                case swipe = "swipe"
                case pinch = "pinch"
                case rotation = "rotation"
                case screenEdgePan = "screenEdgePan"
                case hover = "hover"
                case custom = "custom"
            }
            
            public enum GestureState: String, Sendable, CaseIterable {
                case possible = "possible"
                case began = "began"
                case changed = "changed"
                case ended = "ended"
                case cancelled = "cancelled"
                case failed = "failed"
                case recognized = "recognized"
            }
            
            public init(gestureType: GestureType, state: GestureState, location: CGPoint, velocity: CGPoint = .zero, scale: CGFloat = 1.0, rotation: CGFloat = 0, translation: CGPoint = .zero, numberOfTouches: Int = 1, confidence: Float = 1.0) {
                self.gestureType = gestureType
                self.state = state
                self.location = location
                self.velocity = velocity
                self.scale = scale
                self.rotation = rotation
                self.translation = translation
                self.numberOfTouches = numberOfTouches
                self.confidence = confidence
            }
        }
        
        public enum TouchEventType: String, Sendable, CaseIterable {
            case touchesBegan = "touchesBegan"
            case touchesMoved = "touchesMoved"
            case touchesEnded = "touchesEnded"
            case touchesCancelled = "touchesCancelled"
            case gestureRecognized = "gestureRecognized"
            case motionBegan = "motionBegan"
            case motionEnded = "motionEnded"
            case motionCancelled = "motionCancelled"
        }
        
        public init(touches: [Touch], eventType: TouchEventType, view: ViewInfo? = nil, gesture: RecognizedGesture? = nil) {
            self.touches = touches
            self.eventType = eventType
            self.view = view
            self.gesture = gesture
        }
    }
    
    public init(touchData: TouchData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.touchData = touchData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Touch input result
public struct TouchInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedTouches: [ProcessedTouch]
    public let recognizedGestures: [RecognizedGesture]
    public let touchMetrics: TouchMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: TouchInputError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedTouch: Sendable {
        public let originalTouch: TouchInputEvent.TouchData.Touch
        public let smoothedLocation: CGPoint
        public let predictedLocation: CGPoint?
        public let filteredForce: CGFloat
        public let touchClassification: TouchClassification
        public let confidence: Float
        
        public enum TouchClassification: String, Sendable, CaseIterable {
            case finger = "finger"
            case thumb = "thumb"
            case palm = "palm"
            case stylus = "stylus"
            case unknown = "unknown"
        }
        
        public init(originalTouch: TouchInputEvent.TouchData.Touch, smoothedLocation: CGPoint, predictedLocation: CGPoint? = nil, filteredForce: CGFloat = 0, touchClassification: TouchClassification = .unknown, confidence: Float = 1.0) {
            self.originalTouch = originalTouch
            self.smoothedLocation = smoothedLocation
            self.predictedLocation = predictedLocation
            self.filteredForce = filteredForce
            self.touchClassification = touchClassification
            self.confidence = confidence
        }
    }
    
    public struct RecognizedGesture: Sendable {
        public let gesture: TouchInputEvent.TouchData.RecognizedGesture
        public let touches: [TouchInputEvent.TouchData.Touch]
        public let duration: TimeInterval
        public let distance: CGFloat
        public let averageVelocity: CGPoint
        public let peakVelocity: CGPoint
        
        public init(gesture: TouchInputEvent.TouchData.RecognizedGesture, touches: [TouchInputEvent.TouchData.Touch], duration: TimeInterval, distance: CGFloat, averageVelocity: CGPoint, peakVelocity: CGPoint) {
            self.gesture = gesture
            self.touches = touches
            self.duration = duration
            self.distance = distance
            self.averageVelocity = averageVelocity
            self.peakVelocity = peakVelocity
        }
    }
    
    public struct TouchMetrics: Sendable {
        public let totalTouches: Int
        public let activeTouches: Int
        public let averageForce: CGFloat
        public let maxForce: CGFloat
        public let touchDensity: CGFloat
        public let averageRadius: CGFloat
        public let samplingRate: Double
        public let latency: TimeInterval
        
        public init(totalTouches: Int, activeTouches: Int, averageForce: CGFloat, maxForce: CGFloat, touchDensity: CGFloat, averageRadius: CGFloat, samplingRate: Double, latency: TimeInterval) {
            self.totalTouches = totalTouches
            self.activeTouches = activeTouches
            self.averageForce = averageForce
            self.maxForce = maxForce
            self.touchDensity = touchDensity
            self.averageRadius = averageRadius
            self.samplingRate = samplingRate
            self.latency = latency
        }
    }
    
    public init(eventId: UUID, processedTouches: [ProcessedTouch], recognizedGestures: [RecognizedGesture], touchMetrics: TouchMetrics, processingTime: TimeInterval, success: Bool, error: TouchInputError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.eventId = eventId
        self.processedTouches = processedTouches
        self.recognizedGestures = recognizedGestures
        self.touchMetrics = touchMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var averageConfidence: Float {
        guard !processedTouches.isEmpty else { return 0.0 }
        return processedTouches.reduce(0) { $0 + $1.confidence } / Float(processedTouches.count)
    }
    
    public var gestureCount: Int {
        recognizedGestures.count
    }
    
    public var touchCount: Int {
        processedTouches.count
    }
}

/// Touch input metrics
public struct TouchInputMetrics: Sendable {
    public let totalEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByType: [String: Int]
    public let gesturesByType: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageTouchesPerEvent: Double
    public let averageGesturesPerEvent: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageSamplingRate: Double
        public let missedSamples: Int
        public let averageLatency: TimeInterval
        public let peakConcurrentTouches: Int
        
        public init(bestProcessingTime: TimeInterval = 0, worstProcessingTime: TimeInterval = 0, averageSamplingRate: Double = 0, missedSamples: Int = 0, averageLatency: TimeInterval = 0, peakConcurrentTouches: Int = 0) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageSamplingRate = averageSamplingRate
            self.missedSamples = missedSamples
            self.averageLatency = averageLatency
            self.peakConcurrentTouches = peakConcurrentTouches
        }
    }
    
    public init(totalEvents: Int = 0, successfulEvents: Int = 0, failedEvents: Int = 0, averageProcessingTime: TimeInterval = 0, eventsByType: [String: Int] = [:], gesturesByType: [String: Int] = [:], errorsByType: [String: Int] = [:], averageLatency: TimeInterval = 0, averageTouchesPerEvent: Double = 0, averageGesturesPerEvent: Double = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalEvents = totalEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByType = eventsByType
        self.gesturesByType = gesturesByType
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageTouchesPerEvent = averageTouchesPerEvent
        self.averageGesturesPerEvent = averageGesturesPerEvent
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalEvents > 0 ? Double(successfulEvents) / Double(totalEvents) : 0
    }
}

// MARK: - Touch Input Resource

/// Touch input resource management
@available(iOS 13.0, macOS 10.15, *)
public actor TouchInputCapabilityResource: AxiomCapabilityResource {
    private let configuration: TouchInputCapabilityConfiguration
    private var activeEvents: [UUID: TouchInputEvent] = [:]
    private var eventHistory: [TouchInputResult] = []
    private var resultCache: [String: TouchInputResult] = [:]
    private var touchProcessor: TouchProcessor = TouchProcessor()
    private var gestureRecognizer: GestureRecognizer = GestureRecognizer()
    private var touchTracker: TouchTracker = TouchTracker()
    private var metrics: TouchInputMetrics = TouchInputMetrics()
    private var resultStreamContinuation: AsyncStream<TouchInputResult>.Continuation?
    
    // Helper classes for touch processing
    private class TouchProcessor {
        func processTouches(_ touches: [TouchInputEvent.TouchData.Touch], configuration: TouchInputCapabilityConfiguration) -> [TouchInputResult.ProcessedTouch] {
            return touches.map { touch in
                let smoothedLocation = smoothLocation(touch.location, previousLocation: touch.previousLocation)
                let predictedLocation = configuration.enableTouchPrediction ? predictLocation(touch.location, velocity: touch.velocity) : nil
                let filteredForce = configuration.enableForceTouch ? filterForce(touch.force) : 0
                let classification = classifyTouch(touch)
                
                return TouchInputResult.ProcessedTouch(
                    originalTouch: touch,
                    smoothedLocation: smoothedLocation,
                    predictedLocation: predictedLocation,
                    filteredForce: filteredForce,
                    touchClassification: classification,
                    confidence: calculateConfidence(touch)
                )
            }
        }
        
        private func smoothLocation(_ location: CGPoint, previousLocation: CGPoint) -> CGPoint {
            let smoothingFactor: CGFloat = 0.3
            return CGPoint(
                x: location.x * (1 - smoothingFactor) + previousLocation.x * smoothingFactor,
                y: location.y * (1 - smoothingFactor) + previousLocation.y * smoothingFactor
            )
        }
        
        private func predictLocation(_ location: CGPoint, velocity: CGPoint) -> CGPoint {
            let predictionTime: CGFloat = 0.016 // 16ms ahead
            return CGPoint(
                x: location.x + velocity.x * predictionTime,
                y: location.y + velocity.y * predictionTime
            )
        }
        
        private func filterForce(_ force: CGFloat) -> CGFloat {
            return min(max(force, 0), 1.0)
        }
        
        private func classifyTouch(_ touch: TouchInputEvent.TouchData.Touch) -> TouchInputResult.ProcessedTouch.TouchClassification {
            if touch.radius > 20 {
                return .palm
            } else if touch.radius > 15 {
                return .thumb
            } else if touch.radius > 5 {
                return .finger
            } else if touch.radius < 2 {
                return .stylus
            }
            return .unknown
        }
        
        private func calculateConfidence(_ touch: TouchInputEvent.TouchData.Touch) -> Float {
            var confidence: Float = 1.0
            
            if touch.estimatedProperties.contains(.location) {
                confidence *= 0.8
            }
            if touch.estimatedProperties.contains(.force) {
                confidence *= 0.9
            }
            
            return confidence
        }
    }
    
    private class GestureRecognizer {
        private var gestureStates: [String: TouchInputEvent.TouchData.RecognizedGesture.GestureState] = [:]
        
        func recognizeGestures(from touches: [TouchInputEvent.TouchData.Touch], thresholds: TouchInputCapabilityConfiguration.GestureThresholds) -> [TouchInputEvent.TouchData.RecognizedGesture] {
            var recognizedGestures: [TouchInputEvent.TouchData.RecognizedGesture] = []
            
            if touches.count == 1 {
                if let tapGesture = recognizeTap(touch: touches[0], thresholds: thresholds) {
                    recognizedGestures.append(tapGesture)
                }
                if let swipeGesture = recognizeSwipe(touch: touches[0], thresholds: thresholds) {
                    recognizedGestures.append(swipeGesture)
                }
            } else if touches.count == 2 {
                if let pinchGesture = recognizePinch(touches: touches, thresholds: thresholds) {
                    recognizedGestures.append(pinchGesture)
                }
                if let rotationGesture = recognizeRotation(touches: touches, thresholds: thresholds) {
                    recognizedGestures.append(rotationGesture)
                }
            }
            
            return recognizedGestures
        }
        
        private func recognizeTap(touch: TouchInputEvent.TouchData.Touch, thresholds: TouchInputCapabilityConfiguration.GestureThresholds) -> TouchInputEvent.TouchData.RecognizedGesture? {
            let distance = sqrt(pow(touch.location.x - touch.previousLocation.x, 2) + pow(touch.location.y - touch.previousLocation.y, 2))
            
            if distance <= thresholds.tapMaxDistance && touch.phase == .ended {
                return TouchInputEvent.TouchData.RecognizedGesture(
                    gestureType: .tap,
                    state: .recognized,
                    location: touch.location,
                    numberOfTouches: 1,
                    confidence: 0.9
                )
            }
            
            return nil
        }
        
        private func recognizeSwipe(touch: TouchInputEvent.TouchData.Touch, thresholds: TouchInputCapabilityConfiguration.GestureThresholds) -> TouchInputEvent.TouchData.RecognizedGesture? {
            let distance = sqrt(pow(touch.location.x - touch.previousLocation.x, 2) + pow(touch.location.y - touch.previousLocation.y, 2))
            let velocity = sqrt(pow(touch.velocity.x, 2) + pow(touch.velocity.y, 2))
            
            if distance >= thresholds.swipeMinDistance && velocity >= thresholds.swipeMinVelocity {
                return TouchInputEvent.TouchData.RecognizedGesture(
                    gestureType: .swipe,
                    state: .recognized,
                    location: touch.location,
                    velocity: touch.velocity,
                    numberOfTouches: 1,
                    confidence: 0.8
                )
            }
            
            return nil
        }
        
        private func recognizePinch(touches: [TouchInputEvent.TouchData.Touch], thresholds: TouchInputCapabilityConfiguration.GestureThresholds) -> TouchInputEvent.TouchData.RecognizedGesture? {
            guard touches.count == 2 else { return nil }
            
            let touch1 = touches[0]
            let touch2 = touches[1]
            
            let currentDistance = sqrt(pow(touch1.location.x - touch2.location.x, 2) + pow(touch1.location.y - touch2.location.y, 2))
            let previousDistance = sqrt(pow(touch1.previousLocation.x - touch2.previousLocation.x, 2) + pow(touch1.previousLocation.y - touch2.previousLocation.y, 2))
            
            let scale = previousDistance > 0 ? currentDistance / previousDistance : 1.0
            
            if abs(scale - 1.0) >= thresholds.pinchMinScale {
                let centerLocation = CGPoint(
                    x: (touch1.location.x + touch2.location.x) / 2,
                    y: (touch1.location.y + touch2.location.y) / 2
                )
                
                return TouchInputEvent.TouchData.RecognizedGesture(
                    gestureType: .pinch,
                    state: .changed,
                    location: centerLocation,
                    scale: scale,
                    numberOfTouches: 2,
                    confidence: 0.85
                )
            }
            
            return nil
        }
        
        private func recognizeRotation(touches: [TouchInputEvent.TouchData.Touch], thresholds: TouchInputCapabilityConfiguration.GestureThresholds) -> TouchInputEvent.TouchData.RecognizedGesture? {
            guard touches.count == 2 else { return nil }
            
            let touch1 = touches[0]
            let touch2 = touches[1]
            
            let currentAngle = atan2(touch2.location.y - touch1.location.y, touch2.location.x - touch1.location.x)
            let previousAngle = atan2(touch2.previousLocation.y - touch1.previousLocation.y, touch2.previousLocation.x - touch1.previousLocation.x)
            
            let rotation = currentAngle - previousAngle
            
            if abs(rotation) >= thresholds.rotationMinAngle {
                let centerLocation = CGPoint(
                    x: (touch1.location.x + touch2.location.x) / 2,
                    y: (touch1.location.y + touch2.location.y) / 2
                )
                
                return TouchInputEvent.TouchData.RecognizedGesture(
                    gestureType: .rotation,
                    state: .changed,
                    location: centerLocation,
                    rotation: rotation,
                    numberOfTouches: 2,
                    confidence: 0.8
                )
            }
            
            return nil
        }
    }
    
    private class TouchTracker {
        private var activeTouches: [UUID: TouchInputEvent.TouchData.Touch] = [:]
        
        func updateTouches(_ touches: [TouchInputEvent.TouchData.Touch]) {
            for touch in touches {
                switch touch.phase {
                case .began:
                    activeTouches[touch.id] = touch
                case .moved, .stationary:
                    activeTouches[touch.id] = touch
                case .ended, .cancelled:
                    activeTouches.removeValue(forKey: touch.id)
                default:
                    break
                }
            }
        }
        
        func getActiveTouches() -> [TouchInputEvent.TouchData.Touch] {
            return Array(activeTouches.values)
        }
        
        func getActiveCount() -> Int {
            return activeTouches.count
        }
        
        func reset() {
            activeTouches.removeAll()
        }
    }
    
    public init(configuration: TouchInputCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for touch processing
            cpu: 2.5, // Moderate CPU usage for touch processing
            bandwidth: 0,
            storage: 50_000_000 // 50MB for touch and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 10_000_000 // ~10MB per active event
            let cacheMemory = resultCache.count * 50_000 // ~50KB per cached result
            let historyMemory = eventHistory.count * 20_000
            let processingMemory = 30_000_000 // Touch processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.1 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 25_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Touch input is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableTouchInput
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        touchTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = TouchInputMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        touchProcessor = TouchProcessor()
        gestureRecognizer = GestureRecognizer()
        touchTracker = TouchTracker()
        
        if configuration.enableLogging {
            print("[TouchInput] 🚀 Touch Input capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: TouchInputCapabilityConfiguration) async throws {
        // Update touch input configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<TouchInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Touch Processing
    
    public func processTouch(_ event: TouchInputEvent) async throws -> TouchInputResult {
        guard configuration.enableTouchInput else {
            throw TouchInputError.touchInputDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Update touch tracker
            touchTracker.updateTouches(event.touchData.touches)
            
            // Process touches
            let processedTouches = touchProcessor.processTouches(event.touchData.touches, configuration: configuration)
            
            // Recognize gestures if enabled
            var recognizedGestures: [TouchInputResult.RecognizedGesture] = []
            if configuration.enableGestureRecognition {
                let gestures = gestureRecognizer.recognizeGestures(from: event.touchData.touches, thresholds: configuration.gestureThresholds)
                recognizedGestures = gestures.map { gesture in
                    TouchInputResult.RecognizedGesture(
                        gesture: gesture,
                        touches: event.touchData.touches,
                        duration: 0.1, // Simplified
                        distance: 10.0, // Simplified
                        averageVelocity: gesture.velocity,
                        peakVelocity: gesture.velocity
                    )
                }
            }
            
            // Calculate metrics
            let touchMetrics = calculateTouchMetrics(processedTouches: processedTouches, activeTouches: touchTracker.getActiveTouches())
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = TouchInputResult(
                eventId: event.id,
                processedTouches: processedTouches,
                recognizedGestures: recognizedGestures,
                touchMetrics: touchMetrics,
                processingTime: processingTime,
                success: true,
                metadata: event.metadata
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: event)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logTouchEvent(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = TouchInputResult(
                eventId: event.id,
                processedTouches: [],
                recognizedGestures: [],
                touchMetrics: TouchInputResult.TouchMetrics(totalTouches: 0, activeTouches: 0, averageForce: 0, maxForce: 0, touchDensity: 0, averageRadius: 0, samplingRate: 0, latency: 0),
                processingTime: processingTime,
                success: false,
                error: error as? TouchInputError ?? TouchInputError.processingError(error.localizedDescription)
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logTouchEvent(result)
            }
            
            throw error
        }
    }
    
    public func getActiveEvents() async -> [TouchInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [TouchInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    public func getActiveTouches() async -> [TouchInputEvent.TouchData.Touch] {
        return touchTracker.getActiveTouches()
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> TouchInputMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = TouchInputMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func calculateTouchMetrics(processedTouches: [TouchInputResult.ProcessedTouch], activeTouches: [TouchInputEvent.TouchData.Touch]) -> TouchInputResult.TouchMetrics {
        let totalTouches = processedTouches.count
        let activeTouchesCount = activeTouches.count
        
        let averageForce = processedTouches.isEmpty ? 0 : processedTouches.reduce(0) { $0 + $1.filteredForce } / CGFloat(processedTouches.count)
        let maxForce = processedTouches.map { $0.filteredForce }.max() ?? 0
        
        let averageRadius = activeTouches.isEmpty ? 0 : activeTouches.reduce(0) { $0 + $1.radius } / CGFloat(activeTouches.count)
        
        return TouchInputResult.TouchMetrics(
            totalTouches: totalTouches,
            activeTouches: activeTouchesCount,
            averageForce: averageForce,
            maxForce: maxForce,
            touchDensity: CGFloat(totalTouches) / 100.0, // Simplified
            averageRadius: averageRadius,
            samplingRate: Double(configuration.touchSamplingRate),
            latency: 0.016 // 16ms typical latency
        )
    }
    
    private func generateCacheKey(for event: TouchInputEvent) -> String {
        let touchCount = event.touchData.touches.count
        let eventType = event.touchData.eventType.rawValue
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000) // Milliseconds
        return "\(touchCount)_\(eventType)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: TouchInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalEvents)) + result.processingTime) / Double(totalEvents)
        
        var eventsByType = metrics.eventsByType
        // Simplified - would extract from result
        eventsByType["touch", default: 0] += 1
        
        var gesturesByType = metrics.gesturesByType
        for gesture in result.recognizedGestures {
            gesturesByType[gesture.gesture.gestureType.rawValue, default: 0] += 1
        }
        
        let newAverageTouchesPerEvent = ((metrics.averageTouchesPerEvent * Double(metrics.successfulEvents)) + Double(result.touchCount)) / Double(successfulEvents)
        let newAverageGesturesPerEvent = ((metrics.averageGesturesPerEvent * Double(metrics.successfulEvents)) + Double(result.gestureCount)) / Double(successfulEvents)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let peakConcurrentTouches = max(performanceStats.peakConcurrentTouches, result.touchMetrics.activeTouches)
        
        performanceStats = TouchInputMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageSamplingRate: result.touchMetrics.samplingRate,
            missedSamples: performanceStats.missedSamples,
            averageLatency: result.touchMetrics.latency,
            peakConcurrentTouches: peakConcurrentTouches
        )
        
        metrics = TouchInputMetrics(
            totalEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByType: eventsByType,
            gesturesByType: gesturesByType,
            errorsByType: metrics.errorsByType,
            averageLatency: result.touchMetrics.latency,
            averageTouchesPerEvent: newAverageTouchesPerEvent,
            averageGesturesPerEvent: newAverageGesturesPerEvent,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: TouchInputResult) async {
        let totalEvents = metrics.totalEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = TouchInputMetrics(
            totalEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByType: metrics.eventsByType,
            gesturesByType: metrics.gesturesByType,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageTouchesPerEvent: metrics.averageTouchesPerEvent,
            averageGesturesPerEvent: metrics.averageGesturesPerEvent,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logTouchEvent(_ result: TouchInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let touchCount = result.touchCount
        let gestureCount = result.gestureCount
        let confidence = String(format: "%.3f", result.averageConfidence)
        
        print("[TouchInput] \(statusIcon) Event: \(touchCount) touches, \(gestureCount) gestures, confidence: \(confidence) (\(timeStr)s)")
        
        if let error = result.error {
            print("[TouchInput] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Touch Input Capability Implementation

/// Touch Input capability providing comprehensive touch gesture processing
@available(iOS 13.0, macOS 10.15, *)
public actor TouchInputCapability: DomainCapability {
    public typealias ConfigurationType = TouchInputCapabilityConfiguration
    public typealias ResourceType = TouchInputCapabilityResource
    
    private var _configuration: TouchInputCapabilityConfiguration
    private var _resources: TouchInputCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(5)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "touch-input-capability" }
    
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
    
    public var configuration: TouchInputCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: TouchInputCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: TouchInputCapabilityConfiguration = TouchInputCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = TouchInputCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: TouchInputCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Touch Input configuration")
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
        // Touch input is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Touch input doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Touch Input Operations
    
    /// Process touch input event
    public func processTouch(_ event: TouchInputEvent) async throws -> TouchInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return try await _resources.processTouch(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<TouchInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [TouchInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [TouchInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get active touches
    public func getActiveTouches() async throws -> [TouchInputEvent.TouchData.Touch] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return await _resources.getActiveTouches()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> TouchInputMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Touch Input capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create touch event from UITouch
    public func createTouchEvent(from touches: Set<UITouch>, with eventType: TouchInputEvent.TouchData.TouchEventType, in view: UIView?) -> TouchInputEvent {
        let touchData = touches.map { uiTouch in
            TouchInputEvent.TouchData.Touch(
                phase: convertTouchPhase(uiTouch.phase),
                location: uiTouch.location(in: view),
                previousLocation: uiTouch.previousLocation(in: view),
                force: uiTouch.force,
                maximumPossibleForce: uiTouch.maximumPossibleForce,
                radius: uiTouch.majorRadius,
                timestamp: uiTouch.timestamp
            )
        }
        
        let data = TouchInputEvent.TouchData(touches: touchData, eventType: eventType)
        return TouchInputEvent(touchData: data)
    }
    
    /// Check if touch input is active
    public func hasActiveEvents() async throws -> Bool {
        let activeEvents = try await getActiveEvents()
        return !activeEvents.isEmpty
    }
    
    /// Get active touch count
    public func getActiveTouchCount() async throws -> Int {
        let activeTouches = try await getActiveTouches()
        return activeTouches.count
    }
    
    // MARK: - Private Methods
    
    private func convertTouchPhase(_ phase: UITouch.Phase) -> TouchInputEvent.TouchData.Touch.TouchPhase {
        switch phase {
        case .began:
            return .began
        case .moved:
            return .moved
        case .stationary:
            return .stationary
        case .ended:
            return .ended
        case .cancelled:
            return .cancelled
        case .regionEntered:
            return .regionEntered
        case .regionMoved:
            return .regionMoved
        case .regionExited:
            return .regionExited
        @unknown default:
            return .cancelled
        }
    }
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Touch Input specific errors
public enum TouchInputError: Error, LocalizedError {
    case touchInputDisabled
    case processingError(String)
    case gestureRecognitionFailed
    case invalidTouchData
    case touchTimeout(UUID)
    case unsupportedGesture(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .touchInputDisabled:
            return "Touch input is disabled"
        case .processingError(let reason):
            return "Touch processing failed: \(reason)"
        case .gestureRecognitionFailed:
            return "Gesture recognition failed"
        case .invalidTouchData:
            return "Invalid touch data provided"
        case .touchTimeout(let id):
            return "Touch timeout: \(id)"
        case .unsupportedGesture(let gesture):
            return "Unsupported gesture: \(gesture)"
        case .configurationError(let reason):
            return "Touch input configuration error: \(reason)"
        }
    }
}