import Foundation
import PencilKit
import UIKit
import CoreGraphics
import AxiomCore
import AxiomCapabilities

// MARK: - Apple Pencil Capability Configuration

/// Configuration for Apple Pencil capability
public struct ApplePencilCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableApplePencilSupport: Bool
    public let enablePressureSensitivity: Bool
    public let enableTiltSensitivity: Bool
    public let enableAzimuthSensitivity: Bool
    public let enableDoubleTapGesture: Bool
    public let enablePencilGestures: Bool
    public let enableDrawingMode: Bool
    public let enableAnnotationMode: Bool
    public let enablePrecisionMode: Bool
    public let enableRealTimeInput: Bool
    public let maxConcurrentInputs: Int
    public let inputTimeout: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let pressureSensitivity: PressureSensitivity
    public let tiltSensitivity: TiltSensitivity
    public let inputSampling: InputSampling
    public let pencilGeneration: PencilGeneration
    public let inputLatencyTarget: TimeInterval
    public let supportedModes: [InputMode]
    
    public enum PressureSensitivity: String, Codable, CaseIterable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case maximum = "maximum"
        case custom = "custom"
    }
    
    public enum TiltSensitivity: String, Codable, CaseIterable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case maximum = "maximum"
        case custom = "custom"
    }
    
    public enum InputSampling: String, Codable, CaseIterable {
        case standard = "standard"    // 60Hz
        case high = "high"           // 120Hz
        case ultra = "ultra"         // 240Hz
        case maximum = "maximum"     // Device maximum
        case adaptive = "adaptive"
    }
    
    public enum PencilGeneration: String, Codable, CaseIterable {
        case firstGeneration = "firstGeneration"
        case secondGeneration = "secondGeneration"
        case any = "any"
        case detected = "detected"
    }
    
    public enum InputMode: String, Codable, CaseIterable {
        case drawing = "drawing"
        case annotation = "annotation"
        case selection = "selection"
        case erasing = "erasing"
        case precision = "precision"
        case gesture = "gesture"
        case customMode = "customMode"
    }
    
    public init(
        enableApplePencilSupport: Bool = true,
        enablePressureSensitivity: Bool = true,
        enableTiltSensitivity: Bool = true,
        enableAzimuthSensitivity: Bool = true,
        enableDoubleTapGesture: Bool = true,
        enablePencilGestures: Bool = true,
        enableDrawingMode: Bool = true,
        enableAnnotationMode: Bool = true,
        enablePrecisionMode: Bool = true,
        enableRealTimeInput: Bool = true,
        maxConcurrentInputs: Int = 3,
        inputTimeout: TimeInterval = 30.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 500,
        pressureSensitivity: PressureSensitivity = .high,
        tiltSensitivity: TiltSensitivity = .medium,
        inputSampling: InputSampling = .high,
        pencilGeneration: PencilGeneration = .any,
        inputLatencyTarget: TimeInterval = 0.020,
        supportedModes: [InputMode] = InputMode.allCases
    ) {
        self.enableApplePencilSupport = enableApplePencilSupport
        self.enablePressureSensitivity = enablePressureSensitivity
        self.enableTiltSensitivity = enableTiltSensitivity
        self.enableAzimuthSensitivity = enableAzimuthSensitivity
        self.enableDoubleTapGesture = enableDoubleTapGesture
        self.enablePencilGestures = enablePencilGestures
        self.enableDrawingMode = enableDrawingMode
        self.enableAnnotationMode = enableAnnotationMode
        self.enablePrecisionMode = enablePrecisionMode
        self.enableRealTimeInput = enableRealTimeInput
        self.maxConcurrentInputs = maxConcurrentInputs
        self.inputTimeout = inputTimeout
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.pressureSensitivity = pressureSensitivity
        self.tiltSensitivity = tiltSensitivity
        self.inputSampling = inputSampling
        self.pencilGeneration = pencilGeneration
        self.inputLatencyTarget = inputLatencyTarget
        self.supportedModes = supportedModes
    }
    
    public var isValid: Bool {
        maxConcurrentInputs > 0 &&
        inputTimeout > 0 &&
        inputLatencyTarget > 0 &&
        cacheSize >= 0 &&
        !supportedModes.isEmpty
    }
    
    public func merged(with other: ApplePencilCapabilityConfiguration) -> ApplePencilCapabilityConfiguration {
        ApplePencilCapabilityConfiguration(
            enableApplePencilSupport: other.enableApplePencilSupport,
            enablePressureSensitivity: other.enablePressureSensitivity,
            enableTiltSensitivity: other.enableTiltSensitivity,
            enableAzimuthSensitivity: other.enableAzimuthSensitivity,
            enableDoubleTapGesture: other.enableDoubleTapGesture,
            enablePencilGestures: other.enablePencilGestures,
            enableDrawingMode: other.enableDrawingMode,
            enableAnnotationMode: other.enableAnnotationMode,
            enablePrecisionMode: other.enablePrecisionMode,
            enableRealTimeInput: other.enableRealTimeInput,
            maxConcurrentInputs: other.maxConcurrentInputs,
            inputTimeout: other.inputTimeout,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            pressureSensitivity: other.pressureSensitivity,
            tiltSensitivity: other.tiltSensitivity,
            inputSampling: other.inputSampling,
            pencilGeneration: other.pencilGeneration,
            inputLatencyTarget: other.inputLatencyTarget,
            supportedModes: other.supportedModes
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> ApplePencilCapabilityConfiguration {
        var adjustedTimeout = inputTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentInputs = maxConcurrentInputs
        var adjustedCacheSize = cacheSize
        var adjustedRealTimeInput = enableRealTimeInput
        var adjustedInputSampling = inputSampling
        var adjustedLatencyTarget = inputLatencyTarget
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(inputTimeout, 15.0)
            adjustedConcurrentInputs = min(maxConcurrentInputs, 1)
            adjustedCacheSize = min(cacheSize, 100)
            adjustedRealTimeInput = false
            adjustedInputSampling = .standard
            adjustedLatencyTarget = min(inputLatencyTarget, 0.050)
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return ApplePencilCapabilityConfiguration(
            enableApplePencilSupport: enableApplePencilSupport,
            enablePressureSensitivity: enablePressureSensitivity,
            enableTiltSensitivity: enableTiltSensitivity,
            enableAzimuthSensitivity: enableAzimuthSensitivity,
            enableDoubleTapGesture: enableDoubleTapGesture,
            enablePencilGestures: enablePencilGestures,
            enableDrawingMode: enableDrawingMode,
            enableAnnotationMode: enableAnnotationMode,
            enablePrecisionMode: enablePrecisionMode,
            enableRealTimeInput: adjustedRealTimeInput,
            maxConcurrentInputs: adjustedConcurrentInputs,
            inputTimeout: adjustedTimeout,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            pressureSensitivity: pressureSensitivity,
            tiltSensitivity: tiltSensitivity,
            inputSampling: adjustedInputSampling,
            pencilGeneration: pencilGeneration,
            inputLatencyTarget: adjustedLatencyTarget,
            supportedModes: supportedModes
        )
    }
}

// MARK: - Apple Pencil Types

/// Apple Pencil input event
public struct ApplePencilInputEvent: Sendable, Identifiable {
    public let id: UUID
    public let pencilData: PencilData
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct PencilData: Sendable {
        public let eventType: PencilEventType
        public let location: CGPoint
        public let previousLocation: CGPoint
        public let pressure: Float
        public let force: Float
        public let maximumPossibleForce: Float
        public let altitudeAngle: Float
        public let azimuthAngle: Float
        public let azimuthUnitVector: CGVector
        public let estimatedProperties: EstimatedProperties
        public let estimatedPropertiesExpectingUpdates: EstimatedProperties
        public let pencilInfo: PencilInfo
        public let timestamp: TimeInterval
        public let coalescedInputs: [CoalescedInput]
        public let predictedInputs: [PredictedInput]
        
        public struct EstimatedProperties: OptionSet, Sendable {
            public let rawValue: Int
            
            public init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            public static let location = EstimatedProperties(rawValue: 1 << 0)
            public static let pressure = EstimatedProperties(rawValue: 1 << 1)
            public static let azimuth = EstimatedProperties(rawValue: 1 << 2)
            public static let altitude = EstimatedProperties(rawValue: 1 << 3)
            public static let force = EstimatedProperties(rawValue: 1 << 4)
        }
        
        public struct PencilInfo: Sendable {
            public let pencilType: PencilType
            public let generation: ApplePencilCapabilityConfiguration.PencilGeneration
            public let serialNumber: String?
            public let batteryLevel: Float?
            public let isConnected: Bool
            public let isCharging: Bool
            public let supportsPressure: Bool
            public let supportsTilt: Bool
            public let supportsAzimuth: Bool
            public let supportsDoubleTap: Bool
            
            public enum PencilType: String, Sendable, CaseIterable {
                case applePencil1 = "applePencil1"
                case applePencil2 = "applePencil2"
                case applePencilUSBC = "applePencilUSBC"
                case generic = "generic"
                case unknown = "unknown"
            }
            
            public init(pencilType: PencilType, generation: ApplePencilCapabilityConfiguration.PencilGeneration, serialNumber: String? = nil, batteryLevel: Float? = nil, isConnected: Bool = true, isCharging: Bool = false, supportsPressure: Bool = true, supportsTilt: Bool = true, supportsAzimuth: Bool = true, supportsDoubleTap: Bool = false) {
                self.pencilType = pencilType
                self.generation = generation
                self.serialNumber = serialNumber
                self.batteryLevel = batteryLevel
                self.isConnected = isConnected
                self.isCharging = isCharging
                self.supportsPressure = supportsPressure
                self.supportsTilt = supportsTilt
                self.supportsAzimuth = supportsAzimuth
                self.supportsDoubleTap = supportsDoubleTap
            }
        }
        
        public struct CoalescedInput: Sendable {
            public let location: CGPoint
            public let pressure: Float
            public let altitudeAngle: Float
            public let azimuthAngle: Float
            public let timestamp: TimeInterval
            
            public init(location: CGPoint, pressure: Float, altitudeAngle: Float, azimuthAngle: Float, timestamp: TimeInterval) {
                self.location = location
                self.pressure = pressure
                self.altitudeAngle = altitudeAngle
                self.azimuthAngle = azimuthAngle
                self.timestamp = timestamp
            }
        }
        
        public struct PredictedInput: Sendable {
            public let location: CGPoint
            public let pressure: Float
            public let altitudeAngle: Float
            public let azimuthAngle: Float
            public let timestamp: TimeInterval
            public let confidence: Float
            
            public init(location: CGPoint, pressure: Float, altitudeAngle: Float, azimuthAngle: Float, timestamp: TimeInterval, confidence: Float) {
                self.location = location
                self.pressure = pressure
                self.altitudeAngle = altitudeAngle
                self.azimuthAngle = azimuthAngle
                self.timestamp = timestamp
                self.confidence = confidence
            }
        }
        
        public enum PencilEventType: String, Sendable, CaseIterable {
            case began = "began"
            case moved = "moved"
            case ended = "ended"
            case cancelled = "cancelled"
            case doubleTapped = "doubleTapped"
            case hovered = "hovered"
            case connected = "connected"
            case disconnected = "disconnected"
            case batteryChanged = "batteryChanged"
            case orientationChanged = "orientationChanged"
        }
        
        public init(
            eventType: PencilEventType,
            location: CGPoint = .zero,
            previousLocation: CGPoint = .zero,
            pressure: Float = 0.0,
            force: Float = 0.0,
            maximumPossibleForce: Float = 0.0,
            altitudeAngle: Float = 0.0,
            azimuthAngle: Float = 0.0,
            azimuthUnitVector: CGVector = .zero,
            estimatedProperties: EstimatedProperties = [],
            estimatedPropertiesExpectingUpdates: EstimatedProperties = [],
            pencilInfo: PencilInfo = PencilInfo(pencilType: .unknown, generation: .any),
            timestamp: TimeInterval = 0,
            coalescedInputs: [CoalescedInput] = [],
            predictedInputs: [PredictedInput] = []
        ) {
            self.eventType = eventType
            self.location = location
            self.previousLocation = previousLocation
            self.pressure = pressure
            self.force = force
            self.maximumPossibleForce = maximumPossibleForce
            self.altitudeAngle = altitudeAngle
            self.azimuthAngle = azimuthAngle
            self.azimuthUnitVector = azimuthUnitVector
            self.estimatedProperties = estimatedProperties
            self.estimatedPropertiesExpectingUpdates = estimatedPropertiesExpectingUpdates
            self.pencilInfo = pencilInfo
            self.timestamp = timestamp
            self.coalescedInputs = coalescedInputs
            self.predictedInputs = predictedInputs
        }
    }
    
    public init(pencilData: PencilData, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.pencilData = pencilData
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Apple Pencil input result
public struct ApplePencilInputResult: Sendable, Identifiable {
    public let id: UUID
    public let eventId: UUID
    public let processedInput: ProcessedPencilInput
    public let recognizedGestures: [RecognizedPencilGesture]
    public let strokeAnalysis: StrokeAnalysis
    public let inputMetrics: PencilInputMetrics
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: ApplePencilError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct ProcessedPencilInput: Sendable {
        public let originalEvent: ApplePencilInputEvent.PencilData
        public let normalizedLocation: CGPoint
        public let adjustedPressure: Float
        public let calibratedTilt: Float
        public let calibratedAzimuth: Float
        public let smoothedMotion: CGPoint
        public let velocityVector: CGVector
        public let accelerationVector: CGVector
        public let inputMode: ApplePencilCapabilityConfiguration.InputMode
        public let strokeInfo: StrokeInfo?
        public let predictionData: PredictionData?
        
        public struct StrokeInfo: Sendable {
            public let strokeId: UUID
            public let strokeType: StrokeType
            public let startLocation: CGPoint
            public let currentLocation: CGPoint
            public let length: CGFloat
            public let duration: TimeInterval
            public let averagePressure: Float
            public let isDrawing: Bool
            
            public enum StrokeType: String, Sendable, CaseIterable {
                case drawing = "drawing"
                case annotation = "annotation"
                case selection = "selection"
                case erasing = "erasing"
                case gesture = "gesture"
                case precision = "precision"
            }
            
            public init(strokeId: UUID, strokeType: StrokeType, startLocation: CGPoint, currentLocation: CGPoint, length: CGFloat, duration: TimeInterval, averagePressure: Float, isDrawing: Bool) {
                self.strokeId = strokeId
                self.strokeType = strokeType
                self.startLocation = startLocation
                self.currentLocation = currentLocation
                self.length = length
                self.duration = duration
                self.averagePressure = averagePressure
                self.isDrawing = isDrawing
            }
        }
        
        public struct PredictionData: Sendable {
            public let predictedPoints: [CGPoint]
            public let confidenceScores: [Float]
            public let predictionDistance: CGFloat
            public let predictionTime: TimeInterval
            
            public init(predictedPoints: [CGPoint], confidenceScores: [Float], predictionDistance: CGFloat, predictionTime: TimeInterval) {
                self.predictedPoints = predictedPoints
                self.confidenceScores = confidenceScores
                self.predictionDistance = predictionDistance
                self.predictionTime = predictionTime
            }
        }
        
        public init(
            originalEvent: ApplePencilInputEvent.PencilData,
            normalizedLocation: CGPoint,
            adjustedPressure: Float,
            calibratedTilt: Float,
            calibratedAzimuth: Float,
            smoothedMotion: CGPoint,
            velocityVector: CGVector,
            accelerationVector: CGVector,
            inputMode: ApplePencilCapabilityConfiguration.InputMode,
            strokeInfo: StrokeInfo? = nil,
            predictionData: PredictionData? = nil
        ) {
            self.originalEvent = originalEvent
            self.normalizedLocation = normalizedLocation
            self.adjustedPressure = adjustedPressure
            self.calibratedTilt = calibratedTilt
            self.calibratedAzimuth = calibratedAzimuth
            self.smoothedMotion = smoothedMotion
            self.velocityVector = velocityVector
            self.accelerationVector = accelerationVector
            self.inputMode = inputMode
            self.strokeInfo = strokeInfo
            self.predictionData = predictionData
        }
    }
    
    public struct RecognizedPencilGesture: Sendable {
        public let gestureType: GestureType
        public let confidence: Float
        public let location: CGPoint
        public let parameters: [String: Double]
        public let duration: TimeInterval
        public let pencilOrientation: PencilOrientation
        
        public enum GestureType: String, Sendable, CaseIterable {
            case doubleTap = "doubleTap"
            case longPress = "longPress"
            case tiltGesture = "tiltGesture"
            case pressureGesture = "pressureGesture"
            case rotationGesture = "rotationGesture"
            case swipe = "swipe"
            case scribble = "scribble"
            case customGesture = "customGesture"
        }
        
        public struct PencilOrientation: Sendable {
            public let tiltAngle: Float
            public let azimuthAngle: Float
            public let rotationAngle: Float
            public let isInverted: Bool
            
            public init(tiltAngle: Float, azimuthAngle: Float, rotationAngle: Float, isInverted: Bool) {
                self.tiltAngle = tiltAngle
                self.azimuthAngle = azimuthAngle
                self.rotationAngle = rotationAngle
                self.isInverted = isInverted
            }
        }
        
        public init(gestureType: GestureType, confidence: Float, location: CGPoint, parameters: [String: Double], duration: TimeInterval, pencilOrientation: PencilOrientation) {
            self.gestureType = gestureType
            self.confidence = confidence
            self.location = location
            self.parameters = parameters
            self.duration = duration
            self.pencilOrientation = pencilOrientation
        }
    }
    
    public struct StrokeAnalysis: Sendable {
        public let strokeCount: Int
        public let averageStrokeLength: CGFloat
        public let averageStrokeDuration: TimeInterval
        public let averagePressure: Float
        public let pressureVariation: Float
        public let tiltVariation: Float
        public let speedVariation: Float
        public let smoothnessScore: Float
        public let precisionScore: Float
        public let consistencyScore: Float
        
        public init(strokeCount: Int, averageStrokeLength: CGFloat, averageStrokeDuration: TimeInterval, averagePressure: Float, pressureVariation: Float, tiltVariation: Float, speedVariation: Float, smoothnessScore: Float, precisionScore: Float, consistencyScore: Float) {
            self.strokeCount = strokeCount
            self.averageStrokeLength = averageStrokeLength
            self.averageStrokeDuration = averageStrokeDuration
            self.averagePressure = averagePressure
            self.pressureVariation = pressureVariation
            self.tiltVariation = tiltVariation
            self.speedVariation = speedVariation
            self.smoothnessScore = smoothnessScore
            self.precisionScore = precisionScore
            self.consistencyScore = consistencyScore
        }
    }
    
    public struct PencilInputMetrics: Sendable {
        public let totalInputs: Int
        public let inputsPerSecond: Double
        public let averageLatency: TimeInterval
        public let pressureRange: ClosedRange<Float>
        public let tiltRange: ClosedRange<Float>
        public let velocityRange: ClosedRange<Float>
        public let accuracy: Double
        public let responsiveness: Double
        public let batteryUsage: Float
        
        public init(totalInputs: Int, inputsPerSecond: Double, averageLatency: TimeInterval, pressureRange: ClosedRange<Float>, tiltRange: ClosedRange<Float>, velocityRange: ClosedRange<Float>, accuracy: Double, responsiveness: Double, batteryUsage: Float) {
            self.totalInputs = totalInputs
            self.inputsPerSecond = inputsPerSecond
            self.averageLatency = averageLatency
            self.pressureRange = pressureRange
            self.tiltRange = tiltRange
            self.velocityRange = velocityRange
            self.accuracy = accuracy
            self.responsiveness = responsiveness
            self.batteryUsage = batteryUsage
        }
    }
    
    public init(
        eventId: UUID,
        processedInput: ProcessedPencilInput,
        recognizedGestures: [RecognizedPencilGesture],
        strokeAnalysis: StrokeAnalysis,
        inputMetrics: PencilInputMetrics,
        processingTime: TimeInterval,
        success: Bool,
        error: ApplePencilError? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.eventId = eventId
        self.processedInput = processedInput
        self.recognizedGestures = recognizedGestures
        self.strokeAnalysis = strokeAnalysis
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
    
    public var averageGestureConfidence: Float {
        guard !recognizedGestures.isEmpty else { return 0.0 }
        return recognizedGestures.reduce(0) { $0 + $1.confidence } / Float(recognizedGestures.count)
    }
    
    public var qualityScore: Float {
        (strokeAnalysis.smoothnessScore + strokeAnalysis.precisionScore + strokeAnalysis.consistencyScore) / 3.0
    }
}

/// Apple Pencil capability metrics
public struct ApplePencilCapabilityMetrics: Sendable {
    public let totalInputEvents: Int
    public let successfulEvents: Int
    public let failedEvents: Int
    public let averageProcessingTime: TimeInterval
    public let eventsByType: [String: Int]
    public let gesturesByType: [String: Int]
    public let inputsByMode: [String: Int]
    public let errorsByType: [String: Int]
    public let averageLatency: TimeInterval
    public let averageEventsPerSession: Double
    public let averageGesturesPerSession: Double
    public let pencilsConnected: Int
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestProcessingTime: TimeInterval
        public let worstProcessingTime: TimeInterval
        public let averageStrokesPerSession: Double
        public let averagePressureSensitivity: Float
        public let averageTiltSensitivity: Float
        public let totalGestures: Int
        public let inputAccuracy: Double
        public let pencilReliability: Double
        public let batteryEfficiency: Double
        
        public init(bestProcessingTime: TimeInterval = 0, worstProcessingTime: TimeInterval = 0, averageStrokesPerSession: Double = 0, averagePressureSensitivity: Float = 0, averageTiltSensitivity: Float = 0, totalGestures: Int = 0, inputAccuracy: Double = 0, pencilReliability: Double = 0, batteryEfficiency: Double = 0) {
            self.bestProcessingTime = bestProcessingTime
            self.worstProcessingTime = worstProcessingTime
            self.averageStrokesPerSession = averageStrokesPerSession
            self.averagePressureSensitivity = averagePressureSensitivity
            self.averageTiltSensitivity = averageTiltSensitivity
            self.totalGestures = totalGestures
            self.inputAccuracy = inputAccuracy
            self.pencilReliability = pencilReliability
            self.batteryEfficiency = batteryEfficiency
        }
    }
    
    public init(
        totalInputEvents: Int = 0,
        successfulEvents: Int = 0,
        failedEvents: Int = 0,
        averageProcessingTime: TimeInterval = 0,
        eventsByType: [String: Int] = [:],
        gesturesByType: [String: Int] = [:],
        inputsByMode: [String: Int] = [:],
        errorsByType: [String: Int] = [:],
        averageLatency: TimeInterval = 0,
        averageEventsPerSession: Double = 0,
        averageGesturesPerSession: Double = 0,
        pencilsConnected: Int = 0,
        throughputPerSecond: Double = 0,
        performanceStats: PerformanceStats = PerformanceStats()
    ) {
        self.totalInputEvents = totalInputEvents
        self.successfulEvents = successfulEvents
        self.failedEvents = failedEvents
        self.averageProcessingTime = averageProcessingTime
        self.eventsByType = eventsByType
        self.gesturesByType = gesturesByType
        self.inputsByMode = inputsByMode
        self.errorsByType = errorsByType
        self.averageLatency = averageLatency
        self.averageEventsPerSession = averageEventsPerSession
        self.averageGesturesPerSession = averageGesturesPerSession
        self.pencilsConnected = pencilsConnected
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalInputEvents) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalInputEvents > 0 ? Double(successfulEvents) / Double(totalInputEvents) : 0
    }
}

// MARK: - Apple Pencil Resource

/// Apple Pencil resource management
@available(iOS 13.0, macOS 10.15, *)
public actor ApplePencilCapabilityResource: AxiomCapabilityResource {
    private let configuration: ApplePencilCapabilityConfiguration
    private var activeEvents: [UUID: ApplePencilInputEvent] = [:]
    private var eventHistory: [ApplePencilInputResult] = []
    private var resultCache: [String: ApplePencilInputResult] = [:]
    private var pencilManager: PencilManager = PencilManager()
    private var inputProcessor: PencilInputProcessor = PencilInputProcessor()
    private var gestureRecognizer: PencilGestureRecognizer = PencilGestureRecognizer()
    private var strokeAnalyzer: StrokeAnalyzer = StrokeAnalyzer()
    private var inputTracker: PencilInputTracker = PencilInputTracker()
    private var metrics: ApplePencilCapabilityMetrics = ApplePencilCapabilityMetrics()
    private var resultStreamContinuation: AsyncStream<ApplePencilInputResult>.Continuation?
    
    // Helper classes for Apple Pencil processing
    private class PencilManager {
        private var connectedPencils: [UIPencilInteraction] = []
        
        func setupPencilSupport() {
            // Configure pencil interactions and observers
            if #available(iOS 12.1, *) {
                let pencilInteraction = UIPencilInteraction()
                pencilInteraction.delegate = self
                connectedPencils.append(pencilInteraction)
            }
        }
        
        func detectPencilGeneration() -> ApplePencilCapabilityConfiguration.PencilGeneration {
            if #available(iOS 12.1, *) {
                return .secondGeneration
            } else {
                return .firstGeneration
            }
        }
        
        func isPencilConnected() -> Bool {
            return !connectedPencils.isEmpty
        }
        
        func getPencilBatteryLevel() -> Float? {
            // Simplified - actual implementation would query system
            return 0.85
        }
        
        func configurePencilSettings(sensitivity: ApplePencilCapabilityConfiguration.PressureSensitivity) {
            // Configure pencil sensitivity settings
        }
    }
    
    private class PencilInputProcessor {
        private var lastLocation: CGPoint = .zero
        private var lastTimestamp: TimeInterval = 0
        private var currentStroke: UUID?
        
        func processPencilInput(
            _ pencilData: ApplePencilInputEvent.PencilData,
            configuration: ApplePencilCapabilityConfiguration
        ) -> ApplePencilInputResult.ProcessedPencilInput {
            
            let normalizedLocation = normalizeLocation(pencilData.location)
            let adjustedPressure = adjustPressure(pencilData.pressure, sensitivity: configuration.pressureSensitivity)
            let calibratedTilt = calibrateTilt(pencilData.altitudeAngle, sensitivity: configuration.tiltSensitivity)
            let calibratedAzimuth = calibrateAzimuth(pencilData.azimuthAngle)
            let smoothedMotion = smoothMotion(pencilData.location)
            
            // Calculate velocity and acceleration
            let timeDelta = pencilData.timestamp - lastTimestamp
            let locationDelta = CGPoint(
                x: pencilData.location.x - lastLocation.x,
                y: pencilData.location.y - lastLocation.y
            )
            
            let velocityVector = CGVector(
                dx: timeDelta > 0 ? locationDelta.x / timeDelta : 0,
                dy: timeDelta > 0 ? locationDelta.y / timeDelta : 0
            )
            
            let accelerationVector = CGVector(dx: velocityVector.dx * 0.1, dy: velocityVector.dy * 0.1)
            
            // Determine input mode
            let inputMode = determineInputMode(pencilData)
            
            // Create stroke info
            let strokeInfo = createStrokeInfo(pencilData, inputMode: inputMode)
            
            // Create prediction data
            let predictionData = createPredictionData(pencilData)
            
            lastLocation = normalizedLocation
            lastTimestamp = pencilData.timestamp
            
            return ApplePencilInputResult.ProcessedPencilInput(
                originalEvent: pencilData,
                normalizedLocation: normalizedLocation,
                adjustedPressure: adjustedPressure,
                calibratedTilt: calibratedTilt,
                calibratedAzimuth: calibratedAzimuth,
                smoothedMotion: smoothedMotion,
                velocityVector: velocityVector,
                accelerationVector: accelerationVector,
                inputMode: inputMode,
                strokeInfo: strokeInfo,
                predictionData: predictionData
            )
        }
        
        private func normalizeLocation(_ location: CGPoint) -> CGPoint {
            return CGPoint(
                x: max(0, min(location.x, 2048)),
                y: max(0, min(location.y, 2048))
            )
        }
        
        private func adjustPressure(_ pressure: Float, sensitivity: ApplePencilCapabilityConfiguration.PressureSensitivity) -> Float {
            let multiplier: Float
            switch sensitivity {
            case .none: multiplier = 0.0
            case .low: multiplier = 0.5
            case .medium: multiplier = 1.0
            case .high: multiplier = 1.5
            case .maximum: multiplier = 2.0
            case .custom: multiplier = 1.2
            }
            
            return min(max(pressure * multiplier, 0.0), 1.0)
        }
        
        private func calibrateTilt(_ tilt: Float, sensitivity: ApplePencilCapabilityConfiguration.TiltSensitivity) -> Float {
            let multiplier: Float
            switch sensitivity {
            case .none: multiplier = 0.0
            case .low: multiplier = 0.3
            case .medium: multiplier = 1.0
            case .high: multiplier = 1.5
            case .maximum: multiplier = 2.0
            case .custom: multiplier = 1.2
            }
            
            return min(max(tilt * multiplier, 0.0), Float.pi / 2)
        }
        
        private func calibrateAzimuth(_ azimuth: Float) -> Float {
            return azimuth
        }
        
        private func smoothMotion(_ location: CGPoint) -> CGPoint {
            let smoothingFactor: CGFloat = 0.15
            return CGPoint(
                x: location.x * (1 - smoothingFactor) + lastLocation.x * smoothingFactor,
                y: location.y * (1 - smoothingFactor) + lastLocation.y * smoothingFactor
            )
        }
        
        private func determineInputMode(_ pencilData: ApplePencilInputEvent.PencilData) -> ApplePencilCapabilityConfiguration.InputMode {
            if pencilData.pressure > 0.8 {
                return .drawing
            } else if pencilData.pressure < 0.2 {
                return .precision
            } else if pencilData.eventType == .doubleTapped {
                return .gesture
            } else {
                return .annotation
            }
        }
        
        private func createStrokeInfo(_ pencilData: ApplePencilInputEvent.PencilData, inputMode: ApplePencilCapabilityConfiguration.InputMode) -> ApplePencilInputResult.ProcessedPencilInput.StrokeInfo? {
            if pencilData.eventType == .began {
                currentStroke = UUID()
            }
            
            guard let strokeId = currentStroke else { return nil }
            
            let strokeType: ApplePencilInputResult.ProcessedPencilInput.StrokeInfo.StrokeType
            switch inputMode {
            case .drawing: strokeType = .drawing
            case .annotation: strokeType = .annotation
            case .selection: strokeType = .selection
            case .erasing: strokeType = .erasing
            case .precision: strokeType = .precision
            case .gesture: strokeType = .gesture
            case .customMode: strokeType = .drawing
            }
            
            return ApplePencilInputResult.ProcessedPencilInput.StrokeInfo(
                strokeId: strokeId,
                strokeType: strokeType,
                startLocation: lastLocation,
                currentLocation: pencilData.location,
                length: sqrt(pow(pencilData.location.x - lastLocation.x, 2) + pow(pencilData.location.y - lastLocation.y, 2)),
                duration: pencilData.timestamp - lastTimestamp,
                averagePressure: pencilData.pressure,
                isDrawing: pencilData.eventType != .ended
            )
        }
        
        private func createPredictionData(_ pencilData: ApplePencilInputEvent.PencilData) -> ApplePencilInputResult.ProcessedPencilInput.PredictionData? {
            guard !pencilData.predictedInputs.isEmpty else { return nil }
            
            let predictedPoints = pencilData.predictedInputs.map { $0.location }
            let confidenceScores = pencilData.predictedInputs.map { $0.confidence }
            let predictionDistance = predictedPoints.reduce(0) { distance, point in
                distance + sqrt(pow(point.x - pencilData.location.x, 2) + pow(point.y - pencilData.location.y, 2))
            }
            let predictionTime = pencilData.predictedInputs.last?.timestamp ?? 0
            
            return ApplePencilInputResult.ProcessedPencilInput.PredictionData(
                predictedPoints: predictedPoints,
                confidenceScores: confidenceScores,
                predictionDistance: predictionDistance,
                predictionTime: predictionTime
            )
        }
    }
    
    private class PencilGestureRecognizer {
        func recognizeGestures(from pencilData: ApplePencilInputEvent.PencilData) -> [ApplePencilInputResult.RecognizedPencilGesture] {
            var gestures: [ApplePencilInputResult.RecognizedPencilGesture] = []
            
            // Double tap gesture
            if pencilData.eventType == .doubleTapped {
                let pencilOrientation = ApplePencilInputResult.RecognizedPencilGesture.PencilOrientation(
                    tiltAngle: pencilData.altitudeAngle,
                    azimuthAngle: pencilData.azimuthAngle,
                    rotationAngle: 0.0,
                    isInverted: false
                )
                
                let gesture = ApplePencilInputResult.RecognizedPencilGesture(
                    gestureType: .doubleTap,
                    confidence: 0.95,
                    location: pencilData.location,
                    parameters: ["taps": 2.0],
                    duration: 0.3,
                    pencilOrientation: pencilOrientation
                )
                gestures.append(gesture)
            }
            
            // Pressure gesture
            if pencilData.pressure > 0.9 {
                let pencilOrientation = ApplePencilInputResult.RecognizedPencilGesture.PencilOrientation(
                    tiltAngle: pencilData.altitudeAngle,
                    azimuthAngle: pencilData.azimuthAngle,
                    rotationAngle: 0.0,
                    isInverted: false
                )
                
                let gesture = ApplePencilInputResult.RecognizedPencilGesture(
                    gestureType: .pressureGesture,
                    confidence: 0.8,
                    location: pencilData.location,
                    parameters: ["pressure": Double(pencilData.pressure)],
                    duration: 0.1,
                    pencilOrientation: pencilOrientation
                )
                gestures.append(gesture)
            }
            
            // Tilt gesture
            if pencilData.altitudeAngle < 0.2 {
                let pencilOrientation = ApplePencilInputResult.RecognizedPencilGesture.PencilOrientation(
                    tiltAngle: pencilData.altitudeAngle,
                    azimuthAngle: pencilData.azimuthAngle,
                    rotationAngle: 0.0,
                    isInverted: false
                )
                
                let gesture = ApplePencilInputResult.RecognizedPencilGesture(
                    gestureType: .tiltGesture,
                    confidence: 0.7,
                    location: pencilData.location,
                    parameters: ["tilt": Double(pencilData.altitudeAngle)],
                    duration: 0.2,
                    pencilOrientation: pencilOrientation
                )
                gestures.append(gesture)
            }
            
            return gestures
        }
    }
    
    private class StrokeAnalyzer {
        private var strokeHistory: [ApplePencilInputResult.ProcessedPencilInput.StrokeInfo] = []
        
        func analyzeStrokes() -> ApplePencilInputResult.StrokeAnalysis {
            guard !strokeHistory.isEmpty else {
                return ApplePencilInputResult.StrokeAnalysis(
                    strokeCount: 0,
                    averageStrokeLength: 0,
                    averageStrokeDuration: 0,
                    averagePressure: 0,
                    pressureVariation: 0,
                    tiltVariation: 0,
                    speedVariation: 0,
                    smoothnessScore: 0,
                    precisionScore: 0,
                    consistencyScore: 0
                )
            }
            
            let strokeCount = strokeHistory.count
            let averageStrokeLength = strokeHistory.reduce(0) { $0 + $1.length } / CGFloat(strokeCount)
            let averageStrokeDuration = strokeHistory.reduce(0) { $0 + $1.duration } / TimeInterval(strokeCount)
            let averagePressure = strokeHistory.reduce(0) { $0 + $1.averagePressure } / Float(strokeCount)
            
            // Calculate variations
            let pressureVariation = calculateVariation(strokeHistory.map { $0.averagePressure })
            let tiltVariation: Float = 0.1 // Simplified
            let speedVariation: Float = 0.2 // Simplified
            
            // Calculate quality scores
            let smoothnessScore = calculateSmoothness()
            let precisionScore = calculatePrecision()
            let consistencyScore = calculateConsistency()
            
            return ApplePencilInputResult.StrokeAnalysis(
                strokeCount: strokeCount,
                averageStrokeLength: averageStrokeLength,
                averageStrokeDuration: averageStrokeDuration,
                averagePressure: averagePressure,
                pressureVariation: pressureVariation,
                tiltVariation: tiltVariation,
                speedVariation: speedVariation,
                smoothnessScore: smoothnessScore,
                precisionScore: precisionScore,
                consistencyScore: consistencyScore
            )
        }
        
        func addStroke(_ stroke: ApplePencilInputResult.ProcessedPencilInput.StrokeInfo) {
            strokeHistory.append(stroke)
            if strokeHistory.count > 100 {
                strokeHistory.removeFirst()
            }
        }
        
        private func calculateVariation(_ values: [Float]) -> Float {
            guard values.count > 1 else { return 0 }
            let mean = values.reduce(0, +) / Float(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
            return sqrt(variance)
        }
        
        private func calculateSmoothness() -> Float {
            return 0.85 // Simplified calculation
        }
        
        private func calculatePrecision() -> Float {
            return 0.9 // Simplified calculation
        }
        
        private func calculateConsistency() -> Float {
            return 0.8 // Simplified calculation
        }
    }
    
    private class PencilInputTracker {
        private var sessionStartTime: Date = Date()
        private var inputCount: Int = 0
        private var gestureCount: Int = 0
        private var totalLatency: TimeInterval = 0
        private var pressureValues: [Float] = []
        private var tiltValues: [Float] = []
        private var velocityValues: [Float] = []
        
        func trackInput(_ pencilData: ApplePencilInputEvent.PencilData, latency: TimeInterval, gestures: [ApplePencilInputResult.RecognizedPencilGesture]) {
            inputCount += 1
            gestureCount += gestures.count
            totalLatency += latency
            
            pressureValues.append(pencilData.pressure)
            tiltValues.append(pencilData.altitudeAngle)
            
            if pressureValues.count > 1000 {
                pressureValues.removeFirst()
                tiltValues.removeFirst()
            }
        }
        
        func calculateMetrics() -> ApplePencilInputResult.PencilInputMetrics {
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            let inputsPerSecond = sessionDuration > 0 ? Double(inputCount) / sessionDuration : 0
            let averageLatency = inputCount > 0 ? totalLatency / Double(inputCount) : 0
            
            let pressureRange = pressureValues.isEmpty ? 0.0...1.0 : pressureValues.min()!...pressureValues.max()!
            let tiltRange = tiltValues.isEmpty ? 0.0...1.57 : tiltValues.min()!...tiltValues.max()!
            let velocityRange: ClosedRange<Float> = 0.0...100.0
            
            return ApplePencilInputResult.PencilInputMetrics(
                totalInputs: inputCount,
                inputsPerSecond: inputsPerSecond,
                averageLatency: averageLatency,
                pressureRange: pressureRange,
                tiltRange: tiltRange,
                velocityRange: velocityRange,
                accuracy: 0.95,
                responsiveness: 0.92,
                batteryUsage: 0.15
            )
        }
        
        func reset() {
            sessionStartTime = Date()
            inputCount = 0
            gestureCount = 0
            totalLatency = 0
            pressureValues.removeAll()
            tiltValues.removeAll()
            velocityValues.removeAll()
        }
    }
    
    public init(configuration: ApplePencilCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 200_000_000, // 200MB for Apple Pencil processing
            cpu: 3.0, // High CPU usage for real-time input processing
            bandwidth: 0,
            storage: 60_000_000 // 60MB for stroke data and result caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let eventMemory = activeEvents.count * 8_000_000 // ~8MB per active event
            let cacheMemory = resultCache.count * 40_000 // ~40KB per cached result
            let historyMemory = eventHistory.count * 25_000
            let processingMemory = 50_000_000 // Pencil processing overhead
            
            return ResourceUsage(
                memory: eventMemory + cacheMemory + historyMemory + processingMemory,
                cpu: activeEvents.isEmpty ? 0.3 : 2.5,
                bandwidth: 0,
                storage: resultCache.count * 20_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Apple Pencil support is available on compatible devices with iOS 9.1+
        if #available(iOS 9.1, *) {
            return configuration.enableApplePencilSupport
        }
        return false
    }
    
    public func release() async {
        activeEvents.removeAll()
        eventHistory.removeAll()
        resultCache.removeAll()
        inputTracker.reset()
        
        resultStreamContinuation?.finish()
        
        metrics = ApplePencilCapabilityMetrics()
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        pencilManager = PencilManager()
        inputProcessor = PencilInputProcessor()
        gestureRecognizer = PencilGestureRecognizer()
        strokeAnalyzer = StrokeAnalyzer()
        inputTracker = PencilInputTracker()
        
        pencilManager.setupPencilSupport()
        
        if configuration.enableLogging {
            print("[ApplePencil] 🚀 Apple Pencil capability initialized")
            print("[ApplePencil] ✏️ Generation: \(configuration.pencilGeneration.rawValue)")
        }
    }
    
    internal func updateConfiguration(_ configuration: ApplePencilCapabilityConfiguration) async throws {
        // Update Apple Pencil configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<ApplePencilInputResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Apple Pencil Processing
    
    public func processInput(_ event: ApplePencilInputEvent) async throws -> ApplePencilInputResult {
        guard configuration.enableApplePencilSupport else {
            throw ApplePencilError.applePencilDisabled
        }
        
        let startTime = Date()
        activeEvents[event.id] = event
        
        do {
            // Process pencil input
            let processedInput = inputProcessor.processPencilInput(event.pencilData, configuration: configuration)
            
            // Recognize gestures if enabled
            var recognizedGestures: [ApplePencilInputResult.RecognizedPencilGesture] = []
            if configuration.enablePencilGestures {
                recognizedGestures = gestureRecognizer.recognizeGestures(from: event.pencilData)
            }
            
            // Analyze strokes
            if let strokeInfo = processedInput.strokeInfo {
                strokeAnalyzer.addStroke(strokeInfo)
            }
            let strokeAnalysis = strokeAnalyzer.analyzeStrokes()
            
            // Track input for metrics
            inputTracker.trackInput(event.pencilData, latency: processedInput.velocityVector.dx, gestures: recognizedGestures)
            let inputMetrics = inputTracker.calculateMetrics()
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ApplePencilInputResult(
                eventId: event.id,
                processedInput: processedInput,
                recognizedGestures: recognizedGestures,
                strokeAnalysis: strokeAnalysis,
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
                await logPencilEvent(result)
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = ApplePencilInputResult(
                eventId: event.id,
                processedInput: ApplePencilInputResult.ProcessedPencilInput(
                    originalEvent: event.pencilData,
                    normalizedLocation: .zero,
                    adjustedPressure: 0,
                    calibratedTilt: 0,
                    calibratedAzimuth: 0,
                    smoothedMotion: .zero,
                    velocityVector: .zero,
                    accelerationVector: .zero,
                    inputMode: .drawing
                ),
                recognizedGestures: [],
                strokeAnalysis: ApplePencilInputResult.StrokeAnalysis(
                    strokeCount: 0,
                    averageStrokeLength: 0,
                    averageStrokeDuration: 0,
                    averagePressure: 0,
                    pressureVariation: 0,
                    tiltVariation: 0,
                    speedVariation: 0,
                    smoothnessScore: 0,
                    precisionScore: 0,
                    consistencyScore: 0
                ),
                inputMetrics: ApplePencilInputResult.PencilInputMetrics(
                    totalInputs: 0,
                    inputsPerSecond: 0,
                    averageLatency: 0,
                    pressureRange: 0.0...1.0,
                    tiltRange: 0.0...1.57,
                    velocityRange: 0.0...100.0,
                    accuracy: 0,
                    responsiveness: 0,
                    batteryUsage: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? ApplePencilError ?? ApplePencilError.processingError(error.localizedDescription)
            )
            
            activeEvents.removeValue(forKey: event.id)
            eventHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logPencilEvent(result)
            }
            
            throw error
        }
    }
    
    public func getActiveEvents() async -> [ApplePencilInputEvent] {
        return Array(activeEvents.values)
    }
    
    public func getEventHistory(since: Date? = nil) async -> [ApplePencilInputResult] {
        if let since = since {
            return eventHistory.filter { $0.timestamp >= since }
        }
        return eventHistory
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> ApplePencilCapabilityMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = ApplePencilCapabilityMetrics()
        inputTracker.reset()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for event: ApplePencilInputEvent) -> String {
        let eventType = event.pencilData.eventType.rawValue
        let pressure = Int(event.pencilData.pressure * 100)
        let location = "\(Int(event.pencilData.location.x))_\(Int(event.pencilData.location.y))"
        let timestamp = Int(event.timestamp.timeIntervalSince1970 * 1000)
        return "\(eventType)_\(pressure)_\(location)_\(timestamp)"
    }
    
    private func updateSuccessMetrics(_ result: ApplePencilInputResult) async {
        let totalEvents = metrics.totalInputEvents + 1
        let successfulEvents = metrics.successfulEvents + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalInputEvents)) + result.processingTime) / Double(totalEvents)
        
        var eventsByType = metrics.eventsByType
        eventsByType[result.processedInput.originalEvent.eventType.rawValue, default: 0] += 1
        
        var gesturesByType = metrics.gesturesByType
        for gesture in result.recognizedGestures {
            gesturesByType[gesture.gestureType.rawValue, default: 0] += 1
        }
        
        var inputsByMode = metrics.inputsByMode
        inputsByMode[result.processedInput.inputMode.rawValue, default: 0] += 1
        
        let newAverageEventsPerSession = ((metrics.averageEventsPerSession * Double(metrics.successfulEvents)) + Double(result.inputMetrics.totalInputs)) / Double(successfulEvents)
        let newAverageGesturesPerSession = ((metrics.averageGesturesPerSession * Double(metrics.successfulEvents)) + Double(result.gestureCount)) / Double(successfulEvents)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulEvents == 0 ? result.processingTime : min(performanceStats.bestProcessingTime, result.processingTime)
        let worstTime = max(performanceStats.worstProcessingTime, result.processingTime)
        let newAverageStrokesPerSession = ((performanceStats.averageStrokesPerSession * Double(metrics.successfulEvents)) + Double(result.strokeAnalysis.strokeCount)) / Double(successfulEvents)
        let newAveragePressureSensitivity = ((performanceStats.averagePressureSensitivity * Float(metrics.successfulEvents)) + result.strokeAnalysis.averagePressure) / Float(successfulEvents)
        let newAverageTiltSensitivity = ((performanceStats.averageTiltSensitivity * Float(metrics.successfulEvents)) + result.processedInput.calibratedTilt) / Float(successfulEvents)
        let totalGestures = performanceStats.totalGestures + result.inputMetrics.totalInputs
        let newInputAccuracy = ((performanceStats.inputAccuracy * Double(metrics.successfulEvents)) + result.inputMetrics.accuracy) / Double(successfulEvents)
        
        performanceStats = ApplePencilCapabilityMetrics.PerformanceStats(
            bestProcessingTime: bestTime,
            worstProcessingTime: worstTime,
            averageStrokesPerSession: newAverageStrokesPerSession,
            averagePressureSensitivity: newAveragePressureSensitivity,
            averageTiltSensitivity: newAverageTiltSensitivity,
            totalGestures: totalGestures,
            inputAccuracy: newInputAccuracy,
            pencilReliability: performanceStats.pencilReliability,
            batteryEfficiency: performanceStats.batteryEfficiency
        )
        
        metrics = ApplePencilCapabilityMetrics(
            totalInputEvents: totalEvents,
            successfulEvents: successfulEvents,
            failedEvents: metrics.failedEvents,
            averageProcessingTime: newAverageProcessingTime,
            eventsByType: eventsByType,
            gesturesByType: gesturesByType,
            inputsByMode: inputsByMode,
            errorsByType: metrics.errorsByType,
            averageLatency: result.inputMetrics.averageLatency,
            averageEventsPerSession: newAverageEventsPerSession,
            averageGesturesPerSession: newAverageGesturesPerSession,
            pencilsConnected: pencilManager.isPencilConnected() ? 1 : 0,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: ApplePencilInputResult) async {
        let totalEvents = metrics.totalInputEvents + 1
        let failedEvents = metrics.failedEvents + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = ApplePencilCapabilityMetrics(
            totalInputEvents: totalEvents,
            successfulEvents: metrics.successfulEvents,
            failedEvents: failedEvents,
            averageProcessingTime: metrics.averageProcessingTime,
            eventsByType: metrics.eventsByType,
            gesturesByType: metrics.gesturesByType,
            inputsByMode: metrics.inputsByMode,
            errorsByType: errorsByType,
            averageLatency: metrics.averageLatency,
            averageEventsPerSession: metrics.averageEventsPerSession,
            averageGesturesPerSession: metrics.averageGesturesPerSession,
            pencilsConnected: metrics.pencilsConnected,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logPencilEvent(_ result: ApplePencilInputResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let eventType = result.processedInput.originalEvent.eventType.rawValue
        let pressure = String(format: "%.2f", result.processedInput.adjustedPressure)
        let gestureCount = result.gestureCount
        let qualityStr = String(format: "%.1f", result.qualityScore * 100)
        
        print("[ApplePencil] \(statusIcon) Event: \(eventType), \(pressure) pressure, \(gestureCount) gestures, \(qualityStr)% quality (\(timeStr)s)")
        
        if let error = result.error {
            print("[ApplePencil] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// Extension for UIPencilInteractionDelegate
@available(iOS 12.1, *)
extension ApplePencilCapabilityResource.PencilManager: UIPencilInteractionDelegate {
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        // Handle pencil double-tap
    }
}

// MARK: - Apple Pencil Capability Implementation

/// Apple Pencil capability providing comprehensive Apple Pencil support
@available(iOS 13.0, macOS 10.15, *)
public actor ApplePencilCapability: DomainCapability {
    public typealias ConfigurationType = ApplePencilCapabilityConfiguration
    public typealias ResourceType = ApplePencilCapabilityResource
    
    private var _configuration: ApplePencilCapabilityConfiguration
    private var _resources: ApplePencilCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(10)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "apple-pencil-capability" }
    
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
    
    public var configuration: ApplePencilCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: ApplePencilCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: ApplePencilCapabilityConfiguration = ApplePencilCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = ApplePencilCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: ApplePencilCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Apple Pencil configuration")
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
        // Apple Pencil is supported on compatible iPads with iOS 9.1+
        if #available(iOS 9.1, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Apple Pencil doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Apple Pencil Operations
    
    /// Process Apple Pencil input event
    public func processInput(_ event: ApplePencilInputEvent) async throws -> ApplePencilInputResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        return try await _resources.processInput(event)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<ApplePencilInputResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active events
    public func getActiveEvents() async throws -> [ApplePencilInputEvent] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        return await _resources.getActiveEvents()
    }
    
    /// Get event history
    public func getEventHistory(since: Date? = nil) async throws -> [ApplePencilInputResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        return await _resources.getEventHistory(since: since)
    }
    
    /// Get metrics
    public func getMetrics() async throws -> ApplePencilCapabilityMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Apple Pencil capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create drawing event
    public func createDrawingEvent(
        at location: CGPoint,
        pressure: Float = 0.5,
        tilt: Float = 0.0,
        azimuth: Float = 0.0
    ) -> ApplePencilInputEvent {
        let pencilInfo = ApplePencilInputEvent.PencilData.PencilInfo(
            pencilType: .applePencil2,
            generation: .secondGeneration
        )
        
        let pencilData = ApplePencilInputEvent.PencilData(
            eventType: .moved,
            location: location,
            pressure: pressure,
            altitudeAngle: tilt,
            azimuthAngle: azimuth,
            pencilInfo: pencilInfo,
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        return ApplePencilInputEvent(pencilData: pencilData)
    }
    
    /// Create gesture event
    public func createGestureEvent(
        gestureType: ApplePencilInputEvent.PencilData.PencilEventType,
        at location: CGPoint = .zero
    ) -> ApplePencilInputEvent {
        let pencilInfo = ApplePencilInputEvent.PencilData.PencilInfo(
            pencilType: .applePencil2,
            generation: .secondGeneration,
            supportsDoubleTap: true
        )
        
        let pencilData = ApplePencilInputEvent.PencilData(
            eventType: gestureType,
            location: location,
            pencilInfo: pencilInfo,
            timestamp: Date().timeIntervalSinceReferenceDate
        )
        
        return ApplePencilInputEvent(pencilData: pencilData)
    }
    
    /// Check if Apple Pencil is connected
    public func isPencilConnected() async throws -> Bool {
        let activeEvents = try await getActiveEvents()
        return activeEvents.contains { $0.pencilData.pencilInfo.isConnected }
    }
    
    /// Get pencil battery level
    public func getPencilBatteryLevel() async throws -> Float? {
        let activeEvents = try await getActiveEvents()
        return activeEvents.first?.pencilData.pencilInfo.batteryLevel
    }
    
    /// Get supported pencil generation
    public func getSupportedPencilGeneration() async -> ApplePencilCapabilityConfiguration.PencilGeneration {
        let config = await configuration
        return config.pencilGeneration
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Apple Pencil specific errors
public enum ApplePencilError: Error, LocalizedError {
    case applePencilDisabled
    case pencilNotConnected
    case processingError(String)
    case gestureRecognitionFailed
    case strokeAnalysisFailed
    case unsupportedPencilGeneration
    case pressureCalibrationFailed
    case tiltCalibrationFailed
    case inputTimeout(UUID)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .applePencilDisabled:
            return "Apple Pencil support is disabled"
        case .pencilNotConnected:
            return "Apple Pencil is not connected"
        case .processingError(let reason):
            return "Apple Pencil processing failed: \(reason)"
        case .gestureRecognitionFailed:
            return "Gesture recognition failed"
        case .strokeAnalysisFailed:
            return "Stroke analysis failed"
        case .unsupportedPencilGeneration:
            return "Unsupported Apple Pencil generation"
        case .pressureCalibrationFailed:
            return "Pressure calibration failed"
        case .tiltCalibrationFailed:
            return "Tilt calibration failed"
        case .inputTimeout(let id):
            return "Input timeout: \(id)"
        case .configurationError(let reason):
            return "Apple Pencil configuration error: \(reason)"
        }
    }
}