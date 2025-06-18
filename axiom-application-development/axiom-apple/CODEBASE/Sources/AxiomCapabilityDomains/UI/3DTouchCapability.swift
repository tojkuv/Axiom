import Foundation
import UIKit
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - 3D Touch Capability Configuration

/// Configuration for 3D Touch capability
public struct ThreeDTouchCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enable3DTouchSupport: Bool
    public let enablePeekPop: Bool
    public let enableQuickActions: Bool
    public let enablePreviewActions: Bool
    public let enableForceTouch: Bool
    public let enablePressureAnalysis: Bool
    public let enableGesturePrediction: Bool
    public let enableRealTimeProcessing: Bool
    public let maxConcurrentTouches: Int
    public let touchTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let pressureSensitivity: PressureSensitivity
    public let forceThreshold: Double
    public let peekThreshold: Double
    public let popThreshold: Double
    public let responsiveness: Responsiveness
    public let supportedGestures: [TouchGesture]
    
    public enum PressureSensitivity: String, Codable, CaseIterable {
        case light = "light"
        case medium = "medium"
        case firm = "firm"
        case custom = "custom"
    }
    
    public enum Responsiveness: String, Codable, CaseIterable {
        case immediate = "immediate"
        case standard = "standard"
        case delayed = "delayed"
        case adaptive = "adaptive"
    }
    
    public enum TouchGesture: String, Codable, CaseIterable {
        case peek = "peek"
        case pop = "pop"
        case forceTouch = "forceTouch"
        case pressHold = "pressHold"
        case quickAction = "quickAction"
        case preview = "preview"
        case contextMenu = "contextMenu"
        case hapticFeedback = "hapticFeedback"
    }
    
    public init(
        enable3DTouchSupport: Bool = true,
        enablePeekPop: Bool = true,
        enableQuickActions: Bool = true,
        enablePreviewActions: Bool = true,
        enableForceTouch: Bool = true,
        enablePressureAnalysis: Bool = true,
        enableGesturePrediction: Bool = true,
        enableRealTimeProcessing: Bool = true,
        maxConcurrentTouches: Int = 3,
        touchTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        pressureSensitivity: PressureSensitivity = .medium,
        forceThreshold: Double = 0.5,
        peekThreshold: Double = 0.35,
        popThreshold: Double = 0.8,
        responsiveness: Responsiveness = .standard,
        supportedGestures: [TouchGesture] = TouchGesture.allCases
    ) {
        self.enable3DTouchSupport = enable3DTouchSupport
        self.enablePeekPop = enablePeekPop
        self.enableQuickActions = enableQuickActions
        self.enablePreviewActions = enablePreviewActions
        self.enableForceTouch = enableForceTouch
        self.enablePressureAnalysis = enablePressureAnalysis
        self.enableGesturePrediction = enableGesturePrediction
        self.enableRealTimeProcessing = enableRealTimeProcessing
        self.maxConcurrentTouches = maxConcurrentTouches
        self.touchTimeout = touchTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.pressureSensitivity = pressureSensitivity
        self.forceThreshold = forceThreshold
        self.peekThreshold = peekThreshold
        self.popThreshold = popThreshold
        self.responsiveness = responsiveness
        self.supportedGestures = supportedGestures
    }
    
    public var isValid: Bool {
        maxConcurrentTouches > 0 &&
        touchTimeout > 0 &&
        forceThreshold > 0 && forceThreshold <= 1 &&
        peekThreshold > 0 && peekThreshold <= 1 &&
        popThreshold > 0 && popThreshold <= 1 &&
        peekThreshold < popThreshold &&
        cacheSize >= 0 &&
        !supportedGestures.isEmpty
    }
    
    public func merged(with other: ThreeDTouchCapabilityConfiguration) -> ThreeDTouchCapabilityConfiguration {
        ThreeDTouchCapabilityConfiguration(
            enable3DTouchSupport: other.enable3DTouchSupport,
            enablePeekPop: other.enablePeekPop,
            enableQuickActions: other.enableQuickActions,
            enablePreviewActions: other.enablePreviewActions,
            enableForceTouch: other.enableForceTouch,
            enablePressureAnalysis: other.enablePressureAnalysis,
            enableGesturePrediction: other.enableGesturePrediction,
            enableRealTimeProcessing: other.enableRealTimeProcessing,
            maxConcurrentTouches: other.maxConcurrentTouches,
            touchTimeout: other.touchTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            pressureSensitivity: other.pressureSensitivity,
            forceThreshold: other.forceThreshold,
            peekThreshold: other.peekThreshold,
            popThreshold: other.popThreshold,
            responsiveness: other.responsiveness,
            supportedGestures: other.supportedGestures
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ThreeDTouchCapabilityConfiguration {
        var adjustedTimeout = touchTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentTouches = maxConcurrentTouches
        var adjustedCacheSize = cacheSize
        var adjustedRealTimeProcessing = enableRealTimeProcessing
        var adjustedPressureAnalysis = enablePressureAnalysis
        var adjustedResponsiveness = responsiveness
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(touchTimeout, 15.0)
            adjustedConcurrentTouches = min(maxConcurrentTouches, 1)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedRealTimeProcessing = false
            adjustedPressureAnalysis = false
            adjustedResponsiveness = .standard
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ThreeDTouchCapabilityConfiguration(
            enable3DTouchSupport: enable3DTouchSupport,
            enablePeekPop: enablePeekPop,
            enableQuickActions: enableQuickActions,
            enablePreviewActions: enablePreviewActions,
            enableForceTouch: enableForceTouch,
            enablePressureAnalysis: adjustedPressureAnalysis,
            enableGesturePrediction: enableGesturePrediction,
            enableRealTimeProcessing: adjustedRealTimeProcessing,
            maxConcurrentTouches: adjustedConcurrentTouches,
            touchTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            pressureSensitivity: pressureSensitivity,
            forceThreshold: forceThreshold,
            peekThreshold: peekThreshold,
            popThreshold: popThreshold,
            responsiveness: adjustedResponsiveness,
            supportedGestures: supportedGestures
        )
    }
}

// MARK: - 3D Touch Types

/// 3D Touch input event
public struct ThreeDTouchInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let touchData: TouchData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct TouchData: Sendable {
        public let eventType: TouchEventType
        public let location: CGPoint
        public let previousLocation: CGPoint
        public let force: Double
        public let maximumPossibleForce: Double
        public let pressure: Double
        public let majorRadius: Double
        public let majorRadiusTolerance: Double
        public let phase: TouchPhase
        public let touchType: TouchType
        public let deviceInfo: DeviceInfo
        public let timestamp: TimeInterval
        public let coalescedTouches: [CoalescedTouch]
        public let predictedTouches: [PredictedTouch]
        
        public enum TouchEventType: String, Sendable, CaseIterable {
            case touchBegan = "touchBegan"
            case touchMoved = "touchMoved"
            case touchEnded = "touchEnded"
            case touchCancelled = "touchCancelled"
            case forceTouchBegan = "forceTouchBegan"
            case forceTouchChanged = "forceTouchChanged"
            case forceTouchEnded = "forceTouchEnded"
            case peekStarted = "peekStarted"
            case peekChanged = "peekChanged"
            case peekEnded = "peekEnded"
            case popTriggered = "popTriggered"
        }
        
        public enum TouchPhase: String, Sendable, CaseIterable {
            case began = "began"
            case moved = "moved"
            case stationary = "stationary"
            case ended = "ended"
            case cancelled = "cancelled"
        }
        
        public enum TouchType: String, Sendable, CaseIterable {
            case direct = "direct"
            case indirect = "indirect"
            case pencil = "pencil"
            case stylus = "stylus"
        }
        
        public struct DeviceInfo: Sendable {
            public let supports3DTouch: Bool
            public let supportsForceTouch: Bool
            public let maximumForce: Double
            public let deviceModel: String
            public let screenSize: CGSize
            public let pixelDensity: Double
            
            public init(supports3DTouch: Bool, supportsForceTouch: Bool, maximumForce: Double, deviceModel: String, screenSize: CGSize, pixelDensity: Double) {
                self.supports3DTouch = supports3DTouch
                self.supportsForceTouch = supportsForceTouch
                self.maximumForce = maximumForce
                self.deviceModel = deviceModel
                self.screenSize = screenSize
                self.pixelDensity = pixelDensity
            }
        }
        
        public struct CoalescedTouch: Sendable {
            public let location: CGPoint
            public let force: Double
            public let pressure: Double
            public let timestamp: TimeInterval
            
            public init(location: CGPoint, force: Double, pressure: Double, timestamp: TimeInterval) {
                self.location = location
                self.force = force
                self.pressure = pressure
                self.timestamp = timestamp
            }
        }
        
        public struct PredictedTouch: Sendable {
            public let location: CGPoint
            public let force: Double
            public let pressure: Double
            public let timestamp: TimeInterval
            public let confidence: Double
            
            public init(location: CGPoint, force: Double, pressure: Double, timestamp: TimeInterval, confidence: Double) {
                self.location = location
                self.force = force
                self.pressure = pressure
                self.timestamp = timestamp
                self.confidence = confidence
            }
        }
        
        public init(
            eventType: TouchEventType,
            location: CGPoint = .zero,
            previousLocation: CGPoint = .zero,
            force: Double = 0.0,
            maximumPossibleForce: Double = 1.0,
            pressure: Double = 0.0,
            majorRadius: Double = 0.0,
            majorRadiusTolerance: Double = 0.0,
            phase: TouchPhase = .began,
            touchType: TouchType = .direct,
            deviceInfo: DeviceInfo = DeviceInfo(supports3DTouch: true, supportsForceTouch: true, maximumForce: 1.0, deviceModel: "iPhone", screenSize: CGSize(width: 375, height: 667), pixelDensity: 2.0),
            timestamp: TimeInterval = 0,
            coalescedTouches: [CoalescedTouch] = [],
            predictedTouches: [PredictedTouch] = []
        ) {
            self.eventType = eventType
            self.location = location
            self.previousLocation = previousLocation
            self.force = force
            self.maximumPossibleForce = maximumPossibleForce
            self.pressure = pressure
            self.majorRadius = majorRadius
            self.majorRadiusTolerance = majorRadiusTolerance
            self.phase = phase
            self.touchType = touchType
            self.deviceInfo = deviceInfo
            self.timestamp = timestamp
            self.coalescedTouches = coalescedTouches
            self.predictedTouches = predictedTouches
        }
    }
    
    public init(touchData: TouchData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.touchData = touchData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// 3D Touch input result
public struct ThreeDTouchInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedTouch: ProcessedTouchInput
    public let recognizedGestures: [RecognizedTouchGesture]
    public let pressureAnalysis: PressureAnalysis
    public let inputMetrics: TouchInputMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ThreeDTouchError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedTouchInput: Sendable {
        public let originalEvent: ThreeDTouchInputEvent.TouchData
        public let normalizedForce: Double
        public let calibratedPressure: Double
        public let adjustedLocation: CGPoint
        public let smoothedMotion: CGPoint
        public let velocityVector: CGVector
        public let accelerationVector: CGVector
        public let gestureState: GestureState
        public let touchClassification: TouchClassification
        public let predictionData: PredictionData?
        
        public enum GestureState: String, Sendable, CaseIterable {
            case idle = "idle"
            case tracking = "tracking"
            case peeking = "peeking"
            case popping = "popping"
            case forceTouching = "forceTouching"
            case completed = "completed"
            case cancelled = "cancelled"
        }
        
        public enum TouchClassification: String, Sendable, CaseIterable {
            case lightTouch = "lightTouch"
            case normalTouch = "normalTouch"
            case firmTouch = "firmTouch"
            case forceTouch = "forceTouch"
            case peek = "peek"
            case pop = "pop"
            case quickAction = "quickAction"
        }
        
        public struct PredictionData: Sendable {
            public let predictedLocations: [CGPoint]
            public let predictedForces: [Double]
            public let confidenceScores: [Double]
            public let predictionTime: TimeInterval
            
            public init(predictedLocations: [CGPoint], predictedForces: [Double], confidenceScores: [Double], predictionTime: TimeInterval) {
                self.predictedLocations = predictedLocations
                self.predictedForces = predictedForces
                self.confidenceScores = confidenceScores
                self.predictionTime = predictionTime
            }
        }
        
        public init(
            originalEvent: ThreeDTouchInputEvent.TouchData,
            normalizedForce: Double,
            calibratedPressure: Double,
            adjustedLocation: CGPoint,
            smoothedMotion: CGPoint,
            velocityVector: CGVector,
            accelerationVector: CGVector,
            gestureState: GestureState,
            touchClassification: TouchClassification,
            predictionData: PredictionData? = nil
        ) {
            self.originalEvent = originalEvent
            self.normalizedForce = normalizedForce
            self.calibratedPressure = calibratedPressure
            self.adjustedLocation = adjustedLocation
            self.smoothedMotion = smoothedMotion
            self.velocityVector = velocityVector
            self.accelerationVector = accelerationVector
            self.gestureState = gestureState
            self.touchClassification = touchClassification
            self.predictionData = predictionData
        }
    }
    
    public struct RecognizedTouchGesture: Sendable {
        public let gestureType: GestureType
        public let confidence: Double
        public let location: CGPoint
        public let force: Double
        public let duration: TimeInterval
        public let parameters: [String: Double]
        public let gesturePhase: GesturePhase
        
        public enum GestureType: String, Sendable, CaseIterable {
            case peek = "peek"
            case pop = "pop"
            case forceTouch = "forceTouch"
            case quickAction = "quickAction"
            case pressAndHold = "pressAndHold"
            case preview = "preview"
            case contextMenu = "contextMenu"
            case hapticTrigger = "hapticTrigger"
        }
        
        public enum GesturePhase: String, Sendable, CaseIterable {
            case began = "began"
            case changed = "changed"
            case ended = "ended"
            case cancelled = "cancelled"
            case recognized = "recognized"
        }
        
        public init(gestureType: GestureType, confidence: Double, location: CGPoint, force: Double, duration: TimeInterval, parameters: [String: Double], gesturePhase: GesturePhase) {
            self.gestureType = gestureType
            self.confidence = confidence
            self.location = location
            self.force = force
            self.duration = duration
            self.parameters = parameters
            self.gesturePhase = gesturePhase
        }
    }
    
    public struct PressureAnalysis: Sendable {
        public let averagePressure: Double
        public let peakPressure: Double
        public let pressureVariation: Double
        public let pressureGradient: Double
        public let steadiness: Double
        public let responsiveness: Double
        public let forceAccuracy: Double
        public let pressurePattern: PressurePattern
        
        public enum PressurePattern: String, Sendable, CaseIterable {
            case linear = "linear"
            case exponential = "exponential"
            case stepped = "stepped"
            case oscillating = "oscillating"
            case irregular = "irregular"
        }
        
        public init(averagePressure: Double, peakPressure: Double, pressureVariation: Double, pressureGradient: Double, steadiness: Double, responsiveness: Double, forceAccuracy: Double, pressurePattern: PressurePattern) {
            self.averagePressure = averagePressure
            self.peakPressure = peakPressure
            self.pressureVariation = pressureVariation
            self.pressureGradient = pressureGradient
            self.steadiness = steadiness
            self.responsiveness = responsiveness
            self.forceAccuracy = forceAccuracy
            self.pressurePattern = pressurePattern
        }
    }
    
    public struct TouchInputMetrics: Sendable {
        public let totalTouches: Int
        public let averageForce: Double
        public let touchesPerSecond: Double
        public let averageLatency: TimeInterval
        public let gestureRecognitionRate: Double
        public let forceRange: ClosedRange<Double>
        public let accuracy: Double
        public let responsiveness: Double
        
        public init(totalTouches: Int, averageForce: Double, touchesPerSecond: Double, averageLatency: TimeInterval, gestureRecognitionRate: Double, forceRange: ClosedRange<Double>, accuracy: Double, responsiveness: Double) {
            self.totalTouches = totalTouches
            self.averageForce = averageForce
            self.touchesPerSecond = touchesPerSecond
            self.averageLatency = averageLatency
            self.gestureRecognitionRate = gestureRecognitionRate
            self.forceRange = forceRange
            self.accuracy = accuracy
            self.responsiveness = responsiveness
        }
    }
    
    public init(
        eventId: UUID,
        processedTouch: ProcessedTouchInput,
        recognizedGestures: [RecognizedTouchGesture],
        pressureAnalysis: PressureAnalysis,
        inputMetrics: TouchInputMetrics,
        processingTime: TimeInterval,
        success: Bool,
        error: ThreeDTouchError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.eventId = eventId
        self.processedTouch = processedTouch
        self.recognizedGestures = recognizedGestures
        self.pressureAnalysis = pressureAnalysis
        self.inputMetrics = inputMetrics
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var gestureCount: Int {
        recognizedGestures.count
    }
    
    public var averageGestureConfidence: Double {
        guard !recognizedGestures.isEmpty else { return 0.0 }
        return recognizedGestures.reduce(0) { $0 + $1.confidence } / Double(recognizedGestures.count)
    }
    
    public var qualityScore: Double {
        (pressureAnalysis.steadiness + pressureAnalysis.responsiveness + pressureAnalysis.forceAccuracy) / 3.0
    }
}

/// 3D Touch capability metrics
public struct ThreeDTouchCapabilityMetrics: Sendable {
    public let totalTouchEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByType: [String: Int]
    public let gesturesByType: [String: Int]
    public let touchesByClassification: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageEventsPerSession: Double
    public let averageGesturesPerSession: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageTouchesPerSession: Double
        public let averageForceUsage: Double
        public let averagePressureAccuracy: Double
        public let totalGestures: Int
        public let touchAccuracy: Double
        public let deviceReliability: Double
        public let gestureRecognitionAccuracy: Double
        
        public init(bestProcessingTime: TimeInterval = 0, worstProcessingTime: TimeInterval = 0, averageTouchesPerSession: Double = 0, averageForceUsage: Double = 0, averagePressureAccuracy: Double = 0, totalGestures: Int = 0, touchAccuracy: Double = 0, deviceReliability: Double = 0, gestureRecognitionAccuracy: Double = 0) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageTouchesPerSession = averageTouchesPerSession
            self.averageForceUsage = averageForceUsage
            self.averagePressureAccuracy = averagePressureAccuracy
            self.totalGestures = totalGestures
            self.touchAccuracy = touchAccuracy
            self.deviceReliability = deviceReliability
            self.gestureRecognitionAccuracy = gestureRecognitionAccuracy
        }
    }
    
    public init(
        totalTouchEvents: Int = 0,
        successfulEvents: Int = 0,
        failedEvents: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        eventsByType: [String: Int] = [:],
        gesturesByType: [String: Int] = [:],
        touchesByClassification: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        averageLatency: TimeInterval = 0,
        averageEventsPerSession: Double = 0,
        averageGesturesPerSession: Double = 0,
        throughputPerSecond: Double = 0,
        performanceStats: PerformanceStats = PerformanceStats()
    ) {
        self.totalTouchEvents = totalTouchEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByType = eventsByType
        self.gesturesByType = gesturesByType
        self.touchesByClassification = touchesByClassification
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageEventsPerSession = averageEventsPerSession
        self.averageGesturesPerSession = averageGesturesPerSession
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalTouchEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalTouchEvents > 0 ? Double(successfulEvents) / Double(totalTouchEvents) : 0
    }
}

// MARK: - 3D Touch Resource

/// 3D Touch resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ThreeDTouchCapabilityResource: AxiomCapabilityResource {
    private let configuration: ThreeDTouchCapabilityConfiguration
    private var activeEvents: [UUID: ThreeDTouchInputEvent] = [:]
    private var eventHistory: [ThreeDTouchInputResult] = []
    private var resultCache: [String: ThreeDTouchInputResult] = [:]
    private var touchProcessor: TouchProcessor = TouchProcessor()
    private var gestureRecognizer: TouchGestureRecognizer = TouchGestureRecognizer()
    private var pressureAnalyzer: PressureAnalyzer = PressureAnalyzer()
    private var inputTracker: TouchInputTracker = TouchInputTracker()
    private var metrics: ThreeDTouchCapabilityMetrics = ThreeDTouchCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<ThreeDTouchInputResult>.Continuation?
    
    // Helper classes for 3D Touch processing
    private class TouchProcessor {
        private var lastLocation: CGPoint = .zero
        private var lastTimestamp: TimeInterval = 0
        private var gestureState: ThreeDTouchInputResult.ProcessedTouchInput.GestureState = .idle
        
        func processTouchInput(
            _ touchData: ThreeDTouchInputEvent.TouchData,
            configuration: ThreeDTouchCapabilityConfiguration
        ) -> ThreeDTouchInputResult.ProcessedTouchInput {
            
            let normalizedForce = normalizeForce(touchData.force, maximumForce: touchData.maximumPossibleForce)
            let calibratedPressure = calibratePressure(touchData.pressure, sensitivity: configuration.pressureSensitivity)
            let adjustedLocation = adjustLocation(touchData.location)
            let smoothedMotion = smoothMotion(touchData.location)
            
            // Calculate velocity and acceleration
            let timeDelta = touchData.timestamp - lastTimestamp
            let locationDelta = CGPoint(
                x: touchData.location.x - lastLocation.x,
                y: touchData.location.y - lastLocation.y
            )
            
            let velocityVector = CGVector(
                dx: timeDelta > 0 ? locationDelta.x / timeDelta : 0,
                dy: timeDelta > 0 ? locationDelta.y / timeDelta : 0
            )
            
            let accelerationVector = CGVector(dx: velocityVector.dx * 0.1, dy: velocityVector.dy * 0.1)
            
            // Update gesture state
            gestureState = updateGestureState(touchData, configuration: configuration)
            
            // Classify touch
            let touchClassification = classifyTouch(touchData, configuration: configuration)
            
            // Create prediction data
            let predictionData = createPredictionData(touchData)
            
            lastLocation = adjustedLocation
            lastTimestamp = touchData.timestamp
            
            return ThreeDTouchInputResult.ProcessedTouchInput(
                originalEvent: touchData,
                normalizedForce: normalizedForce,
                calibratedPressure: calibratedPressure,
                adjustedLocation: adjustedLocation,
                smoothedMotion: smoothedMotion,
                velocityVector: velocityVector,
                accelerationVector: accelerationVector,
                gestureState: gestureState,
                touchClassification: touchClassification,
                predictionData: predictionData
            )
        }
        
        private func normalizeForce(_ force: Double, maximumForce: Double) -> Double {
            guard maximumForce > 0 else { return 0 }
            return min(max(force / maximumForce, 0.0), 1.0)
        }
        
        private func calibratePressure(_ pressure: Double, sensitivity: ThreeDTouchCapabilityConfiguration.PressureSensitivity) -> Double {
            let multiplier: Double
            switch sensitivity {
            case .light: multiplier = 0.5
            case .medium: multiplier = 1.0
            case .firm: multiplier = 1.5
            case .custom: multiplier = 1.2
            }
            
            return min(max(pressure * multiplier, 0.0), 1.0)
        }
        
        private func adjustLocation(_ location: CGPoint) -> CGPoint {
            return CGPoint(
                x: max(0, min(location.x, 1000)),
                y: max(0, min(location.y, 1000))
            )
        }
        
        private func smoothMotion(_ location: CGPoint) -> CGPoint {
            let smoothingFactor: CGFloat = 0.15
            return CGPoint(
                x: location.x * (1 - smoothingFactor) + lastLocation.x * smoothingFactor,
                y: location.y * (1 - smoothingFactor) + lastLocation.y * smoothingFactor
            )
        }
        
        private func updateGestureState(_ touchData: ThreeDTouchInputEvent.TouchData, configuration: ThreeDTouchCapabilityConfiguration) -> ThreeDTouchInputResult.ProcessedTouchInput.GestureState {
            let normalizedForce = normalizeForce(touchData.force, maximumForce: touchData.maximumPossibleForce)
            
            switch touchData.eventType {
            case .touchBegan, .forceTouchBegan:
                return .tracking
            case .touchMoved, .forceTouchChanged:
                if normalizedForce >= configuration.popThreshold {
                    return .popping
                } else if normalizedForce >= configuration.peekThreshold {
                    return .peeking
                } else if normalizedForce >= configuration.forceThreshold {
                    return .forceTouching
                } else {
                    return .tracking
                }
            case .touchEnded, .forceTouchEnded:
                return .completed
            case .touchCancelled:
                return .cancelled
            default:
                return gestureState
            }
        }
        
        private func classifyTouch(_ touchData: ThreeDTouchInputEvent.TouchData, configuration: ThreeDTouchCapabilityConfiguration) -> ThreeDTouchInputResult.ProcessedTouchInput.TouchClassification {
            let normalizedForce = normalizeForce(touchData.force, maximumForce: touchData.maximumPossibleForce)
            
            if normalizedForce >= configuration.popThreshold {
                return .pop
            } else if normalizedForce >= configuration.peekThreshold {
                return .peek
            } else if normalizedForce >= configuration.forceThreshold {
                return .forceTouch
            } else if normalizedForce > 0.7 {
                return .firmTouch
            } else if normalizedForce > 0.3 {
                return .normalTouch
            } else {
                return .lightTouch
            }
        }
        
        private func createPredictionData(_ touchData: ThreeDTouchInputEvent.TouchData) -> ThreeDTouchInputResult.ProcessedTouchInput.PredictionData? {
            guard !touchData.predictedTouches.isEmpty else { return nil }
            
            let predictedLocations = touchData.predictedTouches.map { $0.location }
            let predictedForces = touchData.predictedTouches.map { $0.force }
            let confidenceScores = touchData.predictedTouches.map { $0.confidence }
            let predictionTime = touchData.predictedTouches.last?.timestamp ?? 0
            
            return ThreeDTouchInputResult.ProcessedTouchInput.PredictionData(
                predictedLocations: predictedLocations,
                predictedForces: predictedForces,
                confidenceScores: confidenceScores,
                predictionTime: predictionTime
            )
        }
    }
    
    private class TouchGestureRecognizer {
        func recognizeGestures(from touchData: ThreeDTouchInputEvent.TouchData, processedTouch: ThreeDTouchInputResult.ProcessedTouchInput) -> [ThreeDTouchInputResult.RecognizedTouchGesture] {
            var gestures: [ThreeDTouchInputResult.RecognizedTouchGesture] = []
            
            // Peek gesture
            if processedTouch.gestureState == .peeking {
                let gesture = ThreeDTouchInputResult.RecognizedTouchGesture(
                    gestureType: .peek,
                    confidence: 0.9,
                    location: touchData.location,
                    force: processedTouch.normalizedForce,
                    duration: 0.2,
                    parameters: ["force": processedTouch.normalizedForce, "pressure": processedTouch.calibratedPressure],
                    gesturePhase: .began
                )
                gestures.append(gesture)
            }
            
            // Pop gesture
            if processedTouch.gestureState == .popping {
                let gesture = ThreeDTouchInputResult.RecognizedTouchGesture(
                    gestureType: .pop,
                    confidence: 0.95,
                    location: touchData.location,
                    force: processedTouch.normalizedForce,
                    duration: 0.1,
                    parameters: ["force": processedTouch.normalizedForce, "pressure": processedTouch.calibratedPressure],
                    gesturePhase: .recognized
                )
                gestures.append(gesture)
            }
            
            // Force touch gesture
            if processedTouch.gestureState == .forceTouching {
                let gesture = ThreeDTouchInputResult.RecognizedTouchGesture(
                    gestureType: .forceTouch,
                    confidence: 0.85,
                    location: touchData.location,
                    force: processedTouch.normalizedForce,
                    duration: 0.3,
                    parameters: ["force": processedTouch.normalizedForce, "pressure": processedTouch.calibratedPressure],
                    gesturePhase: .changed
                )
                gestures.append(gesture)
            }
            
            // Quick action (edge-based force touch)
            if touchData.location.x < 50 && processedTouch.normalizedForce > 0.8 {
                let gesture = ThreeDTouchInputResult.RecognizedTouchGesture(
                    gestureType: .quickAction,
                    confidence: 0.8,
                    location: touchData.location,
                    force: processedTouch.normalizedForce,
                    duration: 0.15,
                    parameters: ["force": processedTouch.normalizedForce, "edge": 1.0],
                    gesturePhase: .recognized
                )
                gestures.append(gesture)
            }
            
            return gestures
        }
    }
    
    private class PressureAnalyzer {
        private var pressureHistory: [Double] = []
        
        func analyzePressure(from touchData: ThreeDTouchInputEvent.TouchData, processedTouch: ThreeDTouchInputResult.ProcessedTouchInput) -> ThreeDTouchInputResult.PressureAnalysis {
            pressureHistory.append(processedTouch.calibratedPressure)
            if pressureHistory.count > 10 {
                pressureHistory.removeFirst()
            }
            
            let averagePressure = pressureHistory.reduce(0, +) / Double(pressureHistory.count)
            let peakPressure = pressureHistory.max() ?? 0
            let pressureVariation = calculateVariation(pressureHistory)
            let pressureGradient = calculateGradient()
            let steadiness = calculateSteadiness()
            let responsiveness = calculateResponsiveness()
            let forceAccuracy = calculateForceAccuracy()
            let pressurePattern = analyzePressurePattern()
            
            return ThreeDTouchInputResult.PressureAnalysis(
                averagePressure: averagePressure,
                peakPressure: peakPressure,
                pressureVariation: pressureVariation,
                pressureGradient: pressureGradient,
                steadiness: steadiness,
                responsiveness: responsiveness,
                forceAccuracy: forceAccuracy,
                pressurePattern: pressurePattern
            )
        }
        
        private func calculateVariation(_ values: [Double]) -> Double {
            guard values.count > 1 else { return 0 }
            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            return sqrt(variance)
        }
        
        private func calculateGradient() -> Double {
            guard pressureHistory.count >= 2 else { return 0 }
            let current = pressureHistory.last!
            let previous = pressureHistory[pressureHistory.count - 2]
            return current - previous
        }
        
        private func calculateSteadiness() -> Double {
            let variation = calculateVariation(pressureHistory)
            return max(0, 1.0 - variation)
        }
        
        private func calculateResponsiveness() -> Double {
            return 0.9 // Simplified calculation
        }
        
        private func calculateForceAccuracy() -> Double {
            return 0.85 // Simplified calculation
        }
        
        private func analyzePressurePattern() -> ThreeDTouchInputResult.PressureAnalysis.PressurePattern {
            guard pressureHistory.count > 3 else { return .linear }
            
            let isIncreasing = pressureHistory.dropFirst().enumerated().allSatisfy { index, pressure in
                pressure >= pressureHistory[index]
            }
            
            let isOscillating = pressureHistory.indices.dropFirst().contains { index in
                let current = pressureHistory[index]
                let previous = pressureHistory[index - 1]
                return abs(current - previous) > 0.1
            }
            
            if isOscillating {
                return .oscillating
            } else if isIncreasing {
                return .linear
            } else {
                return .irregular
            }
        }
    }
    
    private class TouchInputTracker {
        private var sessionStartTime: Date = Date()
        private var touchCount: Int = 0
        private var gestureCount: Int = 0
        private var totalLatency: TimeInterval = 0
        private var forceValues: [Double] = []
        
        func trackTouch(_ touchData: ThreeDTouchInputEvent.TouchData, latency: TimeInterval, gestures: [ThreeDTouchInputResult.RecognizedTouchGesture]) {
            touchCount += 1
            gestureCount += gestures.count
            totalLatency += latency
            
            forceValues.append(touchData.force)
            if forceValues.count > 100 {
                forceValues.removeFirst()
            }
        }
        
        func calculateMetrics() -> ThreeDTouchInputResult.TouchInputMetrics {
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            let touchesPerSecond = sessionDuration > 0 ? Double(touchCount) / sessionDuration : 0
            let averageLatency = touchCount > 0 ? totalLatency / Double(touchCount) : 0
            let averageForce = forceValues.isEmpty ? 0 : forceValues.reduce(0, +) / Double(forceValues.count)
            let gestureRecognitionRate = touchCount > 0 ? Double(gestureCount) / Double(touchCount) : 0
            let forceRange = forceValues.isEmpty ? 0.0...1.0 : forceValues.min()!...forceValues.max()!
            
            return ThreeDTouchInputResult.TouchInputMetrics(
                totalTouches: touchCount,
                averageForce: averageForce,
                touchesPerSecond: touchesPerSecond,
                averageLatency: averageLatency,
                gestureRecognitionRate: gestureRecognitionRate,
                forceRange: forceRange,
                accuracy: 0.92,
                responsiveness: 0.88
            )
        }
        
        func reset() {
            sessionStartTime = Date()
            touchCount = 0
            gestureCount = 0
            totalLatency = 0
            forceValues.removeAll()
        }
    }
    
    public init(configuration: ThreeDTouchCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 180_000_000, // 180MB for 3D Touch processing
            cpu: 2.8, // High CPU usage for real-time force analysis
            bandwidth: 0,
            storage: 45_000_000 // 45MB for touch data and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 6_000_000 // ~6MB per active event
            let cacheMemory = resultCache.count * 30_000 // ~30KB per cached result
            let historyMemory = eventHistory.count * 18_000
            let processingMemory = 40_000_000 // Touch processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.2 : 2.3,
                bandwidth: 0,
                storage: resultCache.count * 15_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // 3D Touch is available on supported devices with iOS 9+, Force Touch on iOS 13+
        if #available(iOS 9.0, *) {
            return configuration.enable3DTouchSupport
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        inputTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = ThreeDTouchCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        touchProcessor = TouchProcessor()
        gestureRecognizer = TouchGestureRecognizer()
        pressureAnalyzer = PressureAnalyzer()
        inputTracker = TouchInputTracker()
        
        if configuration.enableLogging {
            print("[3DTouch] 🚀 3D Touch capability initialized")
            print("[3DTouch] 📱 Pressure sensitivity: \(configuration.pressureSensitivity.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: ThreeDTouchCapabilityConfiguration) async throws {
        // Update 3D Touch configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<ThreeDTouchInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - 3D Touch Processing
    
    public func processInput(_ event: ThreeDTouchInputEvent) async throws -> ThreeDTouchInputResult {
        guard configuration.enable3DTouchSupport else {
            throw ThreeDTouchError.threeDTouchDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Process touch input
            let processedTouch = touchProcessor.processTouchInput(event.touchData, configuration: configuration)
            
            // Recognize gestures if enabled
            var recognizedGestures: [ThreeDTouchInputResult.RecognizedTouchGesture] = []
            if configuration.enablePeekPop || configuration.enableQuickActions {
                recognizedGestures = gestureRecognizer.recognizeGestures(from: event.touchData, processedTouch: processedTouch)
            }
            
            // Analyze pressure if enabled
            var pressureAnalysis: ThreeDTouchInputResult.PressureAnalysis
            if configuration.enablePressureAnalysis {
                pressureAnalysis = pressureAnalyzer.analyzePressure(from: event.touchData, processedTouch: processedTouch)
            } else {
                pressureAnalysis = ThreeDTouchInputResult.PressureAnalysis(
                    averagePressure: 0, peakPressure: 0, pressureVariation: 0, pressureGradient: 0,
                    steadiness: 0, responsiveness: 0, forceAccuracy: 0, pressurePattern: .linear
                )
            }
            
            // Track input for metrics
            inputTracker.trackTouch(event.touchData, latency: processedTouch.velocityVector.dx, gestures: recognizedGestures)
            let inputMetrics = inputTracker.calculateMetrics()
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ThreeDTouchInputResult(
                eventId: event.id,
                processedTouch: processedTouch,
                recognizedGestures: recognizedGestures,
                pressureAnalysis: pressureAnalysis,
                inputMetrics: inputMetrics,
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
            let result = ThreeDTouchInputResult(
                eventId: event.id,
                processedTouch: ThreeDTouchInputResult.ProcessedTouchInput(
                    originalEvent: event.touchData,
                    normalizedForce: 0,
                    calibratedPressure: 0,
                    adjustedLocation: .zero,
                    smoothedMotion: .zero,
                    velocityVector: .zero,
                    accelerationVector: .zero,
                    gestureState: .idle,
                    touchClassification: .lightTouch
                ),
                recognizedGestures: [],
                pressureAnalysis: ThreeDTouchInputResult.PressureAnalysis(
                    averagePressure: 0, peakPressure: 0, pressureVariation: 0, pressureGradient: 0,
                    steadiness: 0, responsiveness: 0, forceAccuracy: 0, pressurePattern: .linear
                ),
                inputMetrics: ThreeDTouchInputResult.TouchInputMetrics(
                    totalTouches: 0, averageForce: 0, touchesPerSecond: 0, averageLatency: 0,
                    gestureRecognitionRate: 0, forceRange: 0.0...1.0, accuracy: 0, responsiveness: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? ThreeDTouchError ?? ThreeDTouchError.processingError(error.localizedDescription)
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
    
    public func getActiveEvents() async -> [ThreeDTouchInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [ThreeDTouchInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ThreeDTouchCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ThreeDTouchCapabilityMetrics()
        inputTracker.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for event: ThreeDTouchInputEvent) -> String {
        let eventType = event.touchData.eventType.rawValue
        let force = Int(event.touchData.force * 100)
        let location = "\(Int(event.touchData.location.x))_\(Int(event.touchData.location.y))"
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000)
        return "\(eventType)_\(force)_\(location)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: ThreeDTouchInputResult) async {
        let totalEvents = metrics.totalTouchEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalTouchEvents)) + result.processingTime) / Double(totalEvents)
        
        var eventsByType = metrics.eventsByType
        eventsByType[result.processedTouch.originalEvent.eventType.rawValue, default: 0] += 1
        
        var gesturesByType = metrics.gesturesByType
        for gesture in result.recognizedGestures {
            gesturesByType[gesture.gestureType.rawValue, default: 0] += 1
        }
        
        var touchesByClassification = metrics.touchesByClassification
        touchesByClassification[result.processedTouch.touchClassification.rawValue, default: 0] += 1
        
        let newAverageEventsPerSession = ((metrics.averageEventsPerSession * Double(metrics.successfulEvents)) + Double(result.inputMetrics.totalTouches)) / Double(successfulEvents)
        let newAverageGesturesPerSession = ((metrics.averageGesturesPerSession * Double(metrics.successfulEvents)) + Double(result.gestureCount)) / Double(successfulEvents)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let newAverageTouchesPerSession = ((performanceStats.averageTouchesPerSession * Double(metrics.successfulEvents)) + Double(result.inputMetrics.totalTouches)) / Double(successfulEvents)
        let newAverageForceUsage = ((performanceStats.averageForceUsage * Double(metrics.successfulEvents)) + result.inputMetrics.averageForce) / Double(successfulEvents)
        let newAveragePressureAccuracy = ((performanceStats.averagePressureAccuracy * Double(metrics.successfulEvents)) + result.pressureAnalysis.forceAccuracy) / Double(successfulEvents)
        let totalGestures = performanceStats.totalGestures + result.inputMetrics.totalTouches
        let newTouchAccuracy = ((performanceStats.touchAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.accuracy) / Double(successfulEvents)
        let newGestureRecognitionAccuracy = ((performanceStats.gestureRecognitionAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.gestureRecognitionRate) / Double(successfulEvents)
        
        performanceStats = ThreeDTouchCapabilityMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageTouchesPerSession: newAverageTouchesPerSession,
            averageForceUsage: newAverageForceUsage,
            averagePressureAccuracy: newAveragePressureAccuracy,
            totalGestures: totalGestures,
            touchAccuracy: newTouchAccuracy,
            deviceReliability: performanceStats.deviceReliability,
            gestureRecognitionAccuracy: newGestureRecognitionAccuracy
        )
        
        metrics = ThreeDTouchCapabilityMetrics(
            totalTouchEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByType: eventsByType,
            gesturesByType: gesturesByType,
            touchesByClassification: touchesByClassification,
            errorsByType: metrics.errorsByType,
            averageLatency: result.inputMetrics.averageLatency,
            averageEventsPerSession: newAverageEventsPerSession,
            averageGesturesPerSession: newAverageGesturesPerSession,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: ThreeDTouchInputResult) async {
        let totalEvents = metrics.totalTouchEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = ThreeDTouchCapabilityMetrics(
            totalTouchEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByType: metrics.eventsByType,
            gesturesByType: metrics.gesturesByType,
            touchesByClassification: metrics.touchesByClassification,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageEventsPerSession: metrics.averageEventsPerSession,
            averageGesturesPerSession: metrics.averageGesturesPerSession,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logTouchEvent(_ result: ThreeDTouchInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let eventType = result.processedTouch.originalEvent.eventType.rawValue
        let force = String(format: "%.2f", result.processedTouch.normalizedForce)
        let gestureCount = result.gestureCount
        let qualityStr = String(format: "%.1f", result.qualityScore * 100)
        
        print("[3DTouch] \(statusIcon) Event: \(eventType), \(force) force, \(gestureCount) gestures, \(qualityStr)% quality (\(timeStr)s)")
        
        if let error = result.error {
            print("[3DTouch] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - 3D Touch Capability Implementation

/// 3D Touch capability providing comprehensive 3D Touch and Force Touch support
@available(iOS 13.0, macOS 10.15, *)
public actor ThreeDTouchCapability: DomainCapability {
    public typealias ConfigurationType = ThreeDTouchCapabilityConfiguration
    public typealias ResourceType = ThreeDTouchCapabilityResource
    
    private var _configuration: ThreeDTouchCapabilityConfiguration
    private var _resources: ThreeDTouchCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(7)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "3d-touch-capability" }
    
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
    
    public var configuration: ThreeDTouchCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ThreeDTouchCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ThreeDTouchCapabilityConfiguration = ThreeDTouchCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ThreeDTouchCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ThreeDTouchCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid 3D Touch configuration")
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
        // 3D Touch is supported on iPhone 6s and later (until iPhone XR), Force Touch on trackpads
        if #available(iOS 9.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // 3D Touch doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - 3D Touch Operations
    
    /// Process 3D Touch input event
    public func processInput(_ event: ThreeDTouchInputEvent) async throws -> ThreeDTouchInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        return try await _resources.processInput(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<ThreeDTouchInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [ThreeDTouchInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [ThreeDTouchInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ThreeDTouchCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("3D Touch capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create force touch event
    public func createForceTouchEvent(
        at location: CGPoint,
        force: Double = 0.8,
        maximumForce: Double = 1.0,
        pressure: Double = 0.7
    ) -> ThreeDTouchInputEvent {
        let deviceInfo = ThreeDTouchInputEvent.TouchData.DeviceInfo(
            supports3DTouch: true,
            supportsForceTouch: true,
            maximumForce: maximumForce,
            deviceModel: "iPhone",
            screenSize: CGSize(width: 375, height: 667),
            pixelDensity: 2.0
        )
        
        let touchData = ThreeDTouchInputEvent.TouchData(
            eventType: .forceTouchBegan,
            location: location,
            force: force,
            maximumPossibleForce: maximumForce,
            pressure: pressure,
            deviceInfo: deviceInfo,
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        return ThreeDTouchInputEvent(touchData: touchData)
    }
    
    /// Create peek gesture event
    public func createPeekEvent(
        at location: CGPoint,
        force: Double = 0.4,
        maximumForce: Double = 1.0
    ) -> ThreeDTouchInputEvent {
        let deviceInfo = ThreeDTouchInputEvent.TouchData.DeviceInfo(
            supports3DTouch: true,
            supportsForceTouch: true,
            maximumForce: maximumForce,
            deviceModel: "iPhone",
            screenSize: CGSize(width: 375, height: 667),
            pixelDensity: 2.0
        )
        
        let touchData = ThreeDTouchInputEvent.TouchData(
            eventType: .peekStarted,
            location: location,
            force: force,
            maximumPossibleForce: maximumForce,
            pressure: force * 0.8,
            deviceInfo: deviceInfo,
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        return ThreeDTouchInputEvent(touchData: touchData)
    }
    
    /// Create pop gesture event
    public func createPopEvent(
        at location: CGPoint,
        force: Double = 0.9,
        maximumForce: Double = 1.0
    ) -> ThreeDTouchInputEvent {
        let deviceInfo = ThreeDTouchInputEvent.TouchData.DeviceInfo(
            supports3DTouch: true,
            supportsForceTouch: true,
            maximumForce: maximumForce,
            deviceModel: "iPhone",
            screenSize: CGSize(width: 375, height: 667),
            pixelDensity: 2.0
        )
        
        let touchData = ThreeDTouchInputEvent.TouchData(
            eventType: .popTriggered,
            location: location,
            force: force,
            maximumPossibleForce: maximumForce,
            pressure: force * 0.9,
            deviceInfo: deviceInfo,
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        return ThreeDTouchInputEvent(touchData: touchData)
    }
    
    /// Check if 3D Touch is available on device
    public func is3DTouchAvailable() async throws -> Bool {
        if #available(iOS 9.0, *) {
            return true // Simplified check, actual implementation would query device capabilities
        }
        return false
    }
    
    /// Get force touch thresholds
    public func getForceThresholds() async -> (peek: Double, pop: Double, force: Double) {
        let config = await configuration
        return (peek: config.peekThreshold, pop: config.popThreshold, force: config.forceThreshold)
    }
    
    /// Check if device supports haptic feedback
    public func supportsHapticFeedback() async -> Bool {
        return true // Simplified check
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// 3D Touch specific errors
public enum ThreeDTouchError: Error, LocalizedError {
    case threeDTouchDisabled
    case forceNotSupported
    case processingError(String)
    case gestureRecognitionFailed
    case pressureAnalysisFailed
    case invalidTouchData
    case deviceNotSupported
    case touchTimeout(UUID)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .threeDTouchDisabled:
            return "3D Touch support is disabled"
        case .forceNotSupported:
            return "Force touch is not supported on this device"
        case .processingError(let reason):
            return "3D Touch processing failed: \(reason)"
        case .gestureRecognitionFailed:
            return "Gesture recognition failed"
        case .pressureAnalysisFailed:
            return "Pressure analysis failed"
        case .invalidTouchData:
            return "Invalid touch data provided"
        case .deviceNotSupported:
            return "Device does not support 3D Touch"
        case .touchTimeout(let id):
            return "Touch timeout: \(id)"
        case .configurationError(let reason):
            return "3D Touch configuration error: \(reason)"
        }
    }
}