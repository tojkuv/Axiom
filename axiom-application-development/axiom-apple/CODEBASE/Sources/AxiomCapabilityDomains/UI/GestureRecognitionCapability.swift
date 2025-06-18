import Foundation
import UIKit
import CoreGraphics
import CoreML
import CreateML
import AxiomCore
import AxiomCapabilities

// MARK: - Gesture Recognition Capability Configuration

/// Configuration for Gesture Recognition capability
public struct GestureRecognitionCapabilityConfiguration: AxiomCapabilityConfiguration, Codable {
    public let enableGestureRecognition: Bool
    public let enableCustomGestures: Bool
    public let enableGestureLearning: Bool
    public let enableRealTimeRecognition: Bool
    public let enableMultiTouchGestures: Bool
    public let enableCrossDeviceGestures: Bool
    public let maxConcurrentGestures: Int
    public let recognitionTimeout: TimeInterval
    public let minimumConfidence: Float
    public let maximumGestureLength: TimeInterval
    public let enableLogging: Bool
    public let enableMetrics: Bool
    public let enableCaching: Bool
    public let cacheSize: Int
    public let recognitionSensitivity: RecognitionSensitivity
    public let gestureComplexity: GestureComplexity
    public let learningMode: LearningMode
    public let recognitionEngine: RecognitionEngine
    
    public enum RecognitionSensitivity: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case adaptive = "adaptive"
    }
    
    public enum GestureComplexity: String, Codable, CaseIterable {
        case simple = "simple"
        case moderate = "moderate"
        case complex = "complex"
        case advanced = "advanced"
    }
    
    public enum LearningMode: String, Codable, CaseIterable {
        case disabled = "disabled"
        case supervised = "supervised"
        case unsupervised = "unsupervised"
        case reinforcement = "reinforcement"
    }
    
    public enum RecognitionEngine: String, Codable, CaseIterable {
        case traditional = "traditional"
        case neuralNetwork = "neuralNetwork"
        case hybrid = "hybrid"
    }
    
    public init(
        enableGestureRecognition: Bool = true,
        enableCustomGestures: Bool = true,
        enableGestureLearning: Bool = true,
        enableRealTimeRecognition: Bool = true,
        enableMultiTouchGestures: Bool = true,
        enableCrossDeviceGestures: Bool = false,
        maxConcurrentGestures: Int = 10,
        recognitionTimeout: TimeInterval = 5.0,
        minimumConfidence: Float = 0.7,
        maximumGestureLength: TimeInterval = 10.0,
        enableLogging: Bool = false,
        enableMetrics: Bool = true,
        enableCaching: Bool = true,
        cacheSize: Int = 200,
        recognitionSensitivity: RecognitionSensitivity = .medium,
        gestureComplexity: GestureComplexity = .moderate,
        learningMode: LearningMode = .supervised,
        recognitionEngine: RecognitionEngine = .hybrid
    ) {
        self.enableGestureRecognition = enableGestureRecognition
        self.enableCustomGestures = enableCustomGestures
        self.enableGestureLearning = enableGestureLearning
        self.enableRealTimeRecognition = enableRealTimeRecognition
        self.enableMultiTouchGestures = enableMultiTouchGestures
        self.enableCrossDeviceGestures = enableCrossDeviceGestures
        self.maxConcurrentGestures = maxConcurrentGestures
        self.recognitionTimeout = recognitionTimeout
        self.minimumConfidence = minimumConfidence
        self.maximumGestureLength = maximumGestureLength
        self.enableLogging = enableLogging
        self.enableMetrics = enableMetrics
        self.enableCaching = enableCaching
        self.cacheSize = cacheSize
        self.recognitionSensitivity = recognitionSensitivity
        self.gestureComplexity = gestureComplexity
        self.learningMode = learningMode
        self.recognitionEngine = recognitionEngine
    }
    
    public var isValid: Bool {
        maxConcurrentGestures > 0 &&
        recognitionTimeout > 0 &&
        minimumConfidence >= 0.0 && minimumConfidence <= 1.0 &&
        maximumGestureLength > 0 &&
        cacheSize >= 0
    }
    
    public func merged(with other: GestureRecognitionCapabilityConfiguration) -> GestureRecognitionCapabilityConfiguration {
        GestureRecognitionCapabilityConfiguration(
            enableGestureRecognition: other.enableGestureRecognition,
            enableCustomGestures: other.enableCustomGestures,
            enableGestureLearning: other.enableGestureLearning,
            enableRealTimeRecognition: other.enableRealTimeRecognition,
            enableMultiTouchGestures: other.enableMultiTouchGestures,
            enableCrossDeviceGestures: other.enableCrossDeviceGestures,
            maxConcurrentGestures: other.maxConcurrentGestures,
            recognitionTimeout: other.recognitionTimeout,
            minimumConfidence: other.minimumConfidence,
            maximumGestureLength: other.maximumGestureLength,
            enableLogging: other.enableLogging,
            enableMetrics: other.enableMetrics,
            enableCaching: other.enableCaching,
            cacheSize: other.cacheSize,
            recognitionSensitivity: other.recognitionSensitivity,
            gestureComplexity: other.gestureComplexity,
            learningMode: other.learningMode,
            recognitionEngine: other.recognitionEngine
        )
    }
    
    public func adjusted(for environment: AxiomCapabilityEnvironment) -> GestureRecognitionCapabilityConfiguration {
        var adjustedTimeout = recognitionTimeout
        var adjustedLogging = enableLogging
        var adjustedConcurrentGestures = maxConcurrentGestures
        var adjustedCacheSize = cacheSize
        var adjustedSensitivity = recognitionSensitivity
        var adjustedComplexity = gestureComplexity
        var adjustedLearning = enableGestureLearning
        
        if environment.isLowPowerMode {
            adjustedTimeout = min(recognitionTimeout, 2.0)
            adjustedConcurrentGestures = min(maxConcurrentGestures, 3)
            adjustedCacheSize = min(cacheSize, 50)
            adjustedSensitivity = .low
            adjustedComplexity = .simple
            adjustedLearning = false
        }
        
        if environment.isDebug {
            adjustedLogging = true
        }
        
        return GestureRecognitionCapabilityConfiguration(
            enableGestureRecognition: enableGestureRecognition,
            enableCustomGestures: enableCustomGestures,
            enableGestureLearning: adjustedLearning,
            enableRealTimeRecognition: enableRealTimeRecognition,
            enableMultiTouchGestures: enableMultiTouchGestures,
            enableCrossDeviceGestures: enableCrossDeviceGestures,
            maxConcurrentGestures: adjustedConcurrentGestures,
            recognitionTimeout: adjustedTimeout,
            minimumConfidence: minimumConfidence,
            maximumGestureLength: maximumGestureLength,
            enableLogging: adjustedLogging,
            enableMetrics: enableMetrics,
            enableCaching: enableCaching,
            cacheSize: adjustedCacheSize,
            recognitionSensitivity: adjustedSensitivity,
            gestureComplexity: adjustedComplexity,
            learningMode: learningMode,
            recognitionEngine: recognitionEngine
        )
    }
}

// MARK: - Gesture Recognition Types

/// Gesture recognition request
public struct GestureRecognitionRequest: Sendable, Identifiable {
    public let id: UUID
    public let gestureData: GestureData
    public let options: RecognitionOptions
    public let priority: Priority
    public let metadata: [String: String]
    
    public struct GestureData: Sendable {
        public let touchPoints: [TouchPoint]
        public let timeSequence: [TimeInterval]
        public let pressure: [Float]
        public let velocity: [CGPoint]
        public let acceleration: [CGPoint]
        public let deviceOrientation: DeviceOrientation
        public let screenSize: CGSize
        public let activeTouches: Int
        public let gestureStartTime: Date
        public let gestureEndTime: Date?
        
        public struct TouchPoint: Sendable {
            public let location: CGPoint
            public let timestamp: TimeInterval
            public let touchId: Int
            public let phase: TouchPhase
            public let force: Float
            public let radius: CGFloat
            public let angle: Float
            
            public enum TouchPhase: String, Sendable, CaseIterable {
                case began = "began"
                case moved = "moved"
                case ended = "ended"
                case cancelled = "cancelled"
                case stationary = "stationary"
            }
            
            public init(location: CGPoint, timestamp: TimeInterval, touchId: Int, phase: TouchPhase, force: Float = 1.0, radius: CGFloat = 10.0, angle: Float = 0.0) {
                self.location = location
                self.timestamp = timestamp
                self.touchId = touchId
                self.phase = phase
                self.force = force
                self.radius = radius
                self.angle = angle
            }
        }
        
        public enum DeviceOrientation: String, Sendable, CaseIterable {
            case portrait = "portrait"
            case portraitUpsideDown = "portraitUpsideDown"
            case landscapeLeft = "landscapeLeft"
            case landscapeRight = "landscapeRight"
            case faceUp = "faceUp"
            case faceDown = "faceDown"
            case unknown = "unknown"
        }
        
        public init(touchPoints: [TouchPoint], timeSequence: [TimeInterval], pressure: [Float], velocity: [CGPoint], acceleration: [CGPoint], deviceOrientation: DeviceOrientation, screenSize: CGSize, activeTouches: Int, gestureStartTime: Date, gestureEndTime: Date? = nil) {
            self.touchPoints = touchPoints
            self.timeSequence = timeSequence
            self.pressure = pressure
            self.velocity = velocity
            self.acceleration = acceleration
            self.deviceOrientation = deviceOrientation
            self.screenSize = screenSize
            self.activeTouches = activeTouches
            self.gestureStartTime = gestureStartTime
            self.gestureEndTime = gestureEndTime
        }
    }
    
    public struct RecognitionOptions: Sendable {
        public let recognitionMode: RecognitionMode
        public let enableLearning: Bool
        public let customGestureLibrary: [String]
        public let minimumConfidence: Float
        public let maxRecognitionTime: TimeInterval
        public let enableContinuousRecognition: Bool
        public let gestureCategories: [GestureCategory]
        public let recognitionEngine: GestureRecognitionCapabilityConfiguration.RecognitionEngine
        
        public enum RecognitionMode: String, Sendable, CaseIterable {
            case single = "single"
            case multiple = "multiple"
            case sequential = "sequential"
            case simultaneous = "simultaneous"
        }
        
        public enum GestureCategory: String, Sendable, CaseIterable {
            case basic = "basic"
            case drawing = "drawing"
            case navigation = "navigation"
            case manipulation = "manipulation"
            case symbolic = "symbolic"
            case multiTouch = "multiTouch"
            case custom = "custom"
        }
        
        public init(recognitionMode: RecognitionMode = .single, enableLearning: Bool = true, customGestureLibrary: [String] = [], minimumConfidence: Float = 0.7, maxRecognitionTime: TimeInterval = 5.0, enableContinuousRecognition: Bool = true, gestureCategories: [GestureCategory] = [.basic, .navigation], recognitionEngine: GestureRecognitionCapabilityConfiguration.RecognitionEngine = .hybrid) {
            self.recognitionMode = recognitionMode
            self.enableLearning = enableLearning
            self.customGestureLibrary = customGestureLibrary
            self.minimumConfidence = minimumConfidence
            self.maxRecognitionTime = maxRecognitionTime
            self.enableContinuousRecognition = enableContinuousRecognition
            self.gestureCategories = gestureCategories
            self.recognitionEngine = recognitionEngine
        }
    }
    
    public enum Priority: String, Sendable, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case critical = "critical"
    }
    
    public init(gestureData: GestureData, options: RecognitionOptions = RecognitionOptions(), priority: Priority = .normal, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.gestureData = gestureData
        self.options = options
        self.priority = priority
        self.metadata = metadata
    }
}

/// Gesture recognition result
public struct GestureRecognitionResult: Sendable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let recognizedGestures: [RecognizedGesture]
    public let gestureAnalysis: GestureAnalysis
    public let learningFeedback: LearningFeedback?
    public let processingTime: TimeInterval
    public let success: Bool
    public let error: GestureRecognitionError?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public struct RecognizedGesture: Sendable, Identifiable {
        public let id: UUID
        public let gestureName: String
        public let gestureType: GestureType
        public let confidence: Float
        public let boundingBox: CGRect
        public let touchPoints: [CGPoint]
        public let gestureParameters: [String: Double]
        public let duration: TimeInterval
        public let recognitionMethod: RecognitionMethod
        public let similarity: Float
        
        public enum GestureType: String, Sendable, CaseIterable {
            case tap = "tap"
            case doubleTap = "doubleTap"
            case longPress = "longPress"
            case swipe = "swipe"
            case pinch = "pinch"
            case rotation = "rotation"
            case pan = "pan"
            case circle = "circle"
            case line = "line"
            case zigzag = "zigzag"
            case heart = "heart"
            case star = "star"
            case letter = "letter"
            case number = "number"
            case symbol = "symbol"
            case signature = "signature"
            case multiTouchGesture = "multiTouchGesture"
            case customGesture = "customGesture"
        }
        
        public enum RecognitionMethod: String, Sendable, CaseIterable {
            case templateMatching = "templateMatching"
            case neuralNetwork = "neuralNetwork"
            case geometricAnalysis = "geometricAnalysis"
            case statisticalAnalysis = "statisticalAnalysis"
            case hybridApproach = "hybridApproach"
        }
        
        public init(gestureName: String, gestureType: GestureType, confidence: Float, boundingBox: CGRect, touchPoints: [CGPoint], gestureParameters: [String: Double], duration: TimeInterval, recognitionMethod: RecognitionMethod, similarity: Float) {
            self.id = UUID()
            self.gestureName = gestureName
            self.gestureType = gestureType
            self.confidence = confidence
            self.boundingBox = boundingBox
            self.touchPoints = touchPoints
            self.gestureParameters = gestureParameters
            self.duration = duration
            self.recognitionMethod = recognitionMethod
            self.similarity = similarity
        }
    }
    
    public struct GestureAnalysis: Sendable {
        public let gestureComplexity: Double
        public let smoothness: Double
        public let consistency: Double
        public let speed: Double
        public let pressure: Double
        public let directionality: Double
        public let symmetry: Double
        public let pathLength: CGFloat
        public let averageVelocity: CGFloat
        public let peakVelocity: CGFloat
        public let acceleration: CGFloat
        public let jerk: CGFloat
        
        public init(gestureComplexity: Double, smoothness: Double, consistency: Double, speed: Double, pressure: Double, directionality: Double, symmetry: Double, pathLength: CGFloat, averageVelocity: CGFloat, peakVelocity: CGFloat, acceleration: CGFloat, jerk: CGFloat) {
            self.gestureComplexity = gestureComplexity
            self.smoothness = smoothness
            self.consistency = consistency
            self.speed = speed
            self.pressure = pressure
            self.directionality = directionality
            self.symmetry = symmetry
            self.pathLength = pathLength
            self.averageVelocity = averageVelocity
            self.peakVelocity = peakVelocity
            self.acceleration = acceleration
            self.jerk = jerk
        }
    }
    
    public struct LearningFeedback: Sendable {
        public let learningAccuracy: Double
        public let modelConfidence: Double
        public let trainingProgress: Double
        public let recognitionImprovement: Double
        public let suggestedAdjustments: [String]
        public let learningRecommendations: [String]
        
        public init(learningAccuracy: Double, modelConfidence: Double, trainingProgress: Double, recognitionImprovement: Double, suggestedAdjustments: [String], learningRecommendations: [String]) {
            self.learningAccuracy = learningAccuracy
            self.modelConfidence = modelConfidence
            self.trainingProgress = trainingProgress
            self.recognitionImprovement = recognitionImprovement
            self.suggestedAdjustments = suggestedAdjustments
            self.learningRecommendations = learningRecommendations
        }
    }
    
    public init(requestId: UUID, recognizedGestures: [RecognizedGesture], gestureAnalysis: GestureAnalysis, learningFeedback: LearningFeedback? = nil, processingTime: TimeInterval, success: Bool, error: GestureRecognitionError? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.requestId = requestId
        self.recognizedGestures = recognizedGestures
        self.gestureAnalysis = gestureAnalysis
        self.learningFeedback = learningFeedback
        self.processingTime = processingTime
        self.success = success
        self.error = error
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    public var bestGesture: RecognizedGesture? {
        recognizedGestures.max(by: { $0.confidence < $1.confidence })
    }
    
    public var averageConfidence: Float {
        guard !recognizedGestures.isEmpty else { return 0.0 }
        return recognizedGestures.reduce(0) { $0 + $1.confidence } / Float(recognizedGestures.count)
    }
    
    public func gestures(withMinimumConfidence confidence: Float) -> [RecognizedGesture] {
        recognizedGestures.filter { $0.confidence >= confidence }
    }
}

/// Gesture recognition metrics
public struct GestureRecognitionMetrics: Sendable {
    public let totalRecognitions: Int
    public let successfulRecognitions: Int
    public let failedRecognitions: Int
    public let averageProcessingTime: TimeInterval
    public let recognitionsByType: [String: Int]
    public let recognitionsByMethod: [String: Int]
    public let errorsByType: [String: Int]
    public let averageConfidence: Double
    public let learningAccuracy: Double
    public let modelPerformance: Double
    public let throughputPerSecond: Double
    public let performanceStats: PerformanceStats
    
    public struct PerformanceStats: Sendable {
        public let bestRecognitionTime: TimeInterval
        public let worstRecognitionTime: TimeInterval
        public let averageGesturesPerRequest: Double
        public let averageComplexity: Double
        public let learningProgressRate: Double
        public let modelAccuracyImprovement: Double
        public let totalCustomGestures: Int
        public let activeGestureLibraries: Int
        
        public init(bestRecognitionTime: TimeInterval = 0, worstRecognitionTime: TimeInterval = 0, averageGesturesPerRequest: Double = 0, averageComplexity: Double = 0, learningProgressRate: Double = 0, modelAccuracyImprovement: Double = 0, totalCustomGestures: Int = 0, activeGestureLibraries: Int = 0) {
            self.bestRecognitionTime = bestRecognitionTime
            self.worstRecognitionTime = worstRecognitionTime
            self.averageGesturesPerRequest = averageGesturesPerRequest
            self.averageComplexity = averageComplexity
            self.learningProgressRate = learningProgressRate
            self.modelAccuracyImprovement = modelAccuracyImprovement
            self.totalCustomGestures = totalCustomGestures
            self.activeGestureLibraries = activeGestureLibraries
        }
    }
    
    public init(totalRecognitions: Int = 0, successfulRecognitions: Int = 0, failedRecognitions: Int = 0, averageProcessingTime: TimeInterval = 0, recognitionsByType: [String: Int] = [:], recognitionsByMethod: [String: Int] = [:], errorsByType: [String: Int] = [:], averageConfidence: Double = 0, learningAccuracy: Double = 0, modelPerformance: Double = 0, throughputPerSecond: Double = 0, performanceStats: PerformanceStats = PerformanceStats()) {
        self.totalRecognitions = totalRecognitions
        self.successfulRecognitions = successfulRecognitions
        self.failedRecognitions = failedRecognitions
        self.averageProcessingTime = averageProcessingTime
        self.recognitionsByType = recognitionsByType
        self.recognitionsByMethod = recognitionsByMethod
        self.errorsByType = errorsByType
        self.averageConfidence = averageConfidence
        self.learningAccuracy = learningAccuracy
        self.modelPerformance = modelPerformance
        self.throughputPerSecond = averageProcessingTime > 0 ? Double(totalRecognitions) / averageProcessingTime : 0
        self.performanceStats = performanceStats
    }
    
    public var successRate: Double {
        totalRecognitions > 0 ? Double(successfulRecognitions) / Double(totalRecognitions) : 0
    }
}

// MARK: - Gesture Recognition Resource

/// Gesture recognition resource management
@available(iOS 13.0, macOS 10.15, *)
public actor GestureRecognitionCapabilityResource: AxiomCapabilityResource {
    private let configuration: GestureRecognitionCapabilityConfiguration
    private var activeRecognitions: [UUID: GestureRecognitionRequest] = [:]
    private var recognitionQueue: [GestureRecognitionRequest] = []
    private var recognitionHistory: [GestureRecognitionResult] = []
    private var resultCache: [String: GestureRecognitionResult] = [:]
    private var gestureLibrary: [String: GestureTemplate] = [:]
    private var customGestures: [String: GestureTemplate] = [:]
    private var recognitionEngine: GestureRecognitionEngine = GestureRecognitionEngine()
    private var learningModule: GestureLearningModule = GestureLearningModule()
    private var metrics: GestureRecognitionMetrics = GestureRecognitionMetrics()
    private var resultStreamContinuation: AsyncStream<GestureRecognitionResult>.Continuation?
    private var isProcessingQueue: Bool = false
    
    // Helper structures for gesture recognition
    private struct GestureTemplate: Sendable {
        let name: String
        let type: GestureRecognitionResult.RecognizedGesture.GestureType
        let points: [CGPoint]
        let parameters: [String: Double]
        let trainingData: [TrainingExample]
        
        struct TrainingExample: Sendable {
            let touchPoints: [CGPoint]
            let timeSequence: [TimeInterval]
            let metadata: [String: String]
        }
    }
    
    // Helper classes for gesture recognition processing
    private class GestureRecognitionEngine {
        private var templateLibrary: [String: GestureTemplate] = [:]
        
        func recognizeGesture(
            _ gestureData: GestureRecognitionRequest.GestureData,
            options: GestureRecognitionRequest.RecognitionOptions,
            configuration: GestureRecognitionCapabilityConfiguration
        ) -> [GestureRecognitionResult.RecognizedGesture] {
            
            var recognizedGestures: [GestureRecognitionResult.RecognizedGesture] = []
            
            // Basic gesture recognition using geometric analysis
            let touchPoints = gestureData.touchPoints.map { $0.location }
            
            // Recognize basic gestures
            if let basicGesture = recognizeBasicGestures(touchPoints: touchPoints, gestureData: gestureData) {
                recognizedGestures.append(basicGesture)
            }
            
            // Recognize drawing gestures
            if options.gestureCategories.contains(.drawing) {
                if let drawingGesture = recognizeDrawingGestures(touchPoints: touchPoints, gestureData: gestureData) {
                    recognizedGestures.append(drawingGesture)
                }
            }
            
            // Recognize multi-touch gestures
            if configuration.enableMultiTouchGestures && gestureData.activeTouches > 1 {
                if let multiTouchGesture = recognizeMultiTouchGestures(gestureData: gestureData) {
                    recognizedGestures.append(multiTouchGesture)
                }
            }
            
            // Filter by confidence threshold
            return recognizedGestures.filter { $0.confidence >= configuration.minimumConfidence }
        }
        
        private func recognizeBasicGestures(touchPoints: [CGPoint], gestureData: GestureRecognitionRequest.GestureData) -> GestureRecognitionResult.RecognizedGesture? {
            guard !touchPoints.isEmpty else { return nil }
            
            let duration = gestureData.gestureEndTime?.timeIntervalSince(gestureData.gestureStartTime) ?? 0.5
            
            // Single tap detection
            if touchPoints.count == 1 && duration < 0.2 {
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "tap",
                    gestureType: .tap,
                    confidence: 0.9,
                    boundingBox: CGRect(origin: touchPoints[0], size: CGSize(width: 20, height: 20)),
                    touchPoints: touchPoints,
                    gestureParameters: ["duration": duration],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.95
                )
            }
            
            // Long press detection
            if touchPoints.count <= 3 && duration > 0.5 {
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "longPress",
                    gestureType: .longPress,
                    confidence: 0.85,
                    boundingBox: calculateBoundingBox(for: touchPoints),
                    touchPoints: touchPoints,
                    gestureParameters: ["duration": duration],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.9
                )
            }
            
            // Swipe detection
            if touchPoints.count > 3 {
                let startPoint = touchPoints.first!
                let endPoint = touchPoints.last!
                let distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
                
                if distance > 50 && duration < 1.0 {
                    let direction = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
                    return GestureRecognitionResult.RecognizedGesture(
                        gestureName: "swipe",
                        gestureType: .swipe,
                        confidence: 0.8,
                        boundingBox: calculateBoundingBox(for: touchPoints),
                        touchPoints: touchPoints,
                        gestureParameters: ["distance": Double(distance), "direction": Double(direction)],
                        duration: duration,
                        recognitionMethod: .geometricAnalysis,
                        similarity: 0.85
                    )
                }
            }
            
            return nil
        }
        
        private func recognizeDrawingGestures(touchPoints: [CGPoint], gestureData: GestureRecognitionRequest.GestureData) -> GestureRecognitionResult.RecognizedGesture? {
            guard touchPoints.count > 10 else { return nil }
            
            // Circle detection
            if isCircularGesture(touchPoints: touchPoints) {
                let duration = gestureData.gestureEndTime?.timeIntervalSince(gestureData.gestureStartTime) ?? 1.0
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "circle",
                    gestureType: .circle,
                    confidence: 0.7,
                    boundingBox: calculateBoundingBox(for: touchPoints),
                    touchPoints: touchPoints,
                    gestureParameters: ["circularity": 0.8, "radius": Double(calculateRadius(for: touchPoints))],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.75
                )
            }
            
            // Line detection
            if isLinearGesture(touchPoints: touchPoints) {
                let duration = gestureData.gestureEndTime?.timeIntervalSince(gestureData.gestureStartTime) ?? 1.0
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "line",
                    gestureType: .line,
                    confidence: 0.75,
                    boundingBox: calculateBoundingBox(for: touchPoints),
                    touchPoints: touchPoints,
                    gestureParameters: ["straightness": 0.9, "length": Double(calculatePathLength(for: touchPoints))],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.8
                )
            }
            
            return nil
        }
        
        private func recognizeMultiTouchGestures(gestureData: GestureRecognitionRequest.GestureData) -> GestureRecognitionResult.RecognizedGesture? {
            let activeTouches = gestureData.activeTouches
            let duration = gestureData.gestureEndTime?.timeIntervalSince(gestureData.gestureStartTime) ?? 1.0
            
            // Pinch gesture detection
            if activeTouches == 2 {
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "pinch",
                    gestureType: .pinch,
                    confidence: 0.8,
                    boundingBox: calculateBoundingBox(for: gestureData.touchPoints.map { $0.location }),
                    touchPoints: gestureData.touchPoints.map { $0.location },
                    gestureParameters: ["scale": 0.5, "centerX": 160, "centerY": 240],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.85
                )
            }
            
            // Three-finger gesture
            if activeTouches == 3 {
                return GestureRecognitionResult.RecognizedGesture(
                    gestureName: "threeFingerGesture",
                    gestureType: .multiTouchGesture,
                    confidence: 0.75,
                    boundingBox: calculateBoundingBox(for: gestureData.touchPoints.map { $0.location }),
                    touchPoints: gestureData.touchPoints.map { $0.location },
                    gestureParameters: ["fingers": Double(activeTouches)],
                    duration: duration,
                    recognitionMethod: .geometricAnalysis,
                    similarity: 0.8
                )
            }
            
            return nil
        }
        
        private func isCircularGesture(touchPoints: [CGPoint]) -> Bool {
            // Simplified circular gesture detection
            guard touchPoints.count > 20 else { return false }
            
            let center = calculateCenter(for: touchPoints)
            let avgRadius = touchPoints.reduce(0) { sum, point in
                sum + sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
            } / CGFloat(touchPoints.count)
            
            let radiusVariance = touchPoints.reduce(0) { sum, point in
                let radius = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
                return sum + pow(radius - avgRadius, 2)
            } / CGFloat(touchPoints.count)
            
            return radiusVariance < (avgRadius * 0.3)
        }
        
        private func isLinearGesture(touchPoints: [CGPoint]) -> Bool {
            // Simplified linear gesture detection using least squares
            guard touchPoints.count > 5 else { return false }
            
            let n = CGFloat(touchPoints.count)
            let sumX = touchPoints.reduce(0) { $0 + $1.x }
            let sumY = touchPoints.reduce(0) { $0 + $1.y }
            let sumXY = touchPoints.reduce(0) { $0 + ($1.x * $1.y) }
            let sumXX = touchPoints.reduce(0) { $0 + ($1.x * $1.x) }
            
            let slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX)
            let intercept = (sumY - slope * sumX) / n
            
            // Calculate R-squared
            let meanY = sumY / n
            let ssRes = touchPoints.reduce(0) { sum, point in
                let predicted = slope * point.x + intercept
                return sum + pow(point.y - predicted, 2)
            }
            let ssTot = touchPoints.reduce(0) { sum, point in
                sum + pow(point.y - meanY, 2)
            }
            
            let rSquared = 1 - (ssRes / ssTot)
            return rSquared > 0.8 // 80% linearity threshold
        }
        
        private func calculateBoundingBox(for points: [CGPoint]) -> CGRect {
            guard !points.isEmpty else { return .zero }
            
            let minX = points.min(by: { $0.x < $1.x })?.x ?? 0
            let maxX = points.max(by: { $0.x < $1.x })?.x ?? 0
            let minY = points.min(by: { $0.y < $1.y })?.y ?? 0
            let maxY = points.max(by: { $0.y < $1.y })?.y ?? 0
            
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        
        private func calculateCenter(for points: [CGPoint]) -> CGPoint {
            guard !points.isEmpty else { return .zero }
            
            let sumX = points.reduce(0) { $0 + $1.x }
            let sumY = points.reduce(0) { $0 + $1.y }
            
            return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
        }
        
        private func calculateRadius(for points: [CGPoint]) -> CGFloat {
            let center = calculateCenter(for: points)
            let distances = points.map { sqrt(pow($0.x - center.x, 2) + pow($0.y - center.y, 2)) }
            return distances.reduce(0, +) / CGFloat(distances.count)
        }
        
        private func calculatePathLength(for points: [CGPoint]) -> CGFloat {
            guard points.count > 1 else { return 0 }
            
            var length: CGFloat = 0
            for i in 1..<points.count {
                let distance = sqrt(pow(points[i].x - points[i-1].x, 2) + pow(points[i].y - points[i-1].y, 2))
                length += distance
            }
            return length
        }
    }
    
    private class GestureLearningModule {
        private var trainingData: [String: [GestureTemplate.TrainingExample]] = [:]
        private var modelAccuracy: Double = 0.0
        
        func processLearning(
            for gesture: GestureRecognitionResult.RecognizedGesture,
            gestureData: GestureRecognitionRequest.GestureData,
            configuration: GestureRecognitionCapabilityConfiguration
        ) -> GestureRecognitionResult.LearningFeedback? {
            
            guard configuration.enableGestureLearning else { return nil }
            
            // Simulate learning feedback
            let learningAccuracy = min(modelAccuracy + 0.1, 1.0)
            let modelConfidence = Double(gesture.confidence)
            let trainingProgress = 0.75
            let recognitionImprovement = learningAccuracy - modelAccuracy
            
            modelAccuracy = learningAccuracy
            
            let suggestedAdjustments = generateSuggestedAdjustments(for: gesture)
            let learningRecommendations = generateLearningRecommendations(for: gesture)
            
            return GestureRecognitionResult.LearningFeedback(
                learningAccuracy: learningAccuracy,
                modelConfidence: modelConfidence,
                trainingProgress: trainingProgress,
                recognitionImprovement: recognitionImprovement,
                suggestedAdjustments: suggestedAdjustments,
                learningRecommendations: learningRecommendations
            )
        }
        
        private func generateSuggestedAdjustments(for gesture: GestureRecognitionResult.RecognizedGesture) -> [String] {
            var adjustments: [String] = []
            
            if gesture.confidence < 0.8 {
                adjustments.append("Increase gesture consistency")
                adjustments.append("Reduce gesture complexity")
            }
            
            if gesture.duration > 3.0 {
                adjustments.append("Perform gesture more quickly")
            }
            
            return adjustments
        }
        
        private func generateLearningRecommendations(for gesture: GestureRecognitionResult.RecognizedGesture) -> [String] {
            var recommendations: [String] = []
            
            recommendations.append("Practice gesture multiple times")
            recommendations.append("Maintain consistent speed and pressure")
            
            if gesture.gestureType == .customGesture {
                recommendations.append("Provide additional training examples")
            }
            
            return recommendations
        }
    }
    
    public init(configuration: GestureRecognitionCapabilityConfiguration) {
        self.configuration = configuration
    }
    
    public nonisolated var maxUsage: ResourceUsage {
        ResourceUsage(
            memory: 150_000_000, // 150MB for gesture recognition
            cpu: 2.5, // High CPU usage for real-time recognition
            bandwidth: 0,
            storage: 50_000_000 // 50MB for gesture templates and model caching
        )
    }
    
    public var currentUsage: ResourceUsage {
        get async {
            let recognitionMemory = activeRecognitions.count * 15_000_000 // ~15MB per active recognition
            let cacheMemory = resultCache.count * 80_000 // ~80KB per cached result
            let libraryMemory = gestureLibrary.count * 200_000 // ~200KB per gesture template
            let customMemory = customGestures.count * 300_000 // ~300KB per custom gesture
            let historyMemory = recognitionHistory.count * 25_000
            let engineMemory = 30_000_000 // Recognition engine overhead
            
            return ResourceUsage(
                memory: recognitionMemory + cacheMemory + libraryMemory + customMemory + historyMemory + engineMemory,
                cpu: activeRecognitions.isEmpty ? 0.2 : 2.0,
                bandwidth: 0,
                storage: resultCache.count * 40_000 + gestureLibrary.count * 500_000
            )
        }
    }
    
    public func isAvailable() async -> Bool {
        // Gesture recognition is available on iOS 13+
        if #available(iOS 13.0, *) {
            return configuration.enableGestureRecognition
        }
        return false
    }
    
    public func release() async {
        activeRecognitions.removeAll()
        recognitionQueue.removeAll()
        recognitionHistory.removeAll()
        resultCache.removeAll()
        gestureLibrary.removeAll()
        customGestures.removeAll()
        
        recognitionEngine = GestureRecognitionEngine()
        learningModule = GestureLearningModule()
        
        resultStreamContinuation?.finish()
        
        metrics = GestureRecognitionMetrics()
        isProcessingQueue = false
    }
    
    // Internal allocation methods
    internal func allocate() async throws {
        // Initialize gesture recognition components
        recognitionEngine = GestureRecognitionEngine()
        learningModule = GestureLearningModule()
        
        // Load default gesture library
        await loadDefaultGestureLibrary()
        
        if configuration.enableLogging {
            print("[GestureRecognition] 🚀 Gesture Recognition capability initialized")
        }
    }
    
    internal func updateConfiguration(_ configuration: GestureRecognitionCapabilityConfiguration) async throws {
        // Update gesture recognition configurations
    }
    
    // MARK: - Result Streams
    
    public var resultStream: AsyncStream<GestureRecognitionResult> {
        AsyncStream { continuation in
            self.resultStreamContinuation = continuation
        }
    }
    
    // MARK: - Gesture Recognition
    
    public func recognizeGesture(_ request: GestureRecognitionRequest) async throws -> GestureRecognitionResult {
        guard configuration.enableGestureRecognition else {
            throw GestureRecognitionError.gestureRecognitionDisabled
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
        if activeRecognitions.count >= configuration.maxConcurrentGestures {
            recognitionQueue.append(request)
            throw GestureRecognitionError.recognitionQueued(request.id)
        }
        
        let startTime = Date()
        activeRecognitions[request.id] = request
        
        do {
            // Perform gesture recognition
            let recognizedGestures = recognitionEngine.recognizeGesture(
                request.gestureData,
                options: request.options,
                configuration: configuration
            )
            
            // Analyze gesture characteristics
            let gestureAnalysis = analyzeGesture(request.gestureData)
            
            // Process learning feedback if enabled
            var learningFeedback: GestureRecognitionResult.LearningFeedback?
            if configuration.enableGestureLearning, let bestGesture = recognizedGestures.first {
                learningFeedback = learningModule.processLearning(
                    for: bestGesture,
                    gestureData: request.gestureData,
                    configuration: configuration
                )
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            let result = GestureRecognitionResult(
                requestId: request.id,
                recognizedGestures: recognizedGestures,
                gestureAnalysis: gestureAnalysis,
                learningFeedback: learningFeedback,
                processingTime: processingTime,
                success: true,
                metadata: request.metadata
            )
            
            activeRecognitions.removeValue(forKey: request.id)
            recognitionHistory.append(result)
            
            // Cache result if enabled
            if configuration.enableCaching && resultCache.count < configuration.cacheSize {
                let cacheKey = generateCacheKey(for: request)
                resultCache[cacheKey] = result
            }
            
            resultStreamContinuation?.yield(result)
            
            await updateSuccessMetrics(result)
            
            if configuration.enableLogging {
                await logRecognition(result)
            }
            
            // Process queue if available
            if !isProcessingQueue {
                await processRecognitionQueue()
            }
            
            return result
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            let result = GestureRecognitionResult(
                requestId: request.id,
                recognizedGestures: [],
                gestureAnalysis: GestureRecognitionResult.GestureAnalysis(
                    gestureComplexity: 0,
                    smoothness: 0,
                    consistency: 0,
                    speed: 0,
                    pressure: 0,
                    directionality: 0,
                    symmetry: 0,
                    pathLength: 0,
                    averageVelocity: 0,
                    peakVelocity: 0,
                    acceleration: 0,
                    jerk: 0
                ),
                processingTime: processingTime,
                success: false,
                error: error as? GestureRecognitionError ?? GestureRecognitionError.recognitionError(error.localizedDescription)
            )
            
            activeRecognitions.removeValue(forKey: request.id)
            recognitionHistory.append(result)
            
            resultStreamContinuation?.yield(result)
            
            await updateFailureMetrics(result)
            
            if configuration.enableLogging {
                await logRecognition(result)
            }
            
            throw error
        }
    }
    
    public func cancelRecognition(_ requestId: UUID) async {
        activeRecognitions.removeValue(forKey: requestId)
        recognitionQueue.removeAll { $0.id == requestId }
        
        if configuration.enableLogging {
            print("[GestureRecognition] 🚫 Cancelled recognition: \(requestId)")
        }
    }
    
    public func getActiveRecognitions() async -> [GestureRecognitionRequest] {
        return Array(activeRecognitions.values)
    }
    
    public func getRecognitionHistory(since: Date? = nil) async -> [GestureRecognitionResult] {
        if let since = since {
            return recognitionHistory.filter { $0.timestamp >= since }
        }
        return recognitionHistory
    }
    
    // MARK: - Gesture Management
    
    public func addCustomGesture(_ gesture: GestureTemplate) async {
        customGestures[gesture.name] = gesture
        
        if configuration.enableLogging {
            print("[GestureRecognition] 📚 Added custom gesture: \(gesture.name)")
        }
    }
    
    public func removeCustomGesture(_ gestureName: String) async {
        customGestures.removeValue(forKey: gestureName)
        
        if configuration.enableLogging {
            print("[GestureRecognition] 🗑️ Removed custom gesture: \(gestureName)")
        }
    }
    
    public func getGestureLibrary() async -> [String] {
        return Array(gestureLibrary.keys) + Array(customGestures.keys)
    }
    
    // MARK: - Metrics
    
    public func getMetrics() async -> GestureRecognitionMetrics {
        return metrics
    }
    
    public func clearMetrics() async {
        metrics = GestureRecognitionMetrics()
    }
    
    public func clearCache() async {
        resultCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultGestureLibrary() async {
        // Load basic gesture templates
        let basicGestures = [
            "tap", "doubleTap", "longPress", "swipe", "pinch", "rotation", "pan"
        ]
        
        for gestureName in basicGestures {
            let template = GestureTemplate(
                name: gestureName,
                type: gestureTypeFromName(gestureName),
                points: [],
                parameters: [:],
                trainingData: []
            )
            gestureLibrary[gestureName] = template
        }
    }
    
    private func gestureTypeFromName(_ name: String) -> GestureRecognitionResult.RecognizedGesture.GestureType {
        switch name.lowercased() {
        case "tap": return .tap
        case "doubletap": return .doubleTap
        case "longpress": return .longPress
        case "swipe": return .swipe
        case "pinch": return .pinch
        case "rotation": return .rotation
        case "pan": return .pan
        case "circle": return .circle
        case "line": return .line
        default: return .customGesture
        }
    }
    
    private func analyzeGesture(_ gestureData: GestureRecognitionRequest.GestureData) -> GestureRecognitionResult.GestureAnalysis {
        let touchPoints = gestureData.touchPoints.map { $0.location }
        
        // Calculate basic gesture metrics
        let gestureComplexity = calculateComplexity(touchPoints: touchPoints)
        let smoothness = calculateSmoothness(touchPoints: touchPoints)
        let consistency = calculateConsistency(pressures: gestureData.pressure)
        let speed = calculateSpeed(velocities: gestureData.velocity)
        let pressure = gestureData.pressure.reduce(0, +) / Float(gestureData.pressure.count)
        let directionality = calculateDirectionality(touchPoints: touchPoints)
        let symmetry = calculateSymmetry(touchPoints: touchPoints)
        let pathLength = calculatePathLength(touchPoints: touchPoints)
        let averageVelocity = gestureData.velocity.reduce(CGPoint.zero) { result, velocity in
            CGPoint(x: result.x + velocity.x, y: result.y + velocity.y)
        }
        let avgVel = sqrt(pow(averageVelocity.x / CGFloat(gestureData.velocity.count), 2) + pow(averageVelocity.y / CGFloat(gestureData.velocity.count), 2))
        let peakVelocity = gestureData.velocity.map { sqrt(pow($0.x, 2) + pow($0.y, 2)) }.max() ?? 0
        let acceleration = gestureData.acceleration.map { sqrt(pow($0.x, 2) + pow($0.y, 2)) }.reduce(0, +) / CGFloat(gestureData.acceleration.count)
        let jerk = calculateJerk(accelerations: gestureData.acceleration)
        
        return GestureRecognitionResult.GestureAnalysis(
            gestureComplexity: gestureComplexity,
            smoothness: smoothness,
            consistency: consistency,
            speed: speed,
            pressure: Double(pressure),
            directionality: directionality,
            symmetry: symmetry,
            pathLength: pathLength,
            averageVelocity: avgVel,
            peakVelocity: peakVelocity,
            acceleration: acceleration,
            jerk: jerk
        )
    }
    
    private func calculateComplexity(touchPoints: [CGPoint]) -> Double {
        guard touchPoints.count > 1 else { return 0.0 }
        
        var totalAngleChange: Double = 0
        for i in 2..<touchPoints.count {
            let v1 = CGPoint(x: touchPoints[i-1].x - touchPoints[i-2].x, y: touchPoints[i-1].y - touchPoints[i-2].y)
            let v2 = CGPoint(x: touchPoints[i].x - touchPoints[i-1].x, y: touchPoints[i].y - touchPoints[i-1].y)
            
            let angle1 = atan2(v1.y, v1.x)
            let angle2 = atan2(v2.y, v2.x)
            
            totalAngleChange += abs(Double(angle2 - angle1))
        }
        
        return totalAngleChange / Double(touchPoints.count)
    }
    
    private func calculateSmoothness(touchPoints: [CGPoint]) -> Double {
        guard touchPoints.count > 2 else { return 1.0 }
        
        var totalVariation: Double = 0
        for i in 1..<touchPoints.count-1 {
            let curvature = calculateCurvature(
                p1: touchPoints[i-1],
                p2: touchPoints[i],
                p3: touchPoints[i+1]
            )
            totalVariation += abs(curvature)
        }
        
        return max(0.0, 1.0 - (totalVariation / Double(touchPoints.count)))
    }
    
    private func calculateCurvature(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Double {
        let area = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y))
        let d1 = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
        let d2 = sqrt(pow(p3.x - p2.x, 2) + pow(p3.y - p2.y, 2))
        let d3 = sqrt(pow(p3.x - p1.x, 2) + pow(p3.y - p1.y, 2))
        
        guard d1 > 0 && d2 > 0 && d3 > 0 else { return 0.0 }
        return Double(4 * area / (d1 * d2 * d3))
    }
    
    private func calculateConsistency(pressures: [Float]) -> Double {
        guard !pressures.isEmpty else { return 1.0 }
        
        let average = pressures.reduce(0, +) / Float(pressures.count)
        let variance = pressures.map { pow($0 - average, 2) }.reduce(0, +) / Float(pressures.count)
        
        return max(0.0, 1.0 - Double(sqrt(variance) / average))
    }
    
    private func calculateSpeed(velocities: [CGPoint]) -> Double {
        guard !velocities.isEmpty else { return 0.0 }
        
        let speeds = velocities.map { sqrt(pow($0.x, 2) + pow($0.y, 2)) }
        return Double(speeds.reduce(0, +) / CGFloat(speeds.count))
    }
    
    private func calculateDirectionality(touchPoints: [CGPoint]) -> Double {
        guard touchPoints.count > 1 else { return 0.0 }
        
        let startPoint = touchPoints.first!
        let endPoint = touchPoints.last!
        let directDistance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
        let pathLength = calculatePathLength(touchPoints: touchPoints)
        
        guard pathLength > 0 else { return 0.0 }
        return Double(directDistance / pathLength)
    }
    
    private func calculateSymmetry(touchPoints: [CGPoint]) -> Double {
        guard touchPoints.count > 4 else { return 0.5 }
        
        let center = touchPoints.reduce(CGPoint.zero) { result, point in
            CGPoint(x: result.x + point.x, y: result.y + point.y)
        }
        let centerPoint = CGPoint(x: center.x / CGFloat(touchPoints.count), y: center.y / CGFloat(touchPoints.count))
        
        var symmetryScore = 0.0
        let halfCount = touchPoints.count / 2
        
        for i in 0..<halfCount {
            let point1 = touchPoints[i]
            let point2 = touchPoints[touchPoints.count - 1 - i]
            
            let distance1 = sqrt(pow(point1.x - centerPoint.x, 2) + pow(point1.y - centerPoint.y, 2))
            let distance2 = sqrt(pow(point2.x - centerPoint.x, 2) + pow(point2.y - centerPoint.y, 2))
            
            let similarity = 1.0 - abs(distance1 - distance2) / max(distance1, distance2)
            symmetryScore += Double(similarity)
        }
        
        return symmetryScore / Double(halfCount)
    }
    
    private func calculatePathLength(touchPoints: [CGPoint]) -> CGFloat {
        guard touchPoints.count > 1 else { return 0 }
        
        var length: CGFloat = 0
        for i in 1..<touchPoints.count {
            let distance = sqrt(pow(touchPoints[i].x - touchPoints[i-1].x, 2) + pow(touchPoints[i].y - touchPoints[i-1].y, 2))
            length += distance
        }
        return length
    }
    
    private func calculateJerk(accelerations: [CGPoint]) -> CGFloat {
        guard accelerations.count > 1 else { return 0 }
        
        var totalJerk: CGFloat = 0
        for i in 1..<accelerations.count {
            let jerkX = accelerations[i].x - accelerations[i-1].x
            let jerkY = accelerations[i].y - accelerations[i-1].y
            totalJerk += sqrt(pow(jerkX, 2) + pow(jerkY, 2))
        }
        
        return totalJerk / CGFloat(accelerations.count - 1)
    }
    
    private func processRecognitionQueue() async {
        guard !isProcessingQueue && !recognitionQueue.isEmpty else { return }
        
        isProcessingQueue = true
        
        // Sort queue by priority
        recognitionQueue.sort { request1, request2 in
            let priority1 = priorityValue(for: request1.priority)
            let priority2 = priorityValue(for: request2.priority)
            return priority1 > priority2
        }
        
        while !recognitionQueue.isEmpty && activeRecognitions.count < configuration.maxConcurrentGestures {
            let request = recognitionQueue.removeFirst()
            
            do {
                _ = try await recognizeGesture(request)
            } catch {
                if configuration.enableLogging {
                    print("[GestureRecognition] ⚠️ Queued recognition failed: \(request.id)")
                }
            }
        }
        
        isProcessingQueue = false
    }
    
    private func priorityValue(for priority: GestureRecognitionRequest.Priority) -> Int {
        switch priority {
        case .low: return 1
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    private func generateCacheKey(for request: GestureRecognitionRequest) -> String {
        let touchPointsHash = request.gestureData.touchPoints.map { "\($0.location.x),\($0.location.y)" }.joined(separator: "|").hashValue
        let optionsHash = String(describing: request.options).hashValue
        let sensitivityHash = configuration.recognitionSensitivity.rawValue.hashValue
        
        return "\(touchPointsHash)_\(optionsHash)_\(sensitivityHash)"
    }
    
    private func updateCacheHitMetrics() async {
        // Update cache hit metrics
        let totalRecognitions = metrics.totalRecognitions + 1
        
        metrics = GestureRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions + 1,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByType: metrics.recognitionsByType,
            recognitionsByMethod: metrics.recognitionsByMethod,
            errorsByType: metrics.errorsByType,
            averageConfidence: metrics.averageConfidence,
            learningAccuracy: metrics.learningAccuracy,
            modelPerformance: metrics.modelPerformance,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func updateSuccessMetrics(_ result: GestureRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let successfulRecognitions = metrics.successfulRecognitions + 1
        
        let newAverageProcessingTime = ((metrics.averageProcessingTime * Double(metrics.totalRecognitions)) + result.processingTime) / Double(totalRecognitions)
        
        var recognitionsByType = metrics.recognitionsByType
        for gesture in result.recognizedGestures {
            recognitionsByType[gesture.gestureType.rawValue, default: 0] += 1
        }
        
        var recognitionsByMethod = metrics.recognitionsByMethod
        for gesture in result.recognizedGestures {
            recognitionsByMethod[gesture.recognitionMethod.rawValue, default: 0] += 1
        }
        
        let newAverageConfidence = ((metrics.averageConfidence * Double(metrics.successfulRecognitions)) + Double(result.averageConfidence)) / Double(successfulRecognitions)
        
        let newLearningAccuracy = result.learningFeedback?.learningAccuracy ?? metrics.learningAccuracy
        let newModelPerformance = ((metrics.modelPerformance * Double(metrics.successfulRecognitions)) + Double(result.averageConfidence)) / Double(successfulRecognitions)
        
        // Update performance stats
        var performanceStats = metrics.performanceStats
        let bestTime = metrics.successfulRecognitions == 0 ? result.processingTime : min(performanceStats.bestRecognitionTime, result.processingTime)
        let worstTime = max(performanceStats.worstRecognitionTime, result.processingTime)
        let newAverageGesturesPerRequest = ((performanceStats.averageGesturesPerRequest * Double(metrics.successfulRecognitions)) + Double(result.recognizedGestures.count)) / Double(successfulRecognitions)
        let newAverageComplexity = ((performanceStats.averageComplexity * Double(metrics.successfulRecognitions)) + result.gestureAnalysis.gestureComplexity) / Double(successfulRecognitions)
        let newLearningProgressRate = result.learningFeedback?.trainingProgress ?? performanceStats.learningProgressRate
        let newModelAccuracyImprovement = result.learningFeedback?.recognitionImprovement ?? performanceStats.modelAccuracyImprovement
        
        performanceStats = GestureRecognitionMetrics.PerformanceStats(
            bestRecognitionTime: bestTime,
            worstRecognitionTime: worstTime,
            averageGesturesPerRequest: newAverageGesturesPerRequest,
            averageComplexity: newAverageComplexity,
            learningProgressRate: newLearningProgressRate,
            modelAccuracyImprovement: newModelAccuracyImprovement,
            totalCustomGestures: performanceStats.totalCustomGestures,
            activeGestureLibraries: performanceStats.activeGestureLibraries
        )
        
        metrics = GestureRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: successfulRecognitions,
            failedRecognitions: metrics.failedRecognitions,
            averageProcessingTime: newAverageProcessingTime,
            recognitionsByType: recognitionsByType,
            recognitionsByMethod: recognitionsByMethod,
            errorsByType: metrics.errorsByType,
            averageConfidence: newAverageConfidence,
            learningAccuracy: newLearningAccuracy,
            modelPerformance: newModelPerformance,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: performanceStats
        )
    }
    
    private func updateFailureMetrics(_ result: GestureRecognitionResult) async {
        let totalRecognitions = metrics.totalRecognitions + 1
        let failedRecognitions = metrics.failedRecognitions + 1
        
        var errorsByType = metrics.errorsByType
        if let error = result.error {
            let errorKey = String(describing: type(of: error))
            errorsByType[errorKey, default: 0] += 1
        }
        
        metrics = GestureRecognitionMetrics(
            totalRecognitions: totalRecognitions,
            successfulRecognitions: metrics.successfulRecognitions,
            failedRecognitions: failedRecognitions,
            averageProcessingTime: metrics.averageProcessingTime,
            recognitionsByType: metrics.recognitionsByType,
            recognitionsByMethod: metrics.recognitionsByMethod,
            errorsByType: errorsByType,
            averageConfidence: metrics.averageConfidence,
            learningAccuracy: metrics.learningAccuracy,
            modelPerformance: metrics.modelPerformance,
            throughputPerSecond: metrics.throughputPerSecond,
            performanceStats: metrics.performanceStats
        )
    }
    
    private func logRecognition(_ result: GestureRecognitionResult) async {
        let statusIcon = result.success ? "✅" : "❌"
        let timeStr = String(format: "%.3f", result.processingTime)
        let gestureCount = result.recognizedGestures.count
        let avgConfidence = String(format: "%.3f", result.averageConfidence)
        let complexity = String(format: "%.2f", result.gestureAnalysis.gestureComplexity)
        
        print("[GestureRecognition] \(statusIcon) Recognition: \(gestureCount) gestures, avg confidence: \(avgConfidence), complexity: \(complexity) (\(timeStr)s)")
        
        for gesture in result.recognizedGestures {
            print("[GestureRecognition] 👆 \(gesture.gestureName) (\(gesture.gestureType.rawValue)): \(String(format: "%.3f", gesture.confidence))")
        }
        
        if let error = result.error {
            print("[GestureRecognition] ⚠️ ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Gesture Recognition Capability Implementation

/// Gesture Recognition capability providing custom gesture recognition and learning
@available(iOS 13.0, macOS 10.15, *)
public actor GestureRecognitionCapability: DomainCapability {
    public typealias ConfigurationType = GestureRecognitionCapabilityConfiguration
    public typealias ResourceType = GestureRecognitionCapabilityResource
    
    private var _configuration: GestureRecognitionCapabilityConfiguration
    private var _resources: GestureRecognitionCapabilityResource
    private var _environment: AxiomCapabilityEnvironment
    private var _state: AxiomCapabilityState = .unknown
    private var _activationTimeout: Duration = .seconds(8)
    private var stateStreamContinuation: AsyncStream<AxiomCapabilityState>.Continuation?
    
    public nonisolated var id: String { "gesture-recognition-capability" }
    
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
    
    public var configuration: GestureRecognitionCapabilityConfiguration {
        get async { _configuration }
    }
    
    public var resources: GestureRecognitionCapabilityResource {
        get async { _resources }
    }
    
    public var environment: AxiomCapabilityEnvironment {
        get async { _environment }
    }
    
    public init(
        configuration: GestureRecognitionCapabilityConfiguration = GestureRecognitionCapabilityConfiguration(),
        environment: AxiomCapabilityEnvironment = AxiomCapabilityEnvironment()
    ) {
        self._configuration = configuration.adjusted(for: environment)
        self._resources = GestureRecognitionCapabilityResource(configuration: self._configuration)
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
    
    public func updateConfiguration(_ configuration: GestureRecognitionCapabilityConfiguration) async throws {
        guard configuration.isValid else {
            throw AxiomCapabilityError.initializationFailed("Invalid Gesture Recognition configuration")
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
        // Gesture recognition is supported on iOS 13+
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }
    
    public func requestPermission() async throws {
        // Gesture recognition doesn't require special permissions
    }
    
    public func setActivationTimeout(_ timeout: Duration) async {
        _activationTimeout = timeout
    }
    
    // MARK: - Gesture Recognition Operations
    
    /// Recognize gesture from input data
    public func recognizeGesture(_ request: GestureRecognitionRequest) async throws -> GestureRecognitionResult {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return try await _resources.recognizeGesture(request)
    }
    
    /// Cancel gesture recognition
    public func cancelRecognition(_ requestId: UUID) async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        await _resources.cancelRecognition(requestId)
    }
    
    /// Get result stream
    public func getResultStream() async throws -> AsyncStream<GestureRecognitionResult> {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return await _resources.resultStream
    }
    
    /// Get active recognitions
    public func getActiveRecognitions() async throws -> [GestureRecognitionRequest] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return await _resources.getActiveRecognitions()
    }
    
    /// Get recognition history
    public func getRecognitionHistory(since: Date? = nil) async throws -> [GestureRecognitionResult] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return await _resources.getRecognitionHistory(since: since)
    }
    
    /// Get gesture library
    public func getGestureLibrary() async throws -> [String] {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return await _resources.getGestureLibrary()
    }
    
    /// Get metrics
    public func getMetrics() async throws -> GestureRecognitionMetrics {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        return await _resources.getMetrics()
    }
    
    /// Clear metrics
    public func clearMetrics() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        await _resources.clearMetrics()
    }
    
    /// Clear cache
    public func clearCache() async throws {
        guard await isAvailable else {
            throw AxiomCapabilityError.unavailable("Gesture Recognition capability not available")
        }
        
        await _resources.clearCache()
    }
    
    // MARK: - Convenience Methods
    
    /// Create simple tap gesture request
    public func createTapGestureRequest(at location: CGPoint, timestamp: Date = Date()) -> GestureRecognitionRequest {
        let touchPoint = GestureRecognitionRequest.GestureData.TouchPoint(
            location: location,
            timestamp: timestamp.timeIntervalSinceReferenceDate,
            touchId: 1,
            phase: .began
        )
        
        let gestureData = GestureRecognitionRequest.GestureData(
            touchPoints: [touchPoint],
            timeSequence: [0.0],
            pressure: [1.0],
            velocity: [CGPoint.zero],
            acceleration: [CGPoint.zero],
            deviceOrientation: .portrait,
            screenSize: CGSize(width: 320, height: 568),
            activeTouches: 1,
            gestureStartTime: timestamp
        )
        
        return GestureRecognitionRequest(gestureData: gestureData)
    }
    
    /// Create swipe gesture request
    public func createSwipeGestureRequest(from startPoint: CGPoint, to endPoint: CGPoint, duration: TimeInterval = 0.5) -> GestureRecognitionRequest {
        let steps = 10
        var touchPoints: [GestureRecognitionRequest.GestureData.TouchPoint] = []
        var timeSequence: [TimeInterval] = []
        var pressures: [Float] = []
        var velocities: [CGPoint] = []
        
        for i in 0...steps {
            let progress = CGFloat(i) / CGFloat(steps)
            let location = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * progress,
                y: startPoint.y + (endPoint.y - startPoint.y) * progress
            )
            
            let touchPoint = GestureRecognitionRequest.GestureData.TouchPoint(
                location: location,
                timestamp: duration * Double(i) / Double(steps),
                touchId: 1,
                phase: i == 0 ? .began : (i == steps ? .ended : .moved)
            )
            
            touchPoints.append(touchPoint)
            timeSequence.append(duration * Double(i) / Double(steps))
            pressures.append(1.0)
            
            if i > 0 {
                let velocity = CGPoint(
                    x: (location.x - touchPoints[i-1].location.x) / CGFloat(duration / Double(steps)),
                    y: (location.y - touchPoints[i-1].location.y) / CGFloat(duration / Double(steps))
                )
                velocities.append(velocity)
            } else {
                velocities.append(CGPoint.zero)
            }
        }
        
        let gestureData = GestureRecognitionRequest.GestureData(
            touchPoints: touchPoints,
            timeSequence: timeSequence,
            pressure: pressures,
            velocity: velocities,
            acceleration: Array(repeating: CGPoint.zero, count: touchPoints.count),
            deviceOrientation: .portrait,
            screenSize: CGSize(width: 320, height: 568),
            activeTouches: 1,
            gestureStartTime: Date()
        )
        
        return GestureRecognitionRequest(gestureData: gestureData)
    }
    
    /// Check if gesture recognition is active
    public func hasActiveRecognitions() async throws -> Bool {
        let activeRecognitions = try await getActiveRecognitions()
        return !activeRecognitions.isEmpty
    }
    
    /// Get average recognition confidence
    public func getAverageConfidence() async throws -> Double {
        let metrics = try await getMetrics()
        return metrics.averageConfidence
    }
    
    // MARK: - Private Methods
    
    private func transitionTo(_ newState: AxiomCapabilityState) async {
        guard _state != newState else { return }
        _state = newState
        stateStreamContinuation?.yield(newState)
    }
}

// MARK: - Error Types

/// Gesture Recognition specific errors
public enum GestureRecognitionError: Error, LocalizedError {
    case gestureRecognitionDisabled
    case invalidGestureData
    case recognitionError(String)
    case recognitionQueued(UUID)
    case recognitionTimeout(UUID)
    case gestureLibraryError(String)
    case learningModuleError(String)
    case customGestureError(String)
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .gestureRecognitionDisabled:
            return "Gesture recognition is disabled"
        case .invalidGestureData:
            return "Invalid gesture data provided"
        case .recognitionError(let reason):
            return "Gesture recognition failed: \(reason)"
        case .recognitionQueued(let id):
            return "Recognition queued: \(id)"
        case .recognitionTimeout(let id):
            return "Recognition timeout: \(id)"
        case .gestureLibraryError(let reason):
            return "Gesture library error: \(reason)"
        case .learningModuleError(let reason):
            return "Learning module error: \(reason)"
        case .customGestureError(let reason):
            return "Custom gesture error: \(reason)"
        case .configurationError(let reason):
            return "Gesture recognition configuration error: \(reason)"
        }
    }
}